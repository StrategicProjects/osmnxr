# Single-source shortest distances

Minimum-weight distance from `from` to every node in the graph.

## Usage

``` r
ox_distances(g, from, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from:

  A node `osmid`.

- weight:

  Edge column used as weight. Default `"length"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `osmid` and `distance` (`Inf` for unreachable nodes).

## Examples

``` r
g <- example_osm_graph()
ox_distances(g, ox_nearest_nodes(g, 0, 0))
#> # A tibble: 16 × 2
#>    osmid distance
#>    <int>    <dbl>
#>  1     1        0
#>  2     2      100
#>  3     3      200
#>  4     4      300
#>  5     5      100
#>  6     6      200
#>  7     7      300
#>  8     8      400
#>  9     9      200
#> 10    10      300
#> 11    11      400
#> 12    12      500
#> 13    13      300
#> 14    14      400
#> 15    15      500
#> 16    16      600
```
