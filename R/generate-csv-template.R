## Writes a starter CSV that a bank's cloud/infra team can fill in
## directly, with one example row per source so the expected shape
## is unambiguous without needing to read documentation first.

#' Generate a blank CSV inventory template
#'
#' @param output_file Character. Path to write the template CSV to.
#' @param include_examples Logical. If TRUE (default), includes one
#'   example row per source to illustrate the expected format. If
#'   FALSE, writes header only.
#' @return Invisibly, `output_file`.
#' @export
generate_csv_template <- function(output_file, include_examples = TRUE) {
  stopifnot(is.character(output_file), length(output_file) == 1L)

  if (include_examples) {
    df <- data.frame(
      source = c("db", "api_logs", "backups", "third_party_calls"),
      item = c("core_banking_db", "fraud_scoring_api", "dr_snapshot", "chargeback_processor"),
      provider = c("MainOne", "AWS", "Azure", "Stripe"),
      region = c("Lagos-NG", "eu-west-1", "West Europe (Netherlands)", "us-east-1"),
      stringsAsFactors = FALSE
    )
  } else {
    df <- data.frame(
      source = character(0), item = character(0),
      provider = character(0), region = character(0),
      stringsAsFactors = FALSE
    )
  }

  utils::write.csv(df, output_file, row.names = FALSE)
  invisible(output_file)
}
