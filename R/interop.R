# Interoperability with the R spatial-network ecosystem -----------------------

# Add integer from/to columns (node row indices) to an edges table.
add_from_to <- function(nodes, edges) {
  edges$from <- match(edges$u, nodes$osmid)
  edges$to <- match(edges$v, nodes$osmid)
  edges
}

#' Convert to an `sfnetwork`
#'
#' Returns the graph as a `sfnetworks::sfnetwork()` object, ready for the
#' `sfnetworks`/`tidygraph` spatial-network workflow.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param directed Build a directed network. Default `TRUE`.
#'
#' @return An `sfnetwork`.
#' @export
#'
#' @examplesIf rlang::is_installed("sfnetworks")
#' g <- example_osm_graph()
#' ox_as_sfnetwork(g)
ox_as_sfnetwork <- function(g, directed = TRUE) {
  stopifnot(is_osm_graph(g))
  rlang::check_installed("sfnetworks")
  edges <- add_from_to(g$nodes, g$edges)
  sfnetworks::sfnetwork(g$nodes, edges, directed = directed,
                        edges_as_lines = TRUE, force = TRUE)
}

#' Convert to a `tidygraph` table graph
#'
#' Returns the graph as a `tidygraph::tbl_graph()`, dropping geometry (node
#' coordinates are kept as `x`/`y` columns).
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param directed Build a directed graph. Default `TRUE`.
#'
#' @return A `tbl_graph`.
#' @export
#'
#' @examplesIf rlang::is_installed("tidygraph")
#' g <- example_osm_graph()
#' ox_as_tidygraph(g)
ox_as_tidygraph <- function(g, directed = TRUE) {
  stopifnot(is_osm_graph(g))
  rlang::check_installed("tidygraph")
  nodes <- sf::st_drop_geometry(g$nodes)
  edges <- add_from_to(g$nodes, sf::st_drop_geometry(g$edges))
  tidygraph::tbl_graph(nodes = nodes, edges = edges, directed = directed)
}

#' Convert to a `dodgr` graph
#'
#' Returns a `data.frame` in the column layout expected by the `dodgr` routing
#' package (`from_id`, `from_lon`, `from_lat`, `to_id`, `to_lon`, `to_lat`,
#' `d`), suitable for `dodgr::dodgr_dists()` and friends.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param weight Edge column used as the distance/weight `d`. Default
#'   `"length"`.
#'
#' @return A `data.frame` `dodgr` graph.
#' @export
#'
#' @examplesIf rlang::is_installed("dodgr")
#' g <- example_osm_graph()
#' head(ox_as_dodgr(g))
ox_as_dodgr <- function(g, weight = "length") {
  stopifnot(is_osm_graph(g))
  rlang::check_installed("dodgr")
  ids <- g$nodes$osmid
  xy <- sf::st_coordinates(g$nodes)
  ui <- match(g$edges$u, ids)
  vi <- match(g$edges$v, ids)
  data.frame(
    from_id = as.character(g$edges$u),
    from_lon = xy[ui, 1], from_lat = xy[ui, 2],
    to_id = as.character(g$edges$v),
    to_lon = xy[vi, 1], to_lat = xy[vi, 2],
    d = as.numeric(g$edges[[weight]]),
    stringsAsFactors = FALSE
  )
}
