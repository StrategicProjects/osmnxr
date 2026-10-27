# Constrained shortest path

Finds the minimum-`weight` route from `from` to `to` whose total
consumption of a second edge column (`resource`) does not exceed
`budget` — e.g. "the shortest route using at most 500 m of residential
streets", with the residential metres counted by
[`ox_add_edge_penalties()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_penalties.md).
This is the classic constrained shortest path problem.

## Usage

``` r
ox_route_constrained(
  g,
  from,
  to,
  weight = "length",
  resource,
  budget,
  method = c("exact", "lagrangian")
)
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

- method:

  `"exact"` (default) or `"lagrangian"`; see Details.

## Value

A one-row `sf` tibble: `cost`, `resource`, `lower_bound` (a proven lower
bound on the optimal cost; equals `cost` whenever optimality is
certified, which is always the case for `method = "exact"`), a
list-column `path` of the node `osmid`s traversed, and the route's
merged street geometry. An error is raised when no route fits the budget
(the message reports the minimum feasible resource).

## Details

Two solvers, both in the Rust core:

- `method = "exact"` (default) — bicriteria label-setting; always
  returns the true optimum (see
  [`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md)
  for the machinery and for the full cost-vs-resource trade-off curve).

- `method = "lagrangian"` — Lagrangian relaxation (the LARAC algorithm):
  the budget constraint is dualized, so each iteration is a plain
  Dijkstra on `weight + lambda * resource`, with a binary search driving
  `lambda` to the dual optimum. It scales to networks where the exact
  front grows too large, at the price of a possible *duality gap*: the
  route is always feasible, and `lower_bound` brackets how far from
  optimal it can be (`cost == lower_bound` proves optimality; a message
  reports any gap).

## Examples

``` r
g <- example_osm_graph()
g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
g <- ox_add_edge_penalties(g, c(residential = 1))
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
# shortest route crossing at most 300 m of residential streets
ox_route_constrained(g, from, to, resource = "penalty", budget = 300)
#> Simple feature collection with 1 feature and 4 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 1 × 5
#>    cost resource lower_bound path                                       geometry
#>   <dbl>    <dbl>       <dbl> <list>                             <LINESTRING [m]>
#> 1   600      300         600 <int [7]> (0 0, 100 0, 200 0, 200 100, 300 100, 30…
ox_route_constrained(g, from, to, resource = "penalty", budget = 300,
                     method = "lagrangian")
#> Simple feature collection with 1 feature and 4 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 1 × 5
#>    cost resource lower_bound path                                       geometry
#>   <dbl>    <dbl>       <dbl> <list>                             <LINESTRING [m]>
#> 1   600      300         600 <int [7]> (0 0, 100 0, 200 0, 300 0, 300 100, 300 …
```
