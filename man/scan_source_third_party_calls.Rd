\name{scan_source_third_party_calls}
\alias{scan_source_third_party_calls}
\title{Scan third-party vendor data flow residency}
\usage{
scan_source_third_party_calls(config)
}
\arguments{
\item{config}{List of vendor descriptors. Each element must be a list with `item` (vendor/purpose name), `provider`, and `region`. Example: list(list(item = "chargeback_processor", provider = "Stripe", region = "US"))}
}
\value{
A data.frame with columns: source, item, location, jurisdiction, provider, status.
}
\description{
Scan third-party vendor data flow residency
}
