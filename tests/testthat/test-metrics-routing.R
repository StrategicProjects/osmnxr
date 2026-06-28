test_that("ox_basic_stats matches the synthetic grid", {
  g <- example_osm_graph(n = 4, spacing = 100)
  s <- ox_basic_stats(g)
  expect_equal(s$n_nodes, 16L)
  expect_equal(s$n_edges, 48L)
  expect_equal(s$total_length, 4800)
  expect_equal(s$mean_length, 100)
  expect_equal(s$self_loops, 0L)
})

test_that("shortest path on the grid has the right length", {
  g <- example_osm_graph(n = 4, spacing = 100)
  from <- ox_nearest_nodes(g, 0, 0)
  to <- ox_nearest_nodes(g, 300, 300)
  path <- ox_shortest_path(g, from, to)
  expect_gt(length(path), 0)
  expect_identical(path[1], from)
  expect_identical(path[length(path)], to)
  # Manhattan distance on a 4x4 grid corner-to-corner = 6 hops = 7 nodes
  expect_equal(length(path), 7L)
})

test_that("ox_distances returns one row per node", {
  g <- example_osm_graph(n = 4)
  d <- ox_distances(g, ox_nearest_nodes(g, 0, 0))
  expect_equal(nrow(d), 16L)
  expect_true(all(is.finite(d$distance)))
  expect_equal(min(d$distance), 0)
})

test_that("orientation entropy is lower for a grid than a uniform mix", {
  g <- example_osm_graph(n = 5)
  h_grid <- ox_orientation_entropy(g, num_bins = 36)
  # a uniform spread of bearings should have higher entropy
  set.seed(1)
  h_uniform <- rs_orientation_entropy(seq(0, 359, length.out = 360), 36L)
  expect_lt(h_grid, h_uniform)
})

test_that("bearings are within [0, 360)", {
  b <- ox_bearings(example_osm_graph())
  expect_true(all(b >= 0 & b < 360))
})
