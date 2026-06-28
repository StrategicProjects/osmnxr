# Load a bundled real-world example network

Loads a small, real street network shipped with the package (downloaded
once from OpenStreetMap and simplified) so that examples and vignettes
can show real analyses without network access.

## Usage

``` r
ox_example(name = c("olinda"))
```

## Arguments

- name:

  Which network to load. Currently `"olinda"` (the historic centre of
  Olinda, Pernambuco, Brazil; drivable network, simplified).

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Examples

``` r
g <- ox_example("olinda")
g
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 498 nodes, 1191 edges
#> Network type: "unknown"
#> Simplified: FALSE
#> CRS: "WGS 84"
ox_basic_stats(g)
#> # A tibble: 1 × 7
#>   n_nodes n_edges total_length mean_length mean_out_degree self_loops circuity
#>     <int>   <int>        <dbl>       <dbl>           <dbl>      <int>    <dbl>
#> 1     498    1191       95484.        80.2            2.39          1     1.06
```
