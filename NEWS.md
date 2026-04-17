# nychex 0.3.0

* Added `nyc_nta20_sq_sf`: square tile map of 262 NTA 2020 boundaries
  for all five NYC boroughs, using the same assembly approach as the
  hex map but with `square = TRUE`.
* Added `nyc_nta_boros_sq_sf`: borough outline polygons for the NTA
  square tile map.

# nychex 0.2.0

* Added `nyc_ct20_hex_sf`: hexagonal tile map of 2,271 census tracts (2020)
  for all five NYC boroughs. Brooklyn and Queens are tiled as separate
  boroughs.
* Added `nyc_ct_boros_hex_sf`: borough outline polygons for the census
  tract hex map.
* Renamed `nyc_boro_hex_outlines_sf` to `nyc_nta_boros_hex_sf` for
  consistency with the new census tract outlines object.

# nychex 0.1.0

* Added `nyc_nta20_hex_sf`: hexagonal tile map of 262 NTA 2020 boundaries
  for all five NYC boroughs.
* Added `nyc_boro_hex_outlines_sf`: borough outline polygons derived from
  the hex tile map, with separate outlines for Brooklyn and Queens.
