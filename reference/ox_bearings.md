# Compute edge compass bearings

Initial compass bearing (degrees clockwise from north) of each edge,
from its first to its last coordinate. Geographic coordinates are used;
projected graphs are transformed to EPSG:4326 first.

## Usage

``` r
ox_bearings(g)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Value

A numeric vector of bearings, one per edge.

## Examples

``` r
g <- example_osm_graph()
head(ox_bearings(g))
#> [1] 90  0 90  0 90  0
```
