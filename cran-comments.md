## R CMD check results

0 errors | 0 warnings | 0 notes

Tested locally with `R CMD check --as-cran` on macOS (R 4.6.0). The only
local message is "Skipping checking HTML validation", from the HTML Tidy
installed on this machine, not from the package.

## Notes for CRAN

* This is an update (0.1.2 -> 0.1.6; versions 0.1.3 to 0.1.5 were not
  submitted). It adds routing functions (`ox_route_shortest()`,
  `ox_route_tsp()`, `ox_route_pareto()`, `ox_route_constrained()`),
  `ox_blend()`, `ox_validate()`, and a parity pass against OSMnx 2.0/2.1
  (Overpass network filters, edge-attribute aggregation in `ox_simplify()`);
  see NEWS.md. Two documented behaviour changes: `network_type = "drive"` no
  longer includes service roads (use `"drive_service"`), as in OSMnx.
* Title and Description changed to state plainly that the package is an R
  port of the 'OSMnx' Python library by Geoff Boeing (Boeing, 2025,
  <doi:10.1111/gean.70009>): earlier releases said "inspired by", which
  understated it. The OSMnx MIT copyright notice now ships in
  `inst/COPYRIGHTS` (referenced by the new `Copyright` field), and
  `inst/CITATION` gives the OSMnx paper first. Authors and maintainer are
  unchanged.
* The Rust compute core is now the crate 'osmnxr-core' (same authors, MIT),
  pinned exactly and vendored with the other Rust dependencies in
  `src/rust/vendor.tar.xz`, so the package builds offline. Cargo/rustc
  are required at build time, as declared in `SystemRequirements`.
* Examples and tests that contact the OpenStreetMap Overpass/Nominatim services
  are wrapped in `@examplesIf interactive()` and `skip_on_cran()`; all
  CRAN-run examples and tests use bundled data (`ox_example()`,
  `example_osm_graph()`).

## Test environments

* local macOS, R 4.6.0 (`--as-cran`)
* GitHub Actions: macOS, Windows, Ubuntu (R release)
* win-builder (devel and release)
* R-hub v2 (linux, macos, windows)
