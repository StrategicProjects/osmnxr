# Add edge speeds

Assigns a free-flow speed (km/h) to every edge based on its `highway`
class, adding a `speed_kph` column. Unknown classes get `fallback`.

## Usage

``` r
ox_add_edge_speeds(g, speeds = NULL, fallback = 40)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- speeds:

  Optional named numeric vector of `highway = kph` overrides, merged
  over the built-in defaults.

- fallback:

  Speed (km/h) for edges with no matching class. Default `40`.

## Value

The
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
with a `speed_kph` edge column.

## Examples

``` r
g <- example_osm_graph()
g <- ox_add_edge_speeds(g, speeds = c(residential = 25))
head(g$edges$speed_kph)
#> [1] 25 25 25 25 25 25
```
