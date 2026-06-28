# Authors and Citation

## Authors

- **Andre Leite**. Author, maintainer.

- **Marcos Wasilew**. Author.

- **Hugo Vasconcelos**. Author.

- **Carlos Amorin**. Author.

- **Diogo Bezerra**. Author.

- **StrategicProjects**. Copyright holder, funder.

- **The extendr authors**. Copyright holder.  
  Bundled Rust crates extendr-api, extendr-ffi, extendr-macros

- **David Tolnay**. Copyright holder.  
  Bundled Rust crates proc-macro2, quote, syn, paste, readonly,
  unicode-ident

- **Alex Crichton**. Copyright holder.  
  Bundled Rust crate proc-macro2

- **Marvin Loebel**. Copyright holder.  
  Bundled Rust crate lazy_static

- **Aleksey Kladov**. Copyright holder.  
  Bundled Rust crate once_cell

- **Unicode, Inc.**. Copyright holder.  
  Bundled Rust crate unicode-ident (Unicode-3.0 data tables)

## Citation

Source:
[`DESCRIPTION`](https://github.com/StrategicProjects/osmnxr/blob/v0.1.1/DESCRIPTION)

Leite A, Wasilew M, Vasconcelos H, Amorin C, Bezerra D (2026). *osmnxr:
Download, Model and Analyze 'OpenStreetMap' Street Networks*. R package
version 0.1.1, <https://github.com/StrategicProjects/osmnxr>.

    @Manual{,
      title = {osmnxr: Download, Model and Analyze 'OpenStreetMap' Street Networks},
      author = {Andre Leite and Marcos Wasilew and Hugo Vasconcelos and Carlos Amorin and Diogo Bezerra},
      year = {2026},
      note = {R package version 0.1.1},
      url = {https://github.com/StrategicProjects/osmnxr},
    }

## Additional details

    Authorship and copyright of bundled Rust code
    ==============================================

    The osmnxr package contains a Rust compute core that depends on several
    third-party Rust crates. Their source is vendored in src/rust/vendor.tar.xz so
    the package builds offline. Each crate is the copyright of its respective
    authors and is used under the terms of its license, as listed below. The
    corresponding copyright holders are also recorded in the package DESCRIPTION
    (role "cph").

    crate           version   license                              copyright holder(s)
    -----           -------   -------                              -------------------
    extendr-api     0.9.0     MIT                                  The extendr authors
    extendr-ffi     0.9.0     MIT                                  The extendr authors
    extendr-macros  0.9.0     MIT                                  The extendr authors
    lazy_static     1.5.0     MIT OR Apache-2.0                    Marvin Loebel
    once_cell       1.21.4    MIT OR Apache-2.0                    Aleksey Kladov
    paste           1.0.15    MIT OR Apache-2.0                    David Tolnay
    proc-macro2     1.0.106   MIT OR Apache-2.0                    David Tolnay, Alex Crichton
    quote           1.0.46    MIT OR Apache-2.0                    David Tolnay
    readonly        0.2.13    MIT OR Apache-2.0                    David Tolnay
    syn             2.0.118   MIT OR Apache-2.0                    David Tolnay
    unicode-ident   1.0.24    (MIT OR Apache-2.0) AND Unicode-3.0  David Tolnay; Unicode, Inc.

    Crates offered as "MIT OR Apache-2.0" are used here under the MIT license, which
    is compatible with the package's own MIT license. The unicode-ident crate also
    includes Unicode character data under the Unicode License v3 (Unicode-3.0).

    Full license texts are distributed with each crate inside
    src/rust/vendor.tar.xz, and are available at:
      MIT          https://spdx.org/licenses/MIT.html
      Apache-2.0   https://spdx.org/licenses/Apache-2.0.html
      Unicode-3.0  https://spdx.org/licenses/Unicode-3.0.html
