## Offline license verification for residencyR's commercial certificate
## generation. The core audit engine (scanning, classification,
## ingestion) has zero dependencies and NEVER requires this file --
## only gen_residency_certificate() and gen_residency_certificate_pdf(),
## the actual certified deliverable, check for a valid license.
##
## This uses RSA public-key signatures (openssl package), not a
## shared secret. The private key lives only on the licensing
## backend and is never shipped anywhere. This file embeds only the
## PUBLIC key, which is safe to publish -- a public key can verify a
## signature but cannot create a new one. Even with this entire
## package readable on GitHub forever, nobody can forge a valid
## license without the private key.
##
## Honest scope: this stops casual/accidental use past expiry and
## protects against tampering with the license file. It is a
## commercial licensing gate for legitimate B2B customers, not
## anti-piracy DRM against a determined adversary who could, in
## principle, still delete the R code that calls this check entirely
## (the package is open source). Real enforcement is the license
## agreement; this is the good-faith technical backing for it.
##
## Installing the `openssl` package is a one-time, install-time step
## -- like installing residencyR itself. It does not affect the
## "runs fully offline" promise, which is about scanning at runtime
## on an air-gapped machine, not about zero-internet-ever.

## Public key only. Generated alongside a private key that is kept
## only on the licensing backend (see dev/licensing-backend/).
.license_public_key_pem <- "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq6va7MWXfM2RVatGPUmh
YUO9g039FjyYalODGd0e6dOmbzMGW8YUGlqekH99qk55GEH/Tg9EIpXYIaXf8DP2
o8eFiVD1wwZ1gTyZMMQKpOuDbGTp/deC0GGSw5M/TxOoLv2GOssb+nPaa7TmoMN/
akA4ajEtJPN//0PjxjxdRSS/buUCYEUVS2Xh2cMPp0PaPXJwG0oUnc290cq2X0i+
97TOypGiIK9dKk4pkDwxbUIlQ2wtWOxjScwYlcGh1t4c+Tc216q0ZiGwcutPHuwY
1DTtVtu3y9TJaJ6e/DO0D9J1AaypKfOb8nPDlCIH95QzKfaDM50L0SFgGrrxF7eB
MQIDAQAB
-----END PUBLIC KEY-----"

#' @keywords internal
.license_default_path <- function() {
  file.path(tools::R_user_dir("residencyR", which = "config"), "license.lic")
}

#' @keywords internal
.canonical_license_string <- function(fields) {
  paste(fields$LICENSEE, fields$EMAIL, fields$PLAN, fields$ISSUED, fields$EXPIRES, sep = "|")
}

#' @keywords internal
.parse_license_file <- function(path) {
  if (!file.exists(path)) return(NULL)
  lines <- readLines(path, warn = FALSE)
  lines <- lines[grepl(":", lines)]
  if (length(lines) == 0L) return(NULL)
  parts <- strsplit(lines, ":\\s*", perl = TRUE)
  keys <- vapply(parts, function(p) trimws(p[1]), character(1))
  vals <- vapply(parts, function(p) trimws(paste(p[-1], collapse = ":")), character(1))
  as.list(setNames(vals, keys))
}

#' Verify a residencyR license file
#'
#' Checks the license file's signature (RSA public-key verification --
#' confirms it was issued by the licensing backend and hasn't been
#' tampered with) and its expiry date.
#'
#' @param path Character or NULL. Path to a license file. Defaults to
#'   the standard per-user location used by [install_license()].
#' @return A list with `valid` (logical) and `reason` (character), plus
#'   `licensee`, `plan`, and `expires` when valid.
#' @export
verify_license <- function(path = NULL) {
  if (is.null(path)) path <- .license_default_path()

  fields <- .parse_license_file(path)
  if (is.null(fields)) {
    return(list(valid = FALSE, reason = sprintf(
      "No license file found at %s. Call install_license() to activate.", path
    )))
  }

  required <- c("LICENSEE", "EMAIL", "PLAN", "ISSUED", "EXPIRES", "SIGNATURE")
  if (!all(required %in% names(fields))) {
    return(list(valid = FALSE, reason = "License file is malformed (missing required fields)."))
  }

  if (!requireNamespace("openssl", quietly = TRUE)) {
    return(list(valid = FALSE, reason = "Package 'openssl' is required to verify licenses. Install it with install.packages('openssl')."))
  }

  sig_ok <- tryCatch({
    pubkey <- openssl::read_pubkey(.license_public_key_pem)
    sig_raw <- openssl::base64_decode(fields$SIGNATURE)
    data_raw <- charToRaw(enc2utf8(.canonical_license_string(fields)))
    openssl::signature_verify(data_raw, sig_raw, hash = openssl::sha256, pubkey = pubkey)
  }, error = function(e) FALSE)

  if (!isTRUE(sig_ok)) {
    return(list(valid = FALSE, reason = "License signature is invalid -- the file may be corrupted, tampered with, or not genuinely issued."))
  }

  expires <- tryCatch(as.Date(fields$EXPIRES), error = function(e) NA)
  if (is.na(expires)) {
    return(list(valid = FALSE, reason = "License file has an invalid EXPIRES date."))
  }
  if (Sys.Date() > expires) {
    return(list(valid = FALSE, reason = sprintf(
      "License expired on %s. Renew to continue generating certificates.", fields$EXPIRES
    )))
  }

  list(valid = TRUE, reason = "OK", licensee = fields$LICENSEE, plan = fields$PLAN, expires = fields$EXPIRES)
}

#' Install a residencyR license file
#'
#' @param license_text Character. The full contents of a license file,
#'   exactly as issued at purchase or renewal.
#' @param path Character or NULL. Where to install it. Defaults to
#'   the standard per-user location.
#' @return Invisibly, the path the license was written to.
#' @export
install_license <- function(license_text, path = NULL) {
  if (is.null(path)) path <- .license_default_path()
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(license_text, path)
  result <- verify_license(path)
  if (isTRUE(result$valid)) {
    message(sprintf(
      "License installed for %s (%s plan), valid through %s.",
      result$licensee, result$plan, result$expires
    ))
  } else {
    warning(sprintf("License installed but did not validate: %s", result$reason), call. = FALSE)
  }
  invisible(path)
}

#' @keywords internal
.require_license <- function() {
  result <- verify_license()
  if (!isTRUE(result$valid)) {
    stop(
      "residencyR: a valid license is required to generate a certificate.\n",
      "  ", result$reason, "\n",
      "  Contact Infosights Consulting to purchase or renew: 08101688661",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
