# Blending points and graphs into a street network ----------------------------

#' Blend points or another graph into a street network
#'
#' Snaps point locations onto their nearest network edge and splits that edge
#' there, turning each snapped location into a routable node — the `osmnxr`
#' counterpart of `sfnetworks::st_network_blend()`, with the snapping done in
#' the Rust core (grid-indexed planar distance) so city-sized networks blend
#' in seconds.
#'
#' Two-way streets are handled properly: every edge sharing the split edge's
#' geometry (its reversed twin, or a same-direction duplicate) is split at the
#' same location into the same new node, so routability is preserved in both
#' directions. Points that project onto an existing node are attached to that
#' node instead of splitting. Points farther than `tolerance` from every edge
#' are left out with a warning. New nodes get consecutive `osmid`s starting
#' just above the largest id in sight (`g`'s — and `y`'s too in graph mode),
#' so existing ids keep their meaning.
#'
#' When `y` is another [osm_graph][new_osm_graph], the result is a combined
#' multimodal network, built in three steps (as proposed in the issue that
#' motivated this feature): (1) every node of `y` (within `tolerance`, and
#' flagged by `snap_nodes`) is blended into `g` as above; (2) the two graphs
#' are stacked with [ox_union()], so `y`'s own nodes and edges are kept
#' intact; (3) a pair of directed *connector* edges is added between each `y`
#' node and the node it snapped to, which is the connectivity a plain blend +
#' union would miss. Node `osmid`s shared by both graphs are merged by the
#' union directly (no connector needed) — but only when they sit at the same
#' coordinates: reusing an id of `g` for a genuinely different location in
#' `y` is an error (renumber `y`'s ids first). The union here does not
#' deduplicate edges (the two layers are assumed to be distinct networks);
#' combine overlapping downloads with [ox_union()] first when that matters.
#'
#' Distances are planar, in the units of the graph's CRS (reproject
#' geographic networks first — [sf::st_transform()] on `nodes` and `edges` —
#' when a metric `tolerance` matters). Split edges keep their attributes;
#' `length` is
#' recomputed from the new geometries, and `travel_time` / `penalty` (when
#' present) are rescaled proportionally to each piece's share of the parent
#' edge, so routing weights stay consistent.
#'
#' @param g An [osm_graph][new_osm_graph] to blend into.
#' @param y What to blend: an `sf`/`sfc` of `POINT` geometries, or another
#'   `osm_graph` (same CRS as `g`). Attribute columns of an `sf` `y` are
#'   carried onto the new nodes they create.
#' @param tolerance Maximum snapping distance, in CRS units. Points (or `y`
#'   nodes) farther than this from every edge of `g` are not blended.
#'   Default `Inf`.
#' @param connector_attrs Named list of constant attribute values for the
#'   connector edges created in graph mode (e.g.
#'   `list(highway = "connector", travel_time = 60)`). Columns the connectors
#'   do not set are `NA`-filled — in particular, set `travel_time` here (or
#'   fix it afterwards) before routing the blended graph on travel time.
#'   Ignored when `y` is a set of points.
#' @param snap_nodes Which points (or `y` nodes) may be snapped: `TRUE` (the
#'   default, all of them) or a logical vector with one flag per point / `y`
#'   node. Flagged-off points get an `NA` row in `meta$blend`; in graph mode,
#'   flagged-off `y` nodes still enter the union with `y`'s own edges — they
#'   just get no connector (e.g. a station's street-level gates snap, its
#'   platforms don't and are reached through the gates).
#' @param snap_edges Which edges of `g` may receive snapped points: `TRUE`
#'   (the default, all of them) or a logical vector with one flag per row of
#'   `g$edges` (e.g. rule out limited-access flyovers that pass close by).
#'   Note the flag governs where points may *land*, not split propagation:
#'   when a snapped edge is split, edges sharing its geometry (the reversed
#'   twin of a two-way street) are split with it regardless of their own
#'   flag, to keep both directions routable.
#' @param connector_node_attrs Character vector of `y` node attribute columns
#'   to copy onto the two connector edges of each snapped `y` node in graph
#'   mode (e.g. a per-station access time that should weight the connector).
#'   Errors when a column is absent from `y`'s nodes or clashes with
#'   `connector_attrs` or a connector-reserved column (`u`, `v`, `length`).
#'   Ignored when `y` is a set of points.
#'
#' @return An [osm_graph][new_osm_graph]. `meta$blend` records the mapping as
#'   a [tibble][tibble::tibble]: one row per input point (or `y` node not
#'   shared with `g`), with the node `osmid` it became or attached to (`NA`
#'   when beyond `tolerance` or flagged off by `snap_nodes`), the snapping
#'   distance, and `u` / `v` — the endpoints of the `g` edge it snapped onto,
#'   as that edge was *before* the blend (splitting replaces it with pieces
#'   chained through the new nodes).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#'
#' # blend two POIs into the grid: each becomes a routable node
#' pts <- sf::st_sfc(sf::st_point(c(150, 40)), sf::st_point(c(250, 260)),
#'                   crs = 3857)
#' b <- ox_blend(g, pts)
#' b$meta$blend
#' ox_shortest_path(b, b$meta$blend$node[1], b$meta$blend$node[2])
#'
#' # blend a tiny second network (e.g. a metro line) into the grid
#' metro <- new_osm_graph(
#'   sf::st_sf(osmid = c(1001, 1002), access_time = c(30, 45),
#'             geometry = sf::st_sfc(sf::st_point(c(40, 150)),
#'                                   sf::st_point(c(260, 150)), crs = 3857)),
#'   sf::st_sf(u = 1001, v = 1002, length = 220,
#'             geometry = sf::st_sfc(sf::st_linestring(
#'               rbind(c(40, 150), c(260, 150))), crs = 3857)),
#'   meta = list(network_type = "metro")
#' )
#' mm <- ox_blend(g, metro, connector_attrs = list(highway = "connector"),
#'                connector_node_attrs = "access_time")
#' mm
ox_blend <- function(g, y, tolerance = Inf, connector_attrs = list(),
                     snap_nodes = TRUE, snap_edges = TRUE,
                     connector_node_attrs = character()) {
  stopifnot(is_osm_graph(g))
  if (nrow(g$edges) == 0) {
    cli::cli_abort("{.arg g} has no edges to blend into.", call = NULL)
  }
  if (length(tolerance) != 1 || is.na(tolerance) || tolerance < 0) {
    cli::cli_abort("{.arg tolerance} must be a single nonnegative number (or {.code Inf}).", call = NULL)
  }
  snap_edges <- blend_flag(snap_edges, nrow(g$edges), "snap_edges")
  if (!any(snap_edges)) {
    cli::cli_abort("{.arg snap_edges} rules out every edge of {.arg g}.", call = NULL)
  }
  if (is_osm_graph(y)) {
    blend_graph(g, y, tolerance, connector_attrs, snap_nodes, snap_edges,
                connector_node_attrs)
  } else {
    blend_points(g, y, tolerance, snap_nodes, snap_edges)
  }
}

