# Find the nearest node to a point

Returns the `osmid` of the graph node closest (in planar distance) to
each supplied coordinate.

## Usage

``` r
ox_nearest_nodes(g, x, y)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- x, y:

  Numeric vectors of coordinates in the graph's CRS.

## Value

An integer/numeric vector of node `osmid`s, one per input point.

## Examples

``` r
g <- example_osm_graph()
ox_nearest_nodes(g, x = 0, y = 0)
#> [1] 1
```
