# Add edge penalties by road type

Builds a per-edge penalty column from the edge `highway` class: each
edge gets `factor * weight`, where `factor` comes from the named
`penalties` vector (classes not listed get `0`). The column quantifies
how much of a route runs on penalized road types, in the units of
`weight`.

## Usage

``` r
ox_add_edge_penalties(g, penalties, weight = "length", name = "penalty")
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- penalties:

  Named numeric vector of `highway = factor` pairs; each edge's penalty
  is `factor * weight`. Classes not listed (and edges with no `highway`)
  get `0`.

- weight:

  Edge column the factors multiply. Default `"length"`.

- name:

  Name of the new edge column. Default `"penalty"`.

## Value

The
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
with the penalty edge column added.

## Details

Two ways to use it:

- **Scalarized routing** — add the penalty onto the routing weight
  (`g$edges$w <- g$edges$length + g$edges$penalty`) and route on `w`
  with
  [`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md):
  an ordinary shortest path that trades length against preference at a
  fixed rate.

- **Constrained / Pareto routing** — pass the column as the `resource`
  of
  [`ox_route_constrained()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_constrained.md)
  or
  [`ox_route_pareto()`](https://strategicprojects.github.io/osmnxr/reference/ox_route_pareto.md),
  e.g. "fastest route with at most 500 m on residential streets"
  (`penalties = c(residential = 1)`, `budget = 500`).

## Examples

``` r
g <- example_osm_graph()
g <- ox_add_edge_penalties(g, c(residential = 1))
head(g$edges$penalty)
#> [1] 100 100 100 100 100 100
```
