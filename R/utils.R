# Internal helpers ------------------------------------------------------------

# Build a configured httr2 request against `url`.
ox_request <- function(url) {
  httr2::request(url) |>
    httr2::req_user_agent(.osmnxr_settings$user_agent) |>
    httr2::req_timeout(.osmnxr_settings$timeout) |>
    httr2::req_retry(max_tries = .osmnxr_settings$max_tries)
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

# Highway-tag filters per network type (subset of OSMnx's filters).
network_filter <- function(network_type = c("drive", "walk", "bike", "all")) {
  network_type <- rlang::arg_match(network_type)
  switch(network_type,
    drive = "motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link",
    walk  = "footway|path|pedestrian|steps|living_street|residential|service|unclassified|tertiary|secondary|primary|track",
    bike  = "cycleway|path|footway|living_street|residential|service|unclassified|tertiary|secondary|primary|track",
    all   = ".*"
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
