# osmnxr <img src="man/figures/logo.svg" align="right" height="139" alt="osmnxr logo" />

<!-- badges: start -->
![CRAN status](https://www.r-pkg.org/badges/version/osmnxr)
![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/osmnxr)
![License: MIT](https://img.shields.io/badge/license-MIT-darkviolet.svg)
![devel version](https://img.shields.io/badge/devel%20version-0.1.6-blue.svg)
[![R-CMD-check](https://github.com/StrategicProjects/osmnxr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/StrategicProjects/osmnxr/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/StrategicProjects/osmnxr/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/StrategicProjects/osmnxr/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**osmnxr** is *OSMnx for R*: a tidyverse-friendly toolkit, inspired by the
[OSMnx](https://osmnx.readthedocs.io/) Python library, to **download, model,
simplify, analyze and visualize** street networks and other geospatial features
from [OpenStreetMap](https://www.openstreetmap.org/).

It is a **reimplementation** — not a Python wrapper. Heavy graph computation
(routing, simplification, metrics) runs in the bundled **Rust** crate
[osmnxr-core](https://strategicprojects.github.io/osmnxr-core/) via
[extendr](https://extendr.rs/), so there is no Python runtime to manage.
Everything you get back is tidy [`sf`](https://r-spatial.github.io/sf/).

## Installation

Install the released version from CRAN (macOS and Windows binaries need no
Rust; building from source needs the **Rust toolchain**,
[rustup](https://rustup.rs/), version 1.81 or later — the crates it depends on
come with the package, nothing is downloaded):

``` r
install.packages("osmnxr")
```

Or the development version from GitHub (always builds from source):

``` r
# install.packages("remotes")
remotes::install_github("StrategicProjects/osmnxr")
```

## Quick start

``` r
library(osmnxr)

# Download a drivable street network for a place
g <- ox_graph_from_place("Olinda, Brazil", network_type = "drive")
g
plot(g)

# Route between two points (Rust Dijkstra)
from <- ox_nearest_nodes(g, x = -34.85, y = -8.01)
to   <- ox_nearest_nodes(g, x = -34.84, y = -8.00)
ox_shortest_path(g, from, to)

# Urban metrics
ox_basic_stats(g)
ox_orientation_entropy(g)   # street-grid order/disorder
```

No network access? Explore the whole API offline with a synthetic grid:

``` r
g <- example_osm_graph()
ox_basic_stats(g)
ox_shortest_path(g, ox_nearest_nodes(g, 0, 0), ox_nearest_nodes(g, 300, 300))
```

## How it works

`osmnxr` is split into a tidy R API over a Rust compute core:

<img src="man/figures/architecture.svg" alt="osmnxr architecture" width="100%" />

The pipeline, from a place name to an analyzable network:

<img src="man/figures/data-flow.svg" alt="osmnxr data flow" width="100%" />

## Related work

`osmnxr` complements the R geospatial stack — it can hand graphs to
[`sfnetworks`](https://luukvdmeer.github.io/sfnetworks/),
[`tidygraph`](https://tidygraph.data-imaginist.com/) and
[`dodgr`](https://urbananalyst.github.io/dodgr/), and downloads via the same
Overpass API used by [`osmdata`](https://docs.ropensci.org/osmdata/).

## Acknowledgements

`osmnxr` owes its design to [Geoff Boeing](https://geoffboeing.com/)'s
[OSMnx](https://osmnx.readthedocs.io/) (Boeing, G. 2025. "Modeling and
Analyzing Urban Networks and Amenities with OSMnx." *Geographical Analysis*,
57(4): 567–577. doi:[10.1111/gean.70009](https://doi.org/10.1111/gean.70009)).
It follows OSMnx's API and modelling choices; the code is a reimplementation
and shares nothing with it. Its data come from the
[OpenStreetMap](https://www.openstreetmap.org/) contributors and the public
[Overpass](https://overpass-api.de/) and
[Nominatim](https://nominatim.openstreetmap.org/) services.

Thanks to everyone who files issues — user reports shape this package.
[Srikanth Komala Sheshachala (\@talegari)](https://github.com/talegari)
proposed `ox_union()` for multimodal routing (#1), `ox_route_tsp()` for
travelling-salesman routes (#4), constrained / Pareto-optimal routing with
road preferences (#5) and `ox_blend()` for snapping points and whole graphs
into a network (#6); his careful reports with reproducible benchmarks also
led to automatic retries on transient Overpass failures (#2), a ~250× faster
graph-building phase on metro-sized extracts (#3), and the session edge-index
cache plus the `ox_route_shortest()` interface (#5 feedback).

## License

MIT © André Leite and contributors / StrategicProjects.
