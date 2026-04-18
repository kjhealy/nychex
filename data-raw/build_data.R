## Build all hex map data for nychex
## Run this script to regenerate all data objects from source

source(here::here("data-raw", "hex_manhattan.R"))
source(here::here("data-raw", "hex_bronx.R"))
source(here::here("data-raw", "hex_brooklyn_queens.R"))
source(here::here("data-raw", "hex_staten_island.R"))
source(here::here("data-raw", "hex_assembly.R"))

## Load the assembled result and save as package data
nyc_nta20_hex_sf <- readRDS(here::here("data-raw", "hex_assembled.rds"))

usethis::use_data(nyc_nta20_hex_sf, overwrite = TRUE, compress = "xz")

## Build NTA borough outlines
source(here::here("data-raw", "hex_boro_outlines.R"))

## Build NTA square tile map
source(here::here("data-raw", "sq_manhattan.R"))
source(here::here("data-raw", "sq_bronx.R"))
source(here::here("data-raw", "sq_brooklyn_queens.R"))
source(here::here("data-raw", "sq_staten_island.R"))
source(here::here("data-raw", "sq_assembly.R"))
nyc_nta20_sq_sf <- readRDS(here::here("data-raw", "sq_assembled.rds"))
usethis::use_data(nyc_nta20_sq_sf, overwrite = TRUE, compress = "xz")

## Build NTA square borough outlines
source(here::here("data-raw", "sq_boro_outlines.R"))

## Build census tract hex map (contiguous tracts), then add islands
source(here::here("data-raw", "ct_hex_assembly.R"))
source(here::here("data-raw", "ct_hex_islands.R"))
nyc_ct20_hex_sf <- readRDS(here::here("data-raw", "ct_hex_assembled.rds"))
usethis::use_data(nyc_ct20_hex_sf, overwrite = TRUE, compress = "xz")
source(here::here("data-raw", "ct_hex_boro_outlines.R"))

## Build census tract square tile map (contiguous tracts), then add islands
source(here::here("data-raw", "ct_sq_assembly.R"))
source(here::here("data-raw", "ct_sq_islands.R"))
nyc_ct20_sq_sf <- readRDS(here::here("data-raw", "ct_sq_assembled.rds"))
usethis::use_data(nyc_ct20_sq_sf, overwrite = TRUE, compress = "xz")
source(here::here("data-raw", "ct_sq_boro_outlines.R"))
