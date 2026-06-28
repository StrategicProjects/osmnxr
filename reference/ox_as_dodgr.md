# Convert to a `dodgr` graph

Returns a `data.frame` in the column layout expected by the `dodgr`
routing package (`from_id`, `from_lon`, `from_lat`, `to_id`, `to_lon`,
`to_lat`, `d`), suitable for
[`dodgr::dodgr_dists()`](https://UrbanAnalyst.github.io/dodgr/reference/dodgr_dists.html)
and friends.

## Usage

``` r
ox_as_dodgr(g, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- weight:

  Edge column used as the distance/weight `d`. Default `"length"`.

## Value

A `data.frame` `dodgr` graph.

## Examples

``` r
g <- example_osm_graph()
head(ox_as_dodgr(g))
#>   from_id from_lon from_lat to_id to_lon to_lat   d
#> 1       1        0        0     5    100      0 100
#> 2       1        0        0     2      0    100 100
#> 3       5      100        0     9    200      0 100
#> 4       5      100        0     6    100    100 100
#> 5       9      200        0    13    300      0 100
#> 6       9      200        0    10    200    100 100
```
