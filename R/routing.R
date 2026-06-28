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

#' k shortest paths between two nodes
#'
#' Computes up to `k` loopless shortest paths from `from` to `to` using Yen's
#' algorithm in the Rust core. Useful for route alternatives.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param from,to Node `osmid`s.
#' @param k Number of paths to return. Default `3`.
#' @param weight Edge column used as weight. Default `"length"`.
#'
#' @return A [tibble][tibble::tibble] with one row per path: `rank`, `cost` and
#'   a list-column `path` of node `osmid`s, ordered by increasing cost. Fewer
#'   than `k` rows are returned when fewer distinct paths exist.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' from <- ox_nearest_nodes(g, 0, 0)
#' to <- ox_nearest_nodes(g, 200, 200)
#' ox_k_shortest_paths(g, from, to, k = 3)
ox_k_shortest_paths <- function(g, from, to, k = 3, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- match(from, ea$node_ids) - 1L
  t <- match(to, ea$node_ids) - 1L
  if (is.na(s) || is.na(t)) {
    cli::cli_abort("{.arg from}/{.arg to} must be node {.field osmid}s present in the graph.", call = NULL)
  }
  res <- rs_k_shortest_paths(ea$from, ea$to, ea$weight, ea$n_nodes,
                             as.integer(s), as.integer(t), as.integer(k))
  paths <- lapply(res$paths, function(idx) ea$node_ids[idx + 1L])
  tibble::tibble(rank = seq_along(paths), cost = as.numeric(res$costs), path = paths)
}

#' Shortest-path distance matrix
#'
#' Computes the matrix of minimum-weight distances between every `from` node and
#' every `to` node (Rust core; one Dijkstra per source).
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param from Node `osmid`s for the matrix rows.
#' @param to Node `osmid`s for the matrix columns. Defaults to `from`.
#' @param weight Edge column used as weight. Default `"length"`.
#'
#' @return A numeric matrix (`length(from)` x `length(to)`) with `osmid`
#'   dimnames; `Inf` marks unreachable pairs.
#' @export
#'
#' @examples
#' g <- example_osm_graph(n = 3)
#' nodes <- g$nodes$osmid
#' ox_distance_matrix(g, from = nodes[1:2], to = nodes[3:4])
ox_distance_matrix <- function(g, from, to = from, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- match(from, ea$node_ids) - 1L
  t <- match(to, ea$node_ids) - 1L
  if (anyNA(s) || anyNA(t)) {
    cli::cli_abort("All {.arg from}/{.arg to} must be node {.field osmid}s present in the graph.", call = NULL)
  }
  flat <- rs_distance_matrix(ea$from, ea$to, ea$weight, ea$n_nodes,
                             as.integer(s), as.integer(t))
  m <- matrix(flat, nrow = length(s), ncol = length(t), byrow = TRUE,
              dimnames = list(as.character(from), as.character(to)))
  m
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
