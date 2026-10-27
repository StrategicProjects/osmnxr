# helper: directed diamond with a cheap residential route (1-2-4, cost 2,
# penalty 10), an expensive clean route (1-3-4, cost 6, penalty 0) and a
# dominated direct service edge (1-4, cost 10, penalty 2)
diamond_graph <- function() {
  pts <- rbind(c(0, 0), c(1, 1), c(1, -1), c(2, 0))
  nodes <- sf::st_as_sf(
    data.frame(osmid = 1:4, x = pts[, 1], y = pts[, 2]),
    coords = c("x", "y"), crs = 3857, remove = FALSE
  )
  e <- data.frame(
    u = c(1, 2, 1, 3, 1),
    v = c(2, 4, 3, 4, 4),
    osmid = 1:5,
    highway = c("residential", "residential", "primary", "primary", "service"),
    length = c(1, 1, 3, 3, 10)
  )
  geoms <- lapply(seq_len(nrow(e)), function(i) {
    sf::st_linestring(pts[c(e$u[i], e$v[i]), ])
  })
  edges <- sf::st_sf(e, geometry = sf::st_sfc(geoms, crs = 3857))
  g <- new_osm_graph(nodes, edges, meta = list(simplified = TRUE))
  ox_add_edge_penalties(g, c(residential = 5, service = 0.2))
}

test_that("ox_add_edge_penalties builds factor * weight columns", {
  g <- diamond_graph()
  expect_equal(g$edges$penalty, c(5, 5, 0, 0, 2))
  g2 <- ox_add_edge_penalties(g, c(primary = 2), weight = "length", name = "res2")
  expect_equal(g2$edges$res2, c(0, 0, 6, 6, 0))
  expect_error(ox_add_edge_penalties(g, c(1, 2)), "named")
  expect_error(ox_add_edge_penalties(g, c(residential = 1), weight = "nope"), "not found")
})

test_that("ox_route_pareto returns the exact Pareto front as sf", {
  g <- diamond_graph()
  front <- ox_route_pareto(g, 1, 4, resource = "penalty")
  expect_s3_class(front, "sf")
  expect_equal(front$route, 1:2)
  expect_equal(front$cost, c(2, 6))
  expect_equal(front$resource, c(10, 0))
  expect_equal(front$path, list(c(1, 2, 4), c(1, 3, 4)))
  expect_true(all(sf::st_geometry_type(front) %in% c("LINESTRING", "MULTILINESTRING")))
  expect_false(any(sf::st_is_empty(front)))
  # costs/resources agree with the edge columns along each path
  for (i in seq_len(nrow(front))) {
    p <- front$path[[i]]
    idx <- match(paste(p[-length(p)], p[-1]), paste(g$edges$u, g$edges$v))
    expect_equal(front$cost[i], sum(g$edges$length[idx]))
    expect_equal(front$resource[i], sum(g$edges$penalty[idx]))
  }
})

test_that("budget restricts the front and max_routes caps it", {
  g <- diamond_graph()
  within5 <- ox_route_pareto(g, 1, 4, resource = "penalty", budget = 5)
  expect_equal(within5$cost, 6)
  expect_equal(within5$resource, 0)
  capped <- ox_route_pareto(g, 1, 4, resource = "penalty", max_routes = 1)
  expect_equal(nrow(capped), 1)
  expect_equal(capped$cost, 2)
})

test_that("ox_route_constrained solves the budgeted problem exactly", {
  g <- diamond_graph()
  r <- ox_route_constrained(g, 1, 4, resource = "penalty", budget = 5)
  expect_s3_class(r, "sf")
  expect_false("route" %in% names(r))
  expect_equal(r$cost, 6)
  expect_equal(r$lower_bound, r$cost) # exact answers are certified
  expect_equal(r$path[[1]], c(1, 3, 4))
  # a loose budget recovers the unconstrained shortest path
  loose <- ox_route_constrained(g, 1, 4, resource = "penalty", budget = Inf)
  expect_equal(loose$path[[1]], ox_shortest_path(g, 1, 4))
  expect_error(ox_route_constrained(g, 1, 4, resource = "penalty"), "budget")
})