# Internal: blend an sf/sfc of points into g.
blend_points <- function(g, y, tolerance, snap_nodes, snap_edges) {
  pts <- if (inherits(y, "sf")) sf::st_geometry(y) else y
  if (!inherits(pts, "sfc")) {
    cli::cli_abort("{.arg y} must be an {.cls sf}/{.cls sfc} of points or an {.cls osm_graph}.", call = NULL)
  }
  if (!all(sf::st_geometry_type(pts) == "POINT")) {
    cli::cli_abort("{.arg y} must contain only {.val POINT} geometries.", call = NULL)
  }
  check_blend_crs(g, pts)
  snap_nodes <- blend_flag(snap_nodes, length(pts), "snap_nodes")
  attrs <- if (inherits(y, "sf")) sf::st_drop_geometry(y) else NULL
  core <- blend_core(
    g, sf::st_coordinates(pts)[snap_nodes, 1:2, drop = FALSE], tolerance,
    node_attrs = if (!is.null(attrs)) attrs[snap_nodes, , drop = FALSE],
    snap_edges = snap_edges
  )
  out <- core$graph
  blend <- tibble::tibble(
    point = seq_along(pts),
    node = NA_real_, dist = NA_real_, u = NA_real_, v = NA_real_
  )
  blend[snap_nodes, c("node", "dist", "u", "v")] <- core$map
  out$meta$blend <- blend
  out
}

