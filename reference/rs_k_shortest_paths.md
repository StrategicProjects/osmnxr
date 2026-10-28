# Yen's k loopless shortest paths. Returns a list with `paths` (a list of 0-based node-index vectors), `edge_paths` (0-based input-order indices of the edges traversed — the minimum-weight edge of each consecutive node pair, matching Yen's simple-graph abstraction) and `costs` (numeric).

Yen's k loopless shortest paths. Returns a list with `paths` (a list of
0-based node-index vectors), `edge_paths` (0-based input-order indices
of the edges traversed — the minimum-weight edge of each consecutive
node pair, matching Yen's simple-graph abstraction) and `costs`
(numeric).

## Usage

``` r
rs_k_shortest_paths(from, to, weight, n_nodes, source, target, k)
```
