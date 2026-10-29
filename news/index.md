# Changelog

## osmnxr 0.1.5

- The Overpass network filters now mirror OSMnx 2.1’s tag for tag,
  replacing the simplified highway-only regexes used so far. Downloads
  gain the negative filters (`area=yes`, `access=private`,
  `motor_vehicle=no`, `foot=no`, `bicycle=no`, service-road subtypes,
  ways tagged `rest_area`/`services`, and walk ways whose sidewalk is
  mapped as a separate way), and two network types join
  `drive`/`walk`/`bike`/`all`: `drive_service` (drivable including
  service roads) and `all_public`. Note two behaviour changes: `"drive"`
  no longer includes service roads (use `"drive_service"`), and `"all"`
  now means every in-use way including private access rather than
  literally every highway value.

- [`ox_simplify()`](https://strategicprojects.github.io/osmnxr/reference/ox_simplify.md)
  now preserves every edge attribute column (a merged edge takes its
  first segment’s value) instead of keeping only `highway` and `name`,
  and gained `edge_attr_aggs` (as in OSMnx 2): a named list of functions
  combining per-segment values along each merged chain, e.g.
  `list(travel_time = sum, speed_kph = mean)`. By default `travel_time`
  and `penalty` are summed when present, so pre-computed routing weights
  survive simplification instead of being dropped.

- [`ox_consolidate_intersections()`](https://strategicprojects.github.io/osmnxr/reference/ox_consolidate_intersections.md)
  accepts a per-node `tolerance` (one merge radius per node, as in OSMnx
  2: nodes merge when buffers of `tolerance/2` overlap), validates the
  tolerance, and now warns when asked to consolidate an
  already-consolidated graph — it proceeds, since re-clustering with a
  larger tolerance is well-defined here, but the double run is made
  visible.

- New
  [`ox_validate()`](https://strategicprojects.github.io/osmnxr/reference/ox_validate.md)
  checks that a graph meets the package’s structural expectations — `sf`
  types, complete and unique node ids, resolvable `u`/`v`, a usable
  `length`, one CRS, and edge geometries that actually run from their
  `u` node to their `v` node — reporting every problem found in one pass
  (OSMnx gained validation helpers in 2.1.0). Handy after building a
  layer by hand for
  [`ox_blend()`](https://strategicprojects.github.io/osmnxr/reference/ox_blend.md)/[`ox_union()`](https://strategicprojects.github.io/osmnxr/reference/ox_union.md).

- New
  [`ox_blend()`](https://strategicprojects.github.io/osmnxr/reference/ox_blend.md)
  blends point locations — or a whole second graph — into a street
  network ([\#6](https://github.com/StrategicProjects/osmnxr/issues/6),
  requested by [@talegari](https://github.com/talegari)), the `osmnxr`
  counterpart of
  [`sfnetworks::st_network_blend()`](https://luukvdmeer.github.io/sfnetworks/reference/st_network_blend.html):
  each point is snapped onto its nearest edge (grid-indexed planar
  search in the Rust core) and the edge is split there, in both
  directions of a two-way street, turning the location into a routable
  node. Attributes are preserved (`length` recomputed; `travel_time` /
  `penalty` rescaled proportionally), points beyond `tolerance` are
  skipped with a warning, and `meta$blend` maps every input to its node.
  Given a second `osm_graph`, the three-step recipe from the issue is
  applied: blend its nodes in, stack the graphs with
  [`ox_union()`](https://strategicprojects.github.io/osmnxr/reference/ox_union.md),
  and add connector edges between each snapped pair — one routable
  multimodal network.

- [`ox_blend()`](https://strategicprojects.github.io/osmnxr/reference/ox_blend.md)
  gained finer control from [@talegari](https://github.com/talegari)’s
  field test on the Delhi road + metro networks
  ([\#6](https://github.com/StrategicProjects/osmnxr/issues/6)):
  `meta$blend` now also records `u` / `v`, the endpoints of the edge
  each point snapped onto; `snap_nodes` flags which points (or `y`
  nodes) may snap (station gates yes, platforms no); `snap_edges` flags
  which edges of `g` may receive them (keep off limited-access
  flyovers); `connector_node_attrs` copies `y` node attributes — say, a
  per-station access time — onto the connector edges; and reusing a `g`
  osmid in `y` at different coordinates is now an error with a
  renumbering hint, instead of a silently corrupting first-wins merge.

- New
  [`ox_route_shortest()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_shortest.md)
  rounds out the `ox_route_*` family
  ([\#5](https://github.com/StrategicProjects/osmnxr/issues/5) feedback,
  [@talegari](https://github.com/talegari)): the `sf` interface to
  shortest-path routing, returning cost, node path and merged street
  geometry per route, with `k > 1` enumerating loopless alternatives
  (Yen) — one naming scheme and one return shape across
  [`ox_route_shortest()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_shortest.md),
  [`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md),
  [`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md)
  and
  [`ox_route_tsp()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_tsp.md).
  [`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md)
  and
  [`ox_k_shortest_paths()`](https://strategicprojects.github.io/osmnxr/reference/ox_k_shortest_paths.md)
  remain as the lighter node-sequence variants.

- Repeated routing calls on the same graph are much faster
  ([\#5](https://github.com/StrategicProjects/osmnxr/issues/5) feedback,
  [@talegari](https://github.com/talegari)): the structural edge index
  that every router marshals for the Rust core (the dominant per-call
  cost on metro-sized graphs) is now cached for the session,
  content-addressed by the graph’s node ids and edge endpoints — so
  copies hit, edits miss, and nothing goes stale. On the NCR Delhi
  network (2.1M directed edges) a warm
  [`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md)
  call drops from ~0.7 s to the Rust solve time itself.
  [`ox_clear_cache()`](https://strategicprojects.github.io/osmnxr/reference/ox_clear_cache.md)
  also clears this cache. The Dijkstra/Yen solvers additionally return
  the edges they traversed, so
  [`ox_route_shortest()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_shortest.md)
  and
  [`ox_route_tsp()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_tsp.md)
  draw exact geometry across parallel edges (previously
  [`ox_route_tsp()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_tsp.md)
  drew the minimum-weight twin).

- New preference-aware routing
  ([\#5](https://github.com/StrategicProjects/osmnxr/issues/5),
  requested by [@talegari](https://github.com/talegari)):
  [`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md)
  finds the exact minimum-cost route whose consumption of a second edge
  criterion stays within a budget (e.g. “the shortest route using at
  most 500 m of residential streets”), and
  [`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md)
  enumerates the full Pareto front of cost-vs-preference trade-offs.
  Both run on a bicriteria label-setting solver (Martins’ algorithm)
  with dominance pruning and reverse-Dijkstra bounds in the Rust core —
  exact, deterministic, one-way streets respected. The new helper
  [`ox_add_edge_penalties()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_penalties.md)
  builds the penalty/resource edge column from OSM `highway` classes;
  added onto the routing weight it also covers simple scalarized (“soft
  preference”) routing through
  [`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md).

- `ox_route_constrained(method = "lagrangian")` adds a
  Lagrangian-relaxation solver (the LARAC algorithm) beside the exact
  one: the budget constraint is dualized so each iteration is a plain
  Dijkstra on `weight + lambda * resource`, which scales to networks
  where the exact front grows too large. The route returned is always
  feasible and carries a proven `lower_bound` on the optimal cost
  (`cost == lower_bound` certifies optimality; a message reports any
  duality gap). The exact method now also reports `lower_bound`, always
  equal to `cost`
  ([\#5](https://github.com/StrategicProjects/osmnxr/issues/5)).

- Route geometry reconstruction is dramatically faster on large graphs.
  The bicriteria routers now receive the traversed edge indices straight
  from the Rust solvers, so no parallel-edge lookup is needed at all —
  and the geometry is exact even across parallel edges that differ in
  cost or resource (previously the minimum-weight twin was drawn). On
  the NCR Delhi drive network (1.0M nodes / 2.1M directed edges) an
  [`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md)
  query runs in ~0.7 s and a 9-route
  [`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md)
  front in ~1.5 s, down from ~16 s and ~140 s. For
  [`ox_route_tsp()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_tsp.md),
  the parallel-edge lookup is now built once per call instead of once
  per leg (and sorts numerically instead of by string key).

## osmnxr 0.1.4

- New
  [`ox_route_tsp()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_tsp.md)
  solves a travelling-salesman route through a set of stops over the
  street network, in the spirit of `sfnetworks::st_network_travel()`:
  the asymmetric network-distance matrix (one-way streets respected) is
  computed in the Rust core, the visiting order is solved there too with
  an iterated local search (or-opt + swap + 2-opt descent restarted from
  double-bridge perturbations, deterministic), and each leg is returned
  as an `sf` row with its cost, node path and street geometry. Supports
  closed tours (`end = start`, the default), open routes (`end = NULL`)
  and a pinned final stop. Benchmarked against `TSP::solve_TSP()` (the
  backend of `sfnetworks::st_network_travel()`) on identical cost
  matrices over the bundled real networks, it matched or beat it in all
  80 random instances tried (8–50 stops), by ~1% on average at 8 stops
  up to ~10% at 50
  ([\#4](https://github.com/StrategicProjects/osmnxr/issues/4),
  requested by [@talegari](https://github.com/talegari)).

## osmnxr 0.1.3

- `ox_graph_from_*()` is dramatically faster on large areas: building
  the graph from the Overpass response was quadratic in the number of
  edges (it never finished on a metro-sized bbox) and is now vectorised
  — a response with 600,000 nodes / 1 million directed edges parses in
  ~15 s ([\#3](https://github.com/StrategicProjects/osmnxr/issues/3),
  reported by [@talegari](https://github.com/talegari)).

- Overpass and Nominatim requests now retry on HTTP 500, 502 and 504
  (and on connection failures) in addition to httr2’s default 429/503,
  with exponential backoff. The number of attempts remains configurable
  via `ox_settings(max_tries = )`
  ([\#2](https://github.com/StrategicProjects/osmnxr/issues/2), reported
  by [@talegari](https://github.com/talegari)).

## osmnxr 0.1.2

CRAN release: 2026-10-19

- New
  [`ox_union()`](https://strategicprojects.github.io/osmnxr/reference/ox_union.md)
  combines two or more `osm_graph` objects into one: node and edge
  tables are stacked, nodes sharing an `osmid` are merged and edges
  duplicated across graphs are dropped (`dedupe_edges = FALSE` keeps
  them). Attribute columns present in one graph but not another are
  filled with `NA`. Designed for multimodal networks — union a street
  graph with a hand-built layer (e.g. metro) whose transfer edges
  reference street-node `osmid`s, then route across both
  ([\#1](https://github.com/StrategicProjects/osmnxr/issues/1),
  requested by [@talegari](https://github.com/talegari)).

## osmnxr 0.1.1

CRAN release: 2026-07-05

- Fix installation on Windows (R-devel). The rextendr 0.5.0 Makevars
  templates ran an unnecessary install-time `cargo run --bin document`
  step that failed on Windows (`os error 193` while running a build
  script). The extendr wrappers are pre-generated and shipped, so
  installation only needs `cargo build --lib`; the document step has
  been removed from `Makevars.in` / `Makevars.win.in`.

## osmnxr 0.1.0

First public release of *OSMnx for R*.

- [`ox_example()`](https://strategicprojects.github.io/osmnxr/reference/ox_example.md)
  loads a small bundled real network (central Olinda, Brazil) so
  examples and vignettes show real analyses offline. The vignettes were
  reworked around real cases from Boeing (2025) and the OSMnx examples
  gallery: multi-city orientation entropy (Chicago/New Orleans/Rome),
  betweenness chokepoints, travel-time routing and isochrones, and
  amenity accessibility.

- [`ox_orientation_entropy()`](https://strategicprojects.github.io/osmnxr/reference/ox_orientation_entropy.md)
  and
  [`ox_plot_orientation()`](https://strategicprojects.github.io/osmnxr/reference/ox_plot_orientation.md)
  now accept either an `osm_graph` or a numeric vector of bearings.

- [`ox_plot_figure_ground()`](https://strategicprojects.github.io/osmnxr/reference/ox_plot_figure_ground.md)
  draws figure-ground diagrams, and
  [`ox_example()`](https://strategicprojects.github.io/osmnxr/reference/ox_example.md)
  now also bundles `"manhattan"` and `"rome"` networks for the new
  “Figure-ground diagrams” vignette (Boeing 2025, Fig. 3).

- [`ox_simplify()`](https://strategicprojects.github.io/osmnxr/reference/ox_simplify.md)
  now preserves traversability per direction, emitting bidirectional
  edges for two-way streets (fixes zero-valued routing/centrality on
  simplified graphs).

- Download street networks from OpenStreetMap
  ([`ox_graph_from_place()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_place.md),
  [`ox_graph_from_address()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_address.md),
  [`ox_graph_from_point()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_point.md),
  [`ox_graph_from_bbox()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_bbox.md))
  via the Overpass API, returning the tidy `sf`-backed `osm_graph`
  object.

- Geocoding with Nominatim
  ([`ox_geocode()`](https://strategicprojects.github.io/osmnxr/reference/ox_geocode.md),
  [`ox_geocode_to_sf()`](https://strategicprojects.github.io/osmnxr/reference/ox_geocode_to_sf.md)).

- Rust compute core (via extendr): CSR graph, Dijkstra routing
  ([`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md),
  [`ox_distances()`](https://strategicprojects.github.io/osmnxr/reference/ox_distances.md),
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md))
  and metrics
  ([`ox_basic_stats()`](https://strategicprojects.github.io/osmnxr/reference/ox_basic_stats.md),
  [`ox_bearings()`](https://strategicprojects.github.io/osmnxr/reference/ox_bearings.md),
  [`ox_orientation_entropy()`](https://strategicprojects.github.io/osmnxr/reference/ox_orientation_entropy.md)).

- [`example_osm_graph()`](https://strategicprojects.github.io/osmnxr/reference/example_osm_graph.md)
  synthetic grid for offline examples and tests.

- Configuration via
  [`ox_settings()`](https://strategicprojects.github.io/osmnxr/reference/ox_settings.md)
  and session caching with
  [`ox_clear_cache()`](https://strategicprojects.github.io/osmnxr/reference/ox_clear_cache.md).

- Topology cleanup (Rust core):
  [`ox_simplify()`](https://strategicprojects.github.io/osmnxr/reference/ox_simplify.md)
  merges chains of interstitial degree-2 nodes into single edges;
  [`ox_consolidate_intersections()`](https://strategicprojects.github.io/osmnxr/reference/ox_consolidate_intersections.md)
  merges nearby nodes into one (via connected components);
  [`ox_nearest_edges()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_edges.md)
  finds the closest edge to a point.

- Advanced routing (Rust core):
  [`ox_k_shortest_paths()`](https://strategicprojects.github.io/osmnxr/reference/ox_k_shortest_paths.md)
  (Yen’s algorithm),
  [`ox_distance_matrix()`](https://strategicprojects.github.io/osmnxr/reference/ox_distance_matrix.md)
  (many-to-many), and
  [`ox_isochrone()`](https://strategicprojects.github.io/osmnxr/reference/ox_isochrone.md)
  (reachable-area polygons via multi-source Dijkstra + concave hull).

- Travel-time routing:
  [`ox_add_edge_speeds()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_speeds.md)
  and
  [`ox_add_edge_travel_times()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_travel_times.md)
  add `speed_kph` / `travel_time` edge columns for time-weighted
  shortest paths and isochrones.

- New vignette: “Routing and isochrones”.

- Network metrics (Rust core):
  [`ox_centrality()`](https://strategicprojects.github.io/osmnxr/reference/ox_centrality.md)
  (betweenness via Brandes’ algorithm, closeness) and
  [`ox_circuity()`](https://strategicprojects.github.io/osmnxr/reference/ox_circuity.md)
  (street straightness). Circuity is now also reported by
  [`ox_basic_stats()`](https://strategicprojects.github.io/osmnxr/reference/ox_basic_stats.md).

- Interoperability:
  [`ox_as_sfnetwork()`](https://strategicprojects.github.io/osmnxr/reference/ox_as_sfnetwork.md),
  [`ox_as_tidygraph()`](https://strategicprojects.github.io/osmnxr/reference/ox_as_tidygraph.md)
  and
  [`ox_as_dodgr()`](https://strategicprojects.github.io/osmnxr/reference/ox_as_dodgr.md)
  hand the graph to the wider R network ecosystem.

- Export and persistence:
  [`ox_to_geojson()`](https://strategicprojects.github.io/osmnxr/reference/ox_to_geojson.md),
  [`ox_to_maplibre()`](https://strategicprojects.github.io/osmnxr/reference/ox_to_maplibre.md)
  (style fragment), and
  [`ox_save_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_save_graphml.md)
  /
  [`ox_load_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_load_graphml.md)
  for a lossless round-trip (edge geometry stored as WKT), compatible
  with OSMnx / NetworkX / Gephi.

- Feature downloads:
  [`ox_features_from_place()`](https://strategicprojects.github.io/osmnxr/reference/ox_features_from_place.md)
  and
  [`ox_features_from_bbox()`](https://strategicprojects.github.io/osmnxr/reference/ox_features_from_bbox.md)
  fetch POIs, buildings and amenities from OpenStreetMap as tidy `sf`
  points.

- [`ox_plot_orientation()`](https://strategicprojects.github.io/osmnxr/reference/ox_plot_orientation.md)
  draws a polar rose plot of street bearings (ggplot2).

- Documentation: vignettes “Urban metrics”, “Street orientation”,
  “Features and points of interest”, “Interoperability and export” and
  “Accessibility analysis”; full pkgdown reference and articles menu.
