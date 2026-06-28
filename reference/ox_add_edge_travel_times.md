# Add edge travel times

Adds a `travel_time` edge column (in seconds) from edge `length`
(metres) and `speed_kph`. Speeds are added with
[`ox_add_edge_speeds()`](https://strategicprojects.github.io/osmnxr/reference/ox_add_edge_speeds.md)
first if missing. The resulting column can be used as a routing `weight`
for time-based shortest paths and isochrones.

## Usage

``` r
ox_add_edge_travel_times(g)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Value

The
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
with `speed_kph` and `travel_time` edge columns.

## Examples

``` r
g <- example_osm_graph()
g <- ox_add_edge_travel_times(g)
from <- ox_nearest_nodes(g, 0, 0)
to <- ox_nearest_nodes(g, 300, 300)
ox_shortest_path(g, from, to, weight = "travel_time")
#> [1]  1  5  9 13 14 15 16
```
