# Generate a data residency certificate

Generate a data residency certificate

## Usage

``` r
gen_residency_certificate(audit, flagged, bank_name, output_file, regulation)
```

## Arguments

- audit:

  A data.frame as returned by \[scan_data_residency()\].

- flagged:

  A data.frame as returned by \[flag_offshore_calls()\].

- bank_name:

  Character. Name to appear on the certificate.

- output_file:

  Character or NULL. If given, writes the report to this path as a
  markdown file. If NULL, only returns the text.

- regulation:

  A list with \`citation\` and \`deadline_text\`, as used by
  \[build_executive_summary()\]. Defaults to the CBN 2027 data
  localization circular; pass a different value to cite a different
  rule.

## Value

Invisibly, a character vector of the report lines.
