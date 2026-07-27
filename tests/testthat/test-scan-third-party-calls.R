test_that("scan_source_third_party_calls returns empty frame for empty config", {
  result <- scan_source_third_party_calls(list())
  expect_equal(nrow(result), 0L)
  expect_named(result, c("source", "item", "location", "jurisdiction", "provider", "status"))
})

test_that("scan_source_third_party_calls classifies a local vendor as ok", {
  config <- list(
    list(item = "card_switch", provider = "MainOne", region = "Lagos-NG")
  )
  result <- scan_source_third_party_calls(config)
  expect_equal(result$jurisdiction, "local")
  expect_equal(result$status, "ok")
  expect_equal(result$source, "third_party_calls")
})

test_that("scan_source_third_party_calls flags an offshore vendor", {
  config <- list(
    list(item = "chargeback_processor", provider = "Stripe", region = "us-east-1")
  )
  result <- scan_source_third_party_calls(config)
  expect_equal(result$jurisdiction, "offshore")
  expect_equal(result$status, "flagged")
})

test_that("scan_source_third_party_calls handles multiple entries", {
  config <- list(
    list(item = "card_switch", provider = "MainOne", region = "Lagos-NG"),
    list(item = "chargeback_processor", provider = "Stripe", region = "us-east-1")
  )
  result <- scan_source_third_party_calls(config)
  expect_equal(nrow(result), 2L)
})

test_that("third_party_calls is registered by default on load", {
  expect_true("third_party_calls" %in% list_residency_sources())
})
