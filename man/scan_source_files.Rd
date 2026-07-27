\name{scan_source_files}
\alias{scan_source_files}
\title{Scan raw infra config files for candidate residency findings}
\usage{
scan_source_files(path, extensions, recursive)
}
\arguments{
\item{path}{Character. Directory to scan.}
\item{extensions}{Character vector of file extensions to include (without the dot). Defaults to common infra config types.}
\item{recursive}{Logical. Scan subdirectories. Default TRUE.}
}
\value{
A data.frame with columns: source, item, location, provider, jurisdiction, confidence, file, line. Empty (with a warning) if no matching files or no matches are found.
}
\description{
Recursively scans text-based config files for provider/region signatures. Results are unverified candidates for human review -- see the "confidence" column, always "candidate" -- and are meant to be triaged into a real CSV inventory, not treated as a certified audit on their own.
}
