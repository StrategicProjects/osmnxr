# Construct an `osm_graph`

Low-level constructor wrapping tidy `sf` nodes and edges into the
central `osm_graph` object used across the package. Most users obtain an
`osm_graph` from
[`ox_graph_from_place()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_place.md)
and friends rather than calling this directly.

## Usage

``` r
new_osm_graph(nodes, edges, meta = list())
```

## Arguments

- nodes:

  An `sf` object of `POINT` geometries with at least an integer or
  numeric `osmid` column.

- edges:

  An `sf` object of `LINESTRING` geometries with `u` and `v` columns
  referencing node `osmid`s, plus a numeric `length` column.

- meta:

  A named list of metadata (e.g. `network_type`, `simplified`).

## Value

An object of class `osm_graph`.
