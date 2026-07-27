test_that("ingest_csv_inventory errors on missing file", {
  expect_error(ingest_csv_inventory("/nonexistent/path.csv"), "File not found")
})

test_that("ingest_csv_inventory parses a well-formed multi-source CSV", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider,region",
    "db,core_banking_db,MainOne,Lagos-NG",
    "api_logs,fraud_scoring_api,AWS,eu-west-1",
    "backups,dr_snapshot,Azure,West Europe (Ireland)",
    "third_party_calls,chargeback_processor,Stripe,us-east-1"
  ), tmp)

  configs <- ingest_csv_inventory(tmp)
  unlink(tmp)

  expect_setequal(names(configs), c("db", "api_logs", "backups", "third_party_calls"))
  expect_equal(configs$db[[1]]$item, "core_banking_db")
  expect_equal(configs$db[[1]]$provider, "MainOne")
  expect_equal(configs$db[[1]]$region, "Lagos-NG")
})

test_that("ingest_csv_inventory groups multiple rows per source", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider,region",
    "db,core_banking_db,MainOne,Lagos-NG",
    "db,analytics_db,AWS,us-east-1"
  ), tmp)

  configs <- ingest_csv_inventory(tmp)
  unlink(tmp)

  expect_equal(length(configs$db), 2L)
})

test_that("ingest_csv_inventory is case-insensitive and order-agnostic on columns", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "Region,Source,Provider,Item",
    "Lagos-NG,db,MainOne,core_banking_db"
  ), tmp)

  configs <- ingest_csv_inventory(tmp)
  unlink(tmp)

  expect_equal(configs$db[[1]]$item, "core_banking_db")
  expect_equal(configs$db[[1]]$region, "Lagos-NG")
})

test_that("ingest_csv_inventory warns when dropping rows with blank source", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider,region",
    "db,core_banking_db,MainOne,Lagos-NG",
    ",orphan_row,SomeVendor,Somewhere"
  ), tmp)

  expect_warning(configs <- ingest_csv_inventory(tmp), "1 row\\(s\\) dropped")
  expect_equal(length(configs$db), 1L)
  unlink(tmp)
})

test_that("ingest_csv_inventory errors clearly on missing required columns", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider",
    "db,core_banking_db,MainOne"
  ), tmp)

  expect_error(ingest_csv_inventory(tmp), "missing required column")
  unlink(tmp)
})

test_that("ingest_csv_inventory warns on unregistered source names", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider,region",
    "unknown_source,some_item,SomeVendor,Somewhere"
  ), tmp)

  expect_warning(ingest_csv_inventory(tmp), "not registered")
  unlink(tmp)
})

test_that("scan_from_csv runs an end-to-end audit from file", {
  tmp <- tempfile(fileext = ".csv")
  writeLines(c(
    "source,item,provider,region",
    "db,core_banking_db,MainOne,Lagos-NG",
    "api_logs,fraud_scoring_api,AWS,eu-west-1"
  ), tmp)

  audit <- scan_from_csv(tmp)
  unlink(tmp)

  expect_equal(nrow(audit), 2L)
  expect_true(all(c("source", "jurisdiction", "status") %in% names(audit)))
})

test_that("scan_from_csv errors when CSV has no usable rows", {
  tmp <- tempfile(fileext = ".csv")
  writeLines("source,item,provider,region", tmp)
  expect_error(scan_from_csv(tmp), "no usable rows")
  unlink(tmp)
})
