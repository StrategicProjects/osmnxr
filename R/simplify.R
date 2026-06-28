# Topology simplification and intersection consolidation ----------------------

#' Simplify street-network topology
#'
#' Removes interstitial (degree-2) nodes that merely shape the geometry of a
#' street, merging each maximal chain of such nodes into a single edge whose
#' geometry follows the original points and whose `length` is the sum of the
#' merged segments. Only true endpoints and intersections are kept as nodes.
#'
#' The topology walk is performed by the Rust core; geometry is rebuilt with
#' `sf`. Downloaded graphs are unsimplified by default; this is the standard
#' cleanup step before analysis.
#'
#' @param g An unsimplified [osm_graph][new_osm_graph].
#'
#' @return A simplified [osm_graph][new_osm_graph] (with `meta$simplified =
#'   TRUE`).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_simplify(g) # already simplified: returned unchanged
ox_simplify <- function(g) {
  stopifnot(is_osm_graph(g))
  if (isTRUE(g$meta$simplified)) {
    cli::cli_alert_info("Graph is already simplified; returning unchanged.")
    return(g)
  }
  ea <- graph_edge_arrays(g)
  paths <- rs_simplify_paths(ea$from, ea$to, ea$n_nodes)
  paths <- paths[vapply(paths, length, integer(1)) >= 2]
  if (length(paths) == 0) cli::cli_abort("Simplification produced no edges.", call = NULL)

  ids <- ea$node_ids
  coords <- sf::st_coordinates(g$nodes)[, c("X", "Y"), drop = FALSE]
  crs <- sf::st_crs(g$nodes)

  # lookup of original edge attributes by directed "u>v"
  ekey <- paste(g$edges$u, g$edges$v, sep = ">")
  attr_idx <- function(u, v) {
    m <- match(paste(u, v, sep = ">"), ekey)
    if (is.na(m)) match(paste(v, u, sep = ">"), ekey) else m
  }

  geoms <- vector("list", length(paths))
  u <- v <- integer(length(paths))
  highway <- name <- character(length(paths))
  oneway <- logical(length(paths))
  n_seg <- integer(length(paths))

  for (k in seq_along(paths)) {
    p1 <- paths[[k]] + 1L # 1-based row indices into nodes
    geoms[[k]] <- sf::st_linestring(coords[p1, , drop = FALSE])
    u[k] <- ids[p1[1]]
    v[k] <- ids[p1[length(p1)]]
    n_seg[k] <- length(p1) - 1L
    ai <- attr_idx(ids[p1[1]], ids[p1[2]])
    highway[k] <- if (!is.na(ai)) as.character(g$edges$highway[ai]) else NA_character_
    name[k] <- if (!is.na(ai) && "name" %in% names(g$edges)) as.character(g$edges$name[ai]) else NA_character_
    oneway[k] <- if (!is.na(ai) && "oneway" %in% names(g$edges)) isTRUE(g$edges$oneway[ai]) else FALSE
  }

  edges <- sf::st_sf(
    u = u, v = v, highway = highway, name = name, oneway = oneway,
    n_segments = n_seg, geometry = sf::st_sfc(geoms, crs = crs)
  )
  edges$length <- as.numeric(sf::st_length(edges))

  kept <- sort(unique(c(u, v)))
  nodes <- g$nodes[match(kept, ids), ]

  meta <- g$meta
  meta$simplified <- TRUE
  new_osm_graph(nodes, edges, meta)
}

#' Consolidate nearby intersections
#'
#' Merges groups of nodes lying within `tolerance` of one another into single
#' nodes placed at the group centroid, then rewrites edges to the consolidated
#' nodes and drops the resulting self-loops. Useful for collapsing the multiple
#' OSM nodes that represent one complex junction (e.g. dual carriageways).
#'
#' Clustering uses `sf::st_is_within_distance()`; connected components are found
#' by the Rust core. `tolerance` is in the units of the graph CRS, so project
#' the graph first (e.g. to a metric CRS) for a meaningful distance.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param tolerance Distance below which nodes are merged, in CRS units.
#'   Default `10`.
#'
#' @return A consolidated [osm_graph][new_osm_graph] (with `meta$consolidated =
#'   TRUE`).
#' @export
#'
#' @examples
#' g <- example_osm_graph(n = 4, spacing = 100)
#' # nothing is within 10 units here, so the graph is unchanged
#' ox_consolidate_intersections(g, tolerance = 10)
ox_consolidate_intersections <- function(g, tolerance = 10) {
  stopifnot(is_osm_graph(g))
  nodes <- g$nodes
  ids <- nodes$osmid
  within <- sf::st_is_within_distance(nodes, dist = tolerance)
  a <- rep(seq_along(within), lengths(within))
  b <- unlist(within)
  comp <- rs_connected_components(as.integer(a - 1L), as.integer(b - 1L), nrow(nodes))

  coords <- sf::st_coordinates(nodes)[, c("X", "Y"), drop = FALSE]
  crs <- sf::st_crs(nodes)

  roots <- unique(comp)
  new_id <- integer(length(roots))
  cx <- cy <- numeric(length(roots))
  for (i in seq_along(roots)) {
    members <- which(comp == roots[i])
    new_id[i] <- min(ids[members])
    cx[i] <- mean(coords[members, 1])
    cy[i] <- mean(coords[members, 2])
  }
  root_to_newid <- stats::setNames(new_id, as.character(roots))

  # map every old node index -> consolidated osmid
  node_newid <- root_to_newid[as.character(comp)]

  new_nodes <- sf::st_as_sf(
    data.frame(osmid = new_id, x = cx, y = cy),
    coords = c("x", "y"), crs = crs, remove = FALSE
  )

  eu <- node_newid[match(g$edges$u, ids)]
  ev <- node_newid[match(g$edges$v, ids)]
  keep <- eu != ev
  eu <- eu[keep]; ev <- ev[keep]

  ncoord <- stats::setNames(seq_len(nrow(new_nodes)), as.character(new_nodes$osmid))
  geoms <- lapply(seq_along(eu), function(i) {
    sf::st_linestring(rbind(
      c(cx[ncoord[as.character(eu[i])]], cy[ncoord[as.character(eu[i])]]),
      c(cx[ncoord[as.character(ev[i])]], cy[ncoord[as.character(ev[i])]])
    ))
  })
  old <- g$edges[keep, ]
  edges <- sf::st_sf(
    u = eu, v = ev,
    highway = if ("highway" %in% names(old)) old$highway else NA_character_,
    geometry = sf::st_sfc(geoms, crs = crs)
  )
  edges$length <- as.numeric(sf::st_length(edges))

  meta <- g$meta
  meta$consolidated <- TRUE
  new_osm_graph(new_nodes, edges, meta)
}

#' Find the nearest edge to a point
#'
#' Returns, for each supplied coordinate, the graph edge closest in planar
#' distance.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param x,y Numeric vectors of coordinates in the graph's CRS.
#'
#' @return An `sf` subset of `g$edges`, one row per input point.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_nearest_edges(g, x = 50, y = 0)
ox_nearest_edges <- function(g, x, y) {
  stopifnot(is_osm_graph(g))
  pts <- sf::st_as_sf(data.frame(x = x, y = y), coords = c("x", "y"),
                      crs = sf::st_crs(g$nodes))
  idx <- sf::st_nearest_feature(pts, g$edges)
  g$edges[idx, ]
}
