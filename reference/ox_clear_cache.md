# Clear the session cache

Empties the in-memory cache of downloaded OpenStreetMap responses, and
the cache of routing edge indexes that makes repeated `ox_route_*()` /
[`ox_shortest_path()`](https://strategicprojects.github.io/osmnxr/reference/ox_shortest_path.md)
calls on the same graph fast. Both caches are rebuilt transparently on
demand; clearing them only frees memory.

## Usage

``` r
ox_clear_cache()
```

## Value

Invisibly `NULL`.

## Examples

``` r
ox_clear_cache()
```
