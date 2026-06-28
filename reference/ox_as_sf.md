# Extract `sf` nodes and edges from an `osm_graph`

Extract `sf` nodes and edges from an `osm_graph`

## Usage

``` r
ox_as_sf(g)
```

## Arguments

- g:

  An `osm_graph`.

## Value

A named list with `sf` elements `nodes` and `edges`.

## Examples

``` r
g <- example_osm_graph()
parts <- ox_as_sf(g)
parts$edges
#> Simple feature collection with 48 features and 6 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 300 ymax: 300
#> Projected CRS: WGS 84 / Pseudo-Mercator
#> First 10 features:
#>     u  v osmid     highway oneway                      geometry length
#> 1   1  5     1 residential  FALSE       LINESTRING (0 0, 100 0)    100
#> 2   1  2     2 residential  FALSE       LINESTRING (0 0, 0 100)    100
#> 3   5  9     3 residential  FALSE     LINESTRING (100 0, 200 0)    100
#> 4   5  6     4 residential  FALSE   LINESTRING (100 0, 100 100)    100
#> 5   9 13     5 residential  FALSE     LINESTRING (200 0, 300 0)    100
#> 6   9 10     6 residential  FALSE   LINESTRING (200 0, 200 100)    100
#> 7  13 14     7 residential  FALSE   LINESTRING (300 0, 300 100)    100
#> 8   2  6     8 residential  FALSE   LINESTRING (0 100, 100 100)    100
#> 9   2  3     9 residential  FALSE     LINESTRING (0 100, 0 200)    100
#> 10  6 10    10 residential  FALSE LINESTRING (100 100, 200 100)    100
```
