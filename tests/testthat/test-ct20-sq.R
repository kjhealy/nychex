test_that("nyc_ct20_sq_sf has expected structure", {
  expect_s3_class(nyc_ct20_sq_sf, "sf")
  expect_equal(nrow(nyc_ct20_sq_sf), 2325L)
  expect_true(inherits(sf::st_geometry(nyc_ct20_sq_sf), "sfc_POLYGON"))
  expect_false(any(sf::st_is_empty(nyc_ct20_sq_sf)))
  expect_equal(anyDuplicated(nyc_ct20_sq_sf$boro_ct2020), 0L)
  expect_true(all(
    c(
      "geoid",
      "boro_ct2020",
      "ct2020",
      "boro_code",
      "boro_name",
      "nta2020",
      "puma",
      "tile_map"
    ) %in%
      names(nyc_ct20_sq_sf)
  ))
})

test_that("nyc_ct20_sq_sf has all five boroughs", {
  expect_setequal(
    unique(nyc_ct20_sq_sf$boro_name),
    c("Manhattan", "Bronx", "Brooklyn", "Queens", "Staten Island")
  )
})

test_that("nyc_ct20_sq_sf has correct borough counts", {
  counts <- table(nyc_ct20_sq_sf$boro_name)
  expect_equal(as.integer(counts["Manhattan"]), 310L)
  expect_equal(as.integer(counts["Bronx"]), 361L)
  expect_equal(as.integer(counts["Brooklyn"]), 804L)
  expect_equal(as.integer(counts["Queens"]), 724L)
  expect_equal(as.integer(counts["Staten Island"]), 126L)
})

test_that("nyc_ct20_sq_sf has valid CRS", {
  expect_equal(sf::st_crs(nyc_ct20_sq_sf)$epsg, 2263L)
})
