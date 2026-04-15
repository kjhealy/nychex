
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nychex

<!-- badges: start -->

<!-- badges: end -->

nychex provides tessellated hexagonal tile maps for New York City
administrative geographies. Each polygon in the source geography is
represented by a single hexagonal tile, arranged to approximate the
overall spatial layout of the city.

## Installation

You can install the development version of nychex from
[GitHub](https://github.com/kjhealy/nychex) with:

``` r
# install.packages("pak")
pak::pak("kjhealy/nychex")
```

## Example

``` r
library(ggplot2)
library(nychex)

ggplot(nyc_nta20_hex_sf) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.3) +
  scale_fill_brewer(palette = "Set2") +
  labs(fill = "Borough") +
  theme_void()
```

<img src="man/figures/README-hex-map-1.png" alt="" width="100%" />

``` r
ggplot(nyc_nta20_hex_sf) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.3) +
  geom_sf_text(aes(label = nta_abbrev), size = 1.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(fill = "Borough") +
  theme_void()
```

<img src="man/figures/README-hex-map-labeled-1.png" alt="" width="100%" />
