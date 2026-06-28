## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes for CRAN

* This package contains Rust code and requires Cargo/rustc at build time, as
  declared in `SystemRequirements`. Rust dependencies are vendored in
  `src/rust/vendor.tar.xz` so the package builds offline.
* Examples and tests that contact the OpenStreetMap Overpass/Nominatim services
  are wrapped in `@examplesIf interactive()` and `skip_on_cran()`; all
  CRAN-run examples and tests use the offline `example_osm_graph()`.

## Test environments

* local macOS, R release
* GitHub Actions: macOS, Windows, Ubuntu (R release)
