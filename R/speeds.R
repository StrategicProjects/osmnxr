# Edge speeds and travel times ------------------------------------------------

# Default free-flow speeds (km/h) by OSM highway class.
default_speeds <- function() {
  c(
    motorway = 100, motorway_link = 60,
    trunk = 80, trunk_link = 50,
    primary = 60, primary_link = 40,
    secondary = 50, secondary_link = 40,
    tertiary = 40, tertiary_link = 30,
    unclassified = 40, residential = 30, living_street = 10,
    service = 20, track = 20,
    footway = 5, path = 5, pedestrian = 5, steps = 2,
    cycleway = 15
  )
}

#' Add edge speeds
#'
#' Assigns a free-flow speed (km/h) to every edge based on its `highway` class,
#' adding a `speed_kph` column. Unknown classes get `fallback`.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param speeds Optional named numeric vector of `highway = kph` overrides,
#'   merged over the built-in defaults.
#' @param fallback Speed (km/h) for edges with no matching class. Default `40`.
#'
#' @return The [osm_graph][new_osm_graph] with a `speed_kph` edge column.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' g <- ox_add_edge_speeds(g, speeds = c(residential = 25))
#' head(g$edges$speed_kph)
ox_add_edge_speeds <- function(g, speeds = NULL, fallback = 40) {
  stopifnot(is_osm_graph(g))
  tbl <- default_speeds()
  if (!is.null(speeds)) tbl[names(speeds)] <- speeds
  hw <- if ("highway" %in% names(g$edges)) as.character(g$edges$highway) else rep(NA_character_, nrow(g$edges))
  sp <- unname(tbl[hw])
  sp[is.na(sp)] <- fallback
  g$edges$speed_kph <- sp
  g
}

#' Add edge travel times
#'
#' Adds a `travel_time` edge column (in seconds) from edge `length` (metres) and
#' `speed_kph`. Speeds are added with [ox_add_edge_speeds()] first if missing.
#' The resulting column can be used as a routing `weight` for time-based
#' shortest paths and isochrones.
#'
#' @param g An [osm_graph][new_osm_graph].
#'
#' @return The [osm_graph][new_osm_graph] with `speed_kph` and `travel_time`
#'   edge columns.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' g <- ox_add_edge_travel_times(g)
#' from <- ox_nearest_nodes(g, 0, 0)
#' to <- ox_nearest_nodes(g, 300, 300)
#' ox_shortest_path(g, from, to, weight = "travel_time")
ox_add_edge_travel_times <- function(g) {
  stopifnot(is_osm_graph(g))
  if (!"speed_kph" %in% names(g$edges)) g <- ox_add_edge_speeds(g)
  g$edges$travel_time <- as.numeric(g$edges$length) / (g$edges$speed_kph / 3.6)
  g
}
