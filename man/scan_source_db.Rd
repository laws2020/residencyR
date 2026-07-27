\name{scan_source_db}
\alias{scan_source_db}
\title{Scan database hosting residency}
\usage{
scan_source_db(config)
}
\arguments{
\item{config}{List of DB endpoint descriptors. Each element must be a list with `item` (name), `provider`, and `region`. Example: list(list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG"))}
}
\value{
A data.frame with columns: source, item, location, jurisdiction, provider, status.
}
\description{
Scan database hosting residency
}
