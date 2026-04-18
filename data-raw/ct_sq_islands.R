source(here::here("data-raw", "_shared.R"))

ct20_sf <- nycmaps::nyc_census_tracts_2020_sf
nta_hex <- readRDS(here::here("data-raw", "hex_assembled.rds"))
ct_sq <- readRDS(here::here("data-raw", "ct_sq_contiguous.rds"))

## Identify missing tracts
missing_sf <- ct20_sf |>
  filter(!geoid %in% ct_sq$geoid)

cat("Missing tracts to add:", nrow(missing_sf), "\n")

## Target tile area (matches existing CT square tiles)
target_area <- median(as.numeric(st_area(ct_sq$tile_map)))
spacing <- sqrt(target_area)
cat("Square tile spacing:", round(spacing), "\n")

## -- Helpers ------------------------------------------------------------------
nta_pos <- function(nta_code) {
  idx <- which(nta_hex$nta2020 == nta_code)
  st_coordinates(st_centroid(nta_hex$tile_map[idx])) |> as.numeric()
}

rescale_island_group <- function(sf_obj, target_area) {
  geom <- sf_obj$tile_map
  current_area <- median(as.numeric(st_area(geom)))
  scale_factor <- sqrt(target_area / current_area)
  group_centroid <- st_coordinates(st_centroid(st_union(geom)))
  sf_obj$tile_map <- (geom - group_centroid) * scale_factor + group_centroid
  sf_obj
}

move_group <- function(sf_obj, target) {
  current <- st_coordinates(st_centroid(st_union(sf_obj$tile_map))) |> as.numeric()
  offset <- target - current
  sf_obj |> mutate(tile_map = tile_map + offset)
}

prep_tracts <- function(nta_codes) {
  missing_sf |>
    filter(nta2020 %in% nta_codes) |>
    st_cast("POLYGON") |>
    mutate(area = st_area(geometry)) |>
    slice_max(area, n = 1, by = geoid) |>
    ms_simplify(keep = 0.01, keep_shapes = TRUE)
}

find_components <- function(sf_obj) {
  touches <- st_touches(sf_obj)
  n <- nrow(sf_obj)
  components <- rep(0L, n)
  comp_id <- 0L
  for (start in seq_len(n)) {
    if (components[start] > 0) next
    comp_id <- comp_id + 1L
    queue <- start
    components[start] <- comp_id
    while (length(queue) > 0) {
      current <- queue[1]
      queue <- queue[-1]
      neighbors <- touches[[current]]
      new_neighbors <- neighbors[components[neighbors] == 0]
      components[new_neighbors] <- comp_id
      queue <- c(queue, new_neighbors)
    }
  }
  components
}

template_tiles <- ct_sq$tile_map[1:10]

make_island_sf <- function(src_sf, tile_geom, crs) {
  src_sf |>
    st_drop_geometry() |>
    select(any_of(c(
      "geoid", "boro_ct2020", "ct2020", "boro_code", "boro_name",
      "nta2020", "nta_name", "puma"
    ))) |>
    mutate(tile_map = tile_geom) |>
    st_as_sf(sf_column_name = "tile_map") |>
    st_set_crs(crs)
}

make_tiled_sf <- function(sf_obj, crs) {
  sf_obj |>
    st_set_geometry("tile_map") |>
    select(any_of(c(
      "geoid", "boro_ct2020", "ct2020", "boro_code", "boro_name",
      "nta2020", "nta_name", "puma", "tile_map"
    ))) |>
    st_set_crs(crs)
}

target_crs <- st_crs(ct_sq)
island_parts <- list()

## == MANHATTAN ================================================================

## MN0191 — Battery/Governors/Ellis/Liberty (3 non-contiguous tracts)
mn0191 <- prep_tracts("MN0191")
mn0191_ref <- nta_pos("MN0191") + c(2500, 4000)
mn0191_tiles <- purrr::map(
  seq_len(nrow(mn0191)),
  \(i) create_island(template_tiles, mn0191_ref + c((i - 2) * spacing, 0))
)
island_parts$mn0191 <- make_island_sf(mn0191, do.call(c, mn0191_tiles), target_crs)

## MN1191 — Randall's Island (1 tract)
island_parts$mn1191 <- make_island_sf(
  missing_sf |> filter(nta2020 == "MN1191"),
  create_island(template_tiles, nta_pos("MN1191")),
  target_crs
)

