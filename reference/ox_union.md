# Union of `osm_graph` objects

Combines two or more graphs into a single
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).
Node and edge tables are stacked; nodes sharing an `osmid` are merged
(the first occurrence wins) and edges duplicated across graphs are
dropped. Attribute columns present in one graph but not another are
filled with `NA`.

## Usage

``` r
ox_union(..., dedupe_edges = TRUE)
```

## Arguments

- ...:

  Two or more `osm_graph` objects, or a single list of them. All must
  share the same CRS.

- dedupe_edges:

  Drop edges that appear in more than one graph with identical `u`, `v`
  and geometry (as happens when unioning overlapping downloads). Default
  `TRUE`.

## Value

An
[osm_graph](https://strategicprojects.github.io/osmnxr/reference/new_osm_graph.md).
`meta$network_type` concatenates the distinct input types (e.g.
`"drive+walk"`), `meta$simplified` is `TRUE` only if every input was
simplified, and `meta$union_of` records how many graphs were combined.

## Details

Nodes with the same `osmid` are treated as the same location, which is
what stitches the graphs together: overlapping downloads share their OSM
node ids, and a hand-built network (say, a metro layer) connects to a
street graph wherever its edges reference street-node `osmid`s. Custom
networks should therefore use node ids that do not collide with OSM's
except where a connection is intended (negative ids are a safe choice).

## Examples

``` r
g1 <- example_osm_graph(n = 3)

# a second, disjoint network with its own node ids
g2 <- example_osm_graph(n = 3)
g2$nodes$osmid <- g2$nodes$osmid + 1000
g2$edges$u <- g2$edges$u + 1000
g2$edges$v <- g2$edges$v + 1000

u <- ox_union(g1, g2)
u
#> 
#> ── osm_graph ───────────────────────────────────────────────────────────────────
#> 18 nodes, 48 edges
#> Network type: "drive"
#> Simplified: TRUE
#> CRS: "EPSG:3857"

# unioning overlapping graphs dedupes shared nodes and edges
nrow(ox_union(g1, g1)$edges) == nrow(g1$edges)
#> [1] TRUE
```
