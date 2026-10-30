# osmnxr: OpenStreetMap street networks for R

A tidyverse-friendly toolkit to download, model, simplify, analyze and
visualize street networks and other geospatial features from
OpenStreetMap. The design follows Geoff Boeing's OSMnx Python library:
the public API mirrors its function names (`graph_from_place` becomes
[`ox_graph_from_place()`](https://strategicprojects.github.io/osmnxr/reference/ox_graph_from_place.md)),
and its modelling choices (network types, the Overpass filters, topology
simplification, intersection consolidation, the urban metrics) are
reproduced. The code is a reimplementation: no Python runtime is
involved, and the graph algorithms run in the bundled Rust crate
osmnxr-core (<https://strategicprojects.github.io/osmnxr-core/>).

## References

Boeing, G. (2025). Modeling and analyzing urban networks and amenities
with OSMnx. *Geographical Analysis*, 57(4), 567–577.
[doi:10.1111/gean.70009](https://doi.org/10.1111/gean.70009)

## See also

OSMnx: <https://osmnx.readthedocs.io/>. The package website:
<https://strategicprojects.github.io/osmnxr/>.

## Author

**Maintainer**: André Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- André Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Marcos Wasiliew <marcos.wasiliew@gmail.com>
  ([ORCID](https://orcid.org/0009-0004-4694-3159))

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6249-0920))

- Carlos Amorim <carlos.agaf@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6315-8305))

- Diogo Bezerra <diogo.bezerra@ufpe.br>
  ([ORCID](https://orcid.org/0000-0002-1216-8674))

- Júlia Nascimento Barreto <juliabarreto@gd.seplag.pe.gov.br>
  ([ORCID](https://orcid.org/0009-0004-2851-7770))

Other contributors:

- Srikanth Komala Sheshachala <sri.teach@gmail.com> (Issue reports and
  feature proposals (GitHub: talegari)) \[contributor\]

- StrategicProjects (Also copyright holder of the bundled Rust crate
  osmnxr-core) \[copyright holder, funder\]

- The extendr authors (Bundled Rust crates extendr-api, extendr-ffi,
  extendr-macros) \[copyright holder\]

- David Tolnay (Bundled Rust crates proc-macro2, quote, syn, paste,
  readonly, unicode-ident) \[copyright holder\]

- Alex Crichton (Bundled Rust crate proc-macro2) \[copyright holder\]

- Marvin Loebel (Bundled Rust crate lazy_static) \[copyright holder\]

- Aleksey Kladov (Bundled Rust crate once_cell) \[copyright holder\]

- Unicode, Inc. (Bundled Rust crate unicode-ident (Unicode-3.0 data
  tables)) \[copyright holder\]
