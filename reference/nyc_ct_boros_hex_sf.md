# Borough outlines for the NYC census tract 2020 hex map

Polygon outlines of the main contiguous hex area for each NYC borough,
derived from
[nyc_ct20_hex_sf](https://kjhealy.github.io/nychex/reference/nyc_ct20_hex_sf.md).
Disconnected island hexes are excluded. Brooklyn and Queens have
separate outlines, so the shared border between them is visible.

## Usage

``` r
nyc_ct_boros_hex_sf
```

## Format

### `nyc_ct_boros_hex_sf`

A simple feature collection with 5 rows and 3 columns:

- boro_name:

  Borough name.

- boro_code:

  Borough code. 1 = Manhattan, 2 = Bronx, 3 = Brooklyn, 4 = Queens, 5 =
  Staten Island.

- tile_map:

  POLYGON outline geometry (EPSG:2263).

## Source

Derived from
[nyc_ct20_hex_sf](https://kjhealy.github.io/nychex/reference/nyc_ct20_hex_sf.md)
by unioning hex tiles per borough and extracting the largest polygon.

## Author

Kieran Healy
