# Constrained shortest path

Finds the minimum-`weight` route from `from` to `to` whose total
consumption of a second edge column (`resource`) does not exceed
`budget` — e.g. "the shortest route using at most 500 m of residential
streets", with the residential metres counted by
[`ox_add_edge_penalties()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_penalties.md).
This is the classic constrained shortest path problem, solved exactly in
the Rust core (see
[`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md)
for the machinery and for the full cost-vs-resource trade-off curve).

## Usage

``` r
ox_route_constrained(g, from, to, weight = "length", resource, budget)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from, to:

  Node `osmid`s (as returned by
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md)).

- weight:

  Edge column used as routing cost. Default `"length"`.

- resource:

  Name of a nonnegative edge column holding the second criterion, e.g.
  the `"penalty"` column of
  [`ox_add_edge_penalties()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_penalties.md).

- budget:

  Maximum total resource the route may consume.

## Value

A one-row `sf` tibble: `cost`, `resource`, a list-column `path` of the
node `osmid`s traversed, and the route's merged street geometry. An
error is raised when no route fits the budget (the message reports the
minimum feasible resource).

## Examples

``` r
g <- example_osm_graph()
g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
g <- ox_add_edge_penalties(g, c(residential = 1))
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
# shortest route crossing at most 300 m of residential streets
ox_route_constrained(g, from, to, resource = "penalty", budget = 300)
#> Simple feature collection with 1 feature and 3 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 1 × 4
#>    cost resource path                                                   geometry
#> * <dbl>    <dbl> <list>                                         <LINESTRING [m]>
#> 1   600      300 <int [7]> (0 0, 100 0, 200 0, 200 100, 300 100, 300 200, 300 3…
```
