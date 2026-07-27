\name{scan_source_backups}
\alias{scan_source_backups}
\title{Scan backup and disaster-recovery storage residency}
\usage{
scan_source_backups(config)
}
\arguments{
\item{config}{List of backup target descriptors. Each element must be a list with `item` (backup set name), `provider`, and `region`. Example: list(list(item = "dr_snapshot", provider = "Azure", region = "West Europe (Netherlands)"))}
}
\value{
A data.frame with columns: source, item, location, jurisdiction, provider, status.
}
\description{
Scan backup and disaster-recovery storage residency
}
