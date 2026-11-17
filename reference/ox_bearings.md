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

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
g <- example_osm_graph()
head(ox_bearings(g))
#> [1] 90  0 90  0 90  0
```
