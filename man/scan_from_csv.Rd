\name{scan_from_csv}
\alias{scan_from_csv}
\title{Run a full residency audit directly from a CSV inventory}
\usage{
scan_from_csv(path)
}
\arguments{
\item{path}{Character. Path to the CSV inventory.}
}
\value{
A data.frame, same shape as [scan_data_residency()].
}
\description{
Convenience wrapper: reads the CSV, builds the config, and runs [scan_data_residency()] in one call.
}
