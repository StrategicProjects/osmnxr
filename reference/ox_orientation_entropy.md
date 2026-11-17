# Street-orientation entropy

Shannon entropy (in nats) of the distribution of edge compass bearings,
binned into equal sectors. Higher values indicate a more disordered
(organic) network; lower values a more ordered (gridiron) one.

## Usage

``` r
ox_orientation_entropy(x, num_bins = 36)
```

## Arguments

- x:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
  or a numeric vector of bearings (degrees), e.g. from
  [`ox_bearings()`](https://strategicprojects.github.io/osmnxr/reference/ox_bearings.md).

- num_bins:

  Number of equal bearing sectors over `[0, 360)`. Default `36`.

## Value

A numeric scalar (entropy in nats).

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
g <- example_osm_graph()
ox_orientation_entropy(g)
#> [1] 1.526878
```
