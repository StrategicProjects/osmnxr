# Shortest-path distance matrix

Computes the matrix of minimum-weight distances between every `from`
node and every `to` node (Rust core; one Dijkstra per source).

## Usage

``` r
ox_distance_matrix(g, from, to = from, weight = "length")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- from:

  Node `osmid`s for the matrix rows.

- to:

  Node `osmid`s for the matrix columns. Defaults to `from`.

- weight:

  Edge column used as weight. Default `"length"`.

## Value

A numeric matrix (`length(from)` x `length(to)`) with `osmid` dimnames;
`Inf` marks unreachable pairs.

## Examples

``` r
g <- example_osm_graph(n = 3)
nodes <- g$nodes$osmid
ox_distance_matrix(g, from = nodes[1:2], to = nodes[3:4])
#>     3   4
#> 1 200 100
#> 2 100 200
```