# Internal: blend the nodes of graph y into g, union the two graphs, and add
# connector edges between each blended node pair.
blend_graph <- function(g, y, tolerance, connector_attrs, snap_nodes,
                        snap_edges, connector_node_attrs) {
  check_blend_crs(g, sf::st_geometry(y$nodes))
  if (length(connector_attrs) && (is.null(names(connector_attrs)) ||
      any(!nzchar(names(connector_attrs))))) {
    cli::cli_abort("{.arg connector_attrs} must be a fully named list.", call = NULL)
  }
  snap_nodes <- blend_flag(snap_nodes, nrow(y$nodes), "snap_nodes")
  check_connector_node_attrs(connector_node_attrs, y, connector_attrs)

  # an osmid in both graphs means "same node" to the union; catch ids reused
  # for genuinely different locations before they merge silently
  shared <- intersect(g$nodes$osmid, y$nodes$osmid)
  if (length(shared)) {
    g_wkt <- sf::st_as_text(sf::st_geometry(g$nodes)[match(shared, g$nodes$osmid)])
    y_wkt <- sf::st_as_text(sf::st_geometry(y$nodes)[match(shared, y$nodes$osmid)])
    conflict <- shared[g_wkt != y_wkt]
    if (length(conflict)) {
      cli::cli_abort(c(
        "{.arg y} reuses {length(conflict)} {.field osmid}{?s} of {.arg g} at different coordinates (e.g. {.val {conflict[[1]]}}).",
        "i" = "Shared osmids merge into one node in the union. Renumber {.arg y}'s node ids (and the matching {.field u}/{.field v} in its edges) before blending."
      ), call = NULL)
    }
  }

  # nodes already shared by osmid stitch through ox_union(); blend the rest
  new_in_y <- !(y$nodes$osmid %in% g$nodes$osmid)
  pts_all <- y$nodes[new_in_y, ]
  do_snap <- snap_nodes[new_in_y]
  pts <- pts_all[do_snap, ]
  core <- blend_core(
    g, sf::st_coordinates(sf::st_geometry(pts))[, 1:2, drop = FALSE],
    tolerance, node_attrs = NULL, avoid_ids = y$nodes$osmid,
    snap_edges = snap_edges
  )

  # dedupe_edges compares WKT across all edges — minutes on metro-sized
  # graphs, and pointless here: the blended layers are distinct networks.
  # Union overlapping downloads with ox_union() itself before blending.
  out <- ox_union(core$graph, y, dedupe_edges = FALSE)

  # connector edges, both directions, between each y node and its snap node
  with_conn <- which(!is.na(core$map$node) & core$map$node != pts$osmid)
  if (length(with_conn)) {
    y_ids <- pts$osmid[with_conn]
    t_ids <- core$map$node[with_conn]
    y_xy <- sf::st_coordinates(sf::st_geometry(pts))[with_conn, , drop = FALSE]
    t_xy <- sf::st_coordinates(sf::st_geometry(out$nodes))[
      match(t_ids, out$nodes$osmid), , drop = FALSE
    ]
    lines <- lapply(seq_along(with_conn), function(i) {
      sf::st_linestring(rbind(y_xy[i, 1:2], t_xy[i, 1:2]))
    })
    conn <- sf::st_sf(
      u = c(y_ids, t_ids),
      v = c(t_ids, y_ids),
      geometry = sf::st_sfc(c(lines, lines), crs = sf::st_crs(g$nodes))
    )
    conn$length <- as.numeric(sf::st_length(conn))
    for (nm in names(connector_attrs)) conn[[nm]] <- connector_attrs[[nm]]
    for (nm in connector_node_attrs) {
      vals <- pts[[nm]][with_conn]
      conn[[nm]] <- c(vals, vals)
    }
    edges <- bind_sf_rows(
      list(out$edges, conn), attr(out$edges, "sf_column")
    )
    out <- new_osm_graph(out$nodes, edges, out$meta)
  }

  blend <- tibble::tibble(
    osmid = pts_all$osmid,
    node = NA_real_, dist = NA_real_, u = NA_real_, v = NA_real_
  )
  blend[do_snap, c("node", "dist", "u", "v")] <- core$map
  out$meta$blend <- blend
  out
}

