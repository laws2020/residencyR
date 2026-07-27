\name{register_residency_source}
\alias{register_residency_source}
\title{Register a residency scan source}
\usage{
register_residency_source(name, scan_fn)
}
\arguments{
\item{name}{Character. Unique source name (e.g. "db", "api_logs"). Matching is case-insensitive and whitespace-tolerant.}
\item{scan_fn}{Function. Takes a config list, returns a data.frame with columns: source, item, location, jurisdiction, provider, status.}
}
\description{
Register a residency scan source
}
