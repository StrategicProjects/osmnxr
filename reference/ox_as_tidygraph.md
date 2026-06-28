# Convert to a `tidygraph` table graph

Returns the graph as a
[`tidygraph::tbl_graph()`](https://tidygraph.data-imaginist.com/reference/tbl_graph.html),
dropping geometry (node coordinates are kept as `x`/`y` columns).

## Usage

``` r
ox_as_tidygraph(g, directed = TRUE)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- directed:

  Build a directed graph. Default `TRUE`.

## Value

A `tbl_graph`.

## Examples

``` r
g <- example_osm_graph()
ox_as_tidygraph(g)
#> # A tbl_graph: 16 nodes and 48 edges
#> #
#> # A directed simple graph with 1 component
#> #
#> # Node Data: 16 × 3 (active)
#>    osmid     x     y
#>    <int> <dbl> <dbl>
#>  1     1     0     0
#>  2     2     0   100
#>  3     3     0   200
#>  4     4     0   300
#>  5     5   100     0
#>  6     6   100   100
#>  7     7   100   200
#>  8     8   100   300
#>  9     9   200     0
#> 10    10   200   100
#> 11    11   200   200
#> 12    12   200   300
#> 13    13   300     0
#> 14    14   300   100
#> 15    15   300   200
#> 16    16   300   300
#> #
#> # Edge Data: 48 × 8
#>    from    to     u     v osmid highway     oneway length
#>   <int> <int> <int> <int> <int> <chr>       <lgl>   <dbl>
#> 1     1     5     1     5     1 residential FALSE     100
#> 2     1     2     1     2     2 residential FALSE     100
#> 3     5     9     5     9     3 residential FALSE     100
#> # ℹ 45 more rows
```
