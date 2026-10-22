# Overpass query construction and parsing -------------------------------------

# Build an Overpass QL query for a way network within a bbox.
# bbox is c(xmin, ymin, xmax, ymax) in lon/lat.
overpass_bbox_query <- function(bbox, network_type) {
  filt <- network_filter(network_type)
  bb <- sprintf("%.7f,%.7f,%.7f,%.7f", bbox[2], bbox[1], bbox[4], bbox[3])
  glue::glue(
    "[out:json][timeout:{.osmnxr_settings$timeout}];\n",
    "(way[\"highway\"~\"^({filt})$\"]({bb}););\n",
    "(._;>;);\nout body;"
  )
}

# Run an Overpass query, returning the parsed element list.
ox_overpass <- function(query) {
  req <- ox_request(.osmnxr_settings$overpass_url) |>
    httr2::req_body_form(data = query)
  ox_fetch_json(req)
}

# Convert an Overpass element list into an osm_graph. Each consecutive pair of
# nodes within a way becomes a (bidirectional, unless oneway) edge.
overpass_to_graph <- function(res, network_type = "drive", query = NULL) {
  elements <- res$elements
  if (length(elements) == 0) {
    cli::cli_abort("Overpass returned no elements for this query.", call = NULL)
  }
  types <- vapply(elements, function(e) e$type, character(1))

  node_el <- elements[types == "node"]
  node_id <- vapply(node_el, function(e) as.numeric(e$id), numeric(1))
  node_lon <- vapply(node_el, function(e) as.numeric(e$lon), numeric(1))
  node_lat <- vapply(node_el, function(e) as.numeric(e$lat), numeric(1))

  way_el <- elements[types == "way"]
  way_edges <- vector("list", length(way_el))
  for (k in seq_along(way_el)) {
    w <- way_el[[k]]
    refs <- vapply(w$nodes, as.numeric, numeric(1))
    if (length(refs) < 2) next
    tags <- w$tags %||% list()
    n <- length(refs) - 1L
    way_edges[[k]] <- list(
      u = refs[-length(refs)], v = refs[-1L],
      osmid = rep.int(as.numeric(w$id), n),
      name = rep.int(tags$name %||% NA_character_, n),
      highway = rep.int(tags$highway %||% NA_character_, n),
      oneway = rep.int(isTRUE(tags$oneway %in% c("yes", "true", "1")), n)
    )
  }
  way_edges <- way_edges[!vapply(way_edges, is.null, logical(1))]
  if (length(way_edges) == 0) cli::cli_abort("No usable ways in Overpass response.", call = NULL)

  pull <- function(field) unlist(lapply(way_edges, `[[`, field), use.names = FALSE)
  ed <- tibble::tibble(
    u = pull("u"), v = pull("v"), osmid = pull("osmid"),
    name = pull("name"), highway = pull("highway"), oneway = pull("oneway")
  )
  # add reverse direction for two-way edges
  rev <- ed[!ed$oneway, ]
  rev[c("u", "v")] <- rev[c("v", "u")]
  ed <- rbind(ed, rev)

  # keep only edges whose endpoints we have coordinates for
  iu <- match(ed$u, node_id)
  iv <- match(ed$v, node_id)
  keep <- !is.na(iu) & !is.na(iv)
  ed <- ed[keep, ]
  iu <- iu[keep]
  iv <- iv[keep]
  ux <- node_lon[iu]
  uy <- node_lat[iu]
  vx <- node_lon[iv]
  vy <- node_lat[iv]

  geoms <- lapply(seq_len(nrow(ed)), function(i) {
    sf::st_linestring(matrix(c(ux[i], vx[i], uy[i], vy[i]), 2L, 2L))
  })
  edges <- sf::st_sf(ed, geometry = sf::st_sfc(geoms, crs = 4326))
  edges$length <- haversine(ux, uy, vx, vy)

  used <- sort(unique(c(ed$u, ed$v)))
  ui <- match(used, node_id)
  nodes <- sf::st_as_sf(
    data.frame(osmid = used, x = node_lon[ui], y = node_lat[ui]),
    coords = c("x", "y"), crs = 4326, remove = FALSE
  )

  new_osm_graph(nodes, edges, meta = list(
    network_type = network_type, simplified = FALSE, query = query
  ))
}
