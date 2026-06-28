# Accessibility analysis

``` r

library(osmnxr)
```

This article walks through the kind of analysis `osmnxr` is built for:
who can reach a service, and how quickly. It underpins studies of urban
mobility, green mobility (“Fluxo Verde”), and access to schools and
hospitals. We use the offline grid so it runs anywhere; on a real city
the steps are identical.

``` r

g <- example_osm_graph(n = 10, spacing = 100)
g <- ox_add_edge_travel_times(g)
```

## Travel-time isochrones from a facility

Suppose a hospital sits near the centre of the area. The set of
locations reachable within a time budget is its **isochrone**. With
`travel_time` as the weight, cutoffs are in seconds:

``` r

hospital <- ox_nearest_nodes(g, x = 450, y = 450)
iso <- ox_isochrone(g, hospital, cutoffs = c(60, 120), weight = "travel_time")
iso[c("cutoff", "n_nodes")]
#> Simple feature collection with 2 features and 2 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 0 ymin: 0 xmax: 900 ymax: 900
#> Projected CRS: WGS 84 / Pseudo-Mercator
#>   cutoff n_nodes                       geometry
#> 1    120     100 POLYGON ((0 800, 0 900, 100...
#> 2     60      59 POLYGON ((100 400, 0 400, 1...
```

``` r

plot(g, col = "grey85")
plot(sf::st_geometry(iso), add = TRUE, border = NA,
     col = grDevices::adjustcolor(c("#0d3b66", "#2a9d8f"), 0.4))
```

![](accessibility_files/figure-html/unnamed-chunk-4-1.png)

The polygons are nested service areas: everything in the inner polygon
is within one minute of the hospital, the outer within two.

## Distance from many origins to many destinations

To measure how far a set of “schools” is from a set of “homes”, use a
distance matrix. Here every cell is travel time in seconds:

``` r

homes   <- ox_nearest_nodes(g, x = c(0, 900, 0),   y = c(0, 0, 900))
schools <- ox_nearest_nodes(g, x = c(450, 100),    y = c(450, 800))
m <- ox_distance_matrix(g, from = homes, to = schools, weight = "travel_time")
round(m)
#>     55  19
#> 1  108 108
#> 91  96 192
#> 10 120  24
```

The nearest school for each home is the row minimum:

``` r

apply(m, 1, min)
#>   1  91  10 
#> 108  96  24
```

## Putting it together on real data

With network access, the same pipeline runs on a city and its real
facilities:

``` r

g <- ox_graph_from_place("Olinda, Brazil", network_type = "drive") |>
  ox_simplify() |>
  ox_add_edge_travel_times()

hospitals <- ox_features_from_place("Olinda, Brazil", tags = list(amenity = "hospital"))
xy <- sf::st_coordinates(hospitals)
origins <- ox_nearest_nodes(g, xy[, 1], xy[, 2])

# 10- and 20-minute service areas across all hospitals
ox_isochrone(g, origins, cutoffs = c(600, 1200), weight = "travel_time")
```

That polygon set is the basis for equity analysis: overlay population
and you can quantify how many people fall outside a 20-minute reach —
the core question in accessibility and territorial planning.
