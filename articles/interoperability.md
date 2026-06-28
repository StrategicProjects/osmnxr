# Interoperability and export

``` r

library(osmnxr)
g <- example_osm_graph(n = 5)
```

An `osm_graph` is deliberately thin: tidy `sf` nodes and edges. That
makes it easy to hand off to the rest of the R spatial-network
ecosystem, or to export for other tools.

## sf

The nodes and edges are always available as `sf`:

``` r

parts <- ox_as_sf(g)
parts$edges
#> Simple feature collection with 80 features and 6 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 400 ymax: 400
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> First 10 features:
#>     u  v osmid     highway oneway                    geometry length
#> 1   1  6     1 residential  FALSE     LINESTRING (0 0, 100 0)    100
#> 2   1  2     2 residential  FALSE     LINESTRING (0 0, 0 100)    100
#> 3   6 11     3 residential  FALSE   LINESTRING (100 0, 200 0)    100
#> 4   6  7     4 residential  FALSE LINESTRING (100 0, 100 100)    100
#> 5  11 16     5 residential  FALSE   LINESTRING (200 0, 300 0)    100
#> 6  11 12     6 residential  FALSE LINESTRING (200 0, 200 100)    100
#> 7  16 21     7 residential  FALSE   LINESTRING (300 0, 400 0)    100
#> 8  16 17     8 residential  FALSE LINESTRING (300 0, 300 100)    100
#> 9  21 22     9 residential  FALSE LINESTRING (400 0, 400 100)    100
#> 10  2  7    10 residential  FALSE LINESTRING (0 100, 100 100)    100
```

## sfnetworks and tidygraph

Convert to an `sfnetwork` for the `tidygraph` verb workflow, or to a
bare `tbl_graph`:

``` r

net <- ox_as_sfnetwork(g)
net
#> # A sfnetwork with 25 nodes and 80 edges
#> #
#> # CRS:  EPSG:3857 
#> #
#> # A directed simple graph with 1 component with spatially explicit edges
#> #
#> # Node data: 25 × 4 (active)
#>   osmid     x     y    geometry
#>   <int> <dbl> <dbl> <POINT [m]>
#> 1     1     0     0       (0 0)
#> 2     2     0   100     (0 100)
#> 3     3     0   200     (0 200)
#> 4     4     0   300     (0 300)
#> 5     5     0   400     (0 400)
#> 6     6   100     0     (100 0)
#> # ℹ 19 more rows
#> #
#> # Edge data: 80 × 9
#>    from    to     u     v osmid highway  oneway         geometry length
#>   <int> <int> <int> <int> <int> <chr>    <lgl>  <LINESTRING [m]>  <dbl>
#> 1     1     6     1     6     1 residen… FALSE      (0 0, 100 0)    100
#> 2     1     2     1     2     2 residen… FALSE      (0 0, 0 100)    100
#> 3     6    11     6    11     3 residen… FALSE    (100 0, 200 0)    100
#> # ℹ 77 more rows
```

``` r

tg <- ox_as_tidygraph(g)
tg
#> # A tbl_graph: 25 nodes and 80 edges
#> #
#> # A directed simple graph with 1 component
#> #
#> # Node Data: 25 × 3 (active)
#>    osmid     x     y
#>    <int> <dbl> <dbl>
#>  1     1     0     0
#>  2     2     0   100
#>  3     3     0   200
#>  4     4     0   300
#>  5     5     0   400
#>  6     6   100     0
#>  7     7   100   100
#>  8     8   100   200
#>  9     9   100   300
#> 10    10   100   400
#> # ℹ 15 more rows
#> #
#> # Edge Data: 80 × 8
#>    from    to     u     v osmid highway     oneway length
#>   <int> <int> <int> <int> <int> <chr>       <lgl>   <dbl>
#> 1     1     6     1     6     1 residential FALSE     100
#> 2     1     2     1     2     2 residential FALSE     100
#> 3     6    11     6    11     3 residential FALSE     100
#> # ℹ 77 more rows
```

## dodgr

[`ox_as_dodgr()`](https://strategicprojects.github.io/osmnxr/reference/ox_as_dodgr.md)
returns the column layout `dodgr` expects, so you can use its highly
optimised routing directly:

``` r

library(dodgr)
graph <- ox_as_dodgr(g)
dodgr_dists(graph, from = graph$from_id[1], to = graph$to_id[10])
```

## GeoJSON and MapLibre

Export edges to GeoJSON, or build a MapLibre GL style fragment that
points at the written data:

``` r

gj <- tempfile(fileext = ".geojson")
ox_to_geojson(g, gj)

style <- ox_to_maplibre(g, tempfile(fileext = ".geojson"))
str(style, max.level = 2)
#> List of 2
#>  $ sources:List of 1
#>   ..$ osmnxr:List of 2
#>  $ layers :List of 1
#>   ..$ :List of 4
```

## GraphML round-trip

[`ox_save_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_save_graphml.md)
/
[`ox_load_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_load_graphml.md)
persist the graph in a format compatible with OSMnx, NetworkX and Gephi.
Edge geometry is stored as WKT, so the round-trip is lossless:

``` r

f <- tempfile(fileext = ".graphml")
ox_save_graphml(g, f)
g2 <- ox_load_graphml(f)
ox_basic_stats(g2)
#> # A tibble: 1 × 7
#>   n_nodes n_edges total_length mean_length mean_out_degree self_loops circuity
#>     <int>   <int>        <dbl>       <dbl>           <dbl>      <int>    <dbl>
#> 1      25      80         8000         100             3.2          0        1
```
