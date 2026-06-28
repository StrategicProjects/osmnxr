# Compute isochrones (service areas)

For one or more origin nodes, finds the set of nodes reachable within
each `cutoff` (by the chosen edge `weight` — distance or, with
[`ox_add_edge_travel_times()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_travel_times.md),
travel time) and returns a polygon per cutoff: the hull of the reachable
nodes. With several origins, reachability is the minimum cost from any
origin.

## Usage

``` r
ox_isochrone(g, center, cutoffs, weight = "length", ratio = 0.4)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- center:

  One or more origin node `osmid`s (see
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md)).

- cutoffs:

  Numeric vector of cutoff values, in the units of `weight`.

- weight:

  Edge column used as cost. Default `"length"`.

- ratio:

  Concavity for
  [`sf::st_concave_hull()`](https://r-spatial.github.io/sf/reference/geos_unary.html)
  (0 = most concave, 1 = convex). Default `0.4`.

## Value

An `sf` object with one polygon row per cutoff (columns `cutoff`,
`n_nodes`, `geometry`), ordered from largest to smallest cutoff so
smaller areas draw on top.

## Details

Reachable sets come from the Rust Dijkstra core; the hull is built with
[`sf::st_concave_hull()`](https://r-spatial.github.io/sf/reference/geos_unary.html)
when available (GEOS \>= 3.11), falling back to a convex hull. For
metric cutoffs, project the graph to a metric CRS first.

## Examples

``` r
g <- example_osm_graph(n = 6, spacing = 100)
center <- ox_nearest_nodes(g, 250, 250)
iso <- ox_isochrone(g, center, cutoffs = c(100, 300))
iso
#> Simple feature collection with 2 features and 2 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 500 ymax: 500
#> Projected CRS: WGS 84 / Pseudo-Mercator
#>   cutoff n_nodes                       geometry
#> 1    300      23 POLYGON ((0 200, 0 300, 100...
#> 2    100       5 POLYGON ((200 200, 100 200,...
```
