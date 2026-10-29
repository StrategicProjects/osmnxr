# Validating osm_graph objects -------------------------------------------------

#' Validate an `osm_graph`
#'
#' Checks that a graph meets the structural expectations the rest of the
#' package relies on, and fails with one actionable bullet per problem found
#' (all problems are collected first, so one run shows everything). Useful
#' after assembling a graph by hand — a metro layer for [ox_blend()], say —
#' or after editing `nodes`/`edges` directly.
#'
#' The checks: `nodes` and `edges` are `sf` with `POINT` / `LINESTRING`
#' geometries and no empty geometries, sharing one CRS; `nodes$osmid` exists,
#' is numeric, complete and unique; `edges$u`/`edges$v` exist, are complete,
#' and reference existing node `osmid`s; `edges$length` exists, is numeric,
#' complete and nonnegative; and each edge's geometry starts at its `u` node
#' and ends at its `v` node (within `tolerance`, in CRS units) — the
#' invariant that keeps routing results and drawn geometry in agreement.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param tolerance Maximum distance, in CRS units, between an edge geometry
#'   endpoint and its `u`/`v` node before it counts as a mismatch. Default
#'   `1e-6`.
#'
#' @return `g`, invisibly, when the graph is valid; otherwise an error
#'   listing every problem found.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_validate(g)
ox_validate <- function(g, tolerance = 1e-6) {
  if (!is_osm_graph(g)) {
    cli::cli_abort("{.arg g} must be an {.cls osm_graph}.", call = NULL)
  }
  if (!inherits(g$nodes, "sf") || !inherits(g$edges, "sf")) {
    cli::cli_abort(
      "{.code g$nodes} and {.code g$edges} must both be {.cls sf} objects.",
      call = NULL
    )
  }

  issues <- character()
  flag <- function(msg) issues <<- c(issues, "x" = msg)

  nodes <- g$nodes
  edges <- g$edges

  # geometry types and emptiness
  if (!all(sf::st_geometry_type(nodes) == "POINT")) {
    flag("{.code g$nodes} must contain only {.val POINT} geometries.")
  }
  if (!all(sf::st_geometry_type(edges) == "LINESTRING")) {
    flag("{.code g$edges} must contain only {.val LINESTRING} geometries.")
  }
  n_empty <- sum(sf::st_is_empty(nodes)) + sum(sf::st_is_empty(edges))
  if (n_empty > 0) {
    flag("{n_empty} empty geometr{?y/ies} in {.code g$nodes}/{.code g$edges}.")
  }
  if (sf::st_crs(nodes) != sf::st_crs(edges)) {
    flag("{.code g$nodes} and {.code g$edges} have different CRS.")
  }

  # node ids
  ids_ok <- FALSE
  if (!"osmid" %in% names(nodes)) {
    flag("{.code g$nodes} must have an {.field osmid} column.")
  } else if (!is.numeric(nodes$osmid)) {
    flag("{.code g$nodes$osmid} must be numeric.")
  } else if (anyNA(nodes$osmid)) {
    flag("{.code g$nodes$osmid} has {sum(is.na(nodes$osmid))} missing value{?s}.")
  } else {
    ids_ok <- TRUE
    dup <- unique(nodes$osmid[duplicated(nodes$osmid)])
    if (length(dup)) {
      flag("{length(dup)} duplicated node {.field osmid}{?s} (e.g. {.val {dup[[1]]}}).")
    }
  }

  # edge endpoints
  uv_ok <- FALSE
  if (!all(c("u", "v") %in% names(edges))) {
    flag("{.code g$edges} must have {.field u} and {.field v} columns.")
  } else if (anyNA(edges$u) || anyNA(edges$v)) {
    flag("{.code g$edges$u}/{.code g$edges$v} have missing values.")
  } else {
    uv_ok <- TRUE
  }
  if (ids_ok && uv_ok) {
    dangling <- sum(!(edges$u %in% nodes$osmid) | !(edges$v %in% nodes$osmid))
    if (dangling > 0) {
      flag(paste0(
        "{dangling} edge{?s} reference{?s/} node {.field osmid}{?s} absent ",
        "from {.code g$nodes} (ignored in graph computations)."
      ))
    }
  }

  # edge lengths (the default routing weight)
  if (!"length" %in% names(edges)) {
    flag("{.code g$edges} must have a numeric {.field length} column.")
  } else if (!is.numeric(edges$length)) {
    flag("{.code g$edges$length} must be numeric.")
  } else if (anyNA(edges$length)) {
    flag("{.code g$edges$length} has {sum(is.na(edges$length))} missing value{?s}.")
  } else if (any(edges$length < 0)) {
    flag("{.code g$edges$length} has {sum(edges$length < 0)} negative value{?s}.")
  }

  # edge geometries must run from their u node to their v node (only checked
  # once everything above holds, so every edge is a nonempty LINESTRING and
  # the first/last rows below line up with the edge rows)
  if (ids_ok && uv_ok && nrow(edges) > 0 && !length(issues)) {
    xy <- sf::st_coordinates(nodes)
    iu <- match(edges$u, nodes$osmid)
    iv <- match(edges$v, nodes$osmid)
    m <- sf::st_coordinates(edges)
    fst <- m[!duplicated(m[, "L1"]), c("X", "Y"), drop = FALSE]
    lst <- m[!duplicated(m[, "L1"], fromLast = TRUE), c("X", "Y"), drop = FALSE]
    chk <- which(!is.na(iu) & !is.na(iv)) # dangling edges already flagged
    bad <- chk[
      abs(fst[chk, 1] - xy[iu[chk], 1]) > tolerance |
      abs(fst[chk, 2] - xy[iu[chk], 2]) > tolerance |
      abs(lst[chk, 1] - xy[iv[chk], 1]) > tolerance |
      abs(lst[chk, 2] - xy[iv[chk], 2]) > tolerance
    ]
    if (length(bad)) {
      flag(paste0(
        "{length(bad)} edge geometr{?y/ies} {?does/do} not run from {?its/their} ",
        "{.field u} node to {?its/their} {.field v} node ",
        "(within {.arg tolerance}; e.g. row {bad[[1]]})."
      ))
    }
  }

  if (length(issues)) {
    cli::cli_abort(
      c("Invalid {.cls osm_graph}: {length(issues)} problem{?s} found.", issues),
      call = NULL
    )
  }
  cli::cli_alert_success(
    "Valid {.cls osm_graph}: {nrow(nodes)} node{?s}, {nrow(edges)} edge{?s}."
  )
  invisible(g)
}
