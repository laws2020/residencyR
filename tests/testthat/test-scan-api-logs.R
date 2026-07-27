test_that("scan_source_api_logs returns empty frame for empty config", {
  result <- scan_source_api_logs(list())
  expect_equal(nrow(result), 0L)
  expect_named(result, c("source", "item", "location", "jurisdiction", "provider", "status"))
})

test_that("scan_source_api_logs classifies a local endpoint as ok", {
  config <- list(
    list(item = "ussd_gateway", provider = "MainOne", region = "Lagos-NG")
  )
  result <- scan_source_api_logs(config)
  expect_equal(result$jurisdiction, "local")
  expect_equal(result$status, "ok")
  expect_equal(result$source, "api_logs")
})

test_that("scan_source_api_logs flags an offshore endpoint", {
  config <- list(
    list(item = "fraud_scoring_api", provider = "AWS", region = "eu-west-1")
  )
  result <- scan_source_api_logs(config)
  expect_equal(result$jurisdiction, "offshore")
  expect_equal(result$status, "flagged")
})

test_that("scan_source_api_logs handles multiple entries", {
  config <- list(
    list(item = "ussd_gateway", provider = "MainOne", region = "Lagos-NG"),
    list(item = "fraud_scoring_api", provider = "AWS", region = "eu-west-1"),
    list(item = "sms_vendor", provider = "SomeVendor", region = "Unknown Region")
  )
  result <- scan_source_api_logs(config)
  expect_equal(nrow(result), 3L)
  expect_equal(result$jurisdiction, c("local", "offshore", "unknown"))
})
