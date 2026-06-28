# Convert to an `sfnetwork`

Returns the graph as a
[`sfnetworks::sfnetwork()`](https://luukvdmeer.github.io/sfnetworks/reference/sfnetwork.html)
object, ready for the `sfnetworks`/`tidygraph` spatial-network workflow.

## Usage

``` r
ox_as_sfnetwork(g, directed = TRUE)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- directed:

  Build a directed network. Default `TRUE`.

## Value

An `sfnetwork`.

## Examples

``` r
g <- example_osm_graph()
ox_as_sfnetwork(g)
#> # A sfnetwork with 16 nodes and 48 edges
#> #
#> # CRS:  EPSG:3857 
#> #
#> # A directed simple graph with 1 component with spatially explicit edges
#> #
#> # Node data: 16 × 4 (active)
#>   osmid     x     y    geometry
#>   <int> <dbl> <dbl> <POINT [m]>
#> 1     1     0     0       (0 0)
#> 2     2     0   100     (0 100)
#> 3     3     0   200     (0 200)
#> 4     4     0   300     (0 300)
#> 5     5   100     0     (100 0)
#> 6     6   100   100   (100 100)
#> # ℹ 10 more rows
#> #
#> # Edge data: 48 × 9
#>    from    to     u     v osmid highway  oneway         geometry length
#>   <int> <int> <int> <int> <int> <chr>    <lgl>  <LINESTRING [m]>  <dbl>
#> 1     1     5     1     5     1 residen… FALSE      (0 0, 100 0)    100
#> 2     1     2     1     2     2 residen… FALSE      (0 0, 0 100)    100
#> 3     5     9     5     9     3 residen… FALSE    (100 0, 200 0)    100
#> # ℹ 45 more rows
```
