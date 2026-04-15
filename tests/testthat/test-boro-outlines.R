test_that("nyc_boro_hex_outlines_sf has expected structure", {
  expect_s3_class(nyc_boro_hex_outlines_sf, "sf")
  expect_equal(nrow(nyc_boro_hex_outlines_sf), 5L)
  expect_true(inherits(
    sf::st_geometry(nyc_boro_hex_outlines_sf),
    "sfc_POLYGON"
  ))
  expect_false(any(sf::st_is_empty(nyc_boro_hex_outlines_sf)))
  expect_true(all(
    c("boro_code", "boro_name", "tile_map") %in%
      names(nyc_boro_hex_outlines_sf)
  ))
})

test_that("nyc_boro_hex_outlines_sf has all five boroughs", {
  expect_setequal(
    nyc_boro_hex_outlines_sf$boro_name,
    c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island")
  )
})

test_that("nyc_boro_hex_outlines_sf has valid CRS", {
  expect_equal(sf::st_crs(nyc_boro_hex_outlines_sf)$epsg, 2263L)
})
