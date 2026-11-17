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

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
g <- example_osm_graph()
f <- tempfile(fileext = ".graphml")
ox_save_graphml(g, f)
```
