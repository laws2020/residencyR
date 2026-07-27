## Scans raw text-based infra config files (.tf, .tfvars, .yml, .yaml,
## .env, .json) for provider/region signatures, using nothing but
## readLines() + regex. No JSON parsing, no new dependency -- this
## works because Terraform *.tf* source is plain HCL text, not the
## JSON-serialized *.tfstate*.
##
## IMPORTANT: results are candidates, not confirmed inventory. A
## human curating a CSV is asserting fact; a regex match against
## source code is a guess -- it can miss dynamically constructed
## values and can false-positive on comments or dead code. Every row
## this returns is tagged confidence = "candidate" and is deliberately
## NOT registered as a scan_data_residency() source, so it never
## silently blends into a certified audit table.

.aws_region_regex <- "\\b(us|eu|ap|sa|ca|me|af)-(east|west|north|south|central|northeast|northwest|southeast|southwest)-[0-9]\\b"

.azure_named_regions <- c(
  "West Europe", "North Europe", "UK South", "UK West", "France Central",
  "Germany West Central", "Switzerland North", "East US", "East US 2",
  "West US", "West US 2", "Central US", "South Africa North", "UAE North"
)

.ng_location_indicators <- c(
  "Lagos", "Abuja", "Nigeria", "MainOne", "Galaxy Backbone", "Rack Centre", "Medallion"
)

#' @keywords internal
.guess_provider_from_line <- function(line) {
  if (grepl("aws|amazon", line, ignore.case = TRUE)) return("AWS")
  if (grepl("azure|azurerm|microsoft", line, ignore.case = TRUE)) return("Azure")
  if (grepl("google|gcp", line, ignore.case = TRUE)) return("GCP")
  if (grepl("mainone", line, ignore.case = TRUE)) return("MainOne")
  if (grepl("galaxy", line, ignore.case = TRUE)) return("Galaxy Backbone")
  if (grepl("rack ?centre", line, ignore.case = TRUE)) return("Rack Centre")
  "unknown"
}

#' @keywords internal
.guess_provider_window <- function(lines, i, window = 5L) {
  start <- max(1L, i - window)
  context <- paste(lines[start:i], collapse = " ")
  .guess_provider_from_line(context)
}

#' @keywords internal
.empty_code_scan_frame <- function() {
  data.frame(
    source = character(0), item = character(0), location = character(0),
    provider = character(0), jurisdiction = character(0), confidence = character(0),
    file = character(0), line = integer(0), stringsAsFactors = FALSE
  )
}

#' Scan raw infra config files for candidate residency findings
#'
#' Recursively scans text-based config files for provider/region
#' signatures. Results are unverified candidates for human review --
#' see the "confidence" column, always "candidate" -- and are meant
#' to be triaged into a real CSV inventory, not treated as a
#' certified audit on their own.
#'
#' @param path Character. Directory to scan.
#' @param extensions Character vector of file extensions to include
#'   (without the dot). Defaults to common infra config types.
#' @param recursive Logical. Scan subdirectories. Default TRUE.
#' @return A data.frame with columns: source, item, location,
#'   provider, jurisdiction, confidence, file, line. Empty (with a
#'   warning) if no matching files or no matches are found.
#' @export
scan_source_files <- function(path,
                               extensions = c("tf", "tfvars", "yml", "yaml", "env", "json"),
                               recursive = TRUE) {
  if (!dir.exists(path)) {
    stop(sprintf("Directory not found: %s", path), call. = FALSE)
  }

  ext_pattern <- paste0("\\.(", paste(extensions, collapse = "|"), ")$")
  files <- list.files(path, pattern = ext_pattern, recursive = recursive,
                       full.names = TRUE, ignore.case = TRUE, all.files = TRUE)
  files <- files[!grepl("(^|/)\\.\\.?$", files)]  # drop . and .. entries pulled in by all.files

  if (length(files) == 0L) {
    warning("No files matching the given extensions were found under path.", call. = FALSE)
    return(.empty_code_scan_frame())
  }

  rows <- list()

  for (f in files) {
    lines <- tryCatch(suppressWarnings(readLines(f, warn = FALSE)), error = function(e) character(0))
    if (length(lines) == 0L) next

    for (i in seq_along(lines)) {
      line <- lines[i]
      matches <- character(0)

      aws_hits <- regmatches(line, gregexpr(.aws_region_regex, line, ignore.case = TRUE))[[1]]
      if (length(aws_hits) > 0L) matches <- c(matches, aws_hits)

      for (az in .azure_named_regions) {
        if (grepl(az, line, ignore.case = TRUE)) matches <- c(matches, az)
      }

      for (ng in .ng_location_indicators) {
        if (grepl(ng, line, ignore.case = TRUE)) matches <- c(matches, ng)
      }

      if (length(matches) == 0L) next

      provider_guess <- .guess_provider_window(lines, i)

      for (m in unique(matches)) {
        rows[[length(rows) + 1L]] <- data.frame(
          source = "code_scan",
          item = sprintf("%s:%d", basename(f), i),
          location = m,
          provider = provider_guess,
          jurisdiction = classify_jurisdiction(provider_guess, m),
          confidence = "candidate",
          file = f,
          line = i,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(rows) == 0L) {
    warning("No provider/region signatures found in scanned files.", call. = FALSE)
    return(.empty_code_scan_frame())
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}
