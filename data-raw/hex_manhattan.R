source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## -- Manhattan: 38 NTAs, 36 contiguous + 2 islands --------------------------
mn_island_ntas <- c("MN0191", "MN1191")

mn_sf <- nta20_sf |>
  filter(boro_name == "Manhattan") |>
  st_cast("POLYGON") |>
  mutate(area = st_area(geometry)) |>
  slice_max(area, n = 1, by = nta2020)

mn_islands_sf <- mn_sf |>
  filter(nta2020 %in% mn_island_ntas)

mn_main_sf <- mn_sf |>
  filter(nta2020 %nin% mn_island_ntas) |>
  ms_simplify(keep = 0.01, keep_shapes = TRUE)

set.seed(42)
mn_main_sf <- mn_main_sf |>
  mutate(tile_map = generate_map(geometry, square = FALSE, flat_topped = FALSE))

## Add islands back
## MN0191 (Battery-Governors Island) goes south of the main cluster
## MN1191 (Randall's Island) goes northeast, between Manhattan and Bronx
mn_main_bbox <- st_bbox(mn_main_sf$tile_map)

## Get hex size from existing tiles for positioning
hex_centroids <- st_centroid(mn_main_sf$tile_map)
hex_coords <- st_coordinates(hex_centroids)
hex_dists <- as.matrix(dist(hex_coords))
diag(hex_dists) <- Inf
hex_spacing <- min(hex_dists)

## Position MN0191 south of the southern tip
south_hexes <- hex_coords[hex_coords[, 2] == min(hex_coords[, 2]), , drop = FALSE]
mn0191_pos <- c(
  mean(south_hexes[, 1]),
  min(hex_coords[, 2]) - 1.5 * hex_spacing
)

## Position MN1191 northeast of the northern tip
north_hexes <- hex_coords[hex_coords[, 2] == max(hex_coords[, 2]), , drop = FALSE]
mn1191_pos <- c(
  max(hex_coords[, 1]) + hex_spacing,
  max(hex_coords[, 2])
)

mn0191_tile <- create_island(mn_main_sf$tile_map, mn0191_pos)
mn1191_tile <- create_island(mn_main_sf$tile_map, mn1191_pos)

mn_hex_sf <- mn_main_sf |>
  st_set_geometry("tile_map") |>
  select(-geometry, -area) |>
  bind_rows(
    mn_islands_sf |>
      st_drop_geometry() |>
      select(-area) |>
      mutate(
        tile_map = c(mn0191_tile, mn1191_tile)
      ) |>
      st_as_sf(sf_column_name = "tile_map")
  )

## Save intermediate result
saveRDS(mn_hex_sf, here::here("data-raw", "hex_manhattan.rds"))

## Save sample figure
p <- ggplot(mn_hex_sf) +
  geom_sf(aes(geometry = tile_map), fill = "steelblue", color = "white", linewidth = 0.5) +
  geom_sf_text(aes(geometry = tile_map, label = nta_abbrev), size = 2) +
  labs(title = "Manhattan NTA 2020 Hex Map") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "manhattan_hex.png"),
  p,
  width = 6,
  height = 10,
  dpi = 150,
  bg = "white"
)
