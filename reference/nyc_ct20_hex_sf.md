# Hexagonal tile map of NYC census tracts (2020)

A tessellated hexagonal tile map of all 2,325 New York City 2020 census
tracts. Each tract is represented by a single hexagonal polygon tile,
arranged to approximate the geographic layout of the city.

## Usage

``` r
nyc_ct20_hex_sf
```

## Format

### `nyc_ct20_hex_sf`

A simple feature collection with 2325 rows and 9 columns:

- geoid:

  Census GEOID (state + county + tract FIPS code). Use this column for
  joining with other tract-level data.

- boro_ct2020:

  Unique borough-tract identifier (borough code concatenated with tract
  code).

- ct2020:

  Census tract 2020 code (not unique across boroughs).

- boro_code:

  Borough code. 1 = Manhattan, 2 = Bronx, 3 = Brooklyn, 4 = Queens, 5 =
  Staten Island.

- boro_name:

  Borough name.

- nta2020:

  NTA 2020 identifier for the tract.

- nta_name:

  Full NTA name.

- puma:

  Public Use Microdata Area code.

- tile_map:

  POLYGON hexagonal tile geometry (EPSG:2263).

## Source

Derived from census tract 2020 boundaries in the nycmaps package using
the tilemaps algorithm.

## Details

The hex map was generated using the tilemaps algorithm applied to each
borough separately (Manhattan, Bronx, Brooklyn, Queens, Staten Island),
then rescaled to uniform hex size and assembled to preserve NYC's
overall geographic layout. Unlike the NTA hex map, Brooklyn and Queens
were tiled as separate boroughs rather than combined, so there is a
visible gap between them.

Island tracts (those in geographically disconnected NTAs or that become
disconnected after polygon simplification) are included as individual or
small-group tiles positioned near their geographic locations.
Multi-tract island NTAs (e.g. Rockaways, City Island) are tiled as
contiguous groups where possible.

## Author

Kieran Healy
