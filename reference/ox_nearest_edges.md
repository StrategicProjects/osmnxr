# Find the nearest edge to a point

Returns, for each supplied coordinate, the graph edge closest in planar
distance.

## Usage

``` r
ox_nearest_edges(g, x, y)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- x, y:

  Numeric vectors of coordinates in the graph's CRS.

## Value

An `sf` subset of `g$edges`, one row per input point.

## Examples

``` r
g <- example_osm_graph()
ox_nearest_edges(g, x = 50, y = 0)
#> Simple feature collection with 1 feature and 6 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 100 ymax: 0
#> Projected CRS: WGS 84 / Pseudo-Mercator
#>    u v osmid     highway oneway                geometry length
#> 25 5 1    25 residential  FALSE LINESTRING (100 0, 0 0)    100
```
