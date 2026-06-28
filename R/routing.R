# Routing (Rust-backed) -------------------------------------------------------

#' Find the nearest node to a point
#'
#' Returns the `osmid` of the graph node closest (in planar distance) to each
#' supplied coordinate.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param x,y Numeric vectors of coordinates in the graph's CRS.
#'
#' @return An integer/numeric vector of node `osmid`s, one per input point.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_nearest_nodes(g, x = 0, y = 0)
ox_nearest_nodes <- function(g, x, y) {
  stopifnot(is_osm_graph(g))
  pts <- sf::st_as_sf(data.frame(x = x, y = y), coords = c("x", "y"),
                      crs = sf::st_crs(g$nodes))
  idx <- sf::st_nearest_feature(pts, g$nodes)
  g$nodes$osmid[idx]
}

#' Shortest path between two nodes
#'
#' Computes the minimum-weight path from `from` to `to` using Dijkstra's
#' algorithm in the Rust core.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param from,to Node `osmid`s (as returned by [ox_nearest_nodes()]).
#' @param weight Edge column used as weight. Default `"length"`.
#'
#' @return A vector of node `osmid`s describing the path (length 0 if the
#'   target is unreachable).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' from <- ox_nearest_nodes(g, 0, 0)
#' to <- ox_nearest_nodes(g, 300, 300)
#' ox_shortest_path(g, from, to)
ox_shortest_path <- function(g, from, to, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- match(from, ea$node_ids) - 1L
  t <- match(to, ea$node_ids) - 1L
  if (is.na(s) || is.na(t)) {
    cli::cli_abort("{.arg from}/{.arg to} must be node {.field osmid}s present in the graph.", call = NULL)
  }
  path_idx <- rs_shortest_path(ea$from, ea$to, ea$weight, ea$n_nodes,
                               as.integer(s), as.integer(t))
  ea$node_ids[path_idx + 1L]
}

#' Single-source shortest distances
#'
#' Minimum-weight distance from `from` to every node in the graph.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param from A node `osmid`.
#' @param weight Edge column used as weight. Default `"length"`.
#'
#' @return A [tibble][tibble::tibble] with columns `osmid` and `distance`
#'   (`Inf` for unreachable nodes).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_distances(g, ox_nearest_nodes(g, 0, 0))
ox_distances <- function(g, from, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- match(from, ea$node_ids) - 1L
  if (is.na(s)) cli::cli_abort("{.arg from} must be a node {.field osmid} in the graph.", call = NULL)
  d <- rs_dijkstra(ea$from, ea$to, ea$weight, ea$n_nodes, as.integer(s))
  tibble::tibble(osmid = ea$node_ids, distance = d)
}
