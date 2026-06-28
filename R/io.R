# Export and persistence ------------------------------------------------------

#' Export to GeoJSON
#'
#' Writes the graph's edges (or nodes) to a GeoJSON file via [sf::st_write()].
#' Geometry is transformed to EPSG:4326, the GeoJSON standard CRS.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param path Output file path.
#' @param layer Which layer to write: `"edges"` (default) or `"nodes"`.
#'
#' @return `path`, invisibly.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_to_geojson(g, tempfile(fileext = ".geojson"))
ox_to_geojson <- function(g, path, layer = c("edges", "nodes")) {
  stopifnot(is_osm_graph(g))
  layer <- match.arg(layer)
  obj <- if (layer == "edges") g$edges else g$nodes
  if (!is.na(sf::st_crs(obj))) obj <- sf::st_transform(obj, 4326)
  sf::st_write(obj, path, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
  invisible(path)
}

#' Build a MapLibre GL style fragment
#'
#' Writes the edges to a GeoJSON file and returns a MapLibre GL JS style
#' fragment (a list with `sources` and `layers`) that references it, ready to
#' merge into a map style. Serialize with, e.g., `jsonlite::toJSON(...,
#' auto_unbox = TRUE)`.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param path GeoJSON output path for the edge data.
#' @param source_id,layer_id Identifiers for the MapLibre source and layer.
#' @param url URL the style should use to fetch the data. Defaults to
#'   `basename(path)`.
#'
#' @return A named list with `sources` and `layers`, invisibly written data to
#'   `path`.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' style <- ox_to_maplibre(g, tempfile(fileext = ".geojson"))
#' names(style)
ox_to_maplibre <- function(g, path, source_id = "osmnxr", layer_id = "streets",
                           url = basename(path)) {
  stopifnot(is_osm_graph(g))
  ox_to_geojson(g, path, layer = "edges")
  sources <- stats::setNames(list(list(type = "geojson", data = url)), source_id)
  layers <- list(list(
    id = layer_id, type = "line", source = source_id,
    paint = list(`line-color` = "#0d3b66", `line-width` = 1.2)
  ))
  list(sources = sources, layers = layers)
}

# Minimal XML attribute/text escaping.
xml_escape <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

#' Save a graph to GraphML
#'
#' Writes the graph to a GraphML file compatible with OSMnx / NetworkX / Gephi.
#' Edge geometry is preserved losslessly as a WKT attribute, so the graph
#' round-trips through [ox_load_graphml()].
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param path Output `.graphml` path.
#'
#' @return `path`, invisibly.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' f <- tempfile(fileext = ".graphml")
#' ox_save_graphml(g, f)
ox_save_graphml <- function(g, path) {
  stopifnot(is_osm_graph(g))
  nodes <- g$nodes
  edges <- g$edges
  xy <- sf::st_coordinates(nodes)
  crs_wkt <- sf::st_crs(nodes)$wkt %||% ""
  geom_wkt <- sf::st_as_text(sf::st_geometry(edges))

  keys <- c(
    '<key id="d_crs" for="graph" attr.name="crs" attr.type="string"/>',
    '<key id="d_osmid" for="node" attr.name="osmid" attr.type="string"/>',
    '<key id="d_x" for="node" attr.name="x" attr.type="double"/>',
    '<key id="d_y" for="node" attr.name="y" attr.type="double"/>',
    '<key id="d_u" for="edge" attr.name="u" attr.type="string"/>',
    '<key id="d_v" for="edge" attr.name="v" attr.type="string"/>',
    '<key id="d_length" for="edge" attr.name="length" attr.type="double"/>',
    '<key id="d_highway" for="edge" attr.name="highway" attr.type="string"/>',
    '<key id="d_name" for="edge" attr.name="name" attr.type="string"/>',
    '<key id="d_geom" for="edge" attr.name="geometry" attr.type="string"/>'
  )

  node_lines <- sprintf(
    '<node id="n%s"><data key="d_osmid">%s</data><data key="d_x">%.10g</data><data key="d_y">%.10g</data></node>',
    xml_escape(nodes$osmid), xml_escape(nodes$osmid), xy[, 1], xy[, 2]
  )

  hw <- if ("highway" %in% names(edges)) edges$highway else NA
  nm <- if ("name" %in% names(edges)) edges$name else NA
  edge_lines <- sprintf(
    paste0('<edge source="n%s" target="n%s">',
           '<data key="d_u">%s</data><data key="d_v">%s</data>',
           '<data key="d_length">%.10g</data>',
           '<data key="d_highway">%s</data><data key="d_name">%s</data>',
           '<data key="d_geom">%s</data></edge>'),
    xml_escape(edges$u), xml_escape(edges$v),
    xml_escape(edges$u), xml_escape(edges$v),
    as.numeric(edges$length),
    xml_escape(hw), xml_escape(nm), xml_escape(geom_wkt)
  )

  body <- c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<graphml xmlns="http://graphml.graphdrawing.org/xmlns">',
    keys,
    '<graph edgedefault="directed">',
    sprintf('<data key="d_crs">%s</data>', xml_escape(crs_wkt)),
    node_lines,
    edge_lines,
    '</graph>',
    '</graphml>'
  )
  writeLines(body, path, useBytes = TRUE)
  invisible(path)
}

#' Load a graph from GraphML
#'
#' Reads a GraphML file written by [ox_save_graphml()] back into an
#' [osm_graph][new_osm_graph], restoring node coordinates, edge attributes and
#' edge geometry (from the stored WKT).
#'
#' @param path Path to a `.graphml` file.
#'
#' @return An [osm_graph][new_osm_graph].
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' f <- tempfile(fileext = ".graphml")
#' ox_save_graphml(g, f)
#' ox_load_graphml(f)
ox_load_graphml <- function(path) {
  rlang::check_installed("xml2")
  doc <- xml2::read_xml(path)
  xml2::xml_ns_strip(doc)

  data_map <- function(x) {
    ds <- xml2::xml_find_all(x, "./data")
    stats::setNames(xml2::xml_text(ds), xml2::xml_attr(ds, "key"))
  }

  gdata <- data_map(xml2::xml_find_first(doc, ".//graph"))
  crs_wkt <- unname(gdata["d_crs"])
  crs <- if (is.na(crs_wkt) || crs_wkt == "") sf::NA_crs_ else sf::st_crs(crs_wkt)

  nodes_xml <- xml2::xml_find_all(doc, ".//node")
  nd <- lapply(nodes_xml, data_map)
  osmid <- vapply(nd, function(d) suppressWarnings(as.numeric(d["d_osmid"])), numeric(1))
  nx <- vapply(nd, function(d) as.numeric(d["d_x"]), numeric(1))
  ny <- vapply(nd, function(d) as.numeric(d["d_y"]), numeric(1))
  nodes <- sf::st_as_sf(
    data.frame(osmid = osmid, x = nx, y = ny),
    coords = c("x", "y"), crs = crs, remove = FALSE
  )

  edges_xml <- xml2::xml_find_all(doc, ".//edge")
  ed <- lapply(edges_xml, data_map)
  pull <- function(key, fun = identity) vapply(ed, function(d) fun(unname(d[key])), character(1))
  u <- as.numeric(pull("d_u"))
  v <- as.numeric(pull("d_v"))
  geom <- sf::st_as_sfc(pull("d_geom"), crs = crs)
  edges <- sf::st_sf(
    u = u, v = v,
    length = as.numeric(pull("d_length")),
    highway = pull("d_highway"),
    name = pull("d_name"),
    geometry = geom
  )

  new_osm_graph(nodes, edges, meta = list(source = "graphml"))
}
