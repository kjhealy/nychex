
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nychex <img src="man/figures/nychex.png" align="right" width="360" alt="nychex package hex logo">

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

## Examples

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

Borough outlines are also available via `nyc_nta_boros_hex_sf`, with
separate outlines for Brooklyn and Queens:

``` r
ggplot() +
  geom_sf(
    data = nyc_nta20_hex_sf,
    aes(fill = boro_name),
    color = "white",
    linewidth = 0.2,
    alpha = 0.3
  ) +
  geom_sf(
    data = nyc_nta_boros_hex_sf,
    aes(color = boro_name),
    fill = NA,
    linewidth = 0.8
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Set2") +
  labs(fill = "Borough", color = "Borough") +
  theme_void()
```

<img src="man/figures/README-hex-outlines-1.png" alt="" width="100%" />

A census tract level hex map is also available via `nyc_ct20_hex_sf`
(2,271 tracts), with its own borough outlines in `nyc_ct_boros_hex_sf`:

``` r
ggplot(nyc_ct20_hex_sf) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.1) +
  scale_fill_brewer(palette = "Set2") +
  labs(fill = "Borough") +
  theme_void()
```

<img src="man/figures/README-ct-hex-map-1.png" alt="" width="100%" />

``` r
ggplot() +
  geom_sf(
    data = nyc_ct20_hex_sf,
    aes(fill = boro_name),
    color = "white",
    linewidth = 0.2,
    alpha = 0.3
  ) +
  geom_sf(
    data = nyc_ct_boros_hex_sf,
    aes(color = boro_name),
    fill = NA,
    linewidth = 0.8
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Set2") +
  labs(fill = "Borough", color = "Borough") +
  theme_void()
```

<img src="man/figures/README-ct-hex-map-outlines-1.png" alt="" width="100%" />
