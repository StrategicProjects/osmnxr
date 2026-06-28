# Download street networks from OpenStreetMap ---------------------------------

#' Download a street network within a bounding box
#'
#' @param bbox Numeric vector `c(xmin, ymin, xmax, ymax)` in longitude/latitude
#'   (EPSG:4326).
#' @param network_type One of `"drive"`, `"walk"`, `"bike"` or `"all"`.
#'
#' @return An [osm_graph][new_osm_graph].
#' @export
#'
#' @examplesIf interactive()
#' bbox <- c(-34.91, -8.07, -34.87, -8.04)
#' g <- ox_graph_from_bbox(bbox, network_type = "drive")
ox_graph_from_bbox <- function(bbox, network_type = "drive") {
  if (length(bbox) != 4) cli::cli_abort("{.arg bbox} must have length 4 (xmin, ymin, xmax, ymax).", call = NULL)
  cli::cli_progress_step("Querying Overpass for {.val {network_type}} network")
  res <- ox_overpass(overpass_bbox_query(bbox, network_type))
  cli::cli_progress_step("Building graph")
  overpass_to_graph(res, network_type, query = paste0("bbox: ", paste(bbox, collapse = ",")))
}

#' Download a street network around a point
#'
#' @param point Numeric `c(lon, lat)`.
#' @param dist Buffer half-width in metres (a square bounding box of side
#'   `2 * dist` is used). Default `1000`.
#' @inheritParams ox_graph_from_bbox
#'
#' @return An [osm_graph][new_osm_graph].
#' @export
#'
#' @examplesIf interactive()
#' g <- ox_graph_from_point(c(-34.89, -8.05), dist = 800)
ox_graph_from_point <- function(point, dist = 1000, network_type = "drive") {
  if (length(point) != 2) cli::cli_abort("{.arg point} must be {.code c(lon, lat)}.", call = NULL)
  dlat <- dist / 111320
  dlon <- dist / (111320 * cos(point[2] * pi / 180))
  bbox <- c(point[1] - dlon, point[2] - dlat, point[1] + dlon, point[2] + dlat)
  ox_graph_from_bbox(bbox, network_type)
}

#' Download a street network for a named place
#'
#' Geocodes `query` with [ox_geocode()] and downloads the street network within
#' the bounding box of the matched place.
#'
#' @param query A place name, e.g. `"Recife, Brazil"`.
#' @inheritParams ox_graph_from_bbox
#'
#' @return An [osm_graph][new_osm_graph].
#' @export
#'
#' @examplesIf interactive()
#' g <- ox_graph_from_place("Olinda, Brazil", network_type = "drive")
ox_graph_from_place <- function(query, network_type = "drive") {
  geo <- ox_geocode(query, limit = 1)
  # approximate place bbox via a point buffer; refine with polygon in future
  g <- ox_graph_from_point(c(geo$lon[1], geo$lat[1]), dist = 2000, network_type)
  g$meta$query <- query
  g
}

#' Download a street network around an address
#'
#' @param address A street address.
#' @param dist Buffer half-width in metres. Default `1000`.
#' @inheritParams ox_graph_from_bbox
#'
#' @return An [osm_graph][new_osm_graph].
#' @export
#'
#' @examplesIf interactive()
#' g <- ox_graph_from_address("Marco Zero, Recife", dist = 600)
ox_graph_from_address <- function(address, dist = 1000, network_type = "drive") {
  geo <- ox_geocode(address, limit = 1)
  g <- ox_graph_from_point(c(geo$lon[1], geo$lat[1]), dist = dist, network_type)
  g$meta$query <- address
  g
}