# Internal: shared CRS guard.
check_blend_crs <- function(g, pts) {
  if (sf::st_crs(g$nodes) != sf::st_crs(pts)) {
    cli::cli_abort(c(
      "{.arg y} must share {.arg g}'s CRS.",
      "i" = "Reproject with {.fn sf::st_transform} first."
    ), call = NULL)
  }
}

# Internal: a snap_nodes / snap_edges flag, validated and recycled to n.
blend_flag <- function(x, n, what) {
  if (!is.logical(x) || anyNA(x) || !length(x) %in% c(1L, n)) {
    cli::cli_abort(
      "{.arg {what}} must be {.code TRUE}/{.code FALSE} or a logical vector of length {n} with no missing values.",
      call = NULL
    )
  }
  rep_len(x, n)
}

# Internal: connector_node_attrs must name y node columns that no other
# connector column source already claims.
check_connector_node_attrs <- function(attrs, y, connector_attrs) {
  if (!length(attrs)) return(invisible())
  if (!is.character(attrs) || anyNA(attrs)) {
    cli::cli_abort(
      "{.arg connector_node_attrs} must be a character vector of {.code y} node column names.",
      call = NULL
    )
  }
  cols <- setdiff(names(y$nodes), attr(y$nodes, "sf_column"))
  absent <- setdiff(attrs, cols)
  if (length(absent)) {
    cli::cli_abort(
      "{.arg connector_node_attrs} name{?s} column{?s} absent from {.code y}'s nodes: {.val {absent}}.",
      call = NULL
    )
  }
  clash <- intersect(attrs, c(names(connector_attrs), "u", "v", "length"))
  if (length(clash)) {
    cli::cli_abort(
      "{.arg connector_node_attrs} clashes with column{?s} the connectors already set: {.val {clash}}.",
      call = NULL
    )
  }
}

