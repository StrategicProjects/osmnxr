# Blend points or another graph into a street network

Snaps point locations onto their nearest network edge and splits that
edge there, turning each snapped location into a routable node — the
`osmnxr` counterpart of
[`sfnetworks::st_network_blend()`](https://luukvdmeer.github.io/sfnetworks/reference/st_network_blend.html),
with the snapping done in the Rust core (grid-indexed planar distance)
so city-sized networks blend in seconds.

## Usage

``` r
ox_blend(g, y, tolerance = Inf, connector_attrs = list())
```

## Arguments

- g:

  An
  [osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md)
  to blend into.

- y:

  What to blend: an `sf`/`sfc` of `POINT` geometries, or another
  `osm_graph` (same CRS as `g`). Attribute columns of an `sf` `y` are
  carried onto the new nodes they create.

- tolerance:

  Maximum snapping distance, in CRS units. Points (or `y` nodes) farther
  than this from every edge of `g` are not blended. Default `Inf`.

- connector_attrs:

  Named list of constant attribute values for the connector edges
  created in graph mode (e.g.
  `list(highway = "connector", travel_time = 60)`). Columns the
  connectors do not set are `NA`-filled — in particular, set
  `travel_time` here (or fix it afterwards) before routing the blended
  graph on travel time. Ignored when `y` is a set of points.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).
`meta$blend` records the mapping as a
[tibble](https://tibble.tidyverse.org/reference/tibble.html): one row
per input point (or `y` node), with the node `osmid` it became or
attached to (`NA` when beyond `tolerance`) and the snapping distance.

## Details

Two-way streets are handled properly: every edge sharing the split
edge's geometry (its reversed twin, or a same-direction duplicate) is
split at the same location into the same new node, so routability is
preserved in both directions. Points that project onto an existing node
are attached to that node instead of splitting. Points farther than
`tolerance` from every edge are left out with a warning.

When `y` is another
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md),
the result is a combined multimodal network, built in three steps (as
proposed in the issue that motivated this feature): (1) every node of
`y` (within `tolerance`) is blended into `g` as above; (2) the two
graphs are stacked with
[`ox_union()`](https://strategicprojects.github.io/osmnxr/reference/ox_union.md),
so `y`'s own nodes and edges are kept intact; (3) a pair of directed
*connector* edges is added between each `y` node and the node it snapped
to, which is the connectivity a plain blend + union would miss. Node
`osmid`s shared by both graphs are merged by the union directly (no
connector needed). The union here does not deduplicate edges (the two
layers are assumed to be distinct networks); combine overlapping
downloads with
[`ox_union()`](https://strategicprojects.github.io/osmnxr/reference/ox_union.md)
first when that matters.

Distances are planar, in the units of the graph's CRS (reproject
geographic networks first —
[`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
on `nodes` and `edges` — when a metric `tolerance` matters). Split edges
keep their attributes; `length` is recomputed from the new geometries,
and `travel_time` / `penalty` (when present) are rescaled proportionally
to each piece's share of the parent edge, so routing weights stay
consistent.

## Examples

``` r
g <- example_osm_graph()

# blend two POIs into the grid: each becomes a routable node
pts <- sf::st_sfc(sf::st_point(c(150, 40)), sf::st_point(c(250, 260)),
                  crs = 3857)
b <- ox_blend(g, pts)
b$meta$blend
#> # A tibble: 2 × 3
#>   point  node  dist
#>   <int> <dbl> <dbl>
#> 1     1    17    40
#> 2     2    18    40
ox_shortest_path(b, b$meta$blend$node[1], b$meta$blend$node[2])
#> [1] 17  9 10 11 12 18

# blend a tiny second network (e.g. a metro line) into the grid
metro <- new_osm_graph(
  sf::st_sf(osmid = c(1001, 1002),
            geometry = sf::st_sfc(sf::st_point(c(40, 150)),
                                  sf::st_point(c(260, 150)), crs = 3857)),
  sf::st_sf(u = 1001, v = 1002, length = 220,
            geometry = sf::st_sfc(sf::st_linestring(
              rbind(c(40, 150), c(260, 150))), crs = 3857)),
  meta = list(network_type = "metro")
)
mm <- ox_blend(g, metro, connector_attrs = list(highway = "connector"))
mm
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 20 nodes, 57 edges
#> Network type: "drive+metro"
#> Simplified: FALSE
#> CRS: "EPSG:3857"
```
