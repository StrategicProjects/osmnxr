# Get or set package settings

Configure the Overpass and Nominatim endpoints, HTTP behaviour and
caching used by all `ox_*` download functions. Called with no arguments
it returns the current settings as a list; called with named arguments
it updates them and returns the previous values invisibly.

## Usage

``` r
ox_settings(...)
```

## Arguments

- ...:

  Named settings to update. Recognised names: `overpass_url`,
  `nominatim_url`, `user_agent`, `timeout`, `max_tries`, `cache`.

## Value

A named list of settings (current values, or the previous values
invisibly when updating).

## Examples

``` r
ox_settings()
#> $overpass_url
#> [1] "https://overpass-api.de/api/interpreter"
#> 
#> $nominatim_url
#> [1] "https://nominatim.openstreetmap.org"
#> 
#> $user_agent
#> [1] "osmnxr R package (https://github.com/StrategicProjects/osmnxr)"
#> 
#> $timeout
#> [1] 180
#> 
#> $max_tries
#> [1] 3
#> 
#> $cache
#> [1] TRUE
#> 
old <- ox_settings(timeout = 300)
ox_settings(timeout = old$timeout) # restore
```
