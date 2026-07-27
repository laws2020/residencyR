test_that("scan_data_residency dispatches to the db source", {
  configs <- list(
    db = list(
      list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG"),
      list(item = "analytics_db", provider = "AWS", region = "us-east-1")
    )
  )
  audit <- scan_data_residency(sources = "db", configs = configs)
  expect_equal(nrow(audit), 2L)
  expect_true(all(c("source", "jurisdiction", "status") %in% names(audit)))
})

test_that("scan_data_residency errors when no sources given and none registered", {
  # remove all sources temporarily via a fresh registry-free call
  expect_error(scan_data_residency(sources = character(0)), "No residency sources")
})

test_that("scan_data_residency dispatches across db, api_logs, and backups", {
  configs <- list(
    db = list(list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")),
    api_logs = list(list(item = "fraud_scoring_api", provider = "AWS", region = "eu-west-1")),
    backups = list(list(item = "dr_snapshot", provider = "Azure", region = "West Europe (Ireland)"))
  )
  audit <- scan_data_residency(sources = c("db", "api_logs", "backups"), configs = configs)
  expect_equal(nrow(audit), 3L)
  expect_setequal(audit$source, c("db", "api_logs", "backups"))
  expect_equal(sum(audit$status == "flagged"), 2L)
})

test_that("flag_offshore_calls returns only offshore/unknown rows", {
  audit <- data.frame(
    source = c("db", "db", "db"),
    item = c("a", "b", "c"),
    location = c("Lagos-NG", "us-east-1", "Unknown Region"),
    jurisdiction = c("local", "offshore", "unknown"),
    provider = c("MainOne", "AWS", "SomeVendor"),
    status = c("ok", "flagged", "ok"),
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  expect_equal(nrow(flagged), 2L)
  expect_true(all(flagged$jurisdiction %in% c("offshore", "unknown")))
})

test_that("scan_data_residency survives a broken scan source and records the error", {
  register_residency_source("broken_source", function(config) {
    stop("simulated scanner failure")
  })

  configs <- list(
    db = list(list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")),
    broken_source = list(list(item = "x", provider = "y", region = "z"))
  )

  audit <- scan_data_residency(sources = c("db", "broken_source"), configs = configs)

  # the working source's rows still come through
  expect_equal(nrow(audit), 1L)
  expect_equal(audit$source, "db")

  # the failure is recorded, not silently dropped
  errs <- attr(audit, "scan_errors")
  expect_false(is.null(errs))
  expect_true(any(grepl("broken_source", errs)))
  expect_true(any(grepl("simulated scanner failure", errs)))
})

test_that("scan_data_residency has no scan_errors attribute when everything succeeds", {
  configs <- list(db = list(list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")))
  audit <- scan_data_residency(sources = "db", configs = configs)
  expect_null(attr(audit, "scan_errors"))
})

test_that("flag_offshore_calls carries scan_errors through from the audit", {
  audit <- data.frame(
    source = "db", item = "a", location = "us-east-1",
    jurisdiction = "offshore", provider = "AWS", status = "flagged",
    stringsAsFactors = FALSE
  )
  attr(audit, "scan_errors") <- c("api_logs: timeout")
  flagged <- flag_offshore_calls(audit)
  expect_equal(attr(flagged, "scan_errors"), c("api_logs: timeout"))
})
