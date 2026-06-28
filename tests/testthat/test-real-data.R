test_that("ox_example loads a routable real network", {
  g <- ox_example("olinda")
  expect_s3_class(g, "osm_graph")
  expect_gt(nrow(g$nodes), 100)
  expect_gt(nrow(g$edges), 100)
  expect_equal(sf::st_crs(g$nodes)$epsg, 4326L)

  # bidirectional & connected enough that routing and betweenness are non-trivial
  from <- ox_nearest_nodes(g, -34.8553, -8.0089)
  to <- ox_nearest_nodes(g, -34.8505, -8.0125)
  expect_gt(length(ox_shortest_path(g, from, to)), 1)
  ct <- ox_centrality(g, type = "betweenness")
  expect_gt(max(ct$betweenness), 0)
})

test_that("ox_example rejects unknown networks", {
  expect_error(ox_example("atlantis"))
})

test_that("bundled comparison networks load and contrast in form", {
  man <- ox_example("manhattan")
  rome <- ox_example("rome")
  expect_s3_class(man, "osm_graph")
  expect_s3_class(rome, "osm_graph")
  # Manhattan's grid is far more ordered than Rome's organic core
  expect_lt(ox_orientation_entropy(man), ox_orientation_entropy(rome))
})

test_that("ox_plot_figure_ground draws without error", {
  g <- example_osm_graph()
  pdf(NULL)
  on.exit(dev.off())
  expect_invisible(ox_plot_figure_ground(g))
  expect_invisible(ox_plot_figure_ground(g, title = "test"))
})

test_that("orientation functions accept a numeric bearings vector", {
  b <- c(0, 0, 90, 90, 180, 270)
  expect_type(ox_orientation_entropy(b), "double")
  skip_if_not_installed("ggplot2")
  expect_s3_class(ox_plot_orientation(b), "ggplot")
})

test_that("bundled city orientations span low to high entropy", {
  f <- system.file("extdata", "city_orientations.rds", package = "osmnxr")
  skip_if(f == "")
  co <- readRDS(f)
  ent <- tapply(co$bearing, co$city, ox_orientation_entropy)
  # Chicago (grid) < New Orleans (medium) < Rome (organic)
  expect_lt(ent[["Chicago"]], ent[["New Orleans"]])
  expect_lt(ent[["New Orleans"]], ent[["Rome"]])
})
