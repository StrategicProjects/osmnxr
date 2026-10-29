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
#' Every edge attribute column survives simplification: a merged edge takes
#' the value of its first segment, except for columns named in
#' `edge_attr_aggs`, whose per-segment values are combined by the given
#' function (as in OSMnx 2). `length` is always recomputed from the merged
#' geometry unless an explicit `length` aggregator is supplied, and
#' `n_segments` records how many segments each edge merged.
#'
#' @param g An unsimplified [osm_graph][new_osm_graph].
#' @param edge_attr_aggs Named list of functions combining the per-segment
#'   values of an edge attribute along each merged chain, e.g.
#'   `list(travel_time = sum, speed_kph = mean)`. The default `NULL` sums
#'   `travel_time` and `penalty` when those columns exist (so routing weights
#'   stay consistent); pass `list()` to aggregate nothing. Each function
#'   receives the segment values of one merged edge and must return a single
#'   value.
#'
#' @return A simplified [osm_graph][new_osm_graph] (with `meta$simplified =
#'   TRUE`).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_simplify(g) # already simplified: returned unchanged
ox_simplify <- function(g, edge_attr_aggs = NULL) {
  stopifnot(is_osm_graph(g))
  if (isTRUE(g$meta$simplified)) {
    cli::cli_alert_info("Graph is already simplified; returning unchanged.")
    return(g)
  }
  sf_col <- attr(g$edges, "sf_column")
  if (is.null(edge_attr_aggs)) {
    edge_attr_aggs <- list(travel_time = sum, penalty = sum)
    edge_attr_aggs <- edge_attr_aggs[names(edge_attr_aggs) %in% names(g$edges)]
  } else {
    if (!is.list(edge_attr_aggs) ||
        (length(edge_attr_aggs) && (is.null(names(edge_attr_aggs)) ||
                                    any(!nzchar(names(edge_attr_aggs)))))) {
      cli::cli_abort("{.arg edge_attr_aggs} must be a fully named list of functions.", call = NULL)
    }
    if (!all(vapply(edge_attr_aggs, is.function, logical(1)))) {
      cli::cli_abort("{.arg edge_attr_aggs} must contain only functions.", call = NULL)
    }
    absent <- setdiff(names(edge_attr_aggs), names(g$edges))
    if (length(absent)) {
      cli::cli_abort("{.arg edge_attr_aggs} name{?s} column{?s} absent from {.code g$edges}: {.val {absent}}.", call = NULL)
    }
    if (any(names(edge_attr_aggs) %in% c("u", "v", sf_col))) {
      cli::cli_abort("{.arg edge_attr_aggs} cannot aggregate {.field u}, {.field v} or the geometry.", call = NULL)
    }
  }
  ea <- graph_edge_arrays(g)
  paths <- rs_simplify_paths(ea$from, ea$to, ea$n_nodes)
  paths <- paths[vapply(paths, length, integer(1)) >= 2]
  if (length(paths) == 0) cli::cli_abort("Simplification produced no edges.", call = NULL)

  ids <- ea$node_ids
  coords <- sf::st_coordinates(g$nodes)[, c("X", "Y"), drop = FALSE]
  crs <- sf::st_crs(g$nodes)

  # set of directed segments present in the original graph, and a per-pair
  # attribute row lookup (falling back to the reversed twin), keyed by "u>v"
  dirset <- paste(g$edges$u, g$edges$v, sep = ">")
  has_dir <- function(a, b) all(paste(a, b, sep = ">") %in% dirset)
  pair_rows <- function(a, b) {
    m <- match(paste(a, b, sep = ">"), dirset)
    m2 <- match(paste(b, a, sep = ">"), dirset)
    ifelse(is.na(m), m2, m)
  }

  geoms <- list()
  u <- v <- numeric(0)
  n_seg <- integer(0)
  seg_rows <- list() # per merged edge: its segments' rows in g$edges

  add_edge <- function(rows, chain) {
    geoms[[length(geoms) + 1L]] <<- sf::st_linestring(coords[rows, , drop = FALSE])
    u <<- c(u, ids[rows[1]]); v <<- c(v, ids[rows[length(rows)]])
    n_seg <<- c(n_seg, length(rows) - 1L)
    seg_rows[[length(seg_rows) + 1L]] <<- pair_rows(chain[-length(chain)], chain[-1])
  }

  for (k in seq_along(paths)) {
    p1 <- paths[[k]] + 1L # 1-based row indices into nodes
    chain <- ids[p1]
    fwd <- has_dir(chain[-length(chain)], chain[-1])       # traversable u -> v
    bwd <- has_dir(chain[-1], chain[-length(chain)])       # traversable v -> u
    if (!fwd && !bwd) fwd <- TRUE                          # fallback: keep one
    if (fwd) add_edge(p1, chain)
    if (bwd) add_edge(rev(p1), rev(chain))
  }

  edges <- sf::st_sf(
    u = u, v = v, n_segments = n_seg, geometry = sf::st_sfc(geoms, crs = crs)
  )
  first_of <- vapply(seg_rows, function(r) {
    r <- r[!is.na(r)]
    if (length(r)) r[1] else NA_integer_
  }, integer(1))
  for (col in setdiff(names(g$edges), c("u", "v", sf_col))) {
    vals <- g$edges[[col]]
    edges[[col]] <- if (col %in% names(edge_attr_aggs)) {
      f <- edge_attr_aggs[[col]]
      unlist(lapply(seg_rows, function(r) f(vals[r[!is.na(r)]])), use.names = FALSE)
    } else {
      vals[first_of]
    }
  }
  if (!"length" %in% names(edge_attr_aggs)) {
    edges$length <- as.numeric(sf::st_length(edges))
  }

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
#' Consolidating an already-consolidated graph (`meta$consolidated` is set)
#' warns but proceeds, clustering the consolidated nodes again — legitimate
#' for growing the tolerance, but usually a mistake.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param tolerance Distance below which nodes are merged, in CRS units.
#'   Either one number for the whole graph (default `10`), or one number per
#'   node for junction-specific radii (as in OSMnx 2): each node is buffered
#'   by `tolerance / 2`, and nodes merge when their buffers overlap — i.e.
#'   two nodes merge when their distance is at most the mean of their two
#'   tolerances, so a `0` keeps a node out of every merge it does not fall
#'   inside another node's radius for.
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
  if (!is.numeric(tolerance) || anyNA(tolerance) || any(tolerance < 0) ||
      !length(tolerance) %in% c(1L, nrow(nodes))) {
    cli::cli_abort(
      "{.arg tolerance} must be a nonnegative number, or one per node ({nrow(nodes)}).",
      call = NULL
    )
  }
  if (isTRUE(g$meta$consolidated)) {
    cli::cli_warn(
      "Graph is already consolidated; clustering the consolidated nodes again."
    )
  }
  ids <- nodes$osmid
  within <- if (length(tolerance) == 1L) {
    sf::st_is_within_distance(nodes, dist = tolerance)
  } else {
    # per-node radii: buffers of tolerance / 2 overlap exactly when
    # dist(i, j) <= (tolerance[i] + tolerance[j]) / 2
    sf::st_intersects(sf::st_buffer(sf::st_geometry(nodes), tolerance / 2))
  }
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
