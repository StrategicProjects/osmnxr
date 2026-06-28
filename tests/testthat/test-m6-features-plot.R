test_that("ox_plot_orientation returns a ggplot", {
  skip_if_not_installed("ggplot2")
  g <- example_osm_graph()
  p <- ox_plot_orientation(g)
  expect_s3_class(p, "ggplot")
})

test_that("overpass_features_query builds valid QL", {
  q <- overpass_features_query(
    c(-34.91, -8.07, -34.87, -8.04),
    list(amenity = c("school", "hospital"))
  )
  expect_true(grepl("out:json", q))
  expect_true(grepl('node\\["amenity"~"\\^\\(school\\|hospital\\)\\$"\\]', q))
  expect_true(grepl("way\\[", q))
  expect_true(grepl("relation\\[", q))
  expect_true(grepl("out center tags;", q))
})

test_that("features query supports key-present (TRUE) filters", {
  q <- overpass_features_query(c(0, 0, 1, 1), list(building = TRUE))
  expect_true(grepl('node\\["building"\\]', q))
  expect_false(grepl("~", q))
})

test_that("ox_features_from_bbox validates inputs", {
  expect_error(ox_features_from_bbox(c(1, 2, 3), list(amenity = "school")), "length 4")
  expect_error(ox_features_from_bbox(c(0, 0, 1, 1), c("amenity")), "named list")
})

test_that("features_to_sf assembles points with tag columns", {
  res <- list(elements = list(
    list(type = "node", id = 1, lon = -34.9, lat = -8.05,
         tags = list(amenity = "school", name = "A")),
    list(type = "way", id = 2, center = list(lon = -34.88, lat = -8.04),
         tags = list(amenity = "hospital"))
  ))
  sfo <- features_to_sf(res)
  expect_s3_class(sfo, "sf")
  expect_equal(nrow(sfo), 2)
  expect_true(all(c("osm_type", "osm_id", "amenity") %in% names(sfo)))
  expect_equal(sf::st_crs(sfo)$epsg, 4326L)
})
