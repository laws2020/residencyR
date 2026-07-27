test_that("scan_source_files errors on nonexistent directory", {
  expect_error(scan_source_files("/nonexistent/dir/path"), "Directory not found")
})

test_that("scan_source_files warns and returns empty frame when no matching files exist", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines("just some text", file.path(tmp_dir, "notes.txt"))

  expect_warning(result <- scan_source_files(tmp_dir), "No files matching")
  expect_equal(nrow(result), 0L)
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files detects an AWS region in a .tf file", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines(c(
    'resource "aws_db_instance" "analytics" {',
    '  region = "us-east-1"',
    '}'
  ), file.path(tmp_dir, "main.tf"))

  result <- scan_source_files(tmp_dir)
  expect_equal(nrow(result), 1L)
  expect_equal(result$location, "us-east-1")
  expect_equal(result$provider, "AWS")
  expect_equal(result$jurisdiction, "offshore")
  expect_equal(result$confidence, "candidate")
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files detects an Azure named region in a .yml file", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines(c(
    "provider: azure",
    "location: West Europe",
    "resource_group: dr-backups"
  ), file.path(tmp_dir, "config.yml"))

  result <- scan_source_files(tmp_dir)
  expect_true("West Europe" %in% result$location)
  expect_equal(result$provider[result$location == "West Europe"], "Azure")
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files detects a local Nigerian indicator", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines(c(
    "# core banking db, hosted on MainOne, Lagos-NG datacenter"
  ), file.path(tmp_dir, "notes.env"))

  result <- scan_source_files(tmp_dir)
  expect_true(any(result$jurisdiction == "local"))
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files respects the extensions filter", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines('region <- "us-east-1"  # should be ignored, not a config file', file.path(tmp_dir, "script.R"))
  writeLines('region = "us-east-1"', file.path(tmp_dir, "main.tf"))

  result <- scan_source_files(tmp_dir, extensions = c("tf"))
  expect_equal(nrow(result), 1L)
  expect_true(grepl("main.tf", result$file))
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files scans recursively by default", {
  tmp_dir <- tempfile()
  dir.create(file.path(tmp_dir, "modules", "db"), recursive = TRUE)
  writeLines('region = "eu-west-1"', file.path(tmp_dir, "modules", "db", "main.tf"))

  result <- scan_source_files(tmp_dir)
  expect_equal(nrow(result), 1L)
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files warns and returns empty frame when files exist but no matches found", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines('variable "instance_type" { default = "t3.micro" }', file.path(tmp_dir, "vars.tf"))

  expect_warning(result <- scan_source_files(tmp_dir), "No provider/region signatures")
  expect_equal(nrow(result), 0L)
  unlink(tmp_dir, recursive = TRUE)
})

test_that("scan_source_files output can feed into scan_data_residency-compatible shape", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  writeLines(c(
    'resource "aws_db_instance" "analytics" { region = "us-east-1" }'
  ), file.path(tmp_dir, "main.tf"))

  result <- scan_source_files(tmp_dir)
  expect_true(all(c("source", "item", "location", "jurisdiction", "provider") %in% names(result)))
  unlink(tmp_dir, recursive = TRUE)
})
