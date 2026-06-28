# Consolidate nearby intersections

Merges groups of nodes lying within `tolerance` of one another into
single nodes placed at the group centroid, then rewrites edges to the
consolidated nodes and drops the resulting self-loops. Useful for
collapsing the multiple OSM nodes that represent one complex junction
(e.g. dual carriageways).

## Usage

``` r
ox_consolidate_intersections(g, tolerance = 10)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- tolerance:

  Distance below which nodes are merged, in CRS units. Default `10`.

## Value

A consolidated
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
(with `meta$consolidated = TRUE`).

## Details

Clustering uses
[`sf::st_is_within_distance()`](https://r-spatial.github.io/sf/reference/geos_binary_pred.html);
connected components are found by the Rust core. `tolerance` is in the
units of the graph CRS, so project the graph first (e.g. to a metric
CRS) for a meaningful distance.

## Examples

``` r
g <- example_osm_graph(n = 4, spacing = 100)
# nothing is within 10 units here, so the graph is unchanged
ox_consolidate_intersections(g, tolerance = 10)
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 16 nodes, 48 edges
#> Network type: "drive"
#> Simplified: TRUE
#> CRS: "EPSG:3857"
```
