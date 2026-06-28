# Geocode a place or address

Resolve a free-form query to coordinates and metadata using the
OpenStreetMap Nominatim service.

## Usage

``` r
ox_geocode(query, limit = 1)
```

## Arguments

- query:

  A character scalar, e.g. `"Recife, Brazil"`.

- limit:

  Maximum number of results. Default `1`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `display_name`, `lat`, `lon`, `osm_type`, `osm_id` and `class`.

## Examples

``` r
if (FALSE) { # interactive()
ox_geocode("Recife, Brazil")
}
```
