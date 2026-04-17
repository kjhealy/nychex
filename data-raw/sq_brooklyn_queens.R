source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## -- Brooklyn/Queens: 151 NTAs total ----------------------------------------
bkqn_single_islands <- c("BK1891", "BK5691", "BK5692", "QN8491")
bkqn_rockaway <- c("QN1401", "QN1402", "QN1403", "QN8492")
bkqn_disconnected <- c("QN0761", "QN1491")
bkqn_remove <- c(bkqn_single_islands, bkqn_rockaway, bkqn_disconnected)

bkqn_sf <- nta20_sf |>
  filter(boro_name %in% c("Brooklyn", "Queens")) |>
  st_cast("POLYGON") |>
  mutate(area = st_area(geometry)) |>
  slice_max(area, n = 1, by = nta2020)

bkqn_removed_sf <- bkqn_sf |>
  filter(nta2020 %in% bkqn_remove)

bkqn_main_sf <- bkqn_sf |>
  filter(nta2020 %nin% bkqn_remove) |>
  ms_simplify(keep = 0.005, keep_shapes = TRUE)

cat("Main contiguous NTAs:", nrow(bkqn_main_sf), "\n")

set.seed(42)
bkqn_main_sf <- bkqn_main_sf |>
  mutate(tile_map = generate_map(geometry, square = TRUE))

## Get tile spacing
hex_centroids <- st_centroid(bkqn_main_sf$tile_map)
hex_coords <- st_coordinates(hex_centroids)
hex_dists <- as.matrix(dist(hex_coords))
diag(hex_dists) <- Inf
hex_spacing <- min(hex_dists)

bkqn_bbox <- st_bbox(bkqn_main_sf$tile_map)

## Position single islands (Jamaica Bay, south of main cluster)
south_y <- bkqn_bbox["ymin"] - 1.5 * hex_spacing
south_x_center <- mean(c(bkqn_bbox["xmin"], bkqn_bbox["xmax"]))

bk5692_pos <- c(south_x_center - hex_spacing, south_y)
qn8491_pos <- c(south_x_center + hex_spacing, south_y)
bk5691_pos <- c(south_x_center - hex_spacing / 2, south_y - hex_spacing)
bk1891_pos <- c(south_x_center - hex_spacing * 1.5, south_y - hex_spacing)

## QN0761 (Fort Totten) — northeast corner
qn0761_pos <- c(bkqn_bbox["xmax"] + hex_spacing, bkqn_bbox["ymax"])

## QN1491 (Rockaway Community Park)
qn1491_pos <- c(south_x_center, south_y - hex_spacing)

single_island_ntas <- c("BK5692", "QN8491", "BK5691", "BK1891", "QN0761", "QN1491")
single_island_positions <- list(
  bk5692_pos, qn8491_pos, bk5691_pos, bk1891_pos, qn0761_pos, qn1491_pos
)

single_island_tiles <- purrr::map(
  single_island_positions,
  \(pos) create_island(bkqn_main_sf$tile_map, pos)
)

## Rockaway chain — 4 squares in a row
rockaway_y <- south_y - hex_spacing * 2
rockaway_x_start <- south_x_center - hex_spacing * 1.5

rockaway_positions <- list(
  c(rockaway_x_start, rockaway_y),
  c(rockaway_x_start + hex_spacing, rockaway_y),
  c(rockaway_x_start + 2 * hex_spacing, rockaway_y),
  c(rockaway_x_start + 3 * hex_spacing, rockaway_y)
)

rockaway_tiles <- purrr::map(
  rockaway_positions,
  \(pos) create_island(bkqn_main_sf$tile_map, pos)
)

## Assemble
bkqn_sq_sf <- bkqn_main_sf |>
  st_set_geometry("tile_map") |>
  select(-geometry, -area) |>
  bind_rows(
    bkqn_removed_sf |>
      filter(nta2020 %in% single_island_ntas) |>
      arrange(match(nta2020, single_island_ntas)) |>
      st_drop_geometry() |>
      select(-area) |>
      mutate(tile_map = do.call(c, single_island_tiles)) |>
      st_as_sf(sf_column_name = "tile_map")
  ) |>
  bind_rows(
    bkqn_removed_sf |>
      filter(nta2020 %in% bkqn_rockaway) |>
      arrange(match(nta2020, bkqn_rockaway)) |>
      st_drop_geometry() |>
      select(-area) |>
      mutate(tile_map = do.call(c, rockaway_tiles)) |>
      st_as_sf(sf_column_name = "tile_map")
  )

cat("Total BK/QN tiles:", nrow(bkqn_sq_sf), "\n")

saveRDS(bkqn_sq_sf, here::here("data-raw", "sq_brooklyn_queens.rds"))

p <- ggplot(bkqn_sq_sf) +
  geom_sf(
    aes(geometry = tile_map, fill = boro_name),
    color = "white", linewidth = 0.5
  ) +
  scale_fill_manual(values = c("Brooklyn" = "forestgreen", "Queens" = "mediumpurple")) +
  geom_sf_text(aes(geometry = tile_map, label = nta_abbrev), size = 1.5) +
  labs(title = "Brooklyn/Queens NTA 2020 Square Map") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "brooklyn_queens_sq.png"),
  p, width = 12, height = 10, dpi = 150, bg = "white"
)
