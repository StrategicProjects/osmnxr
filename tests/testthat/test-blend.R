# ox_blend(): snapping points and graphs into a network -----------------------

test_that("blending a point splits the edge and its reversed twin", {
  g <- example_osm_graph() # 4x4 grid, spacing 100, bidirectional edges
  pts <- sf::st_sfc(sf::st_point(c(40, 3)), crs = 3857)

  b <- ox_blend(g, pts)
  expect_s3_class(b, "osm_graph")

  # one new node, snapped onto the edge (not at the input point)
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 1)
  new_id <- b$meta$blend$node[1]
  expect_false(new_id %in% g$nodes$osmid)
  xy <- sf::st_coordinates(b$nodes[b$nodes$osmid == new_id, ])
  expect_equal(as.numeric(xy), c(40, 0))
  expect_equal(b$meta$blend$dist[1], 3)

  # the edge between nodes 1 and 5 — (0,0) to (100,0) — was split in both
  # directions: +2 edges
  expect_equal(nrow(b$edges), nrow(g$edges) + 2)
  touching <- b$edges$u == new_id | b$edges$v == new_id
  expect_equal(sum(touching), 4)
  expect_setequal(
    c(b$edges$u[touching], b$edges$v[touching]),
    c(1, 5, new_id)
  )
  # split lengths add up to the parent length
  expect_equal(sort(unique(b$edges$length[touching])), c(40, 60))

  # the new node is routable in both directions
  p <- ox_shortest_path(b, 1, new_id)
  expect_equal(p[length(p)], new_id)
  p <- ox_shortest_path(b, new_id, 16)
  expect_equal(p[1], new_id)
})

test_that("routing through a blended node preserves total distances", {
  g <- example_osm_graph()
  b <- ox_blend(g, sf::st_sfc(sf::st_point(c(50, -10)), crs = 3857))
  new_id <- b$meta$blend$node[1]
  # corner (0,0) is node 1; the new node sits 50 m along its east edge
  expect_equal(ox_distances(b, 1)$distance[match(new_id, b$nodes$osmid)], 50)
  # distances between original nodes are unchanged
  d0 <- ox_distance_matrix(g, from = 1, to = 16)
  d1 <- ox_distance_matrix(b, from = 1, to = 16)
  expect_equal(as.numeric(d0), as.numeric(d1))
})

test_that("points projecting onto an existing node attach to it", {
  g <- example_osm_graph()
  # beyond the corner: projection clamps exactly onto node 1 at (0, 0)
  b <- ox_blend(g, sf::st_sfc(sf::st_point(c(-30, -40)), crs = 3857))
  expect_equal(nrow(b$nodes), nrow(g$nodes))
  expect_equal(nrow(b$edges), nrow(g$edges))
  expect_equal(b$meta$blend$node[1], 1)
  expect_equal(b$meta$blend$dist[1], 50)
})

test_that("tolerance excludes far points with a warning", {
  g <- example_osm_graph()
  pts <- sf::st_sfc(sf::st_point(c(50, 5)), sf::st_point(c(50, 500)), crs = 3857)
  expect_warning(b <- ox_blend(g, pts, tolerance = 10), "not blended")
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 1)
  expect_true(is.na(b$meta$blend$node[2]))
  expect_true(is.na(b$meta$blend$dist[2]))
})

test_that("coincident points share one new node; sf attributes are carried", {
  g <- example_osm_graph()
  y <- sf::st_sf(
    name = c("a", "b"),
    geometry = sf::st_sfc(sf::st_point(c(40, 3)), sf::st_point(c(40, 3)),
                          crs = 3857)
  )
  b <- ox_blend(g, y)
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 1)
  expect_equal(b$meta$blend$node[1], b$meta$blend$node[2])
  new <- b$nodes[b$nodes$osmid == b$meta$blend$node[1], ]
  expect_equal(new$name, "a")
})

test_that("several points on one edge split it into ordered pieces", {
  g <- example_osm_graph()
  pts <- sf::st_sfc(sf::st_point(c(70, 2)), sf::st_point(c(30, 2)), crs = 3857)
  b <- ox_blend(g, pts)
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 2)
  # both directions split twice: 2 edges replaced by 6
  expect_equal(nrow(b$edges), nrow(g$edges) + 4)
  n1 <- b$meta$blend$node[2] # at 30
  n2 <- b$meta$blend$node[1] # at 70
  p <- ox_shortest_path(b, 1, 5)
  expect_equal(p, c(1, n1, n2, 5))
  expect_equal(
    ox_distances(b, 1)$distance[match(c(n1, n2), b$nodes$osmid)],
    c(30, 70)
  )
})

