#' A small synthetic `osm_graph` for examples and tests
#'
#' Builds a tiny `n x n` regular street grid as an [osm_graph][new_osm_graph], with no
#' network access. Edges are bidirectional and weighted by their planar length.
#' Useful for examples, tests and learning the API offline.
#'
#' @param n Grid size; the network has `n * n` nodes. Default `4`.
#' @param spacing Distance between adjacent nodes, in CRS units. Default `100`.
#'
#' @return An [osm_graph][new_osm_graph] in an arbitrary projected CRS.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' g
#' ox_basic_stats(g)
example_osm_graph <- function(n = 4, spacing = 100) {
  grid <- expand.grid(row = seq_len(n), col = seq_len(n))
  grid$osmid <- seq_len(nrow(grid))
  grid$x <- (grid$col - 1) * spacing
  grid$y <- (grid$row - 1) * spacing

  nodes <- sf::st_as_sf(
    grid[c("osmid", "x", "y")],
    coords = c("x", "y"),
    crs = 3857,
    remove = FALSE
  )

  id_of <- function(r, c) grid$osmid[grid$row == r & grid$col == c]
  pairs <- list()
  for (r in seq_len(n)) {
    for (c in seq_len(n)) {
      if (c < n) pairs[[length(pairs) + 1]] <- c(id_of(r, c), id_of(r, c + 1))
      if (r < n) pairs[[length(pairs) + 1]] <- c(id_of(r, c), id_of(r + 1, c))
    }
  }
  und <- do.call(rbind, pairs)
  # make bidirectional
  uv <- rbind(und, und[, c(2, 1)])

  coord <- function(id) c(grid$x[id], grid$y[id])
  geoms <- lapply(seq_len(nrow(uv)), function(i) {
    sf::st_linestring(rbind(coord(uv[i, 1]), coord(uv[i, 2])))
  })
  edges <- sf::st_sf(
    u = uv[, 1],
    v = uv[, 2],
    osmid = seq_len(nrow(uv)),
    highway = "residential",
    oneway = FALSE,
    geometry = sf::st_sfc(geoms, crs = 3857)
  )
  edges$length <- as.numeric(sf::st_length(edges))

  new_osm_graph(nodes, edges, meta = list(
    network_type = "drive", simplified = TRUE, query = "synthetic grid"
  ))
}
