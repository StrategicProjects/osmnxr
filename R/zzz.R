.onLoad <- function(libname, pkgname) {
  defaults <- default_settings()
  for (nm in names(defaults)) assign(nm, defaults[[nm]], envir = .osmnxr_settings)
  invisible()
}
