# Figure-ground diagram of a street network

Draws a figure-ground diagram: the streets in a single colour on a solid
background, with no axes or margins. Cropping different places to the
same extent makes their network form directly comparable, as in Boeing
(2025).

## Usage

``` r
ox_plot_figure_ground(g, bg = "black", col = "white", lwd = 1.2, title = NULL)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- bg, col:

  Background and street colours. Default white-on-black.

- lwd:

  Street line width. Default `1.2`.

- title:

  Optional panel title.

## Value

Invisibly, the `osm_graph`.

## Examples

``` r
g <- example_osm_graph()
ox_plot_figure_ground(g)
```
