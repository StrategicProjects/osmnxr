# Simplify street-network topology

Removes interstitial (degree-2) nodes that merely shape the geometry of
a street, merging each maximal chain of such nodes into a single edge
whose geometry follows the original points and whose `length` is the sum
of the merged segments. Only true endpoints and intersections are kept
as nodes.

## Usage

``` r
ox_simplify(g, edge_attr_aggs = NULL)
```

## Arguments

- g:

  An unsimplified
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- edge_attr_aggs:

  Named list of functions combining the per-segment values of an edge
  attribute along each merged chain, e.g.
  `list(travel_time = sum, speed_kph = mean)`. The default `NULL` sums
  `travel_time` and `penalty` when those columns exist (so routing
  weights stay consistent); pass
  [`list()`](https://rdrr.io/r/base/list.html) to aggregate nothing.
  Each function receives the segment values of one merged edge and must
  return a single value.

## Value

A simplified
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
(with `meta$simplified = TRUE`).

## Details

The topology walk is performed by the Rust core; geometry is rebuilt
with `sf`. Downloaded graphs are unsimplified by default; this is the
standard cleanup step before analysis.

Every edge attribute column survives simplification: a merged edge takes
the value of its first segment, except for columns named in
`edge_attr_aggs`, whose per-segment values are combined by the given
function (as in OSMnx 2). `length` is always recomputed from the merged
geometry unless an explicit `length` aggregator is supplied, and
`n_segments` records how many segments each edge merged.

## Examples

``` r
g <- example_osm_graph()
ox_simplify(g) # already simplified: returned unchanged
#> ℹ Graph is already simplified; returning unchanged.
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 16 nodes, 48 edges
#> Network type: "drive"
#> Simplified: TRUE
#> CRS: "EPSG:3857"
```
