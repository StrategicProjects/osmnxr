# Shortest path between two nodes

Computes the minimum-weight path from `from` to `to` using Dijkstra's
algorithm in the Rust core.

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

## Examples

``` r
g <- example_osm_graph()
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
ox_shortest_path(g, from, to)
#> [1]  1  5  9 13 14 15 16
```
