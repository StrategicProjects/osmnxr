# Download features for a named place

Geocodes `query` with
[`ox_geocode()`](https://strategicprojects.github.io/osmnxr/reference/ox_geocode.md)
and downloads matching features around it. See
[`ox_features_from_bbox()`](https://strategicprojects.github.io/osmnxr/reference/ox_features_from_bbox.md)
for the `tags` format.

## Usage

``` r
ox_features_from_place(query, tags, dist = 2000)
```

## Arguments

- query:

  A place name, e.g. `"Recife, Brazil"`.

- tags:

  Named list of OSM tag filters.

- dist:

  Search half-width in metres around the geocoded point. Default `2000`.

## Value

An `sf` of `POINT` features.

## Examples

``` r
if (FALSE) { # interactive()
ox_features_from_place("Olinda, Brazil", tags = list(amenity = "hospital"))
}
```
