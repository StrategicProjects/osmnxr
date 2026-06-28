# Download geospatial features (POIs, buildings, ...) -------------------------

# Build an Overpass query selecting elements matching `tags` within `bbox`.
# `tags` is a named list: each value is TRUE/NA (key present, any value) or a
# character vector of allowed values.
overpass_features_query <- function(bbox, tags) {
  bb <- sprintf("%.7f,%.7f,%.7f,%.7f", bbox[2], bbox[1], bbox[4], bbox[3])
  parts <- character(0)
  for (k in names(tags)) {
    vals <- tags[[k]]
    filt <- if (isTRUE(vals) || (length(vals) == 1 && is.na(vals))) {
      sprintf('["%s"]', k)
    } else {
      sprintf('["%s"~"^(%s)$"]', k, paste(vals, collapse = "|"))
    }
    for (typ in c("node", "way", "relation")) {
      parts <- c(parts, sprintf("  %s%s(%s);", typ, filt, bb))
    }
  }
  paste0(
    sprintf("[out:json][timeout:%d];\n", .osmnxr_settings$timeout),
    "(\n", paste(parts, collapse = "\n"), "\n);\n",
    "out center tags;"
  )
}

# Convert an Overpass feature response to an sf of points (nodes use their
# coordinate, ways/relations use their centroid via `out center`).
features_to_sf <- function(res) {
  els <- res$elements
  if (length(els) == 0) cli::cli_abort("Overpass returned no features.", call = NULL)
  rows <- lapply(els, function(e) {
    lon <- e$lon %||% e$center$lon
    lat <- e$lat %||% e$center$lat
    base <- list(osm_type = e$type, osm_id = as.numeric(e$id),
                 lon = lon, lat = lat)
    c(base, e$tags %||% list())
  })
  allk <- unique(unlist(lapply(rows, names)))
  mat <- do.call(rbind, lapply(rows, function(r) {
    v <- stats::setNames(rep(NA_character_, length(allk)), allk)
    for (n in names(r)) v[n] <- as.character(r[[n]])
    v
  }))
  df <- as.data.frame(mat, stringsAsFactors = FALSE)
  df$lon <- as.numeric(df$lon)
  df$lat <- as.numeric(df$lat)
  df <- df[!is.na(df$lon) & !is.na(df$lat), , drop = FALSE]
  if (nrow(df) == 0) cli::cli_abort("No features with coordinates found.", call = NULL)
  sf::st_as_sf(df, coords = c("lon", "lat"), crs = 4326)
}

#' Download features within a bounding box
#'
#' Queries OpenStreetMap (via Overpass) for elements matching `tags` — points of
#' interest, amenities, buildings, transit stops, and so on — returning them as
#' an `sf` of points (ways and relations are represented by their centroid).
#'
#' @param bbox Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.
#' @param tags Named list of OSM tag filters. Each element is either `TRUE`
#'   (key present with any value) or a character vector of allowed values, e.g.
#'   `list(amenity = c("school", "hospital"))`.
#'
#' @return An `sf` of `POINT` features with `osm_type`, `osm_id` and one column
#'   per tag encountered.
#' @export
#'
#' @examplesIf interactive()
#' bbox <- c(-34.91, -8.07, -34.87, -8.04)
#' ox_features_from_bbox(bbox, tags = list(amenity = "school"))
ox_features_from_bbox <- function(bbox, tags) {
  if (length(bbox) != 4) cli::cli_abort("{.arg bbox} must have length 4.", call = NULL)
  if (!is.list(tags) || is.null(names(tags))) {
    cli::cli_abort("{.arg tags} must be a named list, e.g. {.code list(amenity = \"school\")}.", call = NULL)
  }
  cli::cli_progress_step("Querying Overpass for features")
  res <- ox_overpass(overpass_features_query(bbox, tags))
  features_to_sf(res)
}

#' Download features for a named place
#'
#' Geocodes `query` with [ox_geocode()] and downloads matching features around
#' it. See [ox_features_from_bbox()] for the `tags` format.
#'
#' @param query A place name, e.g. `"Recife, Brazil"`.
#' @param tags Named list of OSM tag filters.
#' @param dist Search half-width in metres around the geocoded point. Default
#'   `2000`.
#'
#' @return An `sf` of `POINT` features.
#' @export
#'
#' @examplesIf interactive()
#' ox_features_from_place("Olinda, Brazil", tags = list(amenity = "hospital"))
ox_features_from_place <- function(query, tags, dist = 2000) {
  geo <- ox_geocode(query, limit = 1)
  dlat <- dist / 111320
  dlon <- dist / (111320 * cos(geo$lat[1] * pi / 180))
  bbox <- c(geo$lon[1] - dlon, geo$lat[1] - dlat, geo$lon[1] + dlon, geo$lat[1] + dlat)
  ox_features_from_bbox(bbox, tags)
}
