# ox_route_tsp() ---------------------------------------------------------------

# All permutations of a vector (small n only), for brute-force optima.
perms <- function(v) {
  if (length(v) <= 1) return(list(v))
  out <- list()
  for (i in seq_along(v)) {
    for (p in perms(v[-i])) out[[length(out) + 1]] <- c(v[i], p)
  }
  out
}

test_that("closed tour visits every stop once and returns to start", {
  g <- example_osm_graph()
  stops <- c(1, 4, 13, 16, 6)
  route <- ox_route_tsp(g, stops)

  expect_s3_class(route, "sf")
  expect_equal(nrow(route), length(stops))
  expect_equal(route$from[1], stops[1])
  expect_equal(route$to[nrow(route)], stops[1])
  expect_setequal(route$from, stops)
  expect_true(all(is.finite(route$cost)))
  # legs chain: each leg ends where the next begins
  expect_equal(route$to[-nrow(route)], route$from[-1])
})

test_that("closed tour matches the brute-force optimum on a small instance", {
  g <- example_osm_graph()
  stops <- c(1, 4, 13, 16, 6)
  route <- ox_route_tsp(g, stops)

  m <- ox_distance_matrix(g, from = stops, to = stops)
  best <- Inf
  for (p in perms(2:length(stops))) {
    tour <- c(1, p, 1)
    best <- min(best, sum(m[cbind(tour[-length(tour)], tour[-1])]))
  }
  expect_equal(sum(route$cost), best)
})

test_that("leg paths and geometry are consistent with costs", {
  g <- example_osm_graph()
  stops <- c(1, 16, 7, 10)
  route <- ox_route_tsp(g, stops)

  for (i in seq_len(nrow(route))) {
    p <- route$path[[i]]
    expect_equal(p[1], route$from[i])
    expect_equal(p[length(p)], route$to[i])
  }
  # in the synthetic grid, edge weight is geometric length, so each leg's
  # merged geometry must measure exactly its cost
  expect_equal(as.numeric(sf::st_length(route)), route$cost)
})

test_that("open routes honour free and pinned endpoints", {
  g <- example_osm_graph()
  stops <- c(1, 4, 13, 16, 6)

  open_free <- ox_route_tsp(g, stops, end = NULL)
  expect_equal(nrow(open_free), length(stops) - 1)
  expect_equal(open_free$from[1], stops[1])

  pinned <- ox_route_tsp(g, stops, start = 2, end = 5)
  expect_equal(pinned$from[1], stops[2])
  expect_equal(pinned$to[nrow(pinned)], stops[5])
  expect_setequal(c(pinned$from[1], pinned$to), stops)
})

test_that("iterated local search never does worse than plain nearest-neighbour", {
  g <- example_osm_graph(n = 5)
  stops <- c(1, 25, 13, 5, 21, 8, 17)
  nn <- ox_route_tsp(g, stops, method = "nn")
  opt <- ox_route_tsp(g, stops, method = "ils")
  expect_lte(sum(opt$cost), sum(nn$cost))
})

test_that("invalid inputs abort cleanly", {
  g <- example_osm_graph()
  expect_error(ox_route_tsp(g, 1), "at least 2")
  expect_error(ox_route_tsp(g, c(1, 1, 4)), "duplicated")
  expect_error(ox_route_tsp(g, c(1, 4, 13), start = 7), "start")
  expect_error(ox_route_tsp(g, c(1, 4, 13), end = 0), "end")
  expect_error(ox_route_tsp(g, c(1, 4, 999)), "present in the graph")
})

test_that("mutually unreachable stops abort with an informative error", {
  pts <- sf::st_sfc(
    sf::st_point(c(0, 0)), sf::st_point(c(1, 0)), sf::st_point(c(5, 5)),
    crs = 3857
  )
  nodes <- sf::st_sf(osmid = c(1, 2, 3), geometry = pts)
  seg <- sf::st_sfc(sf::st_linestring(rbind(c(0, 0), c(1, 0))), crs = 3857)
  edges <- sf::st_sf(u = 1, v = 2, length = 1, geometry = seg)
  g <- new_osm_graph(nodes, edges)
  expect_error(ox_route_tsp(g, c(1, 2, 3)), "not mutually reachable")
})
