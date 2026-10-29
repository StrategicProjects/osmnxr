# Internal helpers ------------------------------------------------------------

# Build a configured httr2 request against `url`.
ox_request <- function(url) {
  httr2::request(url) |>
    httr2::req_user_agent(.osmnxr_settings$user_agent) |>
    httr2::req_timeout(.osmnxr_settings$timeout) |>
    httr2::req_retry(
      max_tries = .osmnxr_settings$max_tries,
      # Overpass/Nominatim also answer 500/502/504 when overloaded; httr2's
      # default only retries 429/503.
      is_transient = function(resp) {
        httr2::resp_status(resp) %in% c(429L, 500L, 502L, 503L, 504L)
      },
      retry_on_failure = TRUE
    )
}

# Perform a request and parse the JSON body, with optional session caching.
ox_fetch_json <- function(req) {
  key <- rlang::hash(list(req$url, req$body))
  if (isTRUE(.osmnxr_settings$cache) && rlang::env_has(.osmnxr_cache, key)) {
    return(rlang::env_get(.osmnxr_cache, key))
  }
  resp <- httr2::req_perform(req)
  out <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  if (isTRUE(.osmnxr_settings$cache)) rlang::env_poke(.osmnxr_cache, key, out)
  out
}

# Overpass way filter per network type, mirroring OSMnx 2.1's
# _get_network_filter() tag for tag: every way must have a highway tag, and
# the clauses then remove ways incompatible with the requested network.
network_filter <- function(network_type = c("drive", "drive_service", "walk",
                                            "bike", "all", "all_public")) {
  network_type <- rlang::arg_match(network_type)
  access <- '["access"!~"private"]'
  switch(network_type,
    # drivable public streets: no service roads, nothing tagged motor=no, no
    # non-service roads providing services (alleys, driveways, ...)
    drive = paste0(
      '["highway"]["area"!~"yes"]', access,
      '["highway"!~"abandoned|bridleway|bus_guideway|construction|corridor|',
      'cycleway|elevator|escalator|footway|no|path|pedestrian|planned|platform|',
      'proposed|raceway|razed|rest_area|service|services|steps|track"]',
      '["motor_vehicle"!~"no"]["motorcar"!~"no"]',
      '["service"!~"alley|driveway|emergency_access|parking|parking_aisle|private"]'
    ),
    # like drive, but service roads are allowed (minus parking etc.)
    drive_service = paste0(
      '["highway"]["area"!~"yes"]', access,
      '["highway"!~"abandoned|bridleway|bus_guideway|construction|corridor|',
      'cycleway|elevator|escalator|footway|no|path|pedestrian|planned|platform|',
      'proposed|raceway|razed|rest_area|services|steps|track"]',
      '["motor_vehicle"!~"no"]["motorcar"!~"no"]',
      '["service"!~"emergency_access|parking|parking_aisle|private"]'
    ),
    # walkable public ways: no cycle/motor ways, nothing tagged foot=no, and
    # no ways whose sidewalk is mapped as a separate way
    walk = paste0(
      '["highway"]["area"!~"yes"]', access,
      '["highway"!~"abandoned|bus_guideway|construction|cycleway|motor|no|planned|',
      'platform|proposed|raceway|razed|rest_area|services"]',
      '["foot"!~"no"]["service"!~"private"]',
      '["sidewalk"!~"separate"]["sidewalk:both"!~"separate"]',
      '["sidewalk:left"!~"separate"]["sidewalk:right"!~"separate"]'
    ),
    # bikeable public ways: no foot/motor ways, nothing tagged bicycle=no
    bike = paste0(
      '["highway"]["area"!~"yes"]', access,
      '["highway"!~"abandoned|bus_guideway|construction|corridor|elevator|',
      'escalator|footway|motor|no|planned|platform|proposed|raceway|razed|',
      'rest_area|services|steps"]',
      '["bicycle"!~"no"]["service"!~"private"]'
    ),
    # every public way currently in use
    all_public = paste0(
      '["highway"]["area"!~"yes"]', access,
      '["highway"!~"abandoned|construction|no|planned|platform|proposed|raceway|',
      'razed|rest_area|services"]',
      '["service"!~"private"]'
    ),
    # every way currently in use, private-access ones included
    all = paste0(
      '["highway"]["area"!~"yes"]',
      '["highway"!~"abandoned|construction|no|planned|platform|proposed|raceway|',
      'razed|rest_area|services"]'
    )
  )
}

# Haversine distance (metres) between two lon/lat points.
haversine <- function(lon1, lat1, lon2, lat2) {
  r <- 6371000
  p1 <- lat1 * pi / 180
  p2 <- lat2 * pi / 180
  dp <- (lat2 - lat1) * pi / 180
  dl <- (lon2 - lon1) * pi / 180
  a <- sin(dp / 2)^2 + cos(p1) * cos(p2) * sin(dl / 2)^2
  2 * r * asin(pmin(1, sqrt(a)))
}
