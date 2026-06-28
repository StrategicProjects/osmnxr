# Plot an `osm_graph`

Draws the street-network edges (and optionally nodes) using base `sf`
plotting.

## Usage

``` r
# S3 method for class 'osm_graph'
plot(x, nodes = FALSE, col = "#0d3b66", lwd = 0.7, ...)
```

## Arguments

- x:

  An `osm_graph`.

- nodes:

  Logical; overlay node points. Default `FALSE`.

- col, lwd:

  Passed to the edge geometry plot.

- ...:

  Further arguments passed to
  [`sf::plot.sf()`](https://r-spatial.github.io/sf/reference/plot.html).

## Value

Invisibly, the `osm_graph`.
