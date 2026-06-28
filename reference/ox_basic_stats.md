# Basic street-network statistics

Summary measures for an `osm_graph`: node and edge counts, total and
mean edge length, mean out-degree, self-loop count and average circuity.
Computation is performed by the bundled Rust core.

## Usage

``` r
ox_basic_stats(g, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- weight:

  Edge column used as length/weight. Default `"length"`.

## Value

A one-row [tibble](https://tibble.tidyverse.org/reference/tibble.html)
of statistics.

## Examples

``` r
g <- example_osm_graph()
ox_basic_stats(g)
#> # A tibble: 1 × 7
#>   n_nodes n_edges total_length mean_length mean_out_degree self_loops circuity
#>     <int>   <int>        <dbl>       <dbl>           <dbl>      <int>    <dbl>
#> 1      16      48         4800         100               3          0        1
```
