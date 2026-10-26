# Changelog

## osmnxr 0.1.5

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
