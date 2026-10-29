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

  One of `"drive"` (public drivable streets, service roads excluded),
  `"drive_service"` (drivable including service roads), `"walk"`
  (walkable public ways, excluding ways whose sidewalk is mapped as a
  separate way), `"bike"` (bikeable public ways), `"all"` (every way
  currently in use, private-access included) or `"all_public"`. The
  Overpass filters mirror OSMnx 2.1's, tag for tag.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Details

Transient Overpass failures (HTTP 429/5xx, dropped connections) are
retried automatically with exponential backoff; the Overpass endpoint,
timeout and number of attempts are configurable via
[`ox_settings()`](https://strategicprojects.github.io/osmnxr/reference/ox_settings.md).

## Examples

``` r
if (FALSE) { # interactive()
bbox <- c(-34.91, -8.07, -34.87, -8.04)
g <- ox_graph_from_bbox(bbox, network_type = "drive")
}
```
