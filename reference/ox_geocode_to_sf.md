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

## References

osmnxr is an R port of OSMnx. If you use it, please cite:

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## Examples

``` r
if (FALSE) { # interactive()
ox_geocode_to_sf("Recife, Brazil")
}
```
