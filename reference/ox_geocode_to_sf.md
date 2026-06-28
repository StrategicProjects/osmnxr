# Geocode a place to an `sf` boundary

Like
[`ox_geocode()`](https://strategicprojects.github.io/osmnxr/reference/ox_geocode.md)
but returns the place geometry (boundary polygon when available,
otherwise a point) as an `sf` object.

## Usage

``` r
ox_geocode_to_sf(query, limit = 1)
```

## Arguments

- query:

  A character scalar, e.g. `"Recife, Brazil"`.

- limit:

  Maximum number of results. Default `1`.

## Value

An `sf` object (one row per result) in EPSG:4326.

## Examples

``` r
if (FALSE) { # interactive()
ox_geocode_to_sf("Recife, Brazil")
}
```