## MN0801 — Roosevelt Island (3 contiguous tracts, disconnected from main)
mn0801 <- prep_tracts("MN0801")
set.seed(42)
mn0801 <- mn0801 |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
mn0801 <- rescale_island_group(mn0801, target_area)
mn0801 <- move_group(mn0801, nta_pos("MN1191") + c(0, -3 * spacing))
island_parts$mn0801 <- make_tiled_sf(mn0801, target_crs)

## BX0802 — Marble Hill (1 tract, disconnected from Manhattan)
mn_bbox <- st_bbox(ct_sq$tile_map[ct_sq$boro_name == "Manhattan"])
island_parts$bx0802 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BX0802"),
  create_island(template_tiles, c(mn_bbox["xmax"] + spacing, mn_bbox["ymax"])),
  target_crs
)

## == BRONX ====================================================================

## BX1003 — City Island (6 tracts: 3 contiguous + 3 islands)
bx1003 <- prep_tracts("BX1003")
bx1003_comps <- find_components(bx1003)
largest_comp <- as.integer(names(which.max(table(bx1003_comps))))
bx1003_main <- bx1003[bx1003_comps == largest_comp, ]
bx1003_islands <- bx1003[bx1003_comps != largest_comp, ]

set.seed(42)
bx1003_main <- bx1003_main |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
bx1003_main <- rescale_island_group(bx1003_main, target_area)
bx1003_target <- nta_pos("BX1003") + c(-17000, -9560)
bx1003_main <- move_group(bx1003_main, bx1003_target)

bx1003_main_bbox <- st_bbox(bx1003_main$tile_map)
bx1003_island_tiles <- purrr::map(
  seq_len(nrow(bx1003_islands)),
  \(i) create_island(
    template_tiles,
    c(bx1003_target[1] + (i - 2) * spacing, bx1003_main_bbox["ymin"] - spacing)
  )
)

island_parts$bx1003_main <- make_tiled_sf(bx1003_main, target_crs)
island_parts$bx1003_islands <- make_island_sf(
  bx1003_islands, do.call(c, bx1003_island_tiles), target_crs
)

## BX1071 — Hart Island (1 tract)
## Positioned directly E of the easternmost tile of BX1003
bx1003_main_coords <- st_coordinates(st_centroid(bx1003_main$tile_map))
bx1003_island_coords <- do.call(rbind, lapply(
  bx1003_island_tiles, \(t) st_coordinates(st_centroid(t))
))
bx1003_all_coords <- rbind(bx1003_main_coords, bx1003_island_coords)
bx1003_e <- bx1003_all_coords[which.max(bx1003_all_coords[, 1]), ]
bx1071_pos <- bx1003_e + c(spacing, 0)
island_parts$bx1071 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BX1071"),
  create_island(template_tiles, bx1071_pos),
  target_crs
)

## BX0291 — North & South Brother Islands (1 tract)
## Positioned NW of QN0151
qn0151_final <- nta_pos("QN0151") + c(-2000, -1500)
island_parts$bx0291 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BX0291"),
  create_island(template_tiles, qn0151_final + c(-spacing, spacing)),
  target_crs
)

## QN0151 — Rikers Island (1 tract)
island_parts$qn0151 <- make_island_sf(
  missing_sf |> filter(nta2020 == "QN0151"),
  create_island(template_tiles, qn0151_final),
  target_crs
)

## == BROOKLYN =================================================================

## BK5692 at its NTA hex position; BK1891 and BK5691 grouped below it
bk5692_pos <- nta_pos("BK5692")
island_parts$bk5692 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BK5692"),
  create_island(template_tiles, bk5692_pos),
  target_crs
)
island_parts$bk1891 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BK1891"),
  create_island(template_tiles, bk5692_pos + c(-spacing, -spacing)),
  target_crs
)
island_parts$bk5691 <- make_island_sf(
  missing_sf |> filter(nta2020 == "BK5691"),
  create_island(template_tiles, bk5692_pos + c(spacing, -spacing)),
  target_crs
)

## == QUEENS ===================================================================

