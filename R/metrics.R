# Network metrics (Rust-backed) ----------------------------------------------

#' Basic street-network statistics
#'
#' Summary measures for an `osm_graph`: node and edge counts, total and mean
#' edge length, mean out-degree and self-loop count. Computation is performed
#' by the bundled Rust core.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param weight Edge column used as length/weight. Default `"length"`.
#'
#' @return A one-row [tibble][tibble::tibble] of statistics.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_basic_stats(g)
ox_basic_stats <- function(g, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- rs_basic_stats(ea$from, ea$to, ea$weight, ea$n_nodes)
  tibble::as_tibble(s)
}

#' Street-orientation entropy
#'
#' Shannon entropy (in nats) of the distribution of edge compass bearings,
#' binned into equal sectors. Higher values indicate a more disordered
#' (organic) network; lower values a more ordered (gridiron) one.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param num_bins Number of equal bearing sectors over `[0, 360)`. Default `36`.
#'
#' @return A numeric scalar (entropy in nats).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_orientation_entropy(g)
ox_orientation_entropy <- function(g, num_bins = 36) {
  stopifnot(is_osm_graph(g))
  b <- ox_bearings(g)
  rs_orientation_entropy(b, as.integer(num_bins))
}

#' Compute edge compass bearings
#'
#' Initial compass bearing (degrees clockwise from north) of each edge, from
#' its first to its last coordinate. Geographic coordinates are used; projected
#' graphs are transformed to EPSG:4326 first.
#'
#' @param g An [osm_graph][new_osm_graph].
#'
#' @return A numeric vector of bearings, one per edge.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' head(ox_bearings(g))
ox_bearings <- function(g) {
  stopifnot(is_osm_graph(g))
  edges <- g$edges
  if (!is.na(sf::st_crs(edges)) && sf::st_crs(edges) != sf::st_crs(4326)) {
    edges <- sf::st_transform(edges, 4326)
  }
  ends <- lapply(sf::st_geometry(edges), function(ls) {
    m <- sf::st_coordinates(ls)
    c(m[1, "X"], m[1, "Y"], m[nrow(m), "X"], m[nrow(m), "Y"])
  })
  ends <- do.call(rbind, ends)
  rs_bearings(ends[, 2], ends[, 1], ends[, 4], ends[, 3])
}
