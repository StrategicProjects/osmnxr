# Local pkgdown preview. CI (.github/workflows/pkgdown.yaml) builds and
# deploys the published site to the gh-pages branch on push to main; this
# script is only for building the site locally.
devtools::document()
pkgdown::build_site(preview = FALSE)
