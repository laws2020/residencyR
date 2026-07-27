\name{ingest_csv_inventory}
\alias{ingest_csv_inventory}
\title{Build a scan_data_residency() config from a CSV inventory}
\usage{
ingest_csv_inventory(path)
}
\arguments{
\item{path}{Character. Path to a CSV file with columns `source`, `item`, `provider`, `region` (case-insensitive, any order).}
}
\value{
A named list suitable for passing as `configs` to [scan_data_residency()], keyed by source name.
}
\description{
Build a scan_data_residency() config from a CSV inventory
}