## QN0761 — Fort Totten (1 tract)
island_parts$qn0761 <- make_island_sf(
  missing_sf |> filter(nta2020 == "QN0761"),
  create_island(template_tiles, nta_pos("QN0761") + c(0, -3000)),
  target_crs
)

## QN8491 — Jamaica Bay East (1 tract)
island_parts$qn8491 <- make_island_sf(
  missing_sf |> filter(nta2020 == "QN8491"),
  create_island(template_tiles, nta_pos("QN8491") + c(0, 5000)),
  target_crs
)

## -- Rockaway chain: built E to W, positioned relative to JFK ----------------

## QN1401 — Far Rockaway (11 contiguous tracts)
qn1401 <- prep_tracts("QN1401")
set.seed(42)
qn1401 <- qn1401 |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
qn1401 <- rescale_island_group(qn1401, target_area)
qn1401 <- move_group(qn1401, nta_pos("QN1401"))

jfk_pos <- st_coordinates(st_centroid(
  ct_sq$tile_map[ct_sq$nta2020 == "QN8381"]
)) |> as.numeric()
qn1401_coords <- st_coordinates(st_centroid(qn1401$tile_map))
qn1401_top <- qn1401_coords[which.max(qn1401_coords[, 2]), ]
jfk_s <- jfk_pos + c(0, -spacing)
qn1401 <- qn1401 |> mutate(tile_map = tile_map + (jfk_s - qn1401_top))

island_parts$qn1401 <- make_tiled_sf(qn1401, target_crs)

## QN1491 — Rockaway Community Park (1 tract)
## Directly W of QN1401's SW tile
qn1401_coords <- st_coordinates(st_centroid(qn1401$tile_map))
qn1401_min_y <- min(qn1401_coords[, 2])
qn1401_bottom <- which(qn1401_coords[, 2] == qn1401_min_y)
qn1401_sw <- qn1401_coords[qn1401_bottom[which.min(qn1401_coords[qn1401_bottom, 1])], ]
qn1491_pos <- qn1401_sw + c(-spacing, 0)

island_parts$qn1491 <- make_island_sf(
  missing_sf |> filter(nta2020 == "QN1491"),
  create_island(template_tiles, qn1491_pos),
  target_crs
)

## QN1402 — Rockaway Beach (9 contiguous tracts)
## Northernmost tile placed SE of QN1491
qn1402 <- prep_tracts("QN1402")
set.seed(42)
qn1402 <- qn1402 |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
qn1402 <- rescale_island_group(qn1402, target_area)
qn1402 <- move_group(qn1402, nta_pos("QN1402"))

qn1402_coords <- st_coordinates(st_centroid(qn1402$tile_map))
qn1402_top <- qn1402_coords[which.max(qn1402_coords[, 2]), ]
qn1402_target_top <- qn1491_pos + c(0, -spacing)
qn1402 <- qn1402 |> mutate(tile_map = tile_map + (qn1402_target_top - qn1402_top))

island_parts$qn1402 <- make_tiled_sf(qn1402, target_crs)

## QN1403 — Breezy Point area (7 tracts: 5 contiguous + 2 islands)
qn1403 <- prep_tracts("QN1403")
qn1403_comps <- find_components(qn1403)
largest_comp <- as.integer(names(which.max(table(qn1403_comps))))
qn1403_main <- qn1403[qn1403_comps == largest_comp, ]
qn1403_islands <- qn1403[qn1403_comps != largest_comp, ]

set.seed(42)
qn1403_main <- qn1403_main |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
qn1403_main <- rescale_island_group(qn1403_main, target_area)
qn1403_main <- move_group(qn1403_main, nta_pos("QN1403"))

## Easternmost tile placed W of QN1402's westernmost
qn1402_coords <- st_coordinates(st_centroid(qn1402$tile_map))
qn1402_w <- qn1402_coords[which.min(qn1402_coords[, 1]), ]
qn1403_main_coords <- st_coordinates(st_centroid(qn1403_main$tile_map))
qn1403_e <- qn1403_main_coords[which.max(qn1403_main_coords[, 1]), ]
qn1403_main <- qn1403_main |>
  mutate(tile_map = tile_map + (qn1402_w + c(-spacing, 0) - qn1403_e))

