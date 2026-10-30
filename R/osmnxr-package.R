#' osmnxr: OpenStreetMap street networks for R
#'
#' A tidyverse-friendly toolkit to download, model, simplify, analyze and
#' visualize street networks and other geospatial features from
#' OpenStreetMap. The design follows Geoff Boeing's OSMnx Python library:
#' the public API mirrors its function names (`graph_from_place` becomes
#' [ox_graph_from_place()]), and its modelling choices (network types, the
#' Overpass filters, topology simplification, intersection consolidation,
#' the urban metrics) are reproduced. The code is a reimplementation: no
#' Python runtime is involved, and the graph algorithms run in the bundled
#' Rust crate osmnxr-core (<https://strategicprojects.github.io/osmnxr-core/>).
#'
#' @references
#' Boeing, G. (2025). Modeling and analyzing urban networks and amenities
#' with OSMnx. *Geographical Analysis*, 57(4), 567--577.
#' \doi{10.1111/gean.70009}
#'
#' @seealso OSMnx: <https://osmnx.readthedocs.io/>. The package website:
#'   <https://strategicprojects.github.io/osmnxr/>.
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data
#' @importFrom rlang abort
#' @importFrom rlang `%||%`
## usethis namespace: end
NULL
