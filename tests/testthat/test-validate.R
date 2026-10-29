# ox_validate(): structural checks on osm_graph objects ------------------------

test_that("a clean graph validates and returns invisibly", {
  g <- example_osm_graph()
  expect_message(out <- ox_validate(g), "Valid")
  expect_identical(out, g)
  expect_invisible(suppressMessages(ox_validate(g)))
})

test_that("non-graphs and non-sf components abort immediately", {
  expect_error(ox_validate(list()), "osm_graph")
  g <- example_osm_graph()
  g$nodes <- sf::st_drop_geometry(g$nodes)
  expect_error(ox_validate(g), "sf")
})

test_that("duplicated and missing node osmids are flagged", {
  g <- example_osm_graph()
  g$nodes$osmid[2] <- g$nodes$osmid[1]
  expect_error(ox_validate(g), "duplicated node")
  g <- example_osm_graph()
  g$nodes$osmid[1] <- NA
  expect_error(ox_validate(g), "missing value")
})

test_that("dangling edges and missing length are flagged", {
  g <- example_osm_graph()
  g$edges$u[1] <- 99999
  expect_error(ox_validate(g), "absent")
  g <- example_osm_graph()
  g$edges$length <- NULL
  expect_error(ox_validate(g), "length")
  g <- example_osm_graph()
  g$edges$length[3] <- -1
  expect_error(ox_validate(g), "negative")
})

test_that("a CRS mismatch between nodes and edges is flagged", {
  g <- example_osm_graph()
  suppressWarnings(sf::st_crs(g$edges) <- 4326)
  expect_error(ox_validate(g), "CRS")
})

test_that("edge geometries detached from their nodes are flagged", {
  g <- example_osm_graph()
  # move one node away from the edges that reference it
  geom <- sf::st_geometry(g$nodes)
  geom[1] <- sf::st_point(c(-50, -50))
  sf::st_geometry(g$nodes) <- geom
  err <- tryCatch(ox_validate(g), error = function(e) conditionMessage(e))
  expect_match(err, "do not run from")
})

test_that("all problems are reported in one pass", {
  g <- example_osm_graph()
  g$nodes$osmid[2] <- g$nodes$osmid[1]
  g$edges$length[1] <- NA
  err <- tryCatch(ox_validate(g), error = function(e) conditionMessage(e))
  # overwriting node 2's osmid also orphans the edges that referenced it
  expect_match(err, "3 problems")
  expect_match(err, "duplicated")
  expect_match(err, "absent")
  expect_match(err, "missing")
})
