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

#' Travelling-salesman route through a set of nodes
#'
#' Finds a short route through `nodes` over the street network, in the spirit
#' of `sfnetworks::st_network_travel()`. Network distances between all pairs of
#' stops are computed in the Rust core (one Dijkstra per stop, so one-way
#' streets are respected via the asymmetric cost matrix), the visiting order is
#' solved with an iterated local search, and each leg is expanded back into a
#' shortest path with its street geometry.
#'
#' The default solver builds a nearest-neighbour tour and polishes it with an
#' iterated local search: a descent over or-opt (segment relocation), swap and
#' 2-opt moves — every move evaluated exactly on the asymmetric cost matrix —
#' restarted from double-bridge perturbations, keeping the best tour found.
#' The search is deterministic (an internal fixed-seed RNG drives the
#' perturbations, leaving R's RNG untouched). It routinely finds the global
#' optimum for small stop counts, but optimality is not guaranteed (the TSP is
#' NP-hard). `method = "nn"` skips the improvement and keeps the raw
#' nearest-neighbour order.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param nodes Node `osmid`s to visit (at least 2, no duplicates), e.g. from
#'   [ox_nearest_nodes()].
#' @param weight Edge column used as weight. Default `"length"`; use
#'   `"travel_time"` after [ox_add_edge_travel_times()] for fastest routes.
#' @param start Index into `nodes` of the first stop. Default `1`.
#' @param end Index into `nodes` of the final stop. The default (`end = start`)
#'   gives a closed tour that returns to the start; `end = NULL` leaves the
#'   final stop free (an open route); any other index pins the route's end.
#' @param method `"ils"` (default, nearest-neighbour + iterated local search)
#'   or `"nn"` (nearest-neighbour only).
#'
#' @return An `sf` tibble with one row per leg of the route: `leg`, `from` and
#'   `to` (node `osmid`s), `cost` (network distance in `weight` units), a
#'   list-column `path` of the `osmid`s traversed, and the leg's `LINESTRING`
#'   geometry. The total route cost is `sum(out$cost)`.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' stops <- c(1, 4, 13, 16, 6)
#' route <- ox_route_tsp(g, stops)
#' route
#' sum(route$cost)
ox_route_tsp <- function(g, nodes, weight = "length",
                         start = 1, end = start,
                         method = c("ils", "nn")) {
  stopifnot(is_osm_graph(g))
  method <- match.arg(method)
  n <- length(nodes)
  if (n < 2) {
    cli::cli_abort("{.arg nodes} must contain at least 2 stops.", call = NULL)
  }
  if (anyDuplicated(nodes)) {
    cli::cli_abort("{.arg nodes} must not contain duplicated {.field osmid}s.", call = NULL)
  }
  if (length(start) != 1 || is.na(start) || !start %in% seq_len(n)) {
    cli::cli_abort("{.arg start} must be a single index into {.arg nodes}.", call = NULL)
  }
  if (!is.null(end) && (length(end) != 1 || is.na(end) || !end %in% seq_len(n))) {
    cli::cli_abort("{.arg end} must be a single index into {.arg nodes}, or {.code NULL} for an open route.", call = NULL)
  }
  closed <- !is.null(end) && end == start

  ea <- graph_edge_arrays(g, weight)
  s <- match(nodes, ea$node_ids) - 1L
  if (anyNA(s)) {
    cli::cli_abort("All {.arg nodes} must be node {.field osmid}s present in the graph.", call = NULL)
  }

  flat <- rs_distance_matrix(ea$from, ea$to, ea$weight, ea$n_nodes,
                             as.integer(s), as.integer(s))
  cost_m <- matrix(flat, nrow = n, ncol = n, byrow = TRUE)

  end0 <- if (is.null(end) || closed) -1L else as.integer(end - 1L)
  ord <- rs_tsp_tour(flat, as.integer(n), as.integer(start - 1L), end0,
                     closed, method == "ils") + 1L

  seq_idx <- if (closed) c(ord, ord[1]) else ord
  from_idx <- seq_idx[-length(seq_idx)]
  to_idx <- seq_idx[-1]
  costs <- cost_m[cbind(from_idx, to_idx)]
  if (any(!is.finite(costs))) {
    bad <- which(!is.finite(costs))[1]
    cli::cli_abort(
      "No route from node {.val {nodes[from_idx[bad]]}} to node {.val {nodes[to_idx[bad]]}}: the stops are not mutually reachable in this network.",
      call = NULL
    )
  }

  paths <- Map(function(a, b) {
    idx <- rs_shortest_path(ea$from, ea$to, ea$weight, ea$n_nodes,
                            as.integer(s[a]), as.integer(s[b]))
    ea$node_ids[idx + 1L]
  }, from_idx, to_idx)

  lut <- edge_geometry_lut(g, weight)
  geom <- sf::st_sfc(lapply(paths, path_leg_geometry, g = g, weight = weight, lut = lut),
                     crs = sf::st_crs(g$nodes))

  out <- tibble::tibble(
    leg = seq_along(paths),
    from = nodes[from_idx],
    to = nodes[to_idx],
    cost = as.numeric(costs),
    path = unname(paths),
    geometry = geom
  )
  sf::st_as_sf(out)
}

