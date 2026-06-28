# Polar plot of street orientations

Draws a polar histogram (rose plot) of edge compass bearings, the
standard visual summary of a street network's orientation order.
Requires `ggplot2`.

## Usage

``` r
ox_plot_orientation(
  x,
  num_bins = 36,
  fill = "#0d3b66",
  title = "Street orientation"
)
```

## Arguments

- x:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
  or a numeric vector of bearings (degrees), e.g. from
  [`ox_bearings()`](https://strategicprojects.github.io/osmnxr/reference/ox_bearings.md).

- num_bins:

  Number of equal bearing sectors. Default `36`.

- fill:

  Bar fill colour. Default the package blue.

- title:

  Optional plot title.

## Value

A `ggplot` object.

## Examples

``` r
g <- example_osm_graph()
ox_plot_orientation(g)
```
