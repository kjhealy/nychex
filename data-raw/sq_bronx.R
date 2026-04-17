source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## -- Bronx: 50 NTAs, 46 contiguous + 4 islands ------------------------------
bx_island_ntas <- c("BX1003", "BX1071", "BX0291", "QN0151")

bx_sf <- nta20_sf |>
  filter(boro_name == "Bronx") |>
  st_cast("POLYGON") |>
  mutate(area = st_area(geometry)) |>
  slice_max(area, n = 1, by = nta2020)

bx_islands_sf <- bx_sf |>
  filter(nta2020 %in% bx_island_ntas)

bx_main_sf <- bx_sf |>
  filter(nta2020 %nin% bx_island_ntas) |>
  ms_simplify(keep = 0.01, keep_shapes = TRUE)

set.seed(42)
bx_main_sf <- bx_main_sf |>
  mutate(tile_map = generate_map(geometry, square = TRUE))

hex_centroids <- st_centroid(bx_main_sf$tile_map)
hex_coords <- st_coordinates(hex_centroids)
hex_dists <- as.matrix(dist(hex_coords))
diag(hex_dists) <- Inf
hex_spacing <- min(hex_dists)

bx_bbox <- st_bbox(bx_main_sf$tile_map)

## BX1003 — east of main cluster, mid-height
bx1003_pos <- c(bx_bbox["xmax"] + hex_spacing, mean(c(bx_bbox["ymin"], bx_bbox["ymax"])))
## BX1071 — east of main cluster, upper
bx1071_pos <- c(bx_bbox["xmax"] + hex_spacing, mean(c(bx_bbox["ymin"], bx_bbox["ymax"])) + 2 * hex_spacing)
## BX0291 — south of main cluster
bx0291_pos <- c(bx_bbox["xmin"] + 2 * hex_spacing, bx_bbox["ymin"] - hex_spacing)
## QN0151 — south-southeast of main cluster
qn0151_pos <- c(bx_bbox["xmin"] + 4 * hex_spacing, bx_bbox["ymin"] - hex_spacing)

island_tiles <- list(
  create_island(bx_main_sf$tile_map, bx1003_pos),
  create_island(bx_main_sf$tile_map, bx1071_pos),
  create_island(bx_main_sf$tile_map, bx0291_pos),
  create_island(bx_main_sf$tile_map, qn0151_pos)
)

bx_sq_sf <- bx_main_sf |>
  st_set_geometry("tile_map") |>
  select(-geometry, -area) |>
  bind_rows(
    bx_islands_sf |>
      st_drop_geometry() |>
      select(-area) |>
      mutate(tile_map = do.call(c, island_tiles)) |>
      st_as_sf(sf_column_name = "tile_map")
  )

saveRDS(bx_sq_sf, here::here("data-raw", "sq_bronx.rds"))

p <- ggplot(bx_sq_sf) +
  geom_sf(aes(geometry = tile_map), fill = "darkorange", color = "white", linewidth = 0.5) +
  geom_sf_text(aes(geometry = tile_map, label = nta_abbrev), size = 2) +
  labs(title = "Bronx NTA 2020 Square Map") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "bronx_sq.png"),
  p, width = 8, height = 8, dpi = 150, bg = "white"
)
