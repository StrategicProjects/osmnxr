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

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
if (FALSE) { # interactive()
ox_geocode("Recife, Brazil")
}
```
