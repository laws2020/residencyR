test_that("scan_source_backups returns empty frame for empty config", {
  result <- scan_source_backups(list())
  expect_equal(nrow(result), 0L)
  expect_named(result, c("source", "item", "location", "jurisdiction", "provider", "status"))
})

test_that("scan_source_backups classifies a local backup as ok", {
  config <- list(
    list(item = "nightly_transaction_backup", provider = "Galaxy Backbone", region = "Abuja")
  )
  result <- scan_source_backups(config)
  expect_equal(result$jurisdiction, "local")
  expect_equal(result$status, "ok")
  expect_equal(result$source, "backups")
})

test_that("scan_source_backups flags an offshore backup", {
  config <- list(
    list(item = "dr_snapshot", provider = "Azure", region = "West Europe (Ireland)")
  )
  result <- scan_source_backups(config)
  expect_equal(result$jurisdiction, "offshore")
  expect_equal(result$status, "flagged")
})

test_that("scan_source_backups handles multiple entries", {
  config <- list(
    list(item = "nightly_transaction_backup", provider = "Galaxy Backbone", region = "Abuja"),
    list(item = "dr_snapshot", provider = "Azure", region = "West Europe (Ireland)")
  )
  result <- scan_source_backups(config)
  expect_equal(nrow(result), 2L)
})
