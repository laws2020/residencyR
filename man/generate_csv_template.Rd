\name{generate_csv_template}
\alias{generate_csv_template}
\title{Generate a blank CSV inventory template}
\usage{
generate_csv_template(output_file, include_examples)
}
\arguments{
\item{output_file}{Character. Path to write the template CSV to.}
\item{include_examples}{Logical. If TRUE (default), includes one example row per source to illustrate the expected format. If FALSE, writes header only.}
}
\value{
Invisibly, `output_file`.
}
\description{
Generate a blank CSV inventory template
}
