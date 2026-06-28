# Simplify street-network topology

Removes interstitial (degree-2) nodes that merely shape the geometry of
a street, merging each maximal chain of such nodes into a single edge
whose geometry follows the original points and whose `length` is the sum
of the merged segments. Only true endpoints and intersections are kept
as nodes.

## Usage

``` r
ox_simplify(g)
```

## Arguments

- g:

  An unsimplified
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Value

A simplified
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
(with `meta$simplified = TRUE`).

## Details

The topology walk is performed by the Rust core; geometry is rebuilt
with `sf`. Downloaded graphs are unsimplified by default; this is the
standard cleanup step before analysis.

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
