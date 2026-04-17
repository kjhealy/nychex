test_that("nyc_nta20_sq_sf has expected structure", {
  expect_s3_class(nyc_nta20_sq_sf, "sf")
  expect_equal(nrow(nyc_nta20_sq_sf), 262L)
  expect_true(inherits(sf::st_geometry(nyc_nta20_sq_sf), "sfc_POLYGON"))
  expect_false(any(sf::st_is_empty(nyc_nta20_sq_sf)))
  expect_equal(anyDuplicated(nyc_nta20_sq_sf$nta2020), 0L)
  expect_true(all(
    c(
      "boro_code",
      "boro_name",
      "nta2020",
      "nta_name",
      "nta_abbrev",
      "tile_map"
    ) %in%
      names(nyc_nta20_sq_sf)
  ))
})

test_that("nyc_nta20_sq_sf has all five boroughs", {
  expect_setequal(
    unique(nyc_nta20_sq_sf$boro_name),
    c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island")
  )
})

test_that("nyc_nta20_sq_sf has correct borough counts", {
  counts <- table(nyc_nta20_sq_sf$boro_name)
  expect_equal(as.integer(counts["Manhattan"]), 38L)
  expect_equal(as.integer(counts["Bronx"]), 50L)
  expect_equal(as.integer(counts["Brooklyn"]), 69L)
  expect_equal(as.integer(counts["Queens"]), 82L)
  expect_equal(as.integer(counts["Staten Island"]), 23L)
})

test_that("nyc_nta20_sq_sf has valid CRS", {
  expect_equal(sf::st_crs(nyc_nta20_sq_sf)$epsg, 2263L)
})