test_that("infeasible budgets and unreachable targets error informatively", {
  g <- diamond_graph()
  # node 2 is only reachable over 5 penalty units
  expect_error(
    ox_route_constrained(g, 1, 2, resource = "penalty", budget = 1),
    "minimum possible"
  )
  # edges are directed: nothing leads back to node 1
  expect_error(ox_route_pareto(g, 4, 1, resource = "penalty"), "No route")
})

test_that("input validation errors are caught", {
  g <- diamond_graph()
  expect_error(ox_route_pareto(g, 1, 4, resource = "nope"), "not found")
  expect_error(ox_route_pareto(g, 1, 4), "resource")
  expect_error(ox_route_pareto(g, 1, 4, resource = "penalty", budget = -1), "nonnegative")
  expect_error(ox_route_pareto(g, 1, 4, resource = "penalty", max_routes = 0), ">= 1")
  expect_error(ox_route_pareto(g, 1, 99, resource = "penalty"), "osmid")
  g$edges$penalty[1] <- -1
  expect_error(ox_route_pareto(g, 1, 4, resource = "penalty"), "nonnegative")
})

test_that("constrained routing works on the example grid", {
  g <- example_osm_graph()
  # north-south streets residential, east-west primary; any route from corner
  # to corner must climb 300 m of residential streets
  g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
  g <- ox_add_edge_penalties(g, c(residential = 1))
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 300, 300)
  front <- ox_route_pareto(g, from, to, resource = "penalty")
  expect_equal(front$cost, 600)
  expect_equal(front$resource, 300)
  r <- ox_route_constrained(g, from, to, resource = "penalty", budget = 300)
  expect_equal(r$cost, 600)
  expect_error(
    ox_route_constrained(g, from, to, resource = "penalty", budget = 299),
    "minimum possible"
  )
})

test_that("the Lagrangian method returns a feasible route with a bound", {
  g <- diamond_graph()
  # budget 5 on the diamond has a known duality gap (optimum 6, dual peak 4)
  expect_message(
    r <- ox_route_constrained(g, 1, 4, resource = "penalty", budget = 5,
                              method = "lagrangian"),
    "lower bound"
  )
  expect_equal(r$cost, 6)
  expect_equal(r$resource, 0)
  expect_equal(r$path[[1]], c(1, 3, 4))
  expect_true(r$lower_bound <= r$cost)
  # a loose budget takes the unconstrained shortcut: certified, no message
  expect_no_message(
    r2 <- ox_route_constrained(g, 1, 4, resource = "penalty", budget = 100,
                               method = "lagrangian")
  )
  expect_equal(r2$cost, 2)
  expect_equal(r2$lower_bound, 2)
  # same error paths as the exact method
  expect_error(
    ox_route_constrained(g, 1, 2, resource = "penalty", budget = 1,
                         method = "lagrangian"),
    "minimum possible"
  )
  expect_error(
    ox_route_constrained(g, 4, 1, resource = "penalty", budget = 10,
                         method = "lagrangian"),
    "No route"
  )
})

test_that("both methods agree on the example grid", {
  g <- example_osm_graph()
  g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
  g <- ox_add_edge_penalties(g, c(residential = 1))
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 300, 300)
  exact <- ox_route_constrained(g, from, to, resource = "penalty", budget = 300)
  lagr <- suppressMessages(
    ox_route_constrained(g, from, to, resource = "penalty", budget = 300,
                         method = "lagrangian")
  )
  expect_equal(lagr$cost, exact$cost)
  expect_true(lagr$resource <= 300)
  expect_true(lagr$lower_bound <= exact$cost)
})

test_that("a trivial route from a node to itself works", {
  g <- diamond_graph()
  r <- ox_route_pareto(g, 2, 2, resource = "penalty")
  expect_equal(r$cost, 0)
  expect_equal(r$resource, 0)
  expect_equal(r$path[[1]], 2)
})
