# Geocoding via Nominatim -----------------------------------------------------

#' Geocode a place or address
#'
#' Resolve a free-form query to coordinates and metadata using the
#' OpenStreetMap Nominatim service.
#'
#' @param query A character scalar, e.g. `"Recife, Brazil"`.
#' @param limit Maximum number of results. Default `1`.
#'
#' @return A [tibble][tibble::tibble] with columns `display_name`, `lat`,
#'   `lon`, `osm_type`, `osm_id` and `class`.
#' @export
#'
#' @examplesIf interactive()
#' ox_geocode("Recife, Brazil")
ox_geocode <- function(query, limit = 1) {
  rlang::check_required(query)
  req <- ox_request(paste0(.osmnxr_settings$nominatim_url, "/search")) |>
    httr2::req_url_query(q = query, format = "jsonv2", limit = limit,
                         polygon_geojson = 0)
  res <- ox_fetch_json(req)
  if (length(res) == 0) cli::cli_abort("No geocoding result for {.val {query}}.", call = NULL)
  purrr::map_dfr(res, function(r) {
    tibble::tibble(
      display_name = r$display_name %||% NA_character_,
      lat = as.numeric(r$lat),
      lon = as.numeric(r$lon),
      osm_type = r$osm_type %||% NA_character_,
      osm_id = as.numeric(r$osm_id %||% NA),
      class = r$category %||% r$class %||% NA_character_
    )
  })
}

#' Geocode a place to an `sf` boundary
#'
#' Like [ox_geocode()] but returns the place geometry (boundary polygon when
#' available, otherwise a point) as an `sf` object.
#'
#' @inheritParams ox_geocode
#'
#' @return An `sf` object (one row per result) in EPSG:4326.
#' @export
#'
#' @examplesIf interactive()
#' ox_geocode_to_sf("Recife, Brazil")
ox_geocode_to_sf <- function(query, limit = 1) {
  rlang::check_required(query)
  req <- ox_request(paste0(.osmnxr_settings$nominatim_url, "/search")) |>
    httr2::req_url_query(q = query, format = "geojson", limit = limit,
                         polygon_geojson = 1)
  resp <- httr2::req_perform(req)
  txt <- httr2::resp_body_string(resp)
  sf::st_read(txt, quiet = TRUE)
}
