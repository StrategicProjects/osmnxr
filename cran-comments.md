## R CMD check results

0 errors | 0 warnings | 0 notes

Tested locally with `R CMD check --as-cran` on macOS (R 4.6.0).

## Notes for CRAN

* This is an update (0.1.1 -> 0.1.2). It adds one new exported function,
  `ox_union()`, which combines `osm_graph` objects (user request,
  https://github.com/StrategicProjects/osmnxr/issues/1). No API changes to
  existing functions.
* The package contains Rust code and requires Cargo/rustc at build time, as
  declared in `SystemRequirements`. Rust dependencies are vendored in
  `src/rust/vendor.tar.xz` so the package builds offline.
* Examples and tests that contact the OpenStreetMap Overpass/Nominatim services
  are wrapped in `@examplesIf interactive()` and `skip_on_cran()`; all
  CRAN-run examples and tests use bundled data (`ox_example()`,
  `example_osm_graph()`).

## Test environments

* local macOS, R 4.6.0 (`--as-cran`)
* GitHub Actions: macOS, Windows, Ubuntu (R release)
* win-builder (devel and release)
* R-hub v2 (linux, macos, windows)
