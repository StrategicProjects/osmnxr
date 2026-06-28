# Load a graph from GraphML

Reads a GraphML file written by
[`ox_save_graphml()`](https://strategicprojects.github.io/osmnxr/reference/ox_save_graphml.md)
back into an
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md),
restoring node coordinates, edge attributes and edge geometry (from the
stored WKT).

## Usage

``` r
ox_load_graphml(path)
```

## Arguments

- path:

  Path to a `.graphml` file.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).

## Examples

``` r
g <- example_osm_graph()
f <- tempfile(fileext = ".graphml")
ox_save_graphml(g, f)
ox_load_graphml(f)
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 16 nodes, 48 edges
#> Network type: "unknown"
#> Simplified: FALSE
#> CRS: "PROJCRS[\"WGS 84 / Pseudo-Mercator\", BASEGEOGCRS[\"WGS 84\",
#> ENSEMBLE[\"World Geodetic System 1984 ensemble\", MEMBER[\"World Geodetic
#> System 1984 (Transit)\"], MEMBER[\"World Geodetic System 1984 (G730)\"],
#> MEMBER[\"World Geodetic System 1984 (G873)\"], MEMBER[\"World Geodetic System
#> 1984 (G1150)\"], MEMBER[\"World Geodetic System 1984 (G1674)\"], MEMBER[\"World
#> Geodetic System 1984 (G1762)\"], MEMBER[\"World Geodetic System 1984
#> (G2139)\"], ELLIPSOID[\"WGS 84\",6378137,298.257223563,
#> LENGTHUNIT[\"metre\",1]], ENSEMBLEACCURACY[2.0]], PRIMEM[\"Greenwich\",0,
#> ANGLEUNIT[\"degree\",0.0174532925199433]], ID[\"EPSG\",4326]],
#> CONVERSION[\"Popular Visualisation Pseudo-Mercator\", METHOD[\"Popular
#> Visualisation Pseudo Mercator\", ID[\"EPSG\",1024]], PARAMETER[\"Latitude of
#> natural origin\",0, ANGLEUNIT[\"degree\",0.0174532925199433],
#> ID[\"EPSG\",8801]], PARAMETER[\"Longitude of natural origin\",0,
#> ANGLEUNIT[\"degree\",0.0174532925199433], ID[\"EPSG\",8802]], PARAMETER[\"False
#> easting\",0, LENGTHUNIT[\"metre\",1], ID[\"EPSG\",8806]], PARAMETER[\"False
#> northing\",0, LENGTHUNIT[\"metre\",1], ID[\"EPSG\",8807]]], CS[Cartesian,2],
#> AXIS[\"easting (X)\",east, ORDER[1], LENGTHUNIT[\"metre\",1]], AXIS[\"northing
#> (Y)\",north, ORDER[2], LENGTHUNIT[\"metre\",1]], USAGE[ SCOPE[\"Web mapping and
#> visualisation.\"], AREA[\"World between 85.06°S and 85.06°N.\"],
#> BBOX[-85.06,-180,85.06,180]], ID[\"EPSG\",3857]]"
```
