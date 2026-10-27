# Bicriteria shortest paths (Pareto front) from `source` to `target` by label-setting with dominance pruning. Each edge carries a cost and a resource weight; `budget` caps the path resource (`Inf` for none) and `max_routes <= 0` returns the whole front. Returns a list with `paths` (0-based node-index vectors), `edge_paths` (0-based indices of the edges actually traversed, in input order), `costs` and `resources`, ordered by increasing cost.

Bicriteria shortest paths (Pareto front) from `source` to `target` by
label-setting with dominance pruning. Each edge carries a cost and a
resource weight; `budget` caps the path resource (`Inf` for none) and
`max_routes <= 0` returns the whole front. Returns a list with `paths`
(0-based node-index vectors), `edge_paths` (0-based indices of the edges
actually traversed, in input order), `costs` and `resources`, ordered by
increasing cost.

## Usage

``` r
rs_pareto_paths(
  from,
  to,
  w_cost,
  w_resource,
  n_nodes,
  source,
  target,
  budget,
  max_routes
)
```
