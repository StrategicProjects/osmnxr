# Download a street network within a bounding box

Download a street network within a bounding box

## Usage

``` r
ox_graph_from_bbox(bbox, network_type = "drive")
```

## Arguments

- bbox:

  Numeric vector `c(xmin, ymin, xmax, ymax)` in longitude/latitude
  (EPSG:4326).

- network_type:

  One of `"drive"`, `"walk"`, `"bike"` or `"all"`.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Examples

``` r
if (FALSE) { # interactive()
bbox <- c(-34.91, -8.07, -34.87, -8.04)
g <- ox_graph_from_bbox(bbox, network_type = "drive")
}
```
