\name{scan_source_api_logs}
\alias{scan_source_api_logs}
\title{Scan API call destination residency}
\usage{
scan_source_api_logs(config)
}
\arguments{
\item{config}{List of API call descriptors. Each element must be a list with `item` (endpoint/vendor name), `provider`, and `region`. Example: list(list(item = "fraud_scoring_api", provider = "AWS", region = "eu-west-1"))}
}
\value{
A data.frame with columns: source, item, location, jurisdiction, provider, status.
}
\description{
Scan API call destination residency
}
