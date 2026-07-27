test_that("scan_source_db returns empty frame for empty config", {
  result <- scan_source_db(list())
  expect_equal(nrow(result), 0L)
  expect_named(result, c("source", "item", "location", "jurisdiction", "provider", "status"))
})

test_that("scan_source_db classifies a local DB as ok", {
  config <- list(
    list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")
  )
  result <- scan_source_db(config)
  expect_equal(result$jurisdiction, "local")
  expect_equal(result$status, "ok")
})

test_that("scan_source_db flags an offshore DB", {
  config <- list(
    list(item = "analytics_db", provider = "AWS", region = "us-east-1")
  )
  result <- scan_source_db(config)
  expect_equal(result$jurisdiction, "offshore")
  expect_equal(result$status, "flagged")
})

test_that("scan_source_db handles multiple entries", {
  config <- list(
    list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG"),
    list(item = "analytics_db", provider = "AWS", region = "us-east-1")
  )
  result <- scan_source_db(config)
  expect_equal(nrow(result), 2L)
})
