# Build a small UNsimplified graph: a path 1-2-3-4 (nodes 2,3 interstitial)
# plus a branch 3-5, so node 3 is a true intersection.
unsimplified_graph <- function() {
  coords <- rbind(
    c(0, 0),   # 1
    c(100, 0), # 2 (degree 2)
    c(200, 0), # 3 (intersection: neighbours 2,4,5)
    c(300, 0), # 4
    c(200, 100) # 5
  )
  nodes <- sf::st_as_sf(
    data.frame(osmid = 1:5, x = coords[, 1], y = coords[, 2]),
    coords = c("x", "y"), crs = 3857, remove = FALSE
  )
  uv <- rbind(c(1, 2), c(2, 3), c(3, 4), c(3, 5))
  uv <- rbind(uv, uv[, c(2, 1)]) # bidirectional
  geoms <- lapply(seq_len(nrow(uv)), function(i) {
    sf::st_linestring(rbind(coords[uv[i, 1], ], coords[uv[i, 2], ]))
  })
  edges <- sf::st_sf(
    u = uv[, 1], v = uv[, 2], highway = "residential", oneway = FALSE,
    geometry = sf::st_sfc(geoms, crs = 3857)
  )
  edges$length <- as.numeric(sf::st_length(edges))
  new_osm_graph(nodes, edges, meta = list(network_type = "drive", simplified = FALSE))
}

test_that("ox_simplify removes interstitial degree-2 nodes", {
  g <- unsimplified_graph()
  s <- ox_simplify(g)
  expect_true(isTRUE(s$meta$simplified))
  # node 2 is interstitial; nodes 1,3,4,5 are endpoints/intersections
  expect_setequal(s$nodes$osmid, c(1, 3, 4, 5))
  # chain 1-2-3 collapses into one edge per traversable direction (two-way
  # street -> both 1->3 and 3->1), each of length 200 over 2 segments
  e13 <- s$edges[(s$edges$u == 1 & s$edges$v == 3) | (s$edges$u == 3 & s$edges$v == 1), ]
  expect_equal(nrow(e13), 2)
  expect_true(all(round(e13$length) == 200))
  expect_true(all(e13$n_segments == 2L))
})

test_that("ox_simplify is idempotent / no-op on simplified graphs", {
  g <- example_osm_graph()
  expect_message(s <- ox_simplify(g), "already simplified")
  expect_identical(nrow(s$edges), nrow(g$edges))
})

test_that("ox_consolidate_intersections collapses coincident nodes", {
  g <- example_osm_graph(n = 3, spacing = 100)
  # large tolerance collapses everything into one node -> no edges remain
  c1 <- ox_consolidate_intersections(g, tolerance = 1000)
  expect_equal(nrow(c1$nodes), 1L)
  expect_equal(nrow(c1$edges), 0L)
  expect_true(isTRUE(c1$meta$consolidated))

  # tiny tolerance changes nothing
  c2 <- ox_consolidate_intersections(g, tolerance = 1)
  expect_equal(nrow(c2$nodes), nrow(g$nodes))
})

test_that("ox_nearest_edges returns an sf subset of edges", {
  g <- example_osm_graph()
  ne <- ox_nearest_edges(g, x = 50, y = 0)
  expect_s3_class(ne, "sf")
  expect_equal(nrow(ne), 1L)
  expect_true(all(c("u", "v") %in% names(ne)))
})
