# Save a graph to GraphML

Writes the graph to a GraphML file compatible with OSMnx / NetworkX /
Gephi. Edge geometry is preserved losslessly as a WKT attribute, so the
graph round-trips through
[`ox_load_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_load_graphml.md).

## Usage

``` r
ox_save_graphml(g, path)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- path:

  Output `.graphml` path.

## Value

`path`, invisibly.

## Examples

``` r
g <- example_osm_graph()
f <- tempfile(fileext = ".graphml")
ox_save_graphml(g, f)
```
