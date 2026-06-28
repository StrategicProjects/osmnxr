# Download a street network around a point

Download a street network around a point

## Usage

``` r
ox_graph_from_point(point, dist = 1000, network_type = "drive")
```

## Arguments

- point:

  Numeric `c(lon, lat)`.

- dist:

  Buffer half-width in metres (a square bounding box of side `2 * dist`
  is used). Default `1000`.

- network_type:

  One of `"drive"`, `"walk"`, `"bike"` or `"all"`.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Examples

``` r
if (FALSE) { # interactive()
g <- ox_graph_from_point(c(-34.89, -8.05), dist = 800)
}
```
