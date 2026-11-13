#' osmnxr: an R port of OSMnx
#'
#' An R port of OSMnx, the Python library by Geoff Boeing, to download,
#' model, simplify, analyze and visualize street networks and other
#' geospatial features from OpenStreetMap. The design is that of OSMnx: the
#' public API translates its function names (`graph_from_place` becomes
#' [ox_graph_from_place()]), and its modelling choices (network types, the
#' Overpass filters, topology simplification, intersection consolidation,
#' the urban metrics) are reproduced. No Python runtime is involved: the R
#' layer was written for this package and the graph algorithms run in the
#' bundled Rust crate osmnxr-core
#' (<https://strategicprojects.github.io/osmnxr-core/>). The port was made
#' with the assistance of AI coding tools. osmnxr is not affiliated with or
#' endorsed by the OSMnx project; OSMnx's copyright notice is in
#' `system.file("COPYRIGHTS", package = "osmnxr")`.
#'
#' If you use osmnxr, please cite the OSMnx paper below.
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
