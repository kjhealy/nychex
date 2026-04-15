#' Hexagonal tile map of NYC Neighborhood Tabulation Areas (2020)
#'
#' A tessellated hexagonal tile map of New York City's 262 Neighborhood
#' Tabulation Areas (NTA 2020). Each NTA is represented by a single
#' hexagonal polygon tile, arranged to approximate the geographic layout
#' of the city.
#'
#' @format ## `nyc_nta20_hex_sf`
#' A simple feature collection with 262 rows and 12 columns:
#' \describe{
#'   \item{boro_code}{Borough code. 1 = Manhattan, 2 = Bronx,
#'     3 = Brooklyn, 4 = Queens, 5 = Staten Island.}
#'   \item{boro_name}{Borough name.}
#'   \item{county_fips}{County FIPS code.}
#'   \item{nta2020}{NTA 2020 identifier.}
#'   \item{nta_name}{Full NTA name.}
#'   \item{nta_abbrev}{Abbreviated NTA name.}
#'   \item{nta_type}{NTA type (residential or non-residential).}
#'   \item{cdta2020}{Community District Tabulation Area 2020 identifier.}
#'   \item{cdta_name}{Full CDTA name.}
#'   \item{shape_leng}{Perimeter length of the original NTA boundary.}
#'   \item{shape_area}{Area of the original NTA boundary.}
#'   \item{tile_map}{POLYGON hexagonal tile geometry (EPSG:2263).}
#' }
#'
#' @details
#' The hex map was generated using the [tilemaps][tilemaps::generate_map]
#' algorithm applied to borough groups separately, then assembled to
#' preserve NYC's overall geographic layout. Borough groups (Manhattan,
#' Bronx, Brooklyn/Queens, Staten Island) were tiled independently, so
#' hex sizes vary across groups. Island NTAs were added back using
#' [tilemaps::create_island()] and positioned to approximate their
#' geographic locations.
#'
#' @author Kieran Healy
#' @source Derived from NTA 2020 boundaries in the \pkg{nycmaps} package
#'   using the \pkg{tilemaps} algorithm.
"nyc_nta20_hex_sf"
