# Features and points of interest

``` r

library(osmnxr)
```

Beyond street networks, `osmnxr` downloads any OpenStreetMap **feature**
— amenities, building footprints, transit stops, parks, shops — as tidy
`sf` points, mirroring OSMnx’s `features` module (Boeing 2025). Because
these calls hit the live Overpass API, the download chunks below are not
executed when the vignette is built; run them interactively.

## Tag filters

Features are selected with **tags**, given as a named list. Each entry
is either `TRUE` (the key with any value) or a character vector of
allowed values:

``` r

# schools in a place
ox_features_from_place("Olinda, Brazil", tags = list(amenity = "school"))

# the amenities studied in accessibility research, in one call
ox_features_from_place(
  "Recife, Brazil",
  tags = list(amenity = c("school", "hospital", "pharmacy", "marketplace"))
)

# every building footprint (key present, any value)
ox_features_from_place("Olinda, Brazil", tags = list(building = TRUE))

# parks and green space
ox_features_from_place("Recife, Brazil", tags = list(leisure = "park"))

# public transit stops
ox_features_from_place("Recife, Brazil", tags = list(public_transport = "stop_position"))
```

## From a bounding box

When you already know the extent, query a bounding box
(`c(xmin, ymin, xmax, ymax)` in longitude/latitude) directly:

``` r

bbox <- c(-34.91, -8.07, -34.87, -8.04)
pois <- ox_features_from_bbox(bbox, tags = list(amenity = c("pharmacy", "clinic")))
pois
```

## A tidy result

Each call returns an `sf` of points with `osm_type`, `osm_id` and one
column per tag encountered, so it composes directly with `dplyr` and
`sf`:

``` r

library(dplyr)
pois |>
  st_drop_geometry() |>
  count(amenity, sort = TRUE)
```

## Combining features with a network

Features and the street network share the same CRS (EPSG:4326), so you
can snap facilities to the network and analyse access. This is the
bridge to the
[Accessibility](https://strategicprojects.github.io/osmnxr/articles/accessibility.md)
article:

``` r

g <- ox_graph_from_place("Olinda, Brazil", network_type = "walk") |>
  ox_simplify() |>
  ox_add_edge_travel_times()

schools <- ox_features_from_place("Olinda, Brazil", tags = list(amenity = "school"))
xy <- sf::st_coordinates(schools)
nodes <- ox_nearest_nodes(g, xy[, 1], xy[, 2])

# 15-minute walking catchment around every school
ox_isochrone(g, nodes, cutoffs = 900, weight = "travel_time")
```

## References

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*.