#' Pareto-optimal routes trading cost against a resource
#'
#' Enumerates the routes from `from` to `to` that are Pareto-optimal in two
#' criteria: the routing `weight` (cost) and a second nonnegative edge column
#' (`resource`), typically a road-type penalty from [ox_add_edge_penalties()].
#' Each returned route is cheaper than the next and uses more resource than
#' the next; no other route is better on both criteria. The front is computed
#' exactly in the Rust core by bicriteria label-setting (Martins' algorithm)
#' with dominance pruning and reverse-Dijkstra bounds.
#'
#' With a finite `budget` the front is restricted to routes whose total
#' resource is at most `budget`; its first row is then the exact solution of
#' the constrained shortest path problem (see [ox_route_constrained()]).
#'
#' The bicriteria problem is NP-hard in general — the front can be large on
#' pathological inputs — but on street networks with sparse penalties the
#' pruned search is fast. Use `max_routes` to cap the enumeration.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param from,to Node `osmid`s (as returned by [ox_nearest_nodes()]).
#' @param weight Edge column used as routing cost. Default `"length"`.
#' @param resource Name of a nonnegative edge column holding the second
#'   criterion, e.g. the `"penalty"` column of [ox_add_edge_penalties()].
#' @param budget Keep only routes with total resource at most `budget`.
#'   Default `Inf` (the unrestricted front).
#' @param max_routes Return at most this many routes (the cheapest ones).
#'   Default `Inf`.
#'
#' @return An `sf` tibble with one row per Pareto-optimal route, ordered by
#'   increasing cost (and decreasing resource): `route` (rank), `cost`,
#'   `resource`, a list-column `path` of the node `osmid`s traversed, and the
#'   route's merged street geometry.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' # north-south streets are calm residential, east-west ones primary
#' g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
#' g <- ox_add_edge_penalties(g, c(residential = 1))
#' from <- ox_nearest_nodes(g, 0, 0)
#' to <- ox_nearest_nodes(g, 300, 300)
#' ox_route_pareto(g, from, to, resource = "penalty")
ox_route_pareto <- function(g, from, to, weight = "length", resource,
                            budget = Inf, max_routes = Inf) {
  if (length(budget) != 1 || is.na(budget) || budget < 0) {
    cli::cli_abort("{.arg budget} must be a single nonnegative number (or {.code Inf}).", call = NULL)
  }
  if (length(max_routes) != 1 || is.na(max_routes) || max_routes < 1) {
    cli::cli_abort("{.arg max_routes} must be a single number >= 1 (or {.code Inf}).", call = NULL)
  }

  bi <- bi_route_inputs(g, from, to, weight, if (missing(resource)) NULL else resource)
  ea <- bi$ea
  s <- bi$s
  t <- bi$t

  cap <- if (is.infinite(max_routes)) -1L else as.integer(max_routes)
  res <- rs_pareto_paths(ea$from, ea$to, ea$weight, ea$resource, ea$n_nodes,
                         as.integer(s), as.integer(t), as.numeric(budget), cap)

  if (length(res$paths) == 0) {
    abort_no_bi_route(ea, from, to, s, t, budget, resource)
  }

  paths <- lapply(res$paths, function(idx) ea$node_ids[idx + 1L])
  lut <- edge_geometry_lut(g, weight)
  geom <- sf::st_sfc(lapply(paths, path_leg_geometry, g = g, weight = weight, lut = lut),
                     crs = sf::st_crs(g$nodes))
  out <- tibble::tibble(
    route = seq_along(paths),
    cost = as.numeric(res$costs),
    resource = as.numeric(res$resources),
    path = unname(paths),
    geometry = geom
  )
  sf::st_as_sf(out)
}

