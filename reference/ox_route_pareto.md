# Pareto-optimal routes trading cost against a resource

Enumerates the routes from `from` to `to` that are Pareto-optimal in two
criteria: the routing `weight` (cost) and a second nonnegative edge
column (`resource`), typically a road-type penalty from
[`ox_add_edge_penalties()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_penalties.md).
Each returned route is cheaper than the next and uses more resource than
the next; no other route is better on both criteria. The front is
computed exactly in the Rust core by bicriteria label-setting (Martins'
algorithm) with dominance pruning and reverse-Dijkstra bounds.

## Usage

``` r
ox_route_pareto(
  g,
  from,
  to,
  weight = "length",
  resource,
  budget = Inf,
  max_routes = Inf
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

  Keep only routes with total resource at most `budget`. Default `Inf`
  (the unrestricted front).

- max_routes:

  Return at most this many routes (the cheapest ones). Default `Inf`.

## Value

An `sf` tibble with one row per Pareto-optimal route, ordered by
increasing cost (and decreasing resource): `route` (rank), `cost`,
`resource`, a list-column `path` of the node `osmid`s traversed, and the
route's merged street geometry.

## Details

With a finite `budget` the front is restricted to routes whose total
resource is at most `budget`; its first row is then the exact solution
of the constrained shortest path problem (see
[`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md)).

The bicriteria problem is NP-hard in general — the front can be large on
pathological inputs — but on street networks with sparse penalties the
pruned search is fast. Use `max_routes` to cap the enumeration.

## Examples

``` r
g <- example_osm_graph()
# north-south streets are calm residential, east-west ones primary
g$edges$highway <- ifelse(abs(g$edges$u - g$edges$v) == 1, "residential", "primary")
g <- ox_add_edge_penalties(g, c(residential = 1))
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
ox_route_pareto(g, from, to, resource = "penalty")
#> Simple feature collection with 1 feature and 4 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 1 × 5
#>   route  cost resource path                                             geometry
#>   <int> <dbl>    <dbl> <list>                                   <LINESTRING [m]>
#> 1     1   600      300 <int [7]> (0 0, 100 0, 200 0, 200 100, 300 100, 300 200,…
```
