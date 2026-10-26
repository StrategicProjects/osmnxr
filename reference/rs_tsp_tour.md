# Heuristic travelling-salesman visiting order over a row-major `n x n` cost matrix (nearest-neighbour construction, or-opt improvement when `improve`). The tour starts at `start` (0-based); `closed = TRUE` returns there, otherwise `end >= 0` pins the final stop and `end = -1` leaves it free. Returns 0-based indices into the matrix.

Heuristic travelling-salesman visiting order over a row-major `n x n`
cost matrix (nearest-neighbour construction, or-opt improvement when
`improve`). The tour starts at `start` (0-based); `closed = TRUE`
returns there, otherwise `end >= 0` pins the final stop and `end = -1`
leaves it free. Returns 0-based indices into the matrix.

## Usage

``` r
rs_tsp_tour(cost, n, start, end, closed, improve)
```
