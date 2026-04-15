source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## Load all borough hex maps
mn_hex_sf <- readRDS(here::here("data-raw", "hex_manhattan.rds"))
bx_hex_sf <- readRDS(here::here("data-raw", "hex_bronx.rds"))
bkqn_hex_sf <- readRDS(here::here("data-raw", "hex_brooklyn_queens.rds"))
si_hex_sf <- readRDS(here::here("data-raw", "hex_staten_island.rds"))

## -- Compute geographic centroids for each borough group --------------------
geo_centroids <- nta20_sf |>
  group_by(boro_name) |>
  summarise(geometry = st_union(geometry)) |>
  st_centroid() |>
  st_coordinates()

## Brooklyn and Queens need a combined centroid
bkqn_geo <- nta20_sf |>
  filter(boro_name %in% c("Brooklyn", "Queens")) |>
  summarise(geometry = st_union(geometry)) |>
  st_centroid() |>
  st_coordinates()

geo_targets <- list(
  Manhattan = geo_centroids[geo_centroids[, 1] %in%
    st_coordinates(nta20_sf |> filter(boro_name == "Manhattan") |>
    summarise(geometry = st_union(geometry)) |> st_centroid())[, 1], ],
  Bronx = geo_centroids[geo_centroids[, 1] %in%
    st_coordinates(nta20_sf |> filter(boro_name == "Bronx") |>
    summarise(geometry = st_union(geometry)) |> st_centroid())[, 1], ],
  BrooklynQueens = bkqn_geo[1, ],
  StatenIsland = geo_centroids[geo_centroids[, 1] %in%
    st_coordinates(nta20_sf |> filter(boro_name == "Staten Island") |>
    summarise(geometry = st_union(geometry)) |> st_centroid())[, 1], ]
)

## Simpler approach: compute centroids directly
get_group_centroid <- function(sf_obj, boro_filter) {
  nta20_sf |>
    filter(boro_name %in% boro_filter) |>
    summarise(geometry = st_union(geometry)) |>
    st_centroid() |>
    st_coordinates() |>
    as.numeric()
}

geo_mn <- get_group_centroid(nta20_sf, "Manhattan")
geo_bx <- get_group_centroid(nta20_sf, "Bronx")
geo_bkqn <- get_group_centroid(nta20_sf, c("Brooklyn", "Queens"))
geo_si <- get_group_centroid(nta20_sf, "Staten Island")

## -- Compute hex group centroids --------------------------------------------
hex_centroid <- function(hex_sf) {
  st_coordinates(st_centroid(st_union(hex_sf$tile_map))) |> as.numeric()
}

hex_mn <- hex_centroid(mn_hex_sf)
hex_bx <- hex_centroid(bx_hex_sf)
hex_bkqn <- hex_centroid(bkqn_hex_sf)
hex_si <- hex_centroid(si_hex_sf)

## -- Translate each hex group to align with geographic centroids ------------
## Use geographic centroids directly as target positions
translate_hex_group <- function(hex_sf, current_centroid, target_centroid) {
  offset <- target_centroid - current_centroid
  hex_sf |>
    mutate(tile_map = tile_map + offset)
}

mn_hex_sf <- translate_hex_group(mn_hex_sf, hex_mn, geo_mn)
bx_hex_sf <- translate_hex_group(bx_hex_sf, hex_bx, geo_bx)
bkqn_hex_sf <- translate_hex_group(bkqn_hex_sf, hex_bkqn, geo_bkqn)
si_hex_sf <- translate_hex_group(si_hex_sf, hex_si, geo_si)

## -- Combine all groups -----------------------------------------------------
nyc_nta20_hex_sf <- bind_rows(mn_hex_sf, bx_hex_sf, bkqn_hex_sf, si_hex_sf) |>
  st_set_crs(st_crs(nta20_sf))

## Verify
cat("Total hexes:", nrow(nyc_nta20_hex_sf), "\n")
cat("Unique NTAs:", n_distinct(nyc_nta20_hex_sf$nta2020), "\n")
cat("Borough counts:\n")
print(table(nyc_nta20_hex_sf$boro_name))

## Check for any missing NTAs
expected_ntas <- nta20_sf$nta2020
missing <- setdiff(expected_ntas, nyc_nta20_hex_sf$nta2020)
extra <- setdiff(nyc_nta20_hex_sf$nta2020, expected_ntas)
if (length(missing) > 0) cat("Missing NTAs:", paste(missing, collapse = ", "), "\n")
if (length(extra) > 0) cat("Extra NTAs:", paste(extra, collapse = ", "), "\n")

## Save intermediate result
saveRDS(nyc_nta20_hex_sf, here::here("data-raw", "hex_assembled.rds"))

## Save sample figure
p <- ggplot(nyc_nta20_hex_sf) +
  geom_sf(
    aes(fill = boro_name),
    color = "white",
    linewidth = 0.3
  ) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC NTA 2020 Hex Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_hex_assembled.png"),
  p,
  width = 12,
  height = 14,
  dpi = 150,
  bg = "white"
)
