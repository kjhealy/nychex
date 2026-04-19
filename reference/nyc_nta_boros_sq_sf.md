# Borough outlines for the NYC NTA 2020 square tile map

Polygon outlines of the main contiguous square tile area for each NYC
borough, derived from
[nyc_nta20_sq_sf](https://kjhealy.github.io/nychex/reference/nyc_nta20_sq_sf.md).
Disconnected island tiles are excluded. Brooklyn and Queens have
separate outlines, so the shared border between them is visible.

## Usage

``` r
nyc_nta_boros_sq_sf
```

## Format

### `nyc_nta_boros_sq_sf`

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
[nyc_nta20_sq_sf](https://kjhealy.github.io/nychex/reference/nyc_nta20_sq_sf.md)
by unioning square tiles per borough and extracting the largest polygon.

## Author

Kieran Healy
