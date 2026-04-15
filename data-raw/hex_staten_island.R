source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## -- Staten Island: 23 NTAs, 22 contiguous + 1 island ----------------------
si_island_ntas <- c("SI9591") ## Hoffman & Swinburne Islands

si_sf <- nta20_sf |>
  filter(boro_name == "Staten Island") |>
  st_cast("POLYGON") |>
  mutate(area = st_area(geometry)) |>
  slice_max(area, n = 1, by = nta2020)

si_islands_sf <- si_sf |>
  filter(nta2020 %in% si_island_ntas)

si_main_sf <- si_sf |>
  filter(nta2020 %nin% si_island_ntas) |>
  ms_simplify(keep = 0.01, keep_shapes = TRUE)

set.seed(42)
si_main_sf <- si_main_sf |>
  mutate(tile_map = generate_map(geometry, square = FALSE, flat_topped = FALSE))

## Get hex spacing
hex_centroids <- st_centroid(si_main_sf$tile_map)
hex_coords <- st_coordinates(hex_centroids)
hex_dists <- as.matrix(dist(hex_coords))
diag(hex_dists) <- Inf
hex_spacing <- min(hex_dists)

si_bbox <- st_bbox(si_main_sf$tile_map)

## SI9591 (Hoffman & Swinburne Islands) — southeast of Staten Island
si9591_pos <- c(
  si_bbox["xmax"] + hex_spacing,
  si_bbox["ymin"]
)

si9591_tile <- create_island(si_main_sf$tile_map, si9591_pos)

si_hex_sf <- si_main_sf |>
  st_set_geometry("tile_map") |>
  select(-geometry, -area) |>
  bind_rows(
    si_islands_sf |>
      st_drop_geometry() |>
      select(-area) |>
      mutate(tile_map = si9591_tile) |>
      st_as_sf(sf_column_name = "tile_map")
  )

## Save intermediate result
saveRDS(si_hex_sf, here::here("data-raw", "hex_staten_island.rds"))

## Save sample figure
p <- ggplot(si_hex_sf) +
  geom_sf(aes(geometry = tile_map), fill = "tomato", color = "white", linewidth = 0.5) +
  geom_sf_text(aes(geometry = tile_map, label = nta_abbrev), size = 2) +
  labs(title = "Staten Island NTA 2020 Hex Map") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "staten_island_hex.png"),
  p,
  width = 8,
  height = 8,
  dpi = 150,
  bg = "white"
)
