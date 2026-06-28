# Download features within a bounding box

Queries OpenStreetMap (via Overpass) for elements matching `tags` —
points of interest, amenities, buildings, transit stops, and so on —
returning them as an `sf` of points (ways and relations are represented
by their centroid).

## Usage

``` r
ox_features_from_bbox(bbox, tags)
```

## Arguments

- bbox:

  Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.

- tags:

  Named list of OSM tag filters. Each element is either `TRUE` (key
  present with any value) or a character vector of allowed values, e.g.
  `list(amenity = c("school", "hospital"))`.

## Value

An `sf` of `POINT` features with `osm_type`, `osm_id` and one column per
tag encountered.

## Examples

``` r
if (FALSE) { # interactive()
bbox <- c(-34.91, -8.07, -34.87, -8.04)
ox_features_from_bbox(bbox, tags = list(amenity = "school"))
}
```
