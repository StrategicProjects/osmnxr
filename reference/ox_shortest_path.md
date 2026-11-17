# Shortest path between two nodes

Computes the minimum-weight path from `from` to `to` using Dijkstra's
algorithm in the Rust core, returning just the node sequence. See
[`ox_route_shortest()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_shortest.md)
for the richer `sf` interface that also returns the route's cost and
street geometry (and alternatives via `k`).

## Usage

``` r
ox_shortest_path(g, from, to, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from, to:

  Node `osmid`s (as returned by
  [`ox_nearest_nodes()`](https://strategicprojects.github.io/osmnxr/reference/ox_nearest_nodes.md)).

- weight:

  Edge column used as weight. Default `"length"`.

## Value

A vector of node `osmid`s describing the path (length 0 if the target is
unreachable).

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
g <- example_osm_graph()
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
ox_shortest_path(g, from, to)
#> [1]  1  5  9 13 14 15 16
```