test_that("travel_time and penalty rescale proportionally on split edges", {
  g <- example_osm_graph()
  g$edges$travel_time <- g$edges$length / 10
  g$edges$penalty <- g$edges$length
  b <- ox_blend(g, sf::st_sfc(sf::st_point(c(25, 1)), crs = 3857))
  new_id <- b$meta$blend$node[1]
  touching <- b$edges$u == new_id | b$edges$v == new_id
  expect_equal(sort(unique(b$edges$travel_time[touching])), c(2.5, 7.5))
  expect_equal(sort(unique(b$edges$penalty[touching])), c(25, 75))
})

test_that("blending a graph unions, snaps and connects", {
  g <- example_osm_graph()
  # a metro line crossing the grid horizontally at y = 150
  metro <- new_osm_graph(
    sf::st_sf(osmid = c(1001, 1002),
              geometry = sf::st_sfc(sf::st_point(c(40, 150)),
                                    sf::st_point(c(260, 150)), crs = 3857)),
    sf::st_sf(u = c(1001, 1002), v = c(1002, 1001), length = 220,
              geometry = sf::st_sfc(
                sf::st_linestring(rbind(c(40, 150), c(260, 150))),
                sf::st_linestring(rbind(c(260, 150), c(40, 150))),
                crs = 3857)),
    meta = list(network_type = "metro")
  )
  b <- ox_blend(g, metro, connector_attrs = list(highway = "connector"))

  expect_s3_class(b, "osm_graph")
  expect_equal(nrow(b$meta$blend), 2)
  expect_equal(b$meta$blend$osmid, c(1001, 1002))
  # metro ends snap onto the vertical grid edges at x = 0 and x = 300
  expect_equal(b$meta$blend$dist, c(40, 40))
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 2 + 2) # 2 metro + 2 split nodes

  # metro nodes, their snap nodes, and the metro + connector edges are there
  expect_true(all(c(1001, 1002) %in% b$nodes$osmid))
  conn <- !is.na(b$edges$highway) & b$edges$highway == "connector"
  expect_equal(sum(conn), 4) # two pairs, both directions
  expect_equal(sort(unique(b$edges$length[conn])), 40)

  # multimodal route: connector -> metro -> connector beats the street grid
  snap1 <- b$meta$blend$node[1] # at (0, 150)
  snap2 <- b$meta$blend$node[2] # at (300, 150)
  p <- ox_shortest_path(b, snap1, snap2)
  expect_true(all(c(1001, 1002) %in% p))
  d <- ox_distance_matrix(b, from = snap1, to = snap2)
  expect_equal(as.numeric(d), 40 + 220 + 40) # street-only would be 400
})

test_that("shared osmids merge through the union without connectors", {
  g <- example_osm_graph()
  # a second network reusing grid node 4 (0, 300) plus one node of its own
  g2 <- new_osm_graph(
    sf::st_sf(osmid = c(4, 2001),
              geometry = sf::st_sfc(sf::st_point(c(0, 300)),
                                    sf::st_point(c(0, 400)), crs = 3857)),
    sf::st_sf(u = c(4, 2001), v = c(2001, 4), length = 100,
              geometry = sf::st_sfc(
                sf::st_linestring(rbind(c(0, 300), c(0, 400))),
                sf::st_linestring(rbind(c(0, 400), c(0, 300))),
                crs = 3857)),
    meta = list(network_type = "walk")
  )
  b <- ox_blend(g, g2)
  # only the new node was snapped; node 4 stitched by osmid
  expect_equal(b$meta$blend$osmid, 2001)
  # 2001 projects onto node 4 itself (clamped), so no edge is split
  expect_equal(b$meta$blend$node, 4)
  expect_equal(nrow(b$nodes), nrow(g$nodes) + 1)
  p <- ox_shortest_path(b, 1, 2001)
  expect_equal(p[length(p)], 2001)
})

test_that("ox_blend validates its inputs", {
  g <- example_osm_graph()
  pts_wrong_crs <- sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
  expect_error(ox_blend(g, pts_wrong_crs), "CRS")
  expect_error(ox_blend(g, sf::st_sfc(sf::st_point(c(0, 0)), crs = 3857),
                        tolerance = -1), "tolerance")
  expect_error(ox_blend(g, 1:3), "POINT|osm_graph")
  expect_error(
    ox_blend(g, example_osm_graph(), connector_attrs = list(1, 2)),
    "named"
  )
})
