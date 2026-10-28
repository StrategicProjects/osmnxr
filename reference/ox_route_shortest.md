# Shortest route(s) between two nodes, with geometry

The `sf` routing interface, uniform with the rest of the `ox_route_*`
family: computes the minimum-`weight` route from `from` to `to`
(Dijkstra, in the Rust core) and returns it with its cost and merged
street geometry. With `k > 1` it returns up to `k` loopless route
alternatives (Yen's algorithm), one per row, ordered by increasing cost.

## Usage

``` r
ox_route_shortest(g, from, to, weight = "length", k = 1)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from, to:

  Node `osmid`s (as returned by
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md)).

- weight:

  Edge column used as weight. Default `"length"`; use `"travel_time"`
  after
  [`ox_add_edge_travel_times()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_travel_times.md)
  for fastest routes.

- k:

  Number of route alternatives to return. Default `1` (the shortest
  route); larger values enumerate loopless alternatives by increasing
  cost (fewer than `k` rows are returned when fewer distinct routes
  exist).

## Value

An `sf` tibble with one row per route: `route` (rank), `cost`, a
list-column `path` of the node `osmid`s traversed, and the route's
merged street geometry. An error is raised when `to` is unreachable from
`from`.

## Details

The geometry is built from the edges the solver actually traversed, so
it is exact across parallel edges.
[`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md)
and
[`ox_k_shortest_paths()`](https://strategicprojects.github.io/osmnxr/reference/ox_k_shortest_paths.md)
remain as the lighter variants returning only node sequences.

## Examples

``` r
g <- example_osm_graph()
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
ox_route_shortest(g, from, to)
#> Simple feature collection with 1 feature and 3 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 1 × 4
#>   route  cost path                                                   geometry
#>   <int> <dbl> <list>                                         <LINESTRING [m]>
#> 1     1   600 <int [7]> (0 0, 100 0, 200 0, 300 0, 300 100, 300 200, 300 300)
ox_route_shortest(g, from, to, k = 3)
#> Simple feature collection with 3 features and 3 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 3 × 4
#>   route  cost path                                                      geometry
#>   <int> <dbl> <list>                                            <LINESTRING [m]>
#> 1     1   600 <int [7]>    (0 0, 100 0, 200 0, 300 0, 300 100, 300 200, 300 300)
#> 2     2   600 <int [7]> (0 0, 0 100, 100 100, 100 200, 100 300, 200 300, 300 30…
#> 3     3   600 <int [7]> (0 0, 100 0, 100 100, 100 200, 100 300, 200 300, 300 30…
```
