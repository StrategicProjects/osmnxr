# Polar plot of street orientations

Draws a polar histogram (rose plot) of edge compass bearings, the
standard visual summary of a street network's orientation order.
Requires `ggplot2`.

## Usage

``` r
ox_plot_orientation(g, num_bins = 36, fill = "#0d3b66")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- num_bins:

  Number of equal bearing sectors. Default `36`.

- fill:

  Bar fill colour. Default the package blue.

## Value

A `ggplot` object.

## Examples

``` r
g <- example_osm_graph()
ox_plot_orientation(g)
```
