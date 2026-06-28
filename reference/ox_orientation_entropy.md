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

## Examples

``` r
g <- example_osm_graph()
ox_orientation_entropy(g)
#> [1] 1.526878
```
