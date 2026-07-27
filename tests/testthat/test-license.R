## These tests generate real RSA-signed license fixtures using a
## throwaway test keypair (swapped in for the package's real public
## key for the duration of each test, then restored), so we prove
## real signature verification, not just the surrounding logic.
## Skipped entirely if openssl isn't installed.

make_test_license <- function(licensee = "Test Bank Plc", email = "ciso@testbank.com",
                               plan = "annual", issued = "2026-01-01", expires = "2030-01-01",
                               key) {
  canonical <- paste(licensee, email, plan, issued, expires, sep = "|")
  sig <- openssl::signature_create(charToRaw(canonical), hash = openssl::sha256, key = key)
  sig_b64 <- openssl::base64_encode(sig)
  paste(
    sprintf("LICENSEE: %s", licensee),
    sprintf("EMAIL: %s", email),
    sprintf("PLAN: %s", plan),
    sprintf("ISSUED: %s", issued),
    sprintf("EXPIRES: %s", expires),
    sprintf("SIGNATURE: %s", sig_b64),
    sep = "\n"
  )
}

with_test_pubkey <- function(pub_pem, code) {
  old <- .license_public_key_pem
  .license_public_key_pem <<- pub_pem
  on.exit(.license_public_key_pem <<- old, add = TRUE)
  force(code)
}

test_that("verify_license correctly validates a genuinely signed, current license", {
  skip_if_not_installed("openssl")
  key <- openssl::rsa_keygen()
  pub_pem <- as.character(openssl::write_pem(as.list(key)$pubkey))

  with_test_pubkey(pub_pem, {
    lic_text <- make_test_license(key = key)
    tmp <- tempfile()
    writeLines(lic_text, tmp)
    result <- verify_license(tmp)
    expect_true(result$valid)
    expect_equal(result$licensee, "Test Bank Plc")
    expect_equal(result$plan, "annual")
    unlink(tmp)
  })
})

test_that("verify_license rejects a tampered license (expiry date changed after signing)", {
  skip_if_not_installed("openssl")
  key <- openssl::rsa_keygen()
  pub_pem <- as.character(openssl::write_pem(as.list(key)$pubkey))

  with_test_pubkey(pub_pem, {
    lic_text <- make_test_license(expires = "2030-01-01", key = key)
    tampered <- sub("EXPIRES: 2030-01-01", "EXPIRES: 2099-01-01", lic_text, fixed = TRUE)
    tmp <- tempfile()
    writeLines(tampered, tmp)
    result <- verify_license(tmp)
    expect_false(result$valid)
    expect_match(result$reason, "signature is invalid")
    unlink(tmp)
  })
})

test_that("verify_license rejects a license signed with the wrong (untrusted) key", {
  skip_if_not_installed("openssl")
  trusted_key <- openssl::rsa_keygen()
  attacker_key <- openssl::rsa_keygen()
  trusted_pub_pem <- as.character(openssl::write_pem(as.list(trusted_key)$pubkey))

  with_test_pubkey(trusted_pub_pem, {
    lic_text <- make_test_license(key = attacker_key)  # signed with the WRONG key
    tmp <- tempfile()
    writeLines(lic_text, tmp)
    result <- verify_license(tmp)
    expect_false(result$valid)
    expect_match(result$reason, "signature is invalid")
    unlink(tmp)
  })
})

test_that("verify_license reports expiry correctly on an otherwise validly-signed license", {
  skip_if_not_installed("openssl")
  key <- openssl::rsa_keygen()
  pub_pem <- as.character(openssl::write_pem(as.list(key)$pubkey))

  with_test_pubkey(pub_pem, {
    lic_text <- make_test_license(issued = "2020-01-01", expires = "2021-01-01", key = key)
    tmp <- tempfile()
    writeLines(lic_text, tmp)
    result <- verify_license(tmp)
    expect_false(result$valid)
    expect_match(result$reason, "expired on 2021-01-01")
    unlink(tmp)
  })
})

test_that("verify_license handles a missing file clearly", {
  result <- verify_license(tempfile())
  expect_false(result$valid)
  expect_match(result$reason, "No license file found")
})

test_that("verify_license handles a malformed file clearly", {
  tmp <- tempfile()
  writeLines(c("LICENSEE: Test Bank", "EMAIL: x@y.com"), tmp)
  result <- verify_license(tmp)
  expect_false(result$valid)
  expect_match(result$reason, "malformed")
  unlink(tmp)
})

test_that("gen_residency_certificate refuses to run without a valid license", {
  old <- .license_default_path
  .license_default_path <<- function() tempfile()
  on.exit(.license_default_path <<- old, add = TRUE)

  audit <- scan_source_db(list(list(item = "x", provider = "MainOne", region = "Lagos-NG")))
  flagged <- flag_offshore_calls(audit)
  expect_error(
    gen_residency_certificate(audit, flagged, bank_name = "Test"),
    "valid license is required"
  )
})

test_that("gen_residency_certificate_pdf refuses to run without a valid license", {
  old <- .license_default_path
  .license_default_path <<- function() tempfile()
  on.exit(.license_default_path <<- old, add = TRUE)

  audit <- scan_source_db(list(list(item = "x", provider = "MainOne", region = "Lagos-NG")))
  flagged <- flag_offshore_calls(audit)
  expect_error(
    gen_residency_certificate_pdf(audit, flagged, bank_name = "Test", output_file = tempfile(fileext = ".pdf")),
    "valid license is required"
  )
})
