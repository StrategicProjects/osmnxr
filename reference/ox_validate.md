# Validate an `osm_graph`

Checks that a graph meets the structural expectations the rest of the
package relies on, and fails with one actionable bullet per problem
found (all problems are collected first, so one run shows everything).
Useful after assembling a graph by hand — a metro layer for
[`ox_blend()`](https://strategicprojects.github.io/osmnxr/reference/ox_blend.md),
say — or after editing `nodes`/`edges` directly.

## Usage

``` r
ox_validate(g, tolerance = 1e-06)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- tolerance:

  Maximum distance, in CRS units, between an edge geometry endpoint and
  its `u`/`v` node before it counts as a mismatch. Default `1e-6`.

## Value

`g`, invisibly, when the graph is valid; otherwise an error listing
every problem found.

## Details

The checks: `nodes` and `edges` are `sf` with `POINT` / `LINESTRING`
geometries and no empty geometries, sharing one CRS; `nodes$osmid`
exists, is numeric, complete and unique; `edges$u`/`edges$v` exist, are
complete, and reference existing node `osmid`s; `edges$length` exists,
is numeric, complete and nonnegative; and each edge's geometry starts at
its `u` node and ends at its `v` node (within `tolerance`, in CRS units)
— the invariant that keeps routing results and drawn geometry in
agreement.

## Examples

``` r
g <- example_osm_graph()
ox_validate(g)
#> ✔ Valid <osm_graph>: 16 nodes, 48 edges.
```
