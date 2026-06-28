# Changelog

## osmnxr 0.0.0.9000 (development)

First development version. Initial scaffold of *OSMnx for R*.

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
