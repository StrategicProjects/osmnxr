test_that("ox_as_sfnetwork builds an sfnetwork", {
  skip_if_not_installed("sfnetworks")
  g <- example_osm_graph(n = 4)
  net <- ox_as_sfnetwork(g)
  expect_s3_class(net, "sfnetwork")
})

test_that("ox_as_tidygraph builds a tbl_graph", {
  skip_if_not_installed("tidygraph")
  g <- example_osm_graph(n = 4)
  tg <- ox_as_tidygraph(g)
  expect_s3_class(tg, "tbl_graph")
})

test_that("ox_as_dodgr has the expected columns", {
  skip_if_not_installed("dodgr")
  g <- example_osm_graph(n = 3)
  d <- ox_as_dodgr(g)
  expect_true(all(c("from_id", "from_lon", "from_lat",
                    "to_id", "to_lon", "to_lat", "d") %in% names(d)))
  expect_equal(nrow(d), nrow(g$edges))
  expect_true(all(d$d > 0))
})

test_that("ox_as_dodgr errors clearly without dodgr installed", {
  skip_if(rlang::is_installed("dodgr"))
  expect_error(ox_as_dodgr(example_osm_graph()), "dodgr")
})