# Internal: snap pts_xy (a 2-column matrix) onto g's edges (those flagged by
# snap_edges) and split those edges (and their geometry twins) at the snapped
# locations. Returns the new graph plus a map: per point, the node osmid it
# became/attached to (NA when beyond tolerance), the snapping distance, and
# the endpoints of the edge it snapped onto.
blend_core <- function(g, pts_xy, tolerance, node_attrs = NULL,
                       avoid_ids = numeric(), snap_edges = NULL) {
  n_pts <- nrow(pts_xy)
  node_of <- rep(NA_real_, n_pts)
  u_of <- rep(NA_real_, n_pts)
  v_of <- rep(NA_real_, n_pts)
  empty <- function() {
    list(graph = g, map = tibble::tibble(
      node = node_of, dist = rep(NA_real_, n_pts), u = u_of, v = v_of
    ))
  }
  if (n_pts == 0) return(empty())

  allowed <- if (!is.null(snap_edges) && !all(snap_edges)) which(snap_edges)
  if (is.null(allowed)) {
    m <- sf::st_coordinates(g$edges)
    offsets <- c(0L, cumsum(tabulate(m[, "L1"], nbins = nrow(g$edges))))
  } else {
    m <- sf::st_coordinates(sf::st_geometry(g$edges)[allowed])
    offsets <- c(0L, cumsum(tabulate(m[, "L1"], nbins = length(allowed))))
  }
  snap <- rs_snap_points(m[, "X"], m[, "Y"], as.integer(offsets),
                         pts_xy[, 1], pts_xy[, 2], as.numeric(tolerance))
  if (!is.null(allowed)) {
    ok <- snap$edge >= 0
    snap$edge[ok] <- allowed[snap$edge[ok] + 1L] - 1L
  }
  snap$dist[snap$edge < 0] <- NA_real_
  hit <- which(snap$edge >= 0)
  if (length(hit) < n_pts) {
    cli::cli_warn(
      "{n_pts - length(hit)} point{?s} farther than {.arg tolerance} from every edge {?was/were} not blended."
    )
  }
  if (!length(hit)) {
    out <- empty()
    out$map$dist <- as.numeric(snap$dist)
    return(out)
  }

  edges <- g$edges
  geom <- sf::st_geometry(edges)
  aff <- unique(snap$edge[hit] + 1L)

  # candidate pool for geometry twins: every edge joining the affected
  # endpoints (covers reversed twins and same-direction duplicates)
  ends <- unique(c(edges$u[aff], edges$v[aff]))
  pool <- which(edges$u %in% ends & edges$v %in% ends)
  cl <- lapply(geom[pool], function(gm) unclass(gm)[, 1:2, drop = FALSE])
  cum <- lapply(cl, function(mm) {
    c(0, cumsum(sqrt(diff(mm[, 1])^2 + diff(mm[, 2])^2)))
  })
  elen <- vapply(cum, function(x) x[length(x)], numeric(1))

  # group pool edges that share one geometry (in either direction): canonical
  # orientation = lexicographically smaller endpoint first
  canonical <- vapply(seq_along(pool), function(i) {
    mm <- cl[[i]]
    a <- mm[1, ]; b <- mm[nrow(mm), ]
    !(b[1] < a[1] || (b[1] == a[1] && b[2] < a[2]))
  }, logical(1))
  sig <- vapply(seq_along(pool), function(i) {
    mm <- cl[[i]]
    if (!canonical[i]) mm <- mm[rev(seq_len(nrow(mm))), , drop = FALSE]
    rlang::hash(mm)
  }, character(1))
  pool_pos <- match(seq_len(nrow(edges)), pool) # edge row -> pool slot

  # one split record per distinct (group, canonical position); endpoint snaps
  # attach to the existing node instead
  split_key <- character(0)
  split_sig <- character(0)
  split_cpos <- numeric(0)
  split_xy <- NULL
  split_first_pt <- integer(0)
  key_of_pt <- rep(NA_character_, n_pts)
  for (i in hit) {
    e <- snap$edge[i] + 1L
    u_of[i] <- edges$u[e]
    v_of[i] <- edges$v[e]
    p <- pool_pos[e]
    len <- elen[p]
    pos <- snap$pos[i]
    eps <- max(len * 1e-9, 1e-12)
    if (pos <= eps) {
      node_of[i] <- edges$u[e]
      next
    }
    if (pos >= len - eps) {
      node_of[i] <- edges$v[e]
      next
    }
    cpos <- if (canonical[p]) pos else len - pos
    key <- paste(sig[p], round(cpos, 7))
    key_of_pt[i] <- key
    if (!key %in% split_key) {
      split_key <- c(split_key, key)
      split_sig <- c(split_sig, sig[p])
      split_cpos <- c(split_cpos, cpos)
      split_xy <- rbind(split_xy, c(snap$x[i], snap$y[i]))
      split_first_pt <- c(split_first_pt, i)
    }
  }

  if (!length(split_key)) {
    out <- empty()
    out$map <- tibble::tibble(
      node = node_of, dist = as.numeric(snap$dist), u = u_of, v = v_of
    )
    return(out)
  }

  # fresh node ids above everything in sight
  base_id <- max(c(g$nodes$osmid, avoid_ids, 0), na.rm = TRUE)
  split_id <- base_id + seq_along(split_key)
  node_of[!is.na(key_of_pt)] <-
    split_id[match(key_of_pt[!is.na(key_of_pt)], split_key)]

  # split every pool edge whose geometry group received split points
  to_split <- which(sig %in% unique(split_sig))
  rep_rows <- integer(0)
  piece_u <- numeric(0)
  piece_v <- numeric(0)
  piece_geom <- list()
  piece_frac <- numeric(0)
  for (p in to_split) {
    in_grp <- split_sig == sig[p]
    pos_p <- if (canonical[p]) split_cpos[in_grp] else elen[p] - split_cpos[in_grp]
    ids_p <- split_id[in_grp]
    o <- order(pos_p)
    pos_p <- pos_p[o]
    ids_p <- ids_p[o]
    pieces <- split_line(cl[[p]], cum[[p]], pos_p)
    chain <- c(edges$u[pool[p]], ids_p, edges$v[pool[p]])
    k <- length(pieces)
    rep_rows <- c(rep_rows, rep(pool[p], k))
    piece_u <- c(piece_u, chain[-(k + 1)])
    piece_v <- c(piece_v, chain[-1])
    piece_geom <- c(piece_geom, pieces)
    bounds <- c(0, pos_p, elen[p])
    piece_frac <- c(piece_frac, diff(bounds) / elen[p])
  }

  new_edges <- edges[rep_rows, ]
  new_edges$u <- piece_u
  new_edges$v <- piece_v
  sf::st_geometry(new_edges) <- sf::st_sfc(
    lapply(piece_geom, sf::st_linestring), crs = sf::st_crs(g$nodes)
  )
  if ("length" %in% names(new_edges)) {
    new_edges$length <- as.numeric(sf::st_length(new_edges))
  }
  for (col in intersect(c("travel_time", "penalty"), names(new_edges))) {
    new_edges[[col]] <- new_edges[[col]] * piece_frac
  }
  edges_out <- rbind(edges[-pool[to_split], ], new_edges)

  new_nodes <- sf::st_sf(
    osmid = split_id,
    geometry = sf::st_sfc(
      lapply(seq_along(split_id), function(i) sf::st_point(split_xy[i, ])),
      crs = sf::st_crs(g$nodes)
    )
  )
  if (!is.null(node_attrs) && ncol(node_attrs)) {
    carried <- node_attrs[split_first_pt, setdiff(names(node_attrs), c("osmid", names(new_nodes))), drop = FALSE]
    for (nm in names(carried)) new_nodes[[nm]] <- carried[[nm]]
  }
  nodes_out <- bind_sf_rows(
    list(g$nodes, new_nodes), attr(g$nodes, "sf_column")
  )

  list(
    graph = new_osm_graph(nodes_out, edges_out, g$meta),
    map = tibble::tibble(
      node = node_of, dist = as.numeric(snap$dist), u = u_of, v = v_of
    )
  )
}

# Internal: cut a polyline (coordinate matrix `m`, cumulative planar lengths
# `cum`) at the strictly interior `positions` (sorted ascending). Returns one
# coordinate matrix per piece, with the cut points interpolated in.
split_line <- function(m, cum, positions) {
  total <- cum[length(cum)]
  tiny <- max(total * 1e-12, 1e-300)
  at <- function(p) {
    j <- max(which(cum <= p + tiny))
    j <- min(j, nrow(m) - 1)
    span <- cum[j + 1] - cum[j]
    t <- if (span > 0) (p - cum[j]) / span else 0
    m[j, ] * (1 - t) + m[j + 1, ] * t
  }
  bounds <- c(0, positions, total)
  lapply(seq_len(length(bounds) - 1), function(i) {
    inner <- which(cum > bounds[i] + tiny & cum < bounds[i + 1] - tiny)
    rbind(at(bounds[i]), m[inner, , drop = FALSE], at(bounds[i + 1]))
  })
}
