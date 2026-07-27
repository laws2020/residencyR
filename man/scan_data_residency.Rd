\name{scan_data_residency}
\alias{scan_data_residency}
\title{Scan payment data residency across registered sources}
\usage{
scan_data_residency(sources, configs)
}
\arguments{
\item{sources}{Character vector of source names to scan. Defaults to all registered sources.}
\item{configs}{Named list, keyed by source name, of the config to pass to that source's scan function. E.g. list(db = list(list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")))}
}
\value{
A data.frame combining results from all requested sources. If any source failed to scan, the result carries a "scan_errors" attribute: a character vector of "source: message" entries.
}
\description{
Scan payment data residency across registered sources
}
