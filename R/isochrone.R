# Isochrones / service areas --------------------------------------------------

#' Compute isochrones (service areas)
#'
#' For one or more origin nodes, finds the set of nodes reachable within each
#' `cutoff` (by the chosen edge `weight` — distance or, with
#' [ox_add_edge_travel_times()], travel time) and returns a polygon per cutoff:
#' the hull of the reachable nodes. With several origins, reachability is the
#' minimum cost from any origin.
#'
#' Reachable sets come from the Rust Dijkstra core; the hull is built with
#' `sf::st_concave_hull()` when available (GEOS >= 3.11), falling back to a
#' convex hull. For metric cutoffs, project the graph to a metric CRS first.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param center One or more origin node `osmid`s (see [ox_nearest_nodes()]).
#' @param cutoffs Numeric vector of cutoff values, in the units of `weight`.
#' @param weight Edge column used as cost. Default `"length"`.
#' @param ratio Concavity for `sf::st_concave_hull()` (0 = most concave,
#'   1 = convex). Default `0.4`.
#'
#' @return An `sf` object with one polygon row per cutoff (columns `cutoff`,
#'   `n_nodes`, `geometry`), ordered from largest to smallest cutoff so smaller
#'   areas draw on top.
#' @export
#'
#' @examples
#' g <- example_osm_graph(n = 6, spacing = 100)
#' center <- ox_nearest_nodes(g, 250, 250)
#' iso <- ox_isochrone(g, center, cutoffs = c(100, 300))
#' iso
ox_isochrone <- function(g, center, cutoffs, weight = "length", ratio = 0.4) {
  stopifnot(is_osm_graph(g))
  if (length(cutoffs) == 0) cli::cli_abort("{.arg cutoffs} must not be empty.", call = NULL)

  all_ids <- g$nodes$osmid
  dm <- ox_distance_matrix(g, from = center, to = all_ids, weight = weight)
  mind <- apply(dm, 2, min)

  crs <- sf::st_crs(g$nodes)
  cuts <- sort(unique(cutoffs), decreasing = TRUE)
  rows <- list()
  for (cut in cuts) {
    sel <- g$nodes[mind <= cut, ]
    if (nrow(sel) < 3) next
    pts <- sf::st_union(sf::st_geometry(sel))
    hull <- tryCatch(
      sf::st_concave_hull(pts, ratio = ratio),
      error = function(e) sf::st_convex_hull(pts)
    )
    rows[[length(rows) + 1L]] <- sf::st_sf(
      cutoff = cut, n_nodes = nrow(sel),
      geometry = sf::st_sfc(sf::st_geometry(hull)[[1]], crs = crs)
    )
  }
  if (length(rows) == 0) {
    cli::cli_abort("No cutoff reached at least 3 nodes; nothing to hull.", call = NULL)
  }
  do.call(rbind, rows)
}
