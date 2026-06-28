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
