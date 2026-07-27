\name{gen_residency_certificate_pdf}
\alias{gen_residency_certificate_pdf}
\title{Generate a data residency certificate as a PDF}
\usage{
gen_residency_certificate_pdf(audit, flagged, bank_name, output_file, rows_per_page, regulation)
}
\arguments{
\item{audit}{A data.frame as returned by [scan_data_residency()].}
\item{flagged}{A data.frame as returned by [flag_offshore_calls()].}
\item{bank_name}{Character. Name to appear on the certificate.}
\item{output_file}{Character. Path to write the PDF to.}
\item{rows_per_page}{Integer. Max audit rows drawn per page on continuation pages (page 1 fits fewer, since it also carries the stats, charts, and executive summary). Default 20.}
\item{regulation}{A list with `citation` and `deadline_text`, as used by [build_executive_summary()]. Defaults to the CBN 2027 data localization circular.}
}
\value{
Invisibly, `output_file`.
}
\description{
Generate a data residency certificate as a PDF
}
