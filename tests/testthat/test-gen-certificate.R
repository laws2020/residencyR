test_that("gen_residency_certificate produces expected summary lines", {
  audit <- data.frame(
    source = c("db", "api_logs"),
    item = c("core_banking_db", "fraud_api"),
    location = c("Lagos-NG", "eu-west-1"),
    jurisdiction = c("local", "offshore"),
    provider = c("MainOne", "AWS"),
    status = c("ok", "flagged"),
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)

  report <- gen_residency_certificate(audit, flagged, bank_name = "Example Bank")

  expect_true(any(grepl("Example Bank", report)))
  expect_true(any(grepl("Total data points audited: 2", report)))
  expect_true(any(grepl("Flagged for review.*: 1", report)))
  expect_true(any(grepl("fraud_api", report)))
  expect_true(any(grepl("Regulatory Notice", report)))
  expect_true(any(grepl("PSS/DIR/PUB/CIR/001/004", report)))
})

test_that("gen_residency_certificate reports 'None' when nothing flagged", {
  audit <- data.frame(
    source = "db",
    item = "core_banking_db",
    location = "Lagos-NG",
    jurisdiction = "local",
    provider = "MainOne",
    status = "ok",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)

  report <- gen_residency_certificate(audit, flagged, bank_name = "Example Bank")
  expect_true(any(grepl("None. All audited data points are Nigeria-resident", report)))
})

test_that("gen_residency_certificate writes to file when output_file is given", {
  audit <- data.frame(
    source = "db", item = "core_banking_db", location = "Lagos-NG",
    jurisdiction = "local", provider = "MainOne", status = "ok",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  tmp <- tempfile(fileext = ".md")
  gen_residency_certificate(audit, flagged, bank_name = "Example Bank", output_file = tmp)
  expect_true(file.exists(tmp))
  content <- readLines(tmp)
  expect_true(any(grepl("Example Bank", content)))
  unlink(tmp)
})

test_that("gen_residency_certificate shows COMPLIANT verdict when nothing flagged", {
  audit <- data.frame(
    source = "db", item = "core_banking_db", location = "Lagos-NG",
    jurisdiction = "local", provider = "MainOne", status = "ok",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  report <- gen_residency_certificate(audit, flagged, bank_name = "Example Bank")
  expect_true(any(grepl("\\*\\*Verdict:\\*\\* COMPLIANT", report)))
})

test_that("gen_residency_certificate shows NON-COMPLIANT verdict when items flagged", {
  audit <- data.frame(
    source = "db", item = "analytics_db", location = "us-east-1",
    jurisdiction = "offshore", provider = "AWS", status = "flagged",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  report <- gen_residency_certificate(audit, flagged, bank_name = "Example Bank")
  expect_true(any(grepl("\\*\\*Verdict:\\*\\* NON-COMPLIANT", report)))
})

test_that("gen_residency_certificate surfaces scan_errors prominently when present", {
  audit <- data.frame(
    source = "db", item = "core_banking_db", location = "Lagos-NG",
    jurisdiction = "local", provider = "MainOne", status = "ok",
    stringsAsFactors = FALSE
  )
  attr(audit, "scan_errors") <- c("api_logs: connection timed out")
  flagged <- flag_offshore_calls(audit)
  report <- gen_residency_certificate(audit, flagged, bank_name = "Example Bank")

  expect_true(any(grepl("WARNING: incomplete scan", report)))
  expect_true(any(grepl("api_logs: connection timed out", report)))
  expect_true(any(grepl("NOT reflected in this audit", report)))
})
