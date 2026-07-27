test_that("gen_residency_certificate_pdf writes a valid PDF file", {
  audit <- data.frame(
    source = c("db", "api_logs"),
    item = c("core_banking_db", "fraud_scoring_api"),
    location = c("Lagos-NG", "eu-west-1"),
    jurisdiction = c("local", "offshore"),
    provider = c("MainOne", "AWS"),
    status = c("ok", "flagged"),
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  tmp <- tempfile(fileext = ".pdf")

  result <- gen_residency_certificate_pdf(audit, flagged, bank_name = "Example Bank", output_file = tmp)

  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 0)
  # PDF magic bytes
  con <- file(tmp, "rb")
  header <- readBin(con, "raw", 5)
  close(con)
  expect_equal(rawToChar(header), "%PDF-")
  expect_equal(result, tmp)
  unlink(tmp)
})

test_that("gen_residency_certificate_pdf handles an empty audit", {
  audit <- data.frame(
    source = character(0), item = character(0), location = character(0),
    jurisdiction = character(0), provider = character(0), status = character(0),
    stringsAsFactors = FALSE
  )
  flagged <- audit
  tmp <- tempfile(fileext = ".pdf")

  expect_no_error(gen_residency_certificate_pdf(audit, flagged, bank_name = "Example Bank", output_file = tmp))
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("gen_residency_certificate_pdf paginates when rows exceed rows_per_page", {
  n <- 40
  audit <- data.frame(
    source = rep("db", n),
    item = paste0("db_", seq_len(n)),
    location = rep("Lagos-NG", n),
    jurisdiction = rep("local", n),
    provider = rep("MainOne", n),
    status = rep("ok", n),
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  tmp <- tempfile(fileext = ".pdf")

  expect_no_error(
    gen_residency_certificate_pdf(audit, flagged, bank_name = "Example Bank",
                                   output_file = tmp, rows_per_page = 18L)
  )
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 0)
  unlink(tmp)
})

test_that("build_executive_summary reflects flagged count and cites the circular", {
  audit <- data.frame(
    source = c("db", "backups"),
    item = c("core_banking_db", "dr_snapshot"),
    location = c("Lagos-NG", "West Europe (Netherlands)"),
    jurisdiction = c("local", "offshore"),
    provider = c("MainOne", "Azure"),
    status = c("ok", "flagged"),
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  summary <- build_executive_summary(audit, flagged)

  expect_true(grepl("PSS/DIR/PUB/CIR/001/004", summary))
  expect_true(grepl("2 operational data assets", summary))
  expect_true(grepl("1 non-compliant offshore data flow was", summary))
  expect_true(grepl("1 January 2027", summary))
})

test_that("build_executive_summary handles zero flagged items", {
  audit <- data.frame(
    source = "db", item = "core_banking_db", location = "Lagos-NG",
    jurisdiction = "local", provider = "MainOne", status = "ok",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)
  summary <- build_executive_summary(audit, flagged)

  expect_true(grepl("No non-compliant offshore data flows were detected", summary))
})

test_that("build_executive_summary accepts a custom regulation and defaults to CBN 2027", {
  audit <- data.frame(
    source = "db", item = "core_banking_db", location = "Lagos-NG",
    jurisdiction = "local", provider = "MainOne", status = "ok",
    stringsAsFactors = FALSE
  )
  flagged <- flag_offshore_calls(audit)

  default_summary <- build_executive_summary(audit, flagged)
  expect_true(grepl("PSS/DIR/PUB/CIR/001/004", default_summary))

  custom <- list(citation = "Some Other Regulator Rule 123", deadline_text = "31 December 2030")
  custom_summary <- build_executive_summary(audit, flagged, regulation = custom)
  expect_true(grepl("Some Other Regulator Rule 123", custom_summary))
  expect_true(grepl("31 December 2030", custom_summary))
  expect_false(grepl("PSS/DIR/PUB/CIR/001/004", custom_summary))
})
