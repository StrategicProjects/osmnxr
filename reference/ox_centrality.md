# Node centrality

Computes betweenness and/or closeness centrality for every node, using
the Rust core (Brandes' algorithm for betweenness; one Dijkstra per node
for closeness).

## Usage

``` r
ox_centrality(
  g,
  type = c("betweenness", "closeness"),
  weight = "length",
  normalized = TRUE
)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- type:

  Centrality measures to compute: any of `"betweenness"` and
  `"closeness"`. Default both.

- weight:

  Edge column used as weight. Default `"length"`.

- normalized:

  Scale scores for comparability across graphs. Betweenness is divided
  by `(n - 1)(n - 2)`; closeness uses the Wasserman–Faust correction for
  disconnected graphs. Default `TRUE`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
column `osmid` plus one column per requested measure.

## Examples

``` r
g <- example_osm_graph(n = 4)
ox_centrality(g, type = "betweenness")
#> # A tibble: 16 × 2
#>    osmid betweenness
#>    <int>       <dbl>
#>  1     1      0.0198
#>  2     2      0.102 
#>  3     3      0.102 
#>  4     4      0.0198
#>  5     5      0.102 
#>  6     6      0.252 
#>  7     7      0.252 
#>  8     8      0.102 
#>  9     9      0.102 
#> 10    10      0.252 
#> 11    11      0.252 
#> 12    12      0.102 
#> 13    13      0.0198
#> 14    14      0.102 
#> 15    15      0.102 
#> 16    16      0.0198
```
