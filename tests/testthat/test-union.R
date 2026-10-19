# helper: a copy of example_osm_graph() with shifted osmids and geometry,
# so it is a genuinely disjoint second network
shifted_grid <- function(n = 3, id_offset = 1000, dx = 10000) {
  g <- example_osm_graph(n = n)
  crs <- sf::st_crs(g$nodes)
  g$nodes$osmid <- g$nodes$osmid + id_offset
  g$edges$u <- g$edges$u + id_offset
  g$edges$v <- g$edges$v + id_offset
  ng <- sf::st_geometry(g$nodes) + c(dx, 0)
  eg <- sf::st_geometry(g$edges) + c(dx, 0)
  sf::st_geometry(g$nodes) <- sf::st_set_crs(ng, crs)
  sf::st_geometry(g$edges) <- sf::st_set_crs(eg, crs)
  g
}

test_that("ox_union stacks disjoint graphs", {
  g1 <- example_osm_graph(n = 3)
  g2 <- shifted_grid(n = 3)
  u <- ox_union(g1, g2)
  expect_s3_class(u, "osm_graph")
  expect_equal(nrow(u$nodes), nrow(g1$nodes) + nrow(g2$nodes))
  expect_equal(nrow(u$edges), nrow(g1$edges) + nrow(g2$edges))
  expect_equal(sf::st_crs(u$nodes), sf::st_crs(g1$nodes))
  expect_equal(u$meta$union_of, 2)
  expect_true(u$meta$simplified)
})

test_that("ox_union dedupes overlapping nodes and edges", {
  g <- example_osm_graph(n = 3)
  u <- ox_union(g, g)
  expect_equal(nrow(u$nodes), nrow(g$nodes))
  expect_equal(nrow(u$edges), nrow(g$edges))
  # dedupe_edges = FALSE keeps the duplicates
  u2 <- ox_union(g, g, dedupe_edges = FALSE)
  expect_equal(nrow(u2$edges), 2 * nrow(g$edges))
})

test_that("ox_union accepts a list and more than two graphs", {
  g1 <- example_osm_graph(n = 3)
  g2 <- shifted_grid(n = 3, id_offset = 1000)
  g3 <- shifted_grid(n = 3, id_offset = 2000, dx = 20000)
  u <- ox_union(list(g1, g2, g3))
  expect_equal(nrow(u$nodes), 27)
  expect_equal(u$meta$union_of, 3)
})

test_that("a transfer edge makes the union routable across modes", {
  g1 <- example_osm_graph(n = 3)
  g2 <- shifted_grid(n = 3)
  # hand-made "metro" link between node 9 (g1) and node 1001 (g2)
  p1 <- sf::st_coordinates(g1$nodes)[g1$nodes$osmid == 9, ]
  p2 <- sf::st_coordinates(g2$nodes)[g2$nodes$osmid == 1001, ]
  line <- sf::st_sfc(sf::st_linestring(rbind(p1, p2)), crs = sf::st_crs(g1$nodes))
  transfer <- sf::st_sf(
    u = c(9, 1001), v = c(1001, 9),
    length = as.numeric(sf::st_length(line)),
    geometry = c(line, line)
  )
  metro <- new_osm_graph(
    g2$nodes[g2$nodes$osmid == 1001, ], transfer,
    meta = list(network_type = "metro", simplified = TRUE)
  )

  u <- ox_union(g1, g2, metro)
  expect_equal(u$meta$network_type, "drive+metro")
  path <- ox_shortest_path(u, from = 1, to = 1009)
  expect_gt(length(path), 0)
  expect_true(all(c(9, 1001) %in% path))
})

test_that("ox_union validates inputs", {
  g <- example_osm_graph(n = 3)
  expect_error(ox_union(g), "at least two")
  expect_error(ox_union(g, 1), class = "rlang_error")
  g_ll <- g
  sf::st_geometry(g_ll$nodes) <- sf::st_set_crs(
    sf::st_geometry(g_ll$nodes) * 0.0001, 4326
  )
  expect_error(ox_union(g, g_ll), "same CRS")
})

test_that("ox_union warns on conflicting node coordinates", {
  g1 <- example_osm_graph(n = 3)
  g2 <- example_osm_graph(n = 3)
  gm <- sf::st_geometry(g2$nodes)
  gm[1] <- gm[1] + c(5, 5)
  sf::st_geometry(g2$nodes) <- sf::st_set_crs(gm, sf::st_crs(g1$nodes))
  expect_warning(ox_union(g1, g2), "different coordinates")
})

test_that("ox_union fills missing attribute columns with NA", {
  g1 <- example_osm_graph(n = 3)
  g2 <- shifted_grid(n = 3)
  g2$edges$mode <- "rail"
  u <- ox_union(g1, g2)
  expect_true("mode" %in% names(u$edges))
  expect_true(all(is.na(u$edges$mode[seq_len(nrow(g1$edges))])))
})
