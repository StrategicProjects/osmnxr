# ox_route_shortest(): the sf routing interface + the session edge-index cache

test_that("ox_route_shortest returns an sf route with cost and geometry", {
  g <- example_osm_graph()
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 300, 300)

  r <- ox_route_shortest(g, from, to)
  expect_s3_class(r, "sf")
  expect_equal(nrow(r), 1)
  expect_equal(r$route, 1)
  expect_equal(r$cost, 600)
  expect_equal(r$path[[1]], ox_shortest_path(g, from, to))
  expect_equal(as.numeric(sf::st_length(r)), 600)
})

test_that("ox_route_shortest(k > 1) returns ordered alternatives", {
  g <- example_osm_graph()
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 200, 200)

  r <- ox_route_shortest(g, from, to, k = 3)
  expect_equal(nrow(r), 3)
  expect_equal(r$route, 1:3)
  expect_false(is.unsorted(r$cost))
  ks <- ox_k_shortest_paths(g, from, to, k = 3)
  expect_equal(r$cost, ks$cost)
  expect_equal(r$path, ks$path)
  # each route's geometry covers its cost in length
  expect_equal(as.numeric(sf::st_length(r)), r$cost)
})

test_that("ox_route_shortest draws the traversed parallel edge", {
  g <- example_osm_graph(n = 2)
  # add an expensive curvy twin of the 1 -> 2 edge; Dijkstra must keep
  # using (and drawing) the straight cheap one
  curvy <- g$edges[g$edges$u == 1 & g$edges$v == 2, ][1, ]
  sf::st_geometry(curvy) <- sf::st_sfc(
    sf::st_linestring(rbind(c(0, 0), c(50, 60), c(0, 100))), crs = 3857
  )
  curvy$length <- as.numeric(sf::st_length(curvy))
  g$edges <- rbind(g$edges, curvy)

  r <- ox_route_shortest(g, 1, 2)
  expect_equal(r$cost, 100)
  expect_equal(as.numeric(sf::st_length(r)), 100)
})

test_that("ox_route_shortest validates and errors on unreachable targets", {
  g <- example_osm_graph()
  # a one-way island: edge into nowhere
  g$edges <- g$edges[!(g$edges$u == 16 | g$edges$v == 16), ]
  expect_error(ox_route_shortest(g, 1, 16), "No route")
  expect_error(ox_route_shortest(g, 1, 6, k = 0), "k")
  expect_error(ox_route_shortest(g, 1, 99999), "osmid")
})

test_that("the edge-index cache is content-addressed, not stale", {
  ox_clear_cache()
  g <- example_osm_graph()
  d1 <- ox_distances(g, 1)$distance[16]

  # warm cache, then mutate the graph structure in place: results must follow
  g2 <- g
  keep <- !(g2$edges$u == 1 & g2$edges$v == 5) & !(g2$edges$u == 5 & g2$edges$v == 1)
  g2$edges <- g2$edges[keep, ]
  d2 <- ox_distances(g2, 1)$distance[16]
  expect_equal(d1, d2) # the grid has alternate routes of equal length
  expect_equal(nrow(ox_route_shortest(g2, 1, 16)), 1)
  # the original graph still routes identically from its own cache entry
  expect_equal(ox_distances(g, 1)$distance[16], d1)
  p <- ox_shortest_path(g2, 1, 16)
  expect_false(any(p[-length(p)] == 1 & p[-1] == 5))
  ox_clear_cache()
})
