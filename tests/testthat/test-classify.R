test_that("local Nigerian providers classify as local", {
  expect_equal(classify_jurisdiction("MainOne", "Lagos-NG"), "local")
  expect_equal(classify_jurisdiction("Galaxy Backbone", "Abuja"), "local")
  expect_equal(classify_jurisdiction("Rack Centre", "Lagos"), "local")
})

test_that("known hyperscaler regions classify as offshore", {
  expect_equal(classify_jurisdiction("AWS", "us-east-1"), "offshore")
  expect_equal(classify_jurisdiction("Azure", "West Europe (Ireland)"), "offshore")
  expect_equal(classify_jurisdiction("Google Cloud", "europe-west1 (Frankfurt)"), "offshore")
})

test_that("ambiguous or unrecognized strings classify as unknown", {
  expect_equal(classify_jurisdiction("SomeVendor", "Unknown Region"), "unknown")
})

test_that("mixed NG + offshore signals classify as unknown for manual review", {
  expect_equal(classify_jurisdiction("AWS", "ng-lagos-1"), "unknown")
})

test_that("classify_jurisdiction is properly vectorized across rows", {
  providers <- c("MainOne", "AWS", "SomeVendor", "AWS")
  regions   <- c("Lagos", "us-east-1", "Unknown Region", "ng-lagos-1")
  expected  <- c("local", "offshore", "unknown", "unknown")
  expect_equal(classify_jurisdiction(providers, regions), expected)
})

test_that("WIOCC (verified operating a Lagos, Nigeria facility) classifies as local", {
  expect_equal(classify_jurisdiction("WIOCC", "Lagos-NG"), "local")
})
