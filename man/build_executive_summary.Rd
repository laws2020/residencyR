\name{build_executive_summary}
\alias{build_executive_summary}
\title{Build the executive summary paragraph for a residency certificate}
\usage{
build_executive_summary(audit, flagged, regulation)
}
\arguments{
\item{audit}{A data.frame as returned by [scan_data_residency()].}
\item{flagged}{A data.frame as returned by [flag_offshore_calls()].}
\item{regulation}{A list with `citation` and `deadline_text` elements, e.g. `list(citation = "...", deadline_text = "...")`. Defaults to the CBN 2027 data localization circular. Pass a different value to cite a different rule (a future CBN update, a different regulator, or a routine post-deadline re-scan).}
}
\value{
Character. A single paragraph of summary text.
}
\description{
Build the executive summary paragraph for a residency certificate
}
