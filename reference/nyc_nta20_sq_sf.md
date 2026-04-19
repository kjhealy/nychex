# Square tile map of NYC Neighborhood Tabulation Areas (2020)

A tessellated square tile map of New York City's 262 Neighborhood
Tabulation Areas (NTA 2020). Each NTA is represented by a single square
polygon tile, arranged to approximate the geographic layout of the city.

## Usage

``` r
nyc_nta20_sq_sf
```

## Format

### `nyc_nta20_sq_sf`

A simple feature collection with 262 rows and 12 columns:

- boro_code:

  Borough code. 1 = Manhattan, 2 = Bronx, 3 = Brooklyn, 4 = Queens, 5 =
  Staten Island.

- county_fips:

  County FIPS code.

- nta_name:

  Full NTA name.

- nta2020:

  NTA 2020 identifier.

- boro_name:

  Borough name.

- nta_type:

  NTA type (residential or non-residential).

- cdta2020:

  Community District Tabulation Area 2020 identifier.

- cdta_name:

  Full CDTA name.

- shape_leng:

  Perimeter length of the original NTA boundary.

- nta_abbrev:

  Abbreviated NTA name.

- shape_area:

  Area of the original NTA boundary.

- tile_map:

  POLYGON square tile geometry (EPSG:2263).

## Source

Derived from NTA 2020 boundaries in the nycmaps package using the
tilemaps algorithm.

## Details

The square tile map was generated using the tilemaps algorithm with
`square = TRUE`, applied to borough groups separately (Manhattan, Bronx,
Brooklyn/Queens, Staten Island), then rescaled to uniform tile size and
assembled to preserve NYC's overall geographic layout. Island NTAs were
added back using `tilemaps::create_island()` and positioned to
approximate their geographic locations.

## Author

Kieran Healy
