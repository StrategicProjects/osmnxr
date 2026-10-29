# Download a street network around an address

Download a street network around an address

## Usage

``` r
ox_graph_from_address(address, dist = 1000, network_type = "drive")
```

## Arguments

- address:

  A street address.

- dist:

  Buffer half-width in metres. Default `1000`.

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
g <- ox_graph_from_address("Marco Zero, Recife", dist = 600)
}
```