#' Constrained shortest path
#'
#' Finds the minimum-`weight` route from `from` to `to` whose total
#' consumption of a second edge column (`resource`) does not exceed `budget` —
#' e.g. "the shortest route using at most 500 m of residential streets", with
#' the residential metres counted by [ox_add_edge_penalties()]. This is the
#' classic constrained shortest path problem.
#'
#' Two solvers, both in the Rust core:
#' * `method = "exact"` (default) — bicriteria label-setting; always returns
#'   the true optimum (see [ox_route_pareto()] for the machinery and for the
#'   full cost-vs-resource trade-off curve).
#' * `method = "lagrangian"` — Lagrangian relaxation (the LARAC algorithm):
#'   the budget constraint is dualized, so each iteration is a plain Dijkstra
#'   on `weight + lambda * resource`, with a binary search driving `lambda`
#'   to the dual optimum. It scales to networks where the exact front grows
#'   too large, at the price of a possible *duality gap*: the route is always
#'   feasible, and `lower_bound` brackets how far from optimal it can be
#'   (`cost == lower_bound` proves optimality; a message reports any gap).
#'
#' @inheritParams ox_route_pareto
#' @param budget Maximum total resource the route may consume.
#' @param method `"exact"` (default) or `"lagrangian"`; see Details.
#'
#' @return A one-row `sf` tibble: `cost`, `resource`, `lower_bound` (a proven
#'   lower bound on the optimal cost; equals `cost` whenever optimality is
#'   certified, which is always the case for `method = "exact"`), a
#'   list-column `path` of the node `osmid`s traversed, and the route's merged
#'   street geometry. An error is raised when no route fits the budget (the
#'   message reports the minimum feasible resource).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
#' g <- ox_add_edge_penalties(g, c(residential = 1))
#' from <- ox_nearest_nodes(g, 0, 0)
#' to <- ox_nearest_nodes(g, 300, 300)
#' # shortest route crossing at most 300 m of residential streets
#' ox_route_constrained(g, from, to, resource = "penalty", budget = 300)
#' ox_route_constrained(g, from, to, resource = "penalty", budget = 300,
#'                      method = "lagrangian")
ox_route_constrained <- function(g, from, to, weight = "length", resource, budget,
                                 method = c("exact", "lagrangian")) {
  method <- match.arg(method)
  if (missing(budget)) {
    cli::cli_abort("{.arg budget} is required; use {.fn ox_shortest_path} for unconstrained routing.", call = NULL)
  }
  if (method == "exact") {
    out <- ox_route_pareto(g, from, to, weight = weight, resource = resource,
                           budget = budget, max_routes = 1)
    out$route <- NULL
    out$lower_bound <- out$cost
    return(out[c("cost", "resource", "lower_bound", "path", "geometry")])
  }

  if (length(budget) != 1 || is.na(budget) || budget < 0) {
    cli::cli_abort("{.arg budget} must be a single nonnegative number (or {.code Inf}).", call = NULL)
  }
  bi <- bi_route_inputs(g, from, to, weight, if (missing(resource)) NULL else resource)
  ea <- bi$ea
  res <- rs_csp_lagrangian(ea$from, ea$to, ea$weight, ea$resource, ea$n_nodes,
                           as.integer(bi$s), as.integer(bi$t),
                           as.numeric(budget), 50L)
  if (!isTRUE(res$found)) {
    abort_no_bi_route(ea, from, to, bi$s, bi$t, budget, resource)
  }
  gap <- res$cost - res$lower_bound
  if (gap > 1e-9 * (1 + abs(res$cost))) {
    cli::cli_inform(
      "Feasible route found; cost {.val {round(res$cost, 2)}} is within {.val {round(gap, 2)}} ({round(100 * gap / res$cost, 1)}%) of the proven lower bound. Use {.code method = \"exact\"} for a certified optimum."
    )
  }
  path <- ea$node_ids[res$path + 1L]
  geom <- sf::st_sfc(list(path_leg_geometry(path, g, weight)),
                     crs = sf::st_crs(g$nodes))
  out <- tibble::tibble(
    cost = as.numeric(res$cost),
    resource = as.numeric(res$resource),
    lower_bound = as.numeric(res$lower_bound),
    path = list(path),
    geometry = geom
  )
  sf::st_as_sf(out)
}

