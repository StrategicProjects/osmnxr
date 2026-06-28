# Build a MapLibre GL style fragment

Writes the edges to a GeoJSON file and returns a MapLibre GL JS style
fragment (a list with `sources` and `layers`) that references it, ready
to merge into a map style. Serialize with, e.g.,
`jsonlite::toJSON(..., auto_unbox = TRUE)`.

## Usage

``` r
ox_to_maplibre(
  g,
  path,
  source_id = "osmnxr",
  layer_id = "streets",
  url = basename(path)
)
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- path:

  GeoJSON output path for the edge data.

- source_id, layer_id:

  Identifiers for the MapLibre source and layer.

- url:

  URL the style should use to fetch the data. Defaults to
  `basename(path)`.

## Value

A named list with `sources` and `layers`, invisibly written data to
`path`.

## Examples

``` r
g <- example_osm_graph()
style <- ox_to_maplibre(g, tempfile(fileext = ".geojson"))
names(style)
#> [1] "sources" "layers" 
```
