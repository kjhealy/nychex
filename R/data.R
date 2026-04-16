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
#'   \item{county_fips}{County FIPS code.}
#'   \item{nta_name}{Full NTA name.}
#'   \item{nta2020}{NTA 2020 identifier.}
#'   \item{boro_name}{Borough name.}
#'   \item{nta_type}{NTA type (residential or non-residential).}
#'   \item{cdta2020}{Community District Tabulation Area 2020 identifier.}
#'   \item{cdta_name}{Full CDTA name.}
#'   \item{shape_leng}{Perimeter length of the original NTA boundary.}
#'   \item{nta_abbrev}{Abbreviated NTA name.}
#'   \item{shape_area}{Area of the original NTA boundary.}
#'   \item{tile_map}{POLYGON hexagonal tile geometry (EPSG:2263).}
#' }
#'
#' @details
#' The hex map was generated using the [tilemaps][tilemaps::generate_map]
#' algorithm applied to borough groups separately (Manhattan, Bronx,
#' Brooklyn/Queens, Staten Island), then rescaled to uniform hex size and
#' assembled to preserve NYC's overall geographic layout. Island NTAs were
#' added back using [tilemaps::create_island()] and positioned to
#' approximate their geographic locations.
#'
#' @author Kieran Healy
#' @source Derived from NTA 2020 boundaries in the \pkg{nycmaps} package
#'   using the \pkg{tilemaps} algorithm.
"nyc_nta20_hex_sf"


#' Borough outlines for the NYC NTA 2020 hex map
#'
#' Polygon outlines of the main contiguous hex area for each NYC borough,
#' derived from [nyc_nta20_hex_sf]. Disconnected island hexes are excluded.
#' Brooklyn and Queens have separate outlines, so the shared border between
#' them is visible.
#'
#' @format ## `nyc_nta_boros_hex_sf`
#' A simple feature collection with 5 rows and 3 columns:
#' \describe{
#'   \item{boro_name}{Borough name.}
#'   \item{boro_code}{Borough code. 1 = Manhattan, 2 = Bronx,
#'     3 = Brooklyn, 4 = Queens, 5 = Staten Island.}
#'   \item{tile_map}{POLYGON outline geometry (EPSG:2263).}
#' }
#'
#' @author Kieran Healy
#' @source Derived from [nyc_nta20_hex_sf] by unioning hex tiles per
#'   borough and extracting the largest polygon.
"nyc_nta_boros_hex_sf"


#' Borough outlines for the NYC census tract 2020 hex map
#'
#' Polygon outlines of the main contiguous hex area for each NYC borough,
#' derived from [nyc_ct20_hex_sf]. Disconnected island hexes are excluded.
#' Brooklyn and Queens have separate outlines, so the shared border between
#' them is visible.
#'
#' @format ## `nyc_ct_boros_hex_sf`
#' A simple feature collection with 5 rows and 3 columns:
#' \describe{
#'   \item{boro_name}{Borough name.}
#'   \item{boro_code}{Borough code. 1 = Manhattan, 2 = Bronx,
#'     3 = Brooklyn, 4 = Queens, 5 = Staten Island.}
#'   \item{tile_map}{POLYGON outline geometry (EPSG:2263).}
#' }
#'
#' @author Kieran Healy
#' @source Derived from [nyc_ct20_hex_sf] by unioning hex tiles per
#'   borough and extracting the largest polygon.
"nyc_ct_boros_hex_sf"


#' Hexagonal tile map of NYC census tracts (2020)
#'
#' A tessellated hexagonal tile map of New York City's 2020 census tracts.
#' Each tract in the main contiguous area of each borough is represented
#' by a single hexagonal polygon tile, arranged to approximate the
#' geographic layout of the city. Island and disconnected tracts are
#' excluded.
#'
#' @format ## `nyc_ct20_hex_sf`
#' A simple feature collection with 2271 rows and 9 columns:
#' \describe{
#'   \item{geoid}{Census GEOID (state + county + tract FIPS code). Use
#'     this column for joining with other tract-level data.}
#'   \item{boro_ct2020}{Unique borough-tract identifier (borough code
#'     concatenated with tract code).}
#'   \item{ct2020}{Census tract 2020 code (not unique across boroughs).}
#'   \item{boro_code}{Borough code. 1 = Manhattan, 2 = Bronx,
#'     3 = Brooklyn, 4 = Queens, 5 = Staten Island.}
#'   \item{boro_name}{Borough name.}
#'   \item{nta2020}{NTA 2020 identifier for the tract.}
#'   \item{nta_name}{Full NTA name.}
#'   \item{puma}{Public Use Microdata Area code.}
#'   \item{tile_map}{POLYGON hexagonal tile geometry (EPSG:2263).}
#' }
#'
#' @details
#' The hex map was generated using the [tilemaps][tilemaps::generate_map]
#' algorithm applied to each borough separately (Manhattan, Bronx,
#' Brooklyn, Queens, Staten Island), then rescaled to uniform hex size and
#' assembled to preserve NYC's overall geographic layout. Unlike the NTA
#' hex map, Brooklyn and Queens were tiled as separate boroughs rather
#' than combined, so there is a visible gap between them.
#'
#' Island tracts (those in geographically disconnected NTAs or that become
#' disconnected after polygon simplification) are not included in this
#' object. The 2,271 tracts represented are the main contiguous tracts
#' for each borough out of 2,325 total NYC census tracts.
#'
#' @author Kieran Healy
#' @source Derived from census tract 2020 boundaries in the \pkg{nycmaps}
#'   package using the \pkg{tilemaps} algorithm.
"nyc_ct20_hex_sf"
