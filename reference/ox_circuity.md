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

## Examples

``` r
g <- example_osm_graph()
ox_circuity(g)
#> [1] 1
```
