# Interoperability and export

``` r

library(osmnxr)
g <- ox_example("olinda") # a small real network bundled with the package
```

An `osm_graph` is deliberately thin: tidy `sf` nodes and edges. That
makes it easy to hand off to the rest of the R spatial-network
ecosystem, or to export for other tools.

## sf

The nodes and edges are always available as `sf`:

``` r

parts <- ox_as_sf(g)
parts$edges
#> Simple feature collection with 1191 features and 5 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -34.86427 ymin: -8.019512 xmax: -34.84686 ymax: -7.999988
#> Geodetic CRS:  WGS 84
#> First 10 features:
#>             u          v     length     highway                           name
#> 1  3567235794  655141381 143.059872       trunk         Avenida Pan Nordestina
#> 2   655141381 1572683340  39.206250       trunk         Avenida Pan Nordestina
#> 3   655141381 1572703444 108.819636 residential Rua Honorato do Espírito Santo
#> 4  1572703444  655141381 108.819636 residential Rua Honorato do Espírito Santo
#> 5   655144602  655144717  47.559016    tertiary             Rua Lucilo Varejão
#> 6   655144717  655144602  47.559016    tertiary             Rua Lucilo Varejão
#> 7   655144602 1446749601  94.315783    tertiary  Rua Manuel Clementino Marques
#> 8  1446749601  655144602  94.315783    tertiary  Rua Manuel Clementino Marques
#> 9   655144602 7271784016   2.199505    tertiary  Rua Manuel Clementino Marques
#> 10 7271784016  655144602   2.199505    tertiary  Rua Manuel Clementino Marques
#>                          geometry
#> 1  LINESTRING (-34.85776 -8.00...
#> 2  LINESTRING (-34.85716 -8.00...
#> 3  LINESTRING (-34.85716 -8.00...
#> 4  LINESTRING (-34.85675 -8.00...
#> 5  LINESTRING (-34.85867 -8.00...
#> 6  LINESTRING (-34.85889 -8.00...
#> 7  LINESTRING (-34.85867 -8.00...
#> 8  LINESTRING (-34.8595 -8.007...
#> 9  LINESTRING (-34.85867 -8.00...
#> 10 LINESTRING (-34.85865 -8.00...
```

## sfnetworks and tidygraph

Convert to an `sfnetwork` for the `tidygraph` verb workflow, or to a
bare `tbl_graph`:

``` r

net <- ox_as_sfnetwork(g)
net
#> # A sfnetwork with 498 nodes and 1191 edges
#> #
#> # CRS:  WGS 84 
#> #
#> # A directed multigraph with 2 components with spatially explicit edges
#> #
#> # Node data: 498 × 4 (active)
#>       osmid     x     y              geometry
#>       <dbl> <dbl> <dbl>           <POINT [°]>
#> 1 655141381 -34.9 -8.01 (-34.85716 -8.006496)
#> 2 655144602 -34.9 -8.01 (-34.85867 -8.007528)
#> 3 655144709 -34.9 -8.01 (-34.85801 -8.007735)
#> 4 655144717 -34.9 -8.01 (-34.85889 -8.007159)
#> 5 655144723 -34.9 -8.01 (-34.85817 -8.006279)
#> 6 655144725 -34.9 -8.01 (-34.85909 -8.006797)
#> # ℹ 492 more rows
#> #
#> # Edge data: 1,191 × 8
#>    from    to          u        v length highway name                   geometry
#>   <int> <int>      <dbl>    <dbl>  <dbl> <chr>   <chr>          <LINESTRING [°]>
#> 1   260     1 3567235794   6.55e8  143.  trunk   Aven… (-34.85776 -8.00763, -34…
#> 2     1   206  655141381   1.57e9   39.2 trunk   Aven… (-34.85716 -8.006496, -3…
#> 3     1   212  655141381   1.57e9  109.  reside… Rua … (-34.85716 -8.006496, -3…
#> # ℹ 1,188 more rows
```

``` r

tg <- ox_as_tidygraph(g)
tg
#> # A tbl_graph: 498 nodes and 1191 edges
#> #
#> # A directed multigraph with 2 components
#> #
#> # Node Data: 498 × 3 (active)
#>        osmid     x     y
#>        <dbl> <dbl> <dbl>
#>  1 655141381 -34.9 -8.01
#>  2 655144602 -34.9 -8.01
#>  3 655144709 -34.9 -8.01
#>  4 655144717 -34.9 -8.01
#>  5 655144723 -34.9 -8.01
#>  6 655144725 -34.9 -8.01
#>  7 655144730 -34.9 -8.01
#>  8 655144731 -34.9 -8.01
#>  9 655144732 -34.9 -8.01
#> 10 655144733 -34.9 -8.01
#> # ℹ 488 more rows
#> #
#> # Edge Data: 1,191 × 7
#>    from    to          u          v length highway     name                     
#>   <int> <int>      <dbl>      <dbl>  <dbl> <chr>       <chr>                    
#> 1   260     1 3567235794  655141381  143.  trunk       Avenida Pan Nordestina   
#> 2     1   206  655141381 1572683340   39.2 trunk       Avenida Pan Nordestina   
#> 3     1   212  655141381 1572703444  109.  residential Rua Honorato do Espírito…
#> # ℹ 1,188 more rows
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
#> 1     498    1191       95484.        80.2            2.39          1     1.06
```
