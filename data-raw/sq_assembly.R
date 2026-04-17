source(here::here("data-raw", "_shared.R"))

nta20_sf <- nycmaps::nyc_nta20_sf

## Load all borough square maps
mn_sq_sf <- readRDS(here::here("data-raw", "sq_manhattan.rds"))
bx_sq_sf <- readRDS(here::here("data-raw", "sq_bronx.rds"))
bkqn_sq_sf <- readRDS(here::here("data-raw", "sq_brooklyn_queens.rds"))
si_sq_sf <- readRDS(here::here("data-raw", "sq_staten_island.rds"))

## -- Rescale all tiles to uniform size --------------------------------------
all_areas <- c(
  as.numeric(st_area(mn_sq_sf$tile_map)),
  as.numeric(st_area(bx_sq_sf$tile_map)),
  as.numeric(st_area(bkqn_sq_sf$tile_map)),
  as.numeric(st_area(si_sq_sf$tile_map))
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

mn_sq_sf <- rescale_group(mn_sq_sf, target_area)
bx_sq_sf <- rescale_group(bx_sq_sf, target_area)
bkqn_sq_sf <- rescale_group(bkqn_sq_sf, target_area)
si_sq_sf <- rescale_group(si_sq_sf, target_area)

## -- Position each group using geographic centroids -------------------------
get_group_centroid <- function(sf_obj, boro_filter) {
  nta20_sf |>
    filter(boro_name %in% boro_filter) |>
    summarise(geometry = st_union(geometry)) |>
    st_centroid() |>
    st_coordinates() |>
    as.numeric()
}

hex_centroid <- function(sq_sf) {
  st_coordinates(st_centroid(st_union(sq_sf$tile_map))) |> as.numeric()
}

translate_group <- function(sq_sf, current_centroid, target_centroid) {
  offset <- target_centroid - current_centroid
  sq_sf |>
    mutate(tile_map = tile_map + offset)
}

geo_mn <- get_group_centroid(nta20_sf, "Manhattan")
geo_bx <- get_group_centroid(nta20_sf, "Bronx")
geo_bkqn <- get_group_centroid(nta20_sf, c("Brooklyn", "Queens"))
geo_si <- get_group_centroid(nta20_sf, "Staten Island")

mn_sq_sf <- translate_group(mn_sq_sf, hex_centroid(mn_sq_sf), geo_mn)
bx_sq_sf <- translate_group(bx_sq_sf, hex_centroid(bx_sq_sf), geo_bx)
bkqn_sq_sf <- translate_group(bkqn_sq_sf, hex_centroid(bkqn_sq_sf), geo_bkqn)
si_sq_sf <- translate_group(si_sq_sf, hex_centroid(si_sq_sf), geo_si)

## -- Manual nudges (starting from hex map values) ---------------------------
mn_sq_sf <- mn_sq_sf |> mutate(tile_map = tile_map + c(-8500, 0))
bx_sq_sf <- bx_sq_sf |> mutate(tile_map = tile_map + c(4575, 2000))
si_sq_sf <- si_sq_sf |> mutate(tile_map = tile_map + c(17000, 6000))

## -- Combine all groups -----------------------------------------------------
nyc_nta20_sq_sf <- bind_rows(mn_sq_sf, bx_sq_sf, bkqn_sq_sf, si_sq_sf) |>
  st_set_crs(st_crs(nta20_sf))

## -- move_nta helper (square grid version) ----------------------------------
## For square tiles, neighbors are at (+-spacing, 0) and (0, +-spacing)
move_nta <- function(sq_sf, nta_codes, ref, dir, anchor = NULL,
                     spacing_ref = NULL) {
  spacing_nta <- if (!is.null(spacing_ref)) spacing_ref else ref
  ref_boro <- sq_sf$boro_name[sq_sf$nta2020 == spacing_nta]
  boro_idx <- which(sq_sf$boro_name == ref_boro &
    !sq_sf$nta2020 %in% nta_codes)
  boro_coords <- st_coordinates(st_centroid(sq_sf$tile_map[boro_idx]))
  boro_dists <- as.matrix(dist(boro_coords))
  diag(boro_dists) <- Inf
  spacing <- min(boro_dists)

  offsets <- list(
    e  = c(spacing, 0),
    w  = c(-spacing, 0),
    n  = c(0, spacing),
    s  = c(0, -spacing),
    ne = c(spacing, spacing),
    nw = c(-spacing, spacing),
    se = c(spacing, -spacing),
    sw = c(-spacing, -spacing)
  )
  offset <- offsets[[dir]]

  ref_centroid <- st_coordinates(st_centroid(sq_sf$tile_map[
    sq_sf$nta2020 == ref
  ]))
  target_pos <- ref_centroid + offset

  idx <- which(sq_sf$nta2020 %in% nta_codes)
  if (!is.null(anchor)) {
    anchor_pos <- st_coordinates(st_centroid(
      sq_sf$tile_map[sq_sf$nta2020 == anchor]
    ))
  } else {
    anchor_pos <- st_coordinates(st_centroid(st_union(sq_sf$tile_map[idx])))
  }
  shift <- target_pos - anchor_pos
  sq_sf$tile_map[idx] <- sq_sf$tile_map[idx] + shift

  sq_sf
}

## -- Island position adjustments (mirroring hex version) --------------------
## BX1003, BX0291 — nudge 1500ft W
for (nta in c("BX1003", "BX0291")) {
  idx <- which(nyc_nta20_sq_sf$nta2020 == nta)
  nyc_nta20_sq_sf$tile_map[idx] <- nyc_nta20_sq_sf$tile_map[idx] + c(-1500, 0)
}
## SI9591 — SE of SI9592
nyc_nta20_sq_sf <- move_nta(nyc_nta20_sq_sf, "SI9591", ref = "SI9592", dir = "se")
## BX1071 — SE of BX0101
nyc_nta20_sq_sf <- move_nta(nyc_nta20_sq_sf, "BX1071", ref = "BX0101", dir = "se")
## QN0151 — N of QN0102
nyc_nta20_sq_sf <- move_nta(nyc_nta20_sq_sf, "QN0151", ref = "QN0102", dir = "n")
## MN1191 — W of QN0151 (using BK/QN spacing)
nyc_nta20_sq_sf <- move_nta(
  nyc_nta20_sq_sf, "MN1191", ref = "QN0151", dir = "w",
  spacing_ref = "QN0102"
)
## BK5692, BK1891, BK5691 — two hops SE of BK1892
nyc_nta20_sq_sf <- move_nta(
  nyc_nta20_sq_sf, c("BK5692", "BK1891", "BK5691"),
  ref = "BK1892", dir = "se"
)
nyc_nta20_sq_sf <- move_nta(
  nyc_nta20_sq_sf, c("BK5692", "BK1891", "BK5691"),
  ref = "BK5692", dir = "se"
)
## QN8491 — SW of QN8381
nyc_nta20_sq_sf <- move_nta(nyc_nta20_sq_sf, "QN8491", ref = "QN8381", dir = "sw")
## Rockaway chain — SE of QN8491, anchored on QN1491
nyc_nta20_sq_sf <- move_nta(
  nyc_nta20_sq_sf,
  c("QN1491", "QN1401", "QN1402", "QN1403", "QN8492"),
  ref = "QN8491", dir = "se", anchor = "QN1491"
)
## Reverse Rockaway horizontal order
rock_ntas <- c("QN1401", "QN1402", "QN1403", "QN8492")
rock_idx <- match(rock_ntas, nyc_nta20_sq_sf$nta2020)
rock_geoms <- nyc_nta20_sq_sf$tile_map[rock_idx]
rock_xs <- vapply(
  seq_along(rock_geoms),
  \(i) st_coordinates(st_centroid(rock_geoms[i]))[1],
  numeric(1)
)
nyc_nta20_sq_sf$tile_map[rock_idx] <- rock_geoms[order(rock_xs, decreasing = TRUE)]
## QN0761 — NE of QN0704
nyc_nta20_sq_sf <- move_nta(nyc_nta20_sq_sf, "QN0761", ref = "QN0704", dir = "ne")

## Verify
cat("Total tiles:", nrow(nyc_nta20_sq_sf), "\n")
cat("Unique NTAs:", n_distinct(nyc_nta20_sq_sf$nta2020), "\n")
cat("Borough counts:\n")
print(table(nyc_nta20_sq_sf$boro_name))

## Save
saveRDS(nyc_nta20_sq_sf, here::here("data-raw", "sq_assembled.rds"))

## Save sample figures
p <- ggplot(nyc_nta20_sq_sf) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.3) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC NTA 2020 Square Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_sq_assembled.png"),
  p, width = 12, height = 14, dpi = 150, bg = "white"
)

## Labeled version
p2 <- ggplot(nyc_nta20_sq_sf) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.3) +
  geom_sf_text(aes(label = nta2020), size = 1.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC NTA 2020 Square Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_sq_labeled.png"),
  p2, width = 16, height = 18, dpi = 200, bg = "white"
)
