test_that("example_osm_graph builds a valid osm_graph", {
  g <- example_osm_graph(n = 4)
  expect_s3_class(g, "osm_graph")
  expect_true(is_osm_graph(g))
  expect_s3_class(g$nodes, "sf")
  expect_s3_class(g$edges, "sf")
  expect_equal(nrow(g$nodes), 16)
  expect_equal(nrow(g$edges), 48) # 24 undirected edges, bidirectional
  expect_true(all(c("u", "v", "length") %in% names(g$edges)))
})

test_that("ox_as_sf returns nodes and edges", {
  parts <- ox_as_sf(example_osm_graph())
  expect_named(parts, c("nodes", "edges"))
  expect_s3_class(parts$edges, "sf")
})

test_that("constructor validates inputs", {
  expect_error(new_osm_graph(1, 2), class = "rlang_error")
})
