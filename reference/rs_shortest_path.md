# Shortest path between `source` and `target`. Returns a list with `path` (0-based node indices), `edges` (0-based input-order indices of the edges actually traversed, parallel edges included) and `cost`; `path` is empty and `cost` is `Inf` when the target is unreachable.

Shortest path between `source` and `target`. Returns a list with `path`
(0-based node indices), `edges` (0-based input-order indices of the
edges actually traversed, parallel edges included) and `cost`; `path` is
empty and `cost` is `Inf` when the target is unreachable.

## Usage

``` r
rs_shortest_path(from, to, weight, n_nodes, source, target)
```
