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
