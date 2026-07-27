\name{gen_residency_certificate}
\alias{gen_residency_certificate}
\title{Generate a data residency certificate}
\usage{
gen_residency_certificate(audit, flagged, bank_name, output_file, regulation)
}
\arguments{
\item{audit}{A data.frame as returned by [scan_data_residency()].}
\item{flagged}{A data.frame as returned by [flag_offshore_calls()].}
\item{bank_name}{Character. Name to appear on the certificate.}
\item{output_file}{Character or NULL. If given, writes the report to this path as a markdown file. If NULL, only returns the text.}
\item{regulation}{A list with `citation` and `deadline_text`, as used by [build_executive_summary()]. Defaults to the CBN 2027 data localization circular; pass a different value to cite a different rule.}
}
\value{
Invisibly, a character vector of the report lines.
}
\description{
Generate a data residency certificate
}
