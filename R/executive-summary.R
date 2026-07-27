## Shared executive summary text, used by both gen_residency_certificate()
## (markdown) and gen_residency_certificate_pdf() so the two outputs
## stay consistent. Written for a board/CFO reader, not an engineer --
## states the regulatory basis, the headline finding, and the deadline
## in one paragraph.
##
## The regulatory citation and deadline are parameters, not hardcoded
## text -- the CBN 2027 circular is today's reason to run this scan,
## but the scanning engine itself has no expiry date. A future
## circular, a different regulator, or a routine re-scan after the
## 2027 deadline all use the same function with a different citation.

.source_labels <- c(
  db = "production databases",
  api_logs = "API logs",
  backups = "production backups",
  third_party_calls = "third-party processor routing"
)

#' Default regulatory citation used by build_executive_summary()
#'
#' Kept as a named list rather than inline strings so a future
#' circular, deadline extension, or different regulator's rule can be
#' swapped in via the `regulation` argument without editing this file.
#' @keywords internal
.cbn_2027_regulation <- list(
  citation = "Central Bank of Nigeria (CBN) Circular PSS/DIR/PUB/CIR/001/004 (15 June 2026)",
  deadline_text = "1 January 2027",
  regulator_name = "the Central Bank of Nigeria"
)

#' @keywords internal
.describe_flagged_sources <- function(flagged) {
  if (nrow(flagged) == 0L) return("")
  src <- unique(flagged$source)
  labels <- ifelse(src %in% names(.source_labels), .source_labels[src], src)
  if (length(labels) == 1L) return(labels)
  paste0(paste(labels[-length(labels)], collapse = ", "), ", and ", labels[length(labels)])
}

#' Build the executive summary paragraph for a residency certificate
#'
#' @param audit A data.frame as returned by [scan_data_residency()].
#' @param flagged A data.frame as returned by [flag_offshore_calls()].
#' @param regulation A list with `citation` and `deadline_text`
#'   elements, e.g. `list(citation = "...", deadline_text = "...")`.
#'   Defaults to the CBN 2027 data localization circular. Pass a
#'   different value to cite a different rule (a future CBN update,
#'   a different regulator, or a routine post-deadline re-scan).
#' @return Character. A single paragraph of summary text.
#' @export
build_executive_summary <- function(audit, flagged,
                                     regulation = .cbn_2027_regulation) {
  stopifnot(all(c("citation", "deadline_text") %in% names(regulation)))

  total <- nrow(audit)
  n_flagged <- nrow(flagged)
  circular_ref <- regulation$citation
  deadline_text <- regulation$deadline_text

  if (n_flagged == 0L) {
    return(sprintf(
      paste0(
        "Regulatory Notice: This infrastructure scan evaluated %d operational ",
        "data asset%s against %s. No non-compliant offshore data flows were ",
        "detected. Continue periodic re-scanning to maintain this position ",
        "ahead of the %s enforcement deadline."
      ),
      total, if (total == 1L) "" else "s", circular_ref, deadline_text
    ))
  }

  where <- .describe_flagged_sources(flagged)
  sprintf(
    paste0(
      "Regulatory Notice: This infrastructure scan evaluated %d operational ",
      "data asset%s against %s. A total of %d non-compliant offshore data ",
      "flow%s %s detected across %s. Immediate remediation is required ",
      "before the %s enforcement deadline."
    ),
    total, if (total == 1L) "" else "s",
    circular_ref,
    n_flagged, if (n_flagged == 1L) "" else "s",
    if (n_flagged == 1L) "was" else "were",
    where,
    deadline_text
  )
}
