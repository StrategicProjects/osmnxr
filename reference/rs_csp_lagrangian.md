# Constrained shortest path by Lagrangian relaxation (LARAC): each iteration is a plain Dijkstra on `cost + lambda * resource`, with a binary search driving `lambda` to the dual optimum. Returns a list with `found`; when `TRUE` also `path` (0-based nodes), `cost`, `resource`, `lower_bound` (dual bound on the optimal cost; equal to `cost` proves optimality), `lambda` and `iterations` (Dijkstra runs).

Constrained shortest path by Lagrangian relaxation (LARAC): each
iteration is a plain Dijkstra on `cost + lambda * resource`, with a
binary search driving `lambda` to the dual optimum. Returns a list with
`found`; when `TRUE` also `path` (0-based nodes), `cost`, `resource`,
`lower_bound` (dual bound on the optimal cost; equal to `cost` proves
optimality), `lambda` and `iterations` (Dijkstra runs).

## Usage

``` r
rs_csp_lagrangian(
  from,
  to,
  w_cost,
  w_resource,
  n_nodes,
  source,
  target,
  budget,
  max_iter
)
```
