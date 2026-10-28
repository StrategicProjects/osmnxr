# Snap points to the nearest edge polyline (planar distance, grid-indexed). Edges arrive as flattened vertex coordinates (`vx`/`vy`) plus 0-based per-edge `offsets` (length `n_edges + 1`). Returns a list with, per point: `edge` (0-based nearest edge, `-1` when none within `tolerance`), `dist`, the snapped coordinates `x`/`y`, and `pos` (planar distance along the edge's polyline from its first vertex).

Snap points to the nearest edge polyline (planar distance,
grid-indexed). Edges arrive as flattened vertex coordinates (`vx`/`vy`)
plus 0-based per-edge `offsets` (length `n_edges + 1`). Returns a list
with, per point: `edge` (0-based nearest edge, `-1` when none within
`tolerance`), `dist`, the snapped coordinates `x`/`y`, and `pos` (planar
distance along the edge's polyline from its first vertex).

## Usage

``` r
rs_snap_points(vx, vy, offsets, px, py, tolerance)
```
