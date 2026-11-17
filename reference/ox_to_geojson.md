# Export to GeoJSON

Writes the graph's edges (or nodes) to a GeoJSON file via
[`sf::st_write()`](https://r-spatial.github.io/sf/reference/st_write.html).
Geometry is transformed to EPSG:4326, the GeoJSON standard CRS.

## Usage

``` r
ox_to_geojson(g, path, layer = c("edges", "nodes"))
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

- path:

  Output file path.

- layer:

  Which layer to write: `"edges"` (default) or `"nodes"`.

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
ox_to_geojson(g, tempfile(fileext = ".geojson"))
```
