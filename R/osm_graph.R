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

# Union of graphs --------------------------------------------------------------

# Bind a list of sf objects row-wise, harmonising the geometry column name so
# tables coming from different constructors (or user-made sf) stack cleanly.
# Attribute columns missing from one table are filled with NA.
bind_sf_rows <- function(xs, geom_name) {
  xs <- lapply(xs, function(x) {
    old <- attr(x, "sf_column")
    if (!identical(old, geom_name)) {
      names(x)[names(x) == old] <- geom_name
      x <- sf::st_set_geometry(x, geom_name)
    }
    x
  })
  attr_cols <- Reduce(union, lapply(xs, function(x) setdiff(names(x), geom_name)))
  xs <- lapply(xs, function(x) {
    for (col in setdiff(attr_cols, names(x))) x[[col]] <- NA
    x[, c(attr_cols, geom_name)]
  })
  out <- do.call(rbind, xs)
  sf::st_as_sf(tibble::as_tibble(out))
}

#' Union of `osm_graph` objects
#'
#' Combines two or more graphs into a single [osm_graph][new_osm_graph]. Node
#' and edge tables are stacked; nodes sharing an `osmid` are merged (the first
#' occurrence wins) and edges duplicated across graphs are dropped. Attribute
#' columns present in one graph but not another are filled with `NA`.
#'
#' Nodes with the same `osmid` are treated as the same location, which is what
#' stitches the graphs together: overlapping downloads share their OSM node
#' ids, and a hand-built network (say, a metro layer) connects to a street
#' graph wherever its edges reference street-node `osmid`s. Custom networks
#' should therefore use node ids that do not collide with OSM's except where a
#' connection is intended (negative ids are a safe choice).
#'
#' @param ... Two or more `osm_graph` objects, or a single list of them. All
#'   must share the same CRS.
#' @param dedupe_edges Drop edges that appear in more than one graph with
#'   identical `u`, `v` and geometry (as happens when unioning overlapping
#'   downloads). Default `TRUE`.
#'
#' @return An [osm_graph][new_osm_graph]. `meta$network_type` concatenates the
#'   distinct input types (e.g. `"drive+walk"`), `meta$simplified` is `TRUE`
#'   only if every input was simplified, and `meta$union_of` records how many
#'   graphs were combined.
#' @export
#'
#' @examples
#' g1 <- example_osm_graph(n = 3)
#'
#' # a second, disjoint network with its own node ids
#' g2 <- example_osm_graph(n = 3)
#' g2$nodes$osmid <- g2$nodes$osmid + 1000
#' g2$edges$u <- g2$edges$u + 1000
#' g2$edges$v <- g2$edges$v + 1000
#'
#' u <- ox_union(g1, g2)
#' u
#'
#' # unioning overlapping graphs dedupes shared nodes and edges
#' nrow(ox_union(g1, g1)$edges) == nrow(g1$edges)
ox_union <- function(..., dedupe_edges = TRUE) {
  graphs <- rlang::list2(...)
  if (length(graphs) == 1L && !is_osm_graph(graphs[[1L]]) && is.list(graphs[[1L]])) {
    graphs <- graphs[[1L]]
  }
  if (length(graphs) < 2L) {
    cli::cli_abort("Supply at least two {.cls osm_graph} objects.", call = NULL)
  }
  ok <- vapply(graphs, is_osm_graph, logical(1))
  if (!all(ok)) {
    cli::cli_abort(
      "Input{?s} {which(!ok)} {?is/are} not {.cls osm_graph} object{?s}.",
      call = NULL
    )
  }

  crs <- sf::st_crs(graphs[[1L]]$nodes)
  same_crs <- vapply(graphs, function(g) sf::st_crs(g$nodes) == crs, logical(1))
  if (!all(same_crs)) {
    cli::cli_abort(c(
      "All graphs must share the same CRS.",
      "i" = "Reproject with {.fn sf::st_transform} before unioning."
    ), call = NULL)
  }

  nodes <- bind_sf_rows(
    lapply(graphs, `[[`, "nodes"),
    attr(graphs[[1L]]$nodes, "sf_column")
  )
  edges <- bind_sf_rows(
    lapply(graphs, `[[`, "edges"),
    attr(graphs[[1L]]$edges, "sf_column")
  )

  # merge nodes sharing an osmid; warn when their coordinates disagree
  dup <- duplicated(nodes$osmid)
  if (any(dup)) {
    affected <- nodes$osmid %in% nodes$osmid[dup]
    wkt <- sf::st_as_text(sf::st_geometry(nodes)[affected])
    id <- nodes$osmid[affected]
    conflict <- unique(id[duplicated(id) & !duplicated(paste0(id, "|", wkt))])
    if (length(conflict)) {
      cli::cli_warn(c(
        "{length(conflict)} node{?s} share{?s/} an {.field osmid} across graphs but ha{?s/ve} different coordinates.",
        "i" = "Keeping the coordinates of the first occurrence."
      ))
    }
    nodes <- nodes[!dup, ]
  }

  if (isTRUE(dedupe_edges)) {
    key <- paste(edges$u, edges$v, sf::st_as_text(sf::st_geometry(edges)), sep = "|")
    edges <- edges[!duplicated(key), ]
  }

  dangling <- sum(!(edges$u %in% nodes$osmid) | !(edges$v %in% nodes$osmid))
  if (dangling > 0) {
    cli::cli_warn(
      "{dangling} edge{?s} reference{?s/} node {.field osmid}s absent from the union and will be ignored in graph computations."
    )
  }

  types <- unique(vapply(
    graphs, function(g) g$meta$network_type %||% "unknown", character(1)
  ))
  queries <- unique(unlist(lapply(graphs, function(g) g$meta$query)))
  new_osm_graph(nodes, edges, meta = list(
    network_type = paste(types, collapse = "+"),
    simplified = all(vapply(graphs, function(g) isTRUE(g$meta$simplified), logical(1))),
    query = if (length(queries)) paste(queries, collapse = " + ") else NULL,
    union_of = length(graphs)
  ))
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