## Align top row right edges with bottom row right edges
qn1403_main_coords <- st_coordinates(st_centroid(qn1403_main$tile_map))
qn1403_main_ys <- sort(unique(round(qn1403_main_coords[, 2])))
bottom_y <- qn1403_main_ys[1]
top_y <- qn1403_main_ys[2]
bottom_max_x <- max(qn1403_main_coords[round(qn1403_main_coords[, 2]) == bottom_y, 1])
top_max_x <- max(qn1403_main_coords[round(qn1403_main_coords[, 2]) == top_y, 1])
top_row_mask <- round(qn1403_main_coords[, 2]) == top_y
qn1403_main$tile_map[top_row_mask] <- qn1403_main$tile_map[top_row_mask] +
  c(bottom_max_x - top_max_x, 0)

## Nudge QN1403 main east to close gap with QN1402
qn1403_main <- qn1403_main |> mutate(tile_map = tile_map + c(3250, 0))

island_parts$qn1403_main <- make_tiled_sf(qn1403_main, target_crs)

## QN1403 island tracts (2) — just N of QN1403 main, shifted W and N
qn1403_main_coords <- st_coordinates(st_centroid(qn1403_main$tile_map))
qn1403_main_top_y <- max(qn1403_main_coords[, 2])
qn1403_main_w_x <- min(qn1403_main_coords[, 1])
qn1403_island_tiles <- purrr::map(
  seq_len(nrow(qn1403_islands)),
  \(i) create_island(
    template_tiles,
    c(
      qn1403_main_w_x + (i - 1) * spacing - 1000,
      qn1403_main_top_y + spacing + 500
    )
  )
)
island_parts$qn1403_islands <- make_island_sf(
  qn1403_islands, do.call(c, qn1403_island_tiles), target_crs
)

## QN8492 — Jacob Riis Park (3 contiguous tracts)
## Easternmost tile placed W of QN1403 main's westernmost (after nudge)
qn8492 <- prep_tracts("QN8492")
set.seed(42)
qn8492 <- qn8492 |>
  mutate(tile_map = generate_map(geometry, square = TRUE))
qn8492 <- rescale_island_group(qn8492, target_area)
qn8492 <- move_group(qn8492, nta_pos("QN8492"))

qn1403_main_coords <- st_coordinates(st_centroid(qn1403_main$tile_map))
qn1403_w <- qn1403_main_coords[which.min(qn1403_main_coords[, 1]), ]
qn8492_coords <- st_coordinates(st_centroid(qn8492$tile_map))
qn8492_e <- qn8492_coords[which.max(qn8492_coords[, 1]), ]
qn8492 <- qn8492 |>
  mutate(tile_map = tile_map + (qn1403_w + c(-spacing, 0) - qn8492_e))

island_parts$qn8492 <- make_tiled_sf(qn8492, target_crs)

## == STATEN ISLAND ============================================================

## SI9591 — Hoffman & Swinburne Islands (1 tract)
si_main <- ct_sq |> filter(boro_name == "Staten Island")
si_bbox <- st_bbox(si_main$tile_map)
si9591_pos <- c(si_bbox["xmax"] + spacing, si_bbox["ymin"])
si9591_pos <- si9591_pos + c(-6000 / sqrt(2) - 4250, 6000 / sqrt(2))

island_parts$si9591 <- make_island_sf(
  missing_sf |> filter(nta2020 == "SI9591"),
  create_island(template_tiles, si9591_pos),
  target_crs
)

## == COMBINE ==================================================================
all_islands <- bind_rows(island_parts)
cat("Island tracts assembled:", nrow(all_islands), "\n")

ct_sq_full <- bind_rows(ct_sq, all_islands)
cat("Full CT square map:", nrow(ct_sq_full), "tracts\n")
cat("Unique geoids:", n_distinct(ct_sq_full$geoid), "\n")
cat("Borough counts:\n")
print(table(ct_sq_full$boro_name))

## Save
saveRDS(ct_sq_full, here::here("data-raw", "ct_sq_assembled.rds"))

## Sample figure
p <- ggplot(ct_sq_full) +
  geom_sf(aes(fill = boro_name), color = "white", linewidth = 0.1) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "NYC Census Tract 2020 Square Map", fill = "Borough") +
  theme_void()

ggsave(
  here::here("data-raw", "sample-figures", "nyc_ct_sq_assembled.png"),
  p, width = 12, height = 14, dpi = 150, bg = "white"
)
