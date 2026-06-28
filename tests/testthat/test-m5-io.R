test_that("GraphML round-trips losslessly", {
  skip_if_not_installed("xml2")
  g <- example_osm_graph(n = 4)
  f <- tempfile(fileext = ".graphml")
  ox_save_graphml(g, f)
  g2 <- ox_load_graphml(f)

  expect_s3_class(g2, "osm_graph")
  expect_equal(nrow(g2$nodes), nrow(g$nodes))
  expect_equal(nrow(g2$edges), nrow(g$edges))
  expect_true(sf::st_crs(g2$nodes) == sf::st_crs(g$nodes))
  expect_equal(sort(g2$edges$length), sort(g$edges$length))
  expect_setequal(g2$nodes$osmid, g$nodes$osmid)
})

test_that("a graph survives GraphML and stays routable", {
  skip_if_not_installed("xml2")
  g <- example_osm_graph(n = 5)
  f <- tempfile(fileext = ".graphml")
  g2 <- ox_load_graphml(ox_save_graphml(g, f))
  p1 <- ox_shortest_path(g, ox_nearest_nodes(g, 0, 0), ox_nearest_nodes(g, 400, 400))
  p2 <- ox_shortest_path(g2, ox_nearest_nodes(g2, 0, 0), ox_nearest_nodes(g2, 400, 400))
  expect_equal(length(p1), length(p2))
})

test_that("ox_to_geojson writes a readable file", {
  g <- example_osm_graph()
  f <- tempfile(fileext = ".geojson")
  ox_to_geojson(g, f)
  back <- sf::st_read(f, quiet = TRUE)
  expect_equal(nrow(back), nrow(g$edges))
  expect_equal(sf::st_crs(back)$epsg, 4326L)
})

test_that("ox_to_maplibre returns a valid style fragment", {
  g <- example_osm_graph()
  f <- tempfile(fileext = ".geojson")
  style <- ox_to_maplibre(g, f, source_id = "s1", layer_id = "l1")
  expect_named(style, c("sources", "layers"))
  expect_true("s1" %in% names(style$sources))
  expect_equal(style$layers[[1]]$id, "l1")
  expect_equal(style$layers[[1]]$source, "s1")
  expect_true(file.exists(f))
})
