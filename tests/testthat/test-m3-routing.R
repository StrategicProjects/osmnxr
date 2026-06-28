test_that("ox_k_shortest_paths returns ordered distinct paths", {
  g <- example_osm_graph(n = 4, spacing = 100)
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 100, 0) # adjacent node: only one shortest path
  kp <- ox_k_shortest_paths(g, from, to, k = 3)
  expect_s3_class(kp, "tbl_df")
  expect_true(all(diff(kp$cost) >= 0)) # non-decreasing cost
  expect_identical(kp$path[[1]], c(from, to))
  expect_equal(kp$cost[1], 100)
})

test_that("ox_distance_matrix has correct shape and dimnames", {
  g <- example_osm_graph(n = 3, spacing = 100)
  nodes <- g$nodes$osmid
  m <- ox_distance_matrix(g, from = nodes[1:2], to = nodes[3:4])
  expect_equal(dim(m), c(2, 2))
  expect_equal(rownames(m), as.character(nodes[1:2]))
  expect_true(all(is.finite(m)))
})

test_that("distance matrix diagonal is zero", {
  g <- example_osm_graph(n = 3)
  nodes <- g$nodes$osmid
  m <- ox_distance_matrix(g, nodes, nodes)
  expect_equal(unname(diag(m)), rep(0, length(nodes)))
})

test_that("ox_add_edge_speeds and travel_times add usable columns", {
  g <- example_osm_graph()
  g <- ox_add_edge_speeds(g, speeds = c(residential = 25))
  expect_true("speed_kph" %in% names(g$edges))
  expect_true(all(g$edges$speed_kph == 25))

  g <- ox_add_edge_travel_times(g)
  expect_true("travel_time" %in% names(g$edges))
  # 100 m at 25 km/h = 100 / (25/3.6) = 14.4 s
  expect_equal(round(g$edges$travel_time[1], 1), 14.4)
})

test_that("travel-time routing is consistent with distance routing on a grid", {
  g <- ox_add_edge_travel_times(example_osm_graph(n = 4))
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 300, 300)
  # uniform speed -> same path shape length as distance routing
  p_time <- ox_shortest_path(g, from, to, weight = "travel_time")
  p_dist <- ox_shortest_path(g, from, to, weight = "length")
  expect_equal(length(p_time), length(p_dist))
})

test_that("ox_isochrone returns one polygon per reachable cutoff", {
  g <- example_osm_graph(n = 6, spacing = 100)
  center <- ox_nearest_nodes(g, 250, 250)
  iso <- ox_isochrone(g, center, cutoffs = c(100, 300))
  expect_s3_class(iso, "sf")
  expect_equal(nrow(iso), 2)
  expect_equal(iso$cutoff, c(300, 100)) # largest first
  expect_true(all(sf::st_geometry_type(iso) == "POLYGON"))
  # bigger cutoff reaches more nodes and covers more area
  expect_gt(iso$n_nodes[1], iso$n_nodes[2])
  expect_gt(as.numeric(sf::st_area(iso)[1]), as.numeric(sf::st_area(iso)[2]))
})

test_that("ox_isochrone supports multiple origins", {
  g <- example_osm_graph(n = 6, spacing = 100)
  centers <- ox_nearest_nodes(g, c(0, 500), c(0, 500))
  iso <- ox_isochrone(g, centers, cutoffs = 200)
  expect_equal(nrow(iso), 1)
})
