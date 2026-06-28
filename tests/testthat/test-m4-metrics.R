test_that("ox_centrality returns requested columns", {
  g <- example_osm_graph(n = 4)
  both <- ox_centrality(g)
  expect_named(both, c("osmid", "betweenness", "closeness"))
  expect_equal(nrow(both), nrow(g$nodes))

  only_b <- ox_centrality(g, type = "betweenness")
  expect_named(only_b, c("osmid", "betweenness"))
})

test_that("grid centre has the highest centrality", {
  g <- example_osm_graph(n = 5, spacing = 100)
  ct <- ox_centrality(g, normalized = TRUE)
  centre <- ox_nearest_nodes(g, 200, 200) # middle of a 5x5 grid (0..400)
  expect_equal(ct$osmid[which.max(ct$betweenness)], centre)
  expect_equal(ct$osmid[which.max(ct$closeness)], centre)
})

test_that("betweenness of corners is lower than the centre", {
  g <- example_osm_graph(n = 5, spacing = 100)
  ct <- ox_centrality(g, type = "betweenness")
  centre <- ct$betweenness[ct$osmid == ox_nearest_nodes(g, 200, 200)]
  corner <- ct$betweenness[ct$osmid == ox_nearest_nodes(g, 0, 0)]
  expect_gt(centre, corner)
})

test_that("circuity of a straight grid is 1", {
  g <- example_osm_graph(n = 4, spacing = 100)
  expect_equal(ox_circuity(g), 1)
})

test_that("circuity exceeds 1 for winding edges", {
  # one edge from (0,0) to (100,0) but routed via (50,50): polyline length ~141.4
  nodes <- sf::st_as_sf(
    data.frame(osmid = c(1, 2), x = c(0, 100), y = c(0, 0)),
    coords = c("x", "y"), crs = 3857, remove = FALSE
  )
  ls <- sf::st_linestring(rbind(c(0, 0), c(50, 50), c(100, 0)))
  edges <- sf::st_sf(u = 1, v = 2, geometry = sf::st_sfc(ls, crs = 3857))
  edges$length <- as.numeric(sf::st_length(edges))
  g <- new_osm_graph(nodes, edges, meta = list(simplified = TRUE))
  expect_gt(ox_circuity(g), 1.4)
})

test_that("ox_basic_stats now reports circuity", {
  s <- ox_basic_stats(example_osm_graph())
  expect_true("circuity" %in% names(s))
  expect_equal(s$circuity, 1)
})
