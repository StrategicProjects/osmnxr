# overpass_to_graph parsing (offline, synthetic Overpass responses) -----------

ov_node <- function(id, lon, lat) {
  list(type = "node", id = id, lon = lon, lat = lat)
}
ov_way <- function(id, nodes, tags = list()) {
  list(type = "way", id = id, nodes = as.list(nodes), tags = tags)
}

test_that("overpass_to_graph builds bidirectional edges for two-way streets", {
  res <- list(elements = list(
    ov_node(10, -34.90, -8.05),
    ov_node(20, -34.89, -8.05),
    ov_node(30, -34.88, -8.04),
    ov_way(100, c(10, 20, 30), tags = list(name = "Rua A", highway = "residential"))
  ))
  g <- overpass_to_graph(res, "drive")
  expect_s3_class(g, "osm_graph")
  expect_equal(nrow(g$nodes), 3)
  expect_equal(g$nodes$osmid, c(10, 20, 30)) # sorted by osmid
  # 2 consecutive pairs x 2 directions
  expect_equal(nrow(g$edges), 4)
  expect_setequal(paste(g$edges$u, g$edges$v), c("10 20", "20 30", "20 10", "30 20"))
  expect_true(all(g$edges$name == "Rua A"))
  expect_true(all(g$edges$highway == "residential"))
  expect_true(all(g$edges$length > 0))
})

test_that("overpass_to_graph respects oneway tags", {
  res <- list(elements = list(
    ov_node(1, 0, 0), ov_node(2, 0.01, 0),
    ov_way(100, c(1, 2), tags = list(oneway = "yes"))
  ))
  g <- overpass_to_graph(res)
  expect_equal(nrow(g$edges), 1)
  expect_equal(g$edges$u, 1)
  expect_equal(g$edges$v, 2)
})

test_that("overpass_to_graph drops edges whose endpoints lack coordinates", {
  res <- list(elements = list(
    ov_node(1, 0, 0), ov_node(2, 0.01, 0),
    ov_way(100, c(1, 2, 999), tags = list(oneway = "yes")) # 999 has no node element
  ))
  g <- overpass_to_graph(res)
  expect_equal(nrow(g$edges), 1)
  expect_equal(nrow(g$nodes), 2)
  expect_false(999 %in% g$nodes$osmid)
})

test_that("overpass_to_graph edge geometry matches node coordinates", {
  res <- list(elements = list(
    ov_node(1, -34.90, -8.05), ov_node(2, -34.89, -8.04),
    ov_way(100, c(1, 2), tags = list(oneway = "yes"))
  ))
  g <- overpass_to_graph(res)
  coords <- sf::st_coordinates(g$edges$geometry[[1]])
  expect_equal(coords[1, c("X", "Y")], c(X = -34.90, Y = -8.05))
  expect_equal(coords[2, c("X", "Y")], c(X = -34.89, Y = -8.04))
  expect_equal(
    g$edges$length[1],
    haversine(-34.90, -8.05, -34.89, -8.04)
  )
})

test_that("overpass_to_graph fills NA for ways without name/highway tags", {
  res <- list(elements = list(
    ov_node(1, 0, 0), ov_node(2, 0.01, 0),
    ov_way(100, c(1, 2))
  ))
  g <- overpass_to_graph(res)
  expect_true(all(is.na(g$edges$name)))
  expect_true(all(is.na(g$edges$highway)))
  expect_false(any(g$edges$oneway))
})

test_that("overpass_to_graph skips degenerate ways and errors when none usable", {
  res <- list(elements = list(
    ov_node(1, 0, 0), ov_node(2, 0.01, 0),
    ov_way(100, 1), # single-node way: skipped
    ov_way(101, c(1, 2))
  ))
  g <- overpass_to_graph(res)
  expect_equal(nrow(g$edges), 2) # one pair, both directions

  expect_error(
    overpass_to_graph(list(elements = list(ov_node(1, 0, 0), ov_way(100, 1)))),
    "No usable ways"
  )
  expect_error(overpass_to_graph(list(elements = list())), "no elements")
})

# Retry policy -----------------------------------------------------------------

test_that("ox_request retries transient Overpass failures (429/5xx)", {
  req <- ox_request("https://example.com")
  expect_equal(req$policies$retry_max_tries, ox_settings()$max_tries)
  is_transient <- req$policies$retry_is_transient
  for (code in c(429L, 500L, 502L, 503L, 504L)) {
    expect_true(is_transient(httr2::response(status_code = code)), label = paste("status", code))
  }
  expect_false(is_transient(httr2::response(status_code = 404)))
  expect_true(isTRUE(req$policies$retry_on_failure))
})
