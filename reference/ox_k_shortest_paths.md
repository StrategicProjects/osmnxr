# k shortest paths between two nodes

Computes up to `k` loopless shortest paths from `from` to `to` using
Yen's algorithm in the Rust core. Useful for route alternatives.

## Usage

``` r
ox_k_shortest_paths(g, from, to, k = 3, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from, to:

  Node `osmid`s.

- k:

  Number of paths to return. Default `3`.

- weight:

  Edge column used as weight. Default `"length"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per path: `rank`, `cost` and a list-column `path` of node `osmid`s,
ordered by increasing cost. Fewer than `k` rows are returned when fewer
distinct paths exist.

## Examples

``` r
g <- example_osm_graph()
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 200, 200)
ox_k_shortest_paths(g, from, to, k = 3)
#> # A tibble: 3 × 3
#>    rank  cost path     
#>   <int> <dbl> <list>   
#> 1     1   400 <int [5]>
#> 2     2   400 <int [5]>
#> 3     3   400 <int [5]>
```
