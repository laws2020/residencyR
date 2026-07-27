\name{flag_offshore_calls}
\alias{flag_offshore_calls}
\title{Flag offshore residency records}
\usage{
flag_offshore_calls(audit)
}
\arguments{
\item{audit}{A data.frame as returned by [scan_data_residency()].}
}
\value{
Subset of `audit` where jurisdiction is "offshore" or "unknown" (needs manual review). Carries over any "scan_errors" attribute from `audit`.
}
\description{
Flag offshore residency records
}
