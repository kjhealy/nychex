test_that("nyc_nta_boros_hex_sf has expected structure", {
  expect_s3_class(nyc_nta_boros_hex_sf, "sf")
  expect_equal(nrow(nyc_nta_boros_hex_sf), 5L)
  expect_true(inherits(
    sf::st_geometry(nyc_nta_boros_hex_sf),
    "sfc_POLYGON"
  ))
  expect_false(any(sf::st_is_empty(nyc_nta_boros_hex_sf)))
  expect_true(all(
    c("boro_code", "boro_name", "tile_map") %in%
      names(nyc_nta_boros_hex_sf)
  ))
})

test_that("nyc_nta_boros_hex_sf has all five boroughs", {
  expect_setequal(
    nyc_nta_boros_hex_sf$boro_name,
    c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island")
  )
})

test_that("nyc_nta_boros_hex_sf has valid CRS", {
  expect_equal(sf::st_crs(nyc_nta_boros_hex_sf)$epsg, 2263L)
})
