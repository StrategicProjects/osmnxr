# osmnxr 0.1.5

* New preference-aware routing (#5, requested by @talegari):
  `ox_route_constrained()` finds the exact minimum-cost route whose
  consumption of a second edge criterion stays within a budget (e.g. "the
  shortest route using at most 500 m of residential streets"), and
  `ox_route_pareto()` enumerates the full Pareto front of cost-vs-preference
  trade-offs. Both run on a bicriteria label-setting solver (Martins'
  algorithm) with dominance pruning and reverse-Dijkstra bounds in the Rust
  core — exact, deterministic, one-way streets respected. The new helper
  `ox_add_edge_penalties()` builds the penalty/resource edge column from OSM
  `highway` classes; added onto the routing weight it also covers simple
  scalarized ("soft preference") routing through `ox_shortest_path()`.

* `ox_route_constrained(method = "lagrangian")` adds a Lagrangian-relaxation
  solver (the LARAC algorithm) beside the exact one: the budget constraint
  is dualized so each iteration is a plain Dijkstra on
  `weight + lambda * resource`, which scales to networks where the exact
  front grows too large. The route returned is always feasible and carries a
  proven `lower_bound` on the optimal cost (`cost == lower_bound` certifies
  optimality; a message reports any duality gap). The exact method now also
  reports `lower_bound`, always equal to `cost` (#5).

* Rebuilding route geometries is dramatically faster on large graphs: the
  parallel-edge lookup is now computed once per call instead of once per
  route/leg (and sorts numerically instead of by string key). On the NCR
  Delhi drive network (1.0M nodes / 2.1M directed edges) this takes
  `ox_route_constrained()` from ~16 s to ~3.5 s per query and a 9-route
  `ox_route_pareto()` front from ~140 s to ~6.5 s; the Rust solvers
  themselves answer in under a second even at that scale. `ox_route_tsp()`
  legs benefit equally.

# osmnxr 0.1.4

* New `ox_route_tsp()` solves a travelling-salesman route through a set of
  stops over the street network, in the spirit of
  `sfnetworks::st_network_travel()`: the asymmetric network-distance matrix
  (one-way streets respected) is computed in the Rust core, the visiting order
  is solved there too with an iterated local search (or-opt + swap + 2-opt
  descent restarted from double-bridge perturbations, deterministic), and each
  leg is returned as an `sf` row with its cost, node path and street geometry.
  Supports closed tours (`end = start`, the default), open routes (`end =
  NULL`) and a pinned final stop. Benchmarked against `TSP::solve_TSP()` (the
  backend of `sfnetworks::st_network_travel()`) on identical cost matrices
  over the bundled real networks, it matched or beat it in all 80 random
  instances tried (8–50 stops), by ~1% on average at 8 stops up to ~10% at 50
  (#4, requested by @talegari).

# osmnxr 0.1.3

* `ox_graph_from_*()` is dramatically faster on large areas: building the graph
  from the Overpass response was quadratic in the number of edges (it never
  finished on a metro-sized bbox) and is now vectorised — a response with
  600,000 nodes / 1 million directed edges parses in ~15 s (#3, reported by
  @talegari).

* Overpass and Nominatim requests now retry on HTTP 500, 502 and 504 (and on
  connection failures) in addition to httr2's default 429/503, with exponential
  backoff. The number of attempts remains configurable via
  `ox_settings(max_tries = )` (#2, reported by @talegari).

# osmnxr 0.1.2

* New `ox_union()` combines two or more `osm_graph` objects into one: node and
  edge tables are stacked, nodes sharing an `osmid` are merged and edges
  duplicated across graphs are dropped (`dedupe_edges = FALSE` keeps them).
  Attribute columns present in one graph but not another are filled with `NA`.
  Designed for multimodal networks — union a street graph with a hand-built
  layer (e.g. metro) whose transfer edges reference street-node `osmid`s, then
  route across both (#1, requested by @talegari).

# osmnxr 0.1.1

* Fix installation on Windows (R-devel). The rextendr 0.5.0 Makevars templates
  ran an unnecessary install-time `cargo run --bin document` step that failed on
  Windows (`os error 193` while running a build script). The extendr wrappers
  are pre-generated and shipped, so installation only needs `cargo build --lib`;
  the document step has been removed from `Makevars.in` / `Makevars.win.in`.

# osmnxr 0.1.0

First public release of *OSMnx for R*.

* `ox_example()` loads a small bundled real network (central Olinda, Brazil) so
  examples and vignettes show real analyses offline. The vignettes were
  reworked around real cases from Boeing (2025) and the OSMnx examples gallery:
  multi-city orientation entropy (Chicago/New Orleans/Rome), betweenness
  chokepoints, travel-time routing and isochrones, and amenity accessibility.
* `ox_orientation_entropy()` and `ox_plot_orientation()` now accept either an
  `osm_graph` or a numeric vector of bearings.
* `ox_plot_figure_ground()` draws figure-ground diagrams, and `ox_example()`
  now also bundles `"manhattan"` and `"rome"` networks for the new
  "Figure-ground diagrams" vignette (Boeing 2025, Fig. 3).
* `ox_simplify()` now preserves traversability per direction, emitting
  bidirectional edges for two-way streets (fixes zero-valued routing/centrality
  on simplified graphs).

* Download street networks from OpenStreetMap (`ox_graph_from_place()`,
  `ox_graph_from_address()`, `ox_graph_from_point()`, `ox_graph_from_bbox()`)
  via the Overpass API, returning the tidy `sf`-backed `osm_graph` object.
* Geocoding with Nominatim (`ox_geocode()`, `ox_geocode_to_sf()`).
* Rust compute core (via extendr): CSR graph, Dijkstra routing
  (`ox_shortest_path()`, `ox_distances()`, `ox_nearest_nodes()`) and metrics
  (`ox_basic_stats()`, `ox_bearings()`, `ox_orientation_entropy()`).
* `example_osm_graph()` synthetic grid for offline examples and tests.
* Configuration via `ox_settings()` and session caching with `ox_clear_cache()`.
* Topology cleanup (Rust core): `ox_simplify()` merges chains of interstitial
  degree-2 nodes into single edges; `ox_consolidate_intersections()` merges
  nearby nodes into one (via connected components); `ox_nearest_edges()` finds
  the closest edge to a point.
* Advanced routing (Rust core): `ox_k_shortest_paths()` (Yen's algorithm),
  `ox_distance_matrix()` (many-to-many), and `ox_isochrone()` (reachable-area
  polygons via multi-source Dijkstra + concave hull).
* Travel-time routing: `ox_add_edge_speeds()` and `ox_add_edge_travel_times()`
  add `speed_kph` / `travel_time` edge columns for time-weighted shortest
  paths and isochrones.
* New vignette: "Routing and isochrones".
* Network metrics (Rust core): `ox_centrality()` (betweenness via Brandes'
  algorithm, closeness) and `ox_circuity()` (street straightness). Circuity is
  now also reported by `ox_basic_stats()`.
* Interoperability: `ox_as_sfnetwork()`, `ox_as_tidygraph()` and
  `ox_as_dodgr()` hand the graph to the wider R network ecosystem.
* Export and persistence: `ox_to_geojson()`, `ox_to_maplibre()` (style
  fragment), and `ox_save_graphml()` / `ox_load_graphml()` for a lossless
  round-trip (edge geometry stored as WKT), compatible with OSMnx / NetworkX /
  Gephi.
* Feature downloads: `ox_features_from_place()` and `ox_features_from_bbox()`
  fetch POIs, buildings and amenities from OpenStreetMap as tidy `sf` points.
* `ox_plot_orientation()` draws a polar rose plot of street bearings (ggplot2).
* Documentation: vignettes "Urban metrics", "Street orientation", "Features and
  points of interest", "Interoperability and export" and "Accessibility
  analysis"; full pkgdown reference and articles menu.