# Internal: shared input validation for the bicriteria routers. Returns the
# aligned edge arrays plus 0-based source/target indices.
bi_route_inputs <- function(g, from, to, weight, resource) {
  stopifnot(is_osm_graph(g))
  if (is.null(resource) || !is.character(resource) || length(resource) != 1) {
    cli::cli_abort("{.arg resource} must name a single edge column; see {.fn ox_add_edge_penalties}.", call = NULL)
  }
  if (!resource %in% names(g$edges)) {
    cli::cli_abort("Edge column {.field {resource}} not found in {.arg g}; create it with {.fn ox_add_edge_penalties}.", call = NULL)
  }
  ea <- graph_edge_arrays_bi(g, weight, resource)
  if (anyNA(ea$weight) || any(ea$weight < 0)) {
    cli::cli_abort("Edge column {.field {weight}} must be nonnegative with no missing values.", call = NULL)
  }
  if (anyNA(ea$resource) || any(ea$resource < 0) || any(is.infinite(ea$resource))) {
    cli::cli_abort("Edge column {.field {resource}} must be finite, nonnegative and have no missing values.", call = NULL)
  }
  s <- match(from, ea$node_ids) - 1L
  t <- match(to, ea$node_ids) - 1L
  if (length(s) != 1 || length(t) != 1 || is.na(s) || is.na(t)) {
    cli::cli_abort("{.arg from}/{.arg to} must be node {.field osmid}s present in the graph.", call = NULL)
  }
  list(ea = ea, s = s, t = t)
}

# Internal: the shared "no feasible route" error, distinguishing an
# unreachable target from a budget that is too tight.
abort_no_bi_route <- function(ea, from, to, s, t, budget, resource) {
  min_r <- rs_dijkstra(ea$from, ea$to, ea$resource, ea$n_nodes, as.integer(s))[t + 1L]
  if (is.infinite(min_r)) {
    cli::cli_abort("No route from node {.val {from}} to node {.val {to}} in this network.", call = NULL)
  }
  cli::cli_abort(
    "No route from node {.val {from}} to node {.val {to}} within {.arg budget} = {.val {budget}}: the minimum possible {.field {resource}} is {.val {min_r}}.",
    call = NULL
  )
}

# Internal: edge-row lookup by "u v" key, resolving parallel edges to the
# minimum-weight one (matching what Dijkstra traversed). Built once per call
# and shared across a route's legs: on metro-sized graphs this is the
# expensive part, not the routing.
edge_geometry_lut <- function(g, weight = "length") {
  key <- paste(g$edges$u, g$edges$v)
  w <- if (weight %in% names(g$edges)) as.numeric(g$edges[[weight]]) else rep(1, nrow(g$edges))
  o <- order(w)
  first <- o[!duplicated(key[o])]
  stats::setNames(first, key[first])
}

# Internal: merge the street geometries along a node-osmid path into a single
# (MULTI)LINESTRING sfg. `lut` comes from edge_geometry_lut(); pass it when
# building several legs/routes so it is computed once.
path_leg_geometry <- function(path, g, weight = "length", lut = NULL) {
  if (length(path) < 2) return(sf::st_linestring())
  if (is.null(lut)) lut <- edge_geometry_lut(g, weight)
  idx <- lut[paste(path[-length(path)], path[-1])]
  u <- sf::st_cast(sf::st_union(sf::st_geometry(g$edges)[idx]), "MULTILINESTRING")
  sf::st_line_merge(u)[[1]]
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
