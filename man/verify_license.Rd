\name{verify_license}
\alias{verify_license}
\title{Verify a residencyR license file}
\usage{
verify_license(path)
}
\arguments{
\item{path}{Character or NULL. Path to a license file. Defaults to the standard per-user location used by [install_license()].}
}
\value{
A list with `valid` (logical) and `reason` (character), plus `licensee`, `plan`, and `expires` when valid.
}
\description{
Checks the license file's signature (RSA public-key verification -- confirms it was issued by the licensing backend and hasn't been tampered with) and its expiry date.
}
