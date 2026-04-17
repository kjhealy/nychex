source(here::here("data-raw", "_shared.R"))

ct20_sf <- nycmaps::nyc_census_tracts_2020_sf

## Load all borough square maps
mn <- readRDS(here::here("data-raw", "ct_sq_manhattan.rds"))
bx <- readRDS(here::here("data-raw", "ct_sq_bronx.rds"))
bk <- readRDS(here::here("data-raw", "ct_sq_brooklyn.rds"))
qn <- readRDS(here::here("data-raw", "ct_sq_queens.rds"))
si <- readRDS(here::here("data-raw", "ct_sq_staten_island.rds"))

## Extract contiguous sf objects
mn_sq <- mn$contiguous
bx_sq <- bx$contiguous
bk_sq <- bk$contiguous
qn_sq <- qn$contiguous
si_sq <- si$contiguous

## -- Rescale all tiles to uniform size ----------------------------------------
all_areas <- c(
  as.numeric(st_area(mn_sq$tile_map)),
  as.numeric(st_area(bx_sq$tile_map)),
  as.numeric(st_area(bk_sq$tile_map)),
  as.numeric(st_area(qn_sq$tile_map)),
  as.numeric(st_area(si_sq$tile_map))
)
target_area <- median(all_areas)
cat("Target tile area:", round(target_area), "\n")

rescale_group <- function(sq_sf, target_area) {
  geom <- sq_sf$tile_map
  current_area <- median(as.numeric(st_area(geom)))
  scale_factor <- sqrt(target_area / current_area)
  group_centroid <- st_coordinates(st_centroid(st_union(geom)))
  sq_sf$tile_map <- (geom - group_centroid) * scale_factor + group_centroid
  sq_sf
}

mn_sq <- rescale_group(mn_sq, target_area)
bx_sq <- rescale_group(bx_sq, target_area)
bk_sq <- rescale_group(bk_sq, target_area)
qn_sq <- rescale_group(qn_sq, target_area)
si_sq <- rescale_group(si_sq, target_area)

## -- Position each group using geographic centroids ---------------------------
get_group_centroid <- function(boro_filter) {
  ct20_sf |>
    filter(boro_name %in% boro_filter) |>
    summarise(geometry = st_union(geometry)) |>
    st_centroid() |>
    st_coordinates() |>
    as.numeric()
}

sq_centroid <- function(sq_sf) {
  st_coordinates(st_centroid(st_union(sq_sf$tile_map))) |> as.numeric()
}

translate_group <- function(sq_sf, current_centroid, target_centroid) {
  offset <- target_centroid - current_centroid
  sq_sf |> mutate(tile_map = tile_map + offset)
}

geo_mn <- get_group_centroid("Manhattan")
geo_bx <- get_group_centroid("Bronx")
geo_bk <- get_group_centroid("Brooklyn")
geo_qn <- get_group_centroid("Queens")
geo_si <- get_group_centroid("Staten Island")

mn_sq <- translate_group(mn_sq, sq_centroid(mn_sq), geo_mn)
bx_sq <- translate_group(bx_sq, sq_centroid(bx_sq), geo_bx)
bk_sq <- translate_group(bk_sq, sq_centroid(bk_sq), geo_bk)
qn_sq <- translate_group(qn_sq, sq_centroid(qn_sq), geo_qn)
si_sq <- translate_group(si_sq, sq_centroid(si_sq), geo_si)

## -- Manual nudges ------------------------------------------------------------
mn_sq <- mn_sq |> mutate(tile_map = tile_map + c(-6900, -3500))
bx_sq <- bx_sq |> mutate(tile_map = tile_map + c(-2425, -10000))
bk_sq <- bk_sq |> mutate(tile_map = tile_map + c(2100, -1000))
qn_sq <- qn_sq |> mutate(tile_map = tile_map + c(2050, 4250))
si_sq <- si_sq |> mutate(tile_map = tile_map + c(19500, 6500))

## -- Combine all groups -------------------------------------------------------
standardize_cols <- function(sq_sf) {
  sq_sf |>
    st_set_geometry("tile_map") |>
    select(
      geoid, boro_ct2020, ct2020, boro_code, boro_name, nta2020, nta_name,
      puma, tile_map
    )
}

nyc_ct20_sq_sf <- bind_rows(
  standardize_cols(mn_sq),
  standardize_cols(bx_sq),
  standardize_cols(bk_sq),
  standardize_cols(qn_sq),
  standardize_cols(si_sq)
) |>
  st_set_crs(st_crs(ct20_sf))

## Verify
cat("Total tiles:", nrow(nyc_ct20_sq_sf), "\n")
cat("Unique tracts (boro_ct2020):", n_distinct(nyc_ct20_sq_sf$boro_ct2020), "\n")
cat("Borough counts:\n")
print(table(nyc_ct20_sq_sf$boro_name))

## Save
saveRDS(nyc_ct20_sq_sf, here::here("data-raw", "ct_sq_assembled.rds"))

## Save sample figures
p <- ggplot(nyc_ct20_sq_sf) +
  geom_sf(
    aes(fill = boro_name),
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC Census Tract 2020 Square Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_ct_sq_assembled.png"),
  p,
  width = 12,
  height = 14,
  dpi = 150,
  bg = "white"
)
