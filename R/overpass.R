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
  lon_of <- stats::setNames(node_lon, as.character(node_id))
  lat_of <- stats::setNames(node_lat, as.character(node_id))

  way_el <- elements[types == "way"]
  edge_rows <- list()
  for (w in way_el) {
    refs <- vapply(w$nodes, as.numeric, numeric(1))
    if (length(refs) < 2) next
    tags <- w$tags %||% list()
    oneway <- isTRUE(tags$oneway %in% c("yes", "true", "1"))
    name <- tags$name %||% NA_character_
    highway <- tags$highway %||% NA_character_
    for (i in seq_len(length(refs) - 1L)) {
      edge_rows[[length(edge_rows) + 1L]] <- list(
        u = refs[i], v = refs[i + 1L], osmid = as.numeric(w$id),
        name = name, highway = highway, oneway = oneway
      )
    }
  }
  if (length(edge_rows) == 0) cli::cli_abort("No usable ways in Overpass response.", call = NULL)

  ed <- tibble::tibble(
    u = vapply(edge_rows, `[[`, numeric(1), "u"),
    v = vapply(edge_rows, `[[`, numeric(1), "v"),
    osmid = vapply(edge_rows, `[[`, numeric(1), "osmid"),
    name = vapply(edge_rows, `[[`, character(1), "name"),
    highway = vapply(edge_rows, `[[`, character(1), "highway"),
    oneway = vapply(edge_rows, `[[`, logical(1), "oneway")
  )
  # add reverse direction for two-way edges
  rev <- ed[!ed$oneway, ]
  rev[c("u", "v")] <- rev[c("v", "u")]
  ed <- rbind(ed, rev)

  # keep only edges whose endpoints we have coordinates for
  ed <- ed[as.character(ed$u) %in% names(lon_of) & as.character(ed$v) %in% names(lon_of), ]

  geoms <- lapply(seq_len(nrow(ed)), function(i) {
    sf::st_linestring(rbind(
      c(lon_of[[as.character(ed$u[i])]], lat_of[[as.character(ed$u[i])]]),
      c(lon_of[[as.character(ed$v[i])]], lat_of[[as.character(ed$v[i])]])
    ))
  })
  edges <- sf::st_sf(ed, geometry = sf::st_sfc(geoms, crs = 4326))
  edges$length <- haversine(
    lon_of[as.character(ed$u)], lat_of[as.character(ed$u)],
    lon_of[as.character(ed$v)], lat_of[as.character(ed$v)]
  )

  used <- sort(unique(c(ed$u, ed$v)))
  nodes <- sf::st_as_sf(
    data.frame(osmid = used, x = lon_of[as.character(used)], y = lat_of[as.character(used)]),
    coords = c("x", "y"), crs = 4326, remove = FALSE
  )

  new_osm_graph(nodes, edges, meta = list(
    network_type = network_type, simplified = FALSE, query = query
  ))
}
