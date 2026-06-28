# Network metrics (Rust-backed) ----------------------------------------------

#' Basic street-network statistics
#'
#' Summary measures for an `osm_graph`: node and edge counts, total and mean
#' edge length, mean out-degree, self-loop count and average circuity.
#' Computation is performed by the bundled Rust core.
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param weight Edge column used as length/weight. Default `"length"`.
#'
#' @return A one-row [tibble][tibble::tibble] of statistics.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_basic_stats(g)
ox_basic_stats <- function(g, weight = "length") {
  stopifnot(is_osm_graph(g))
  ea <- graph_edge_arrays(g, weight)
  s <- rs_basic_stats(ea$from, ea$to, ea$weight, ea$n_nodes)
  out <- tibble::as_tibble(s)
  out$circuity <- ox_circuity(g)
  out
}

# Resolve `x` to a numeric bearings vector: an osm_graph -> ox_bearings(x);
# a numeric vector -> itself.
as_bearings <- function(x) {
  if (is_osm_graph(x)) return(ox_bearings(x))
  if (is.numeric(x)) return(x)
  cli::cli_abort("Expected an {.cls osm_graph} or a numeric bearings vector.", call = NULL)
}

#' Street-orientation entropy
#'
#' Shannon entropy (in nats) of the distribution of edge compass bearings,
#' binned into equal sectors. Higher values indicate a more disordered
#' (organic) network; lower values a more ordered (gridiron) one.
#'
#' @param x An [osm_graph][new_osm_graph] or a numeric vector of bearings
#'   (degrees), e.g. from [ox_bearings()].
#' @param num_bins Number of equal bearing sectors over `[0, 360)`. Default `36`.
#'
#' @return A numeric scalar (entropy in nats).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_orientation_entropy(g)
ox_orientation_entropy <- function(x, num_bins = 36) {
  rs_orientation_entropy(as_bearings(x), as.integer(num_bins))
}

#' Compute edge compass bearings
#'
#' Initial compass bearing (degrees clockwise from north) of each edge, from
#' its first to its last coordinate. Geographic coordinates are used; projected
#' graphs are transformed to EPSG:4326 first.
#'
#' @param g An [osm_graph][new_osm_graph].
#'
#' @return A numeric vector of bearings, one per edge.
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' head(ox_bearings(g))
ox_bearings <- function(g) {
  stopifnot(is_osm_graph(g))
  edges <- g$edges
  if (!is.na(sf::st_crs(edges)) && sf::st_crs(edges) != sf::st_crs(4326)) {
    edges <- sf::st_transform(edges, 4326)
  }
  ends <- lapply(sf::st_geometry(edges), function(ls) {
    m <- sf::st_coordinates(ls)
    c(m[1, "X"], m[1, "Y"], m[nrow(m), "X"], m[nrow(m), "Y"])
  })
  ends <- do.call(rbind, ends)
  rs_bearings(ends[, 2], ends[, 1], ends[, 4], ends[, 3])
}

#' Polar plot of street orientations
#'
#' Draws a polar histogram (rose plot) of edge compass bearings, the standard
#' visual summary of a street network's orientation order. Requires `ggplot2`.
#'
#' @param x An [osm_graph][new_osm_graph] or a numeric vector of bearings
#'   (degrees), e.g. from [ox_bearings()].
#' @param num_bins Number of equal bearing sectors. Default `36`.
#' @param fill Bar fill colour. Default the package blue.
#' @param title Optional plot title.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examplesIf rlang::is_installed("ggplot2")
#' g <- example_osm_graph()
#' ox_plot_orientation(g)
ox_plot_orientation <- function(x, num_bins = 36, fill = "#0d3b66", title = "Street orientation") {
  rlang::check_installed("ggplot2")
  b <- as_bearings(x)
  bw <- 360 / num_bins
  idx <- floor((b %% 360) / bw)
  idx[idx >= num_bins] <- num_bins - 1
  centers <- (idx + 0.5) * bw
  levels <- (seq_len(num_bins) - 0.5) * bw
  counts <- as.data.frame(table(factor(centers, levels = levels)))
  names(counts) <- c("bearing", "count")
  counts$bearing <- as.numeric(as.character(counts$bearing))

  ggplot2::ggplot(counts, ggplot2::aes(x = .data$bearing, y = .data$count)) +
    ggplot2::geom_col(width = bw, fill = fill, colour = "white", linewidth = 0.2) +
    ggplot2::coord_polar(start = 0) +
    ggplot2::scale_x_continuous(
      limits = c(0, 360),
      breaks = seq(0, 315, 45),
      labels = c("N", "NE", "E", "SE", "S", "SW", "W", "NW")
    ) +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    ggplot2::theme_minimal()
}

#' Node centrality
#'
#' Computes betweenness and/or closeness centrality for every node, using the
#' Rust core (Brandes' algorithm for betweenness; one Dijkstra per node for
#' closeness).
#'
#' @param g An [osm_graph][new_osm_graph].
#' @param type Centrality measures to compute: any of `"betweenness"` and
#'   `"closeness"`. Default both.
#' @param weight Edge column used as weight. Default `"length"`.
#' @param normalized Scale scores for comparability across graphs. Betweenness
#'   is divided by `(n - 1)(n - 2)`; closeness uses the Wasserman--Faust
#'   correction for disconnected graphs. Default `TRUE`.
#'
#' @return A [tibble][tibble::tibble] with column `osmid` plus one column per
#'   requested measure.
#' @export
#'
#' @examples
#' g <- example_osm_graph(n = 4)
#' ox_centrality(g, type = "betweenness")
ox_centrality <- function(g, type = c("betweenness", "closeness"),
                          weight = "length", normalized = TRUE) {
  stopifnot(is_osm_graph(g))
  type <- match.arg(type, c("betweenness", "closeness"), several.ok = TRUE)
  ea <- graph_edge_arrays(g, weight)
  out <- tibble::tibble(osmid = ea$node_ids)
  if ("betweenness" %in% type) {
    out$betweenness <- rs_betweenness(ea$from, ea$to, ea$weight, ea$n_nodes, normalized)
  }
  if ("closeness" %in% type) {
    out$closeness <- rs_closeness(ea$from, ea$to, ea$weight, ea$n_nodes, normalized)
  }
  out
}

#' Average network circuity
#'
#' The ratio of total edge length to total straight-line (great-circle for
#' geographic CRS, Euclidean for projected) distance between edge endpoints. A
#' value of `1` means perfectly straight streets; higher values indicate more
#' winding networks.
#'
#' @param g An [osm_graph][new_osm_graph].
#'
#' @return A numeric scalar (>= 1).
#' @export
#'
#' @examples
#' g <- example_osm_graph()
#' ox_circuity(g)
ox_circuity <- function(g) {
  stopifnot(is_osm_graph(g))
  ids <- g$nodes$osmid
  xy <- sf::st_coordinates(g$nodes)
  ui <- match(g$edges$u, ids)
  vi <- match(g$edges$v, ids)
  if (isTRUE(sf::st_is_longlat(g$nodes))) {
    sld <- haversine(xy[ui, 1], xy[ui, 2], xy[vi, 1], xy[vi, 2])
  } else {
    sld <- sqrt((xy[ui, 1] - xy[vi, 1])^2 + (xy[ui, 2] - xy[vi, 2])^2)
  }
  total_sld <- sum(sld)
  if (total_sld == 0) return(NA_real_)
  sum(as.numeric(g$edges$length)) / total_sld
}
