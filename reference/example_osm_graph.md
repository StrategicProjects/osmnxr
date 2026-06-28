# A small synthetic `osm_graph` for examples and tests

Builds a tiny `n x n` regular street grid as an
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md),
with no network access. Edges are bidirectional and weighted by their
planar length. Useful for examples, tests and learning the API offline.

## Usage

``` r
example_osm_graph(n = 4, spacing = 100)
```

## Arguments

- n:

  Grid size; the network has `n * n` nodes. Default `4`.

- spacing:

  Distance between adjacent nodes, in CRS units. Default `100`.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
in an arbitrary projected CRS.

## Examples

``` r
g <- example_osm_graph()
g
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 16 nodes, 48 edges
#> Network type: "drive"
#> Simplified: TRUE
#> CRS: "EPSG:3857"
ox_basic_stats(g)
#> # A tibble: 1 × 7
#>   n_nodes n_edges total_length mean_length mean_out_degree self_loops circuity
#>     <int>   <int>        <dbl>       <dbl>           <dbl>      <int>    <dbl>
#> 1      16      48         4800         100               3          0        1
```
