# Package-level settings and session cache -----------------------------------

# Mutable settings store (populated in .onLoad via default_settings()).
.osmnxr_settings <- new.env(parent = emptyenv())

# Session cache for downloaded responses, keyed with rlang::hash().
.osmnxr_cache <- new.env(parent = emptyenv())

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
#' Empties the in-memory cache of downloaded OpenStreetMap responses.
#'
#' @return Invisibly `NULL`.
#' @export
#'
#' @examples
#' ox_clear_cache()
ox_clear_cache <- function() {
  rm(list = ls(.osmnxr_cache), envir = .osmnxr_cache)
  invisible(NULL)
}
