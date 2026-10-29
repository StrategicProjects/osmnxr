# Download a street network for a named place

Geocodes `query` with
[`ox_geocode()`](https://strategicprojects.github.io/osmnxr/reference/ox_geocode.md)
and downloads the street network within the bounding box of the matched
place.

## Usage

``` r
ox_graph_from_place(query, network_type = "drive")
```

## Arguments

- query:

  A place name, e.g. `"Recife, Brazil"`.

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

## Examples

``` r
if (FALSE) { # interactive()
g <- ox_graph_from_place("Olinda, Brazil", network_type = "drive")
}
```
