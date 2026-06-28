# osmnxr 0.0.0.9000 (development)

First development version. Initial scaffold of *OSMnx for R*.

* Download street networks from OpenStreetMap (`ox_graph_from_place()`,
  `ox_graph_from_address()`, `ox_graph_from_point()`, `ox_graph_from_bbox()`)
  via the Overpass API, returning the tidy `sf`-backed `osm_graph` object.
* Geocoding with Nominatim (`ox_geocode()`, `ox_geocode_to_sf()`).
* Rust compute core (via extendr): CSR graph, Dijkstra routing
  (`ox_shortest_path()`, `ox_distances()`, `ox_nearest_nodes()`) and metrics
  (`ox_basic_stats()`, `ox_bearings()`, `ox_orientation_entropy()`).
* `example_osm_graph()` synthetic grid for offline examples and tests.
* Configuration via `ox_settings()` and session caching with `ox_clear_cache()`.
