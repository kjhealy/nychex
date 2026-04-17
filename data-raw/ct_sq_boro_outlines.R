source(here::here("data-raw", "_shared.R"))

nyc_ct20_sq_sf <- readRDS(here::here("data-raw", "ct_sq_assembled.rds"))

## Build borough outlines by unioning squares per borough, then keeping
## only the largest polygon (drops disconnected islands).
nyc_ct_boros_sq_sf <- nyc_ct20_sq_sf |>
  group_by(boro_name, boro_code) |>
  summarise(tile_map = st_union(tile_map), .groups = "drop") |>
  mutate(tile_map = lapply(tile_map, function(geom) {
    if (inherits(geom, "MULTIPOLYGON")) {
      polys <- st_cast(st_sfc(geom), "POLYGON")
      areas <- st_area(polys)
      polys[[which.max(areas)]]
    } else {
      geom
    }
  })) |>
  mutate(tile_map = st_sfc(tile_map)) |>
  st_as_sf(sf_column_name = "tile_map") |>
  st_set_crs(st_crs(nyc_ct20_sq_sf)) |>
  arrange(boro_code)

saveRDS(nyc_ct_boros_sq_sf, here::here("data-raw", "ct_sq_boro_outlines.rds"))

usethis::use_data(nyc_ct_boros_sq_sf, overwrite = TRUE, compress = "xz")
