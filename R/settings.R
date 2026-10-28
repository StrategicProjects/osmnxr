# Package-level settings and session cache -----------------------------------

# Mutable settings store (populated in .onLoad via default_settings()).
.osmnxr_settings <- new.env(parent = emptyenv())

# Session cache for downloaded responses, keyed with rlang::hash().
.osmnxr_cache <- new.env(parent = emptyenv())

# Session cache of structural edge indexes (see graph_edge_index() in
# osm_graph.R), keyed by a hash of the graph's node ids and edge endpoints.
.osmnxr_edge_index <- new.env(parent = emptyenv())

default_settings <- function() {
  list(
    overpass_url   = "https://overpass-api.de/api/interpreter",
    nominatim_url  = "https://nominatim.openstreetmap.org",
    user_agent     = "osmnxr R package (https://github.com/StrategicProjects/osmnxr)",
    timeout        = 180,
    max_tries      = 3,
    cache          = TRUE
  )
}

#' Get or set package settings
#'
#' Configure the Overpass and Nominatim endpoints, HTTP behaviour and caching
#' used by all `ox_*` download functions. Called with no arguments it returns
#' the current settings as a list; called with named arguments it updates them
#' and returns the previous values invisibly.
#'
#' @param ... Named settings to update. Recognised names: `overpass_url`,
#'   `nominatim_url`, `user_agent`, `timeout`, `max_tries`, `cache`.
#'
#' @details
#' `timeout` (seconds) applies both to the HTTP request and to the Overpass
#' server-side query timeout. `max_tries` is the total number of attempts per
#' request: transient failures — HTTP 429, 500, 502, 503, 504 and dropped
#' connections, which busy Overpass/Nominatim servers routinely return — are
#' retried with exponential backoff (honouring any `Retry-After` header)
#' before an error is raised. `cache` toggles the in-session response cache
#' (see [ox_clear_cache()]).
#'
#' @return A named list of settings (current values, or the previous values
#'   invisibly when updating).
#' @export
#'
#' @examples
#' ox_settings()
#' old <- ox_settings(timeout = 300)
#' ox_settings(timeout = old$timeout) # restore
ox_settings <- function(...) {
  updates <- rlang::list2(...)
  current <- as.list(.osmnxr_settings)
  if (length(updates) == 0) {
    return(current[names(default_settings())])
  }
  unknown <- setdiff(names(updates), names(default_settings()))
  if (length(unknown) > 0) {
    cli::cli_abort(c("Unknown setting{?s}: {.val {unknown}}."), call = NULL)
  }
  previous <- current[names(updates)]
  for (nm in names(updates)) assign(nm, updates[[nm]], envir = .osmnxr_settings)
  invisible(previous)
}

#' Clear the session cache
#'
#' Empties the in-memory cache of downloaded OpenStreetMap responses, and the
#' cache of routing edge indexes that makes repeated `ox_route_*()` /
#' `ox_shortest_path()` calls on the same graph fast. Both caches are rebuilt
#' transparently on demand; clearing them only frees memory.
#'
#' @return Invisibly `NULL`.
#' @export
#'
#' @examples
#' ox_clear_cache()
ox_clear_cache <- function() {
  rm(list = ls(.osmnxr_cache), envir = .osmnxr_cache)
  rm(list = ls(.osmnxr_edge_index, all.names = TRUE), envir = .osmnxr_edge_index)
  invisible(NULL)
}
