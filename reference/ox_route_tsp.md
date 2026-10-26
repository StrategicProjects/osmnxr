# Travelling-salesman route through a set of nodes

Finds a short route through `nodes` over the street network, in the
spirit of `sfnetworks::st_network_travel()`. Network distances between
all pairs of stops are computed in the Rust core (one Dijkstra per stop,
so one-way streets are respected via the asymmetric cost matrix), the
visiting order is solved with an iterated local search, and each leg is
expanded back into a shortest path with its street geometry.

## Usage

``` r
ox_route_tsp(
  g,
  nodes,
  weight = "length",
  start = 1,
  end = start,
  method = c("ils", "nn")
)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- nodes:

  Node `osmid`s to visit (at least 2, no duplicates), e.g. from
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md).

- weight:

  Edge column used as weight. Default `"length"`; use `"travel_time"`
  after
  [`ox_add_edge_travel_times()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_travel_times.md)
  for fastest routes.

- start:

  Index into `nodes` of the first stop. Default `1`.

- end:

  Index into `nodes` of the final stop. The default (`end = start`)
  gives a closed tour that returns to the start; `end = NULL` leaves the
  final stop free (an open route); any other index pins the route's end.

- method:

  `"ils"` (default, nearest-neighbour + iterated local search) or `"nn"`
  (nearest-neighbour only).

## Value

An `sf` tibble with one row per leg of the route: `leg`, `from` and `to`
(node `osmid`s), `cost` (network distance in `weight` units), a
list-column `path` of the `osmid`s traversed, and the leg's `LINESTRING`
geometry. The total route cost is `sum(out$cost)`.

## Details

The default solver builds a nearest-neighbour tour and polishes it with
an iterated local search: a descent over or-opt (segment relocation),
swap and 2-opt moves — every move evaluated exactly on the asymmetric
cost matrix — restarted from double-bridge perturbations, keeping the
best tour found. The search is deterministic (an internal fixed-seed RNG
drives the perturbations, leaving R's RNG untouched). It routinely finds
the global optimum for small stop counts, but optimality is not
guaranteed (the TSP is NP-hard). `method = "nn"` skips the improvement
and keeps the raw nearest-neighbour order.

## Examples

``` r
g <- example_osm_graph()
stops <- c(1, 4, 13, 16, 6)
route <- ox_route_tsp(g, stops)
route
#> Simple feature collection with 5 features and 5 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> # A tibble: 5 × 6
#>     leg  from    to  cost path                                geometry
#>   <int> <dbl> <dbl> <dbl> <list>                      <LINESTRING [m]>
#> 1     1     1     6   200 <int [3]>              (0 0, 100 0, 100 100)
#> 2     2     6     4   300 <int [4]>     (100 100, 0 100, 0 200, 0 300)
#> 3     3     4    16   300 <int [4]> (0 300, 100 300, 200 300, 300 300)
#> 4     4    16    13   300 <int [4]> (300 300, 300 200, 300 100, 300 0)
#> 5     5    13     1   300 <int [4]>         (300 0, 200 0, 100 0, 0 0)
sum(route$cost)
#> [1] 1400
```
