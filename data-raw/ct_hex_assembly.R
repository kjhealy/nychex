source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf
ct20_sf <- nycmaps::nyc_census_tracts_2020_sf

## Load all borough hex maps
mn <- readRDS(here::here("data-raw", "ct_hex_manhattan.rds"))
bx <- readRDS(here::here("data-raw", "ct_hex_bronx.rds"))
bk <- readRDS(here::here("data-raw", "ct_hex_brooklyn.rds"))
qn <- readRDS(here::here("data-raw", "ct_hex_queens.rds"))
si <- readRDS(here::here("data-raw", "ct_hex_staten_island.rds"))

## Extract contiguous hex sf objects
mn_hex <- mn$contiguous
bx_hex <- bx$contiguous
bk_hex <- bk$contiguous
qn_hex <- qn$contiguous
si_hex <- si$contiguous

## -- Rescale all hexes to uniform size --------------------------------------
all_areas <- c(
  as.numeric(st_area(mn_hex$tile_map)),
  as.numeric(st_area(bx_hex$tile_map)),
  as.numeric(st_area(bk_hex$tile_map)),
  as.numeric(st_area(qn_hex$tile_map)),
  as.numeric(st_area(si_hex$tile_map))
)
target_area <- median(all_areas)
cat("Target hex area:", round(target_area), "\n")

rescale_group <- function(hex_sf, target_area) {
  geom <- hex_sf$tile_map
  current_area <- median(as.numeric(st_area(geom)))
  scale_factor <- sqrt(target_area / current_area)
  group_centroid <- st_coordinates(st_centroid(st_union(geom)))
  hex_sf$tile_map <- (geom - group_centroid) * scale_factor + group_centroid
  hex_sf
}

mn_hex <- rescale_group(mn_hex, target_area)
bx_hex <- rescale_group(bx_hex, target_area)
bk_hex <- rescale_group(bk_hex, target_area)
qn_hex <- rescale_group(qn_hex, target_area)
si_hex <- rescale_group(si_hex, target_area)

## -- Position each group using geographic centroids -------------------------
get_group_centroid <- function(boro_filter) {
  ct20_sf |>
    filter(boro_name %in% boro_filter) |>
    summarise(geometry = st_union(geometry)) |>
    st_centroid() |>
    st_coordinates() |>
    as.numeric()
}

hex_centroid <- function(hex_sf) {
  st_coordinates(st_centroid(st_union(hex_sf$tile_map))) |> as.numeric()
}

translate_hex_group <- function(hex_sf, current_centroid, target_centroid) {
  offset <- target_centroid - current_centroid
  hex_sf |>
    mutate(tile_map = tile_map + offset)
}

geo_mn <- get_group_centroid("Manhattan")
geo_bx <- get_group_centroid("Bronx")
geo_bk <- get_group_centroid("Brooklyn")
geo_qn <- get_group_centroid("Queens")
geo_si <- get_group_centroid("Staten Island")

mn_hex <- translate_hex_group(mn_hex, hex_centroid(mn_hex), geo_mn)
bx_hex <- translate_hex_group(bx_hex, hex_centroid(bx_hex), geo_bx)
bk_hex <- translate_hex_group(bk_hex, hex_centroid(bk_hex), geo_bk)
qn_hex <- translate_hex_group(qn_hex, hex_centroid(qn_hex), geo_qn)
si_hex <- translate_hex_group(si_hex, hex_centroid(si_hex), geo_si)

## -- Manual nudges to prevent overlap ---------------------------------------
## Start with the same nudges as the NTA map, scaled if needed
mn_hex <- mn_hex |> mutate(tile_map = tile_map + c(-7500, -3500))
bx_hex <- bx_hex |> mutate(tile_map = tile_map + c(-2425, -10000))
qn_hex <- qn_hex |> mutate(tile_map = tile_map + c(2050, 4250))
si_hex <- si_hex |> mutate(tile_map = tile_map + c(17000, 6000))

## -- Combine all groups -----------------------------------------------------
## Standardize columns across groups before binding
standardize_cols <- function(hex_sf) {
  hex_sf |>
    st_set_geometry("tile_map") |>
    select(
      geoid, boro_ct2020, ct2020, boro_code, boro_name, nta2020, nta_name,
      puma, tile_map
    )
}

nyc_ct20_hex_sf <- bind_rows(
  standardize_cols(mn_hex),
  standardize_cols(bx_hex),
  standardize_cols(bk_hex),
  standardize_cols(qn_hex),
  standardize_cols(si_hex)
) |>
  st_set_crs(st_crs(ct20_sf))

## Verify
cat("Total hexes:", nrow(nyc_ct20_hex_sf), "\n")
cat("Unique tracts (boro_ct2020):", n_distinct(nyc_ct20_hex_sf$boro_ct2020), "\n")
cat("Borough counts:\n")
print(table(nyc_ct20_hex_sf$boro_name))

## Save
saveRDS(nyc_ct20_hex_sf, here::here("data-raw", "ct_hex_assembled.rds"))

## Save sample figures
p <- ggplot(nyc_ct20_hex_sf) +
  geom_sf(
    aes(fill = boro_name),
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC Census Tract 2020 Hex Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_ct_hex_assembled.png"),
  p,
  width = 12,
  height = 14,
  dpi = 150,
  bg = "white"
)

## Also a version colored by NTA
p2 <- ggplot(nyc_ct20_hex_sf) +
  geom_sf(
    aes(fill = nta2020),
    color = "white",
    linewidth = 0.05,
    show.legend = FALSE
  ) +
  labs(title = "NYC Census Tract 2020 Hex Map (by NTA)") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_ct_hex_assembled_nta.png"),
  p2,
  width = 12,
  height = 14,
  dpi = 150,
  bg = "white"
)
