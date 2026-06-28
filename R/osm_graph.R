# The osm_graph S3 object -----------------------------------------------------

#' Construct an `osm_graph`
#'
#' Low-level constructor wrapping tidy `sf` nodes and edges into the central
#' `osm_graph` object used across the package. Most users obtain an `osm_graph`
#' from [ox_graph_from_place()] and friends rather than calling this directly.
#'
#' @param nodes An `sf` object of `POINT` geometries with at least an integer
#'   or numeric `osmid` column.
#' @param edges An `sf` object of `LINESTRING` geometries with `u` and `v`
#'   columns referencing node `osmid`s, plus a numeric `length` column.
#' @param meta A named list of metadata (e.g. `network_type`, `simplified`).
#'
#' @return An object of class `osm_graph`.
#' @aliases osm_graph
#' @export
new_osm_graph <- function(nodes, edges, meta = list()) {
  if (!inherits(nodes, "sf")) cli::cli_abort("{.arg nodes} must be an {.cls sf} object.", call = NULL)
  if (!inherits(edges, "sf")) cli::cli_abort("{.arg edges} must be an {.cls sf} object.", call = NULL)
  if (!all(c("u", "v") %in% names(edges))) {
    cli::cli_abort("{.arg edges} must have {.field u} and {.field v} columns.", call = NULL)
  }
  structure(
    list(nodes = nodes, edges = edges, crs = sf::st_crs(nodes), meta = meta),
    class = "osm_graph"
  )
}

#' Test whether an object is an `osm_graph`
#' @param x An object.
#' @return A logical scalar.
#' @export
is_osm_graph <- function(x) inherits(x, "osm_graph")

# Internal: build the 0-based directed edge arrays the Rust core expects.
# Returns from/to (0-based integer node indices), weight, n_nodes and the
# ordered vector of node osmids (so results can be mapped back).
graph_edge_arrays <- function(g, weight = "length") {
  ids <- g$nodes$osmid
  idx <- match(g$edges$u, ids) - 1L
  jdx <- match(g$edges$v, ids) - 1L
  keep <- !is.na(idx) & !is.na(jdx)
  w <- if (weight %in% names(g$edges)) as.numeric(g$edges[[weight]]) else rep(1, nrow(g$edges))
  list(
    from = idx[keep],
    to = jdx[keep],
    weight = w[keep],
    n_nodes = length(ids),
    node_ids = ids
  )
}

#' @export
print.osm_graph <- function(x, ...) {
  cli::cli_h1("osm_graph")
  cli::cli_text("{.strong {nrow(x$nodes)}} nodes, {.strong {nrow(x$edges)}} edges")
  nt <- x$meta$network_type %||% "unknown"
  cli::cli_text("Network type: {.val {nt}}")
  cli::cli_text("Simplified: {.val {isTRUE(x$meta$simplified)}}")
  crs <- sf::st_crs(x$nodes)
  cli::cli_text("CRS: {.val {if (is.na(crs)) 'none' else crs$input}}")
  invisible(x)
}

#' @export
summary.osm_graph <- function(object, ...) {
  ox_basic_stats(object)
}

#' Plot an `osm_graph`
#'
#' Draws the street-network edges (and optionally nodes) using base `sf`
#' plotting.
#'
#' @param x An `osm_graph`.
#' @param nodes Logical; overlay node points. Default `FALSE`.
#' @param col,lwd Passed to the edge geometry plot.
#' @param ... Further arguments passed to [sf::plot.sf()].
#'
#' @return Invisibly, the `osm_graph`.
#' @export
plot.osm_graph <- function(x, nodes = FALSE, col = "#0d3b66", lwd = 0.7, ...) {
  plot(sf::st_geometry(x$edges), col = col, lwd = lwd, ...)
  if (nodes) plot(sf::st_geometry(x$nodes), add = TRUE, pch = 19, cex = 0.3, col = "#b7410e")
  invisible(x)
}

#' Extract `sf` nodes and edges from an `osm_graph`
#'
#' @param g An `osm_graph`.
#' @return A named list with `sf` elements `nodes` and `edges`.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' parts <- ox_as_sf(g)
#' parts$edges
ox_as_sf <- function(g) {
  stopifnot(is_osm_graph(g))
  list(nodes = g$nodes, edges = g$edges)
}

#' Figure-ground diagram of a street network
#'
#' Draws a figure-ground diagram: the streets in a single colour on a solid
#' background, with no axes or margins. Cropping different places to the same
#' extent makes their network form directly comparable, as in Boeing (2025).
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param bg,col Background and street colours. Default white-on-black.
#' @param lwd Street line width. Default `1.2`.
#' @param title Optional panel title.
#'
#' @return Invisibly, the `osm_graph`.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_plot_figure_ground(g)
ox_plot_figure_ground <- function(g, bg = "black", col = "white", lwd = 1.2, title = NULL) {
  stopifnot(is_osm_graph(g))
  mar <- if (is.null(title)) c(0, 0, 0, 0) else c(0, 0, 1.6, 0)
  op <- graphics::par(bg = bg, mar = mar)
  on.exit(graphics::par(op))
  plot(sf::st_geometry(g$edges), col = col, lwd = lwd)
  if (!is.null(title)) graphics::title(main = title, col.main = col, line = 0.2)
  invisible(g)
}
