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

  One of `"drive"`, `"walk"`, `"bike"` or `"all"`.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Examples

``` r
if (FALSE) { # interactive()
g <- ox_graph_from_address("Marco Zero, Recife", dist = 600)
}
```
