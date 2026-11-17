# Average network circuity

The ratio of total edge length to total straight-line (great-circle for
geographic CRS, Euclidean for projected) distance between edge
endpoints. A value of `1` means perfectly straight streets; higher
values indicate more winding networks.

## Usage

``` r
ox_circuity(g)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Value

A numeric scalar (\>= 1).

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
g <- example_osm_graph()
ox_circuity(g)
#> [1] 1
```
