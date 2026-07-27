# Build the executive summary paragraph for a residency certificate

Build the executive summary paragraph for a residency certificate

## Usage

``` r
build_executive_summary(audit, flagged, regulation)
```

## Arguments

- audit:

  A data.frame as returned by \[scan_data_residency()\].

- flagged:

  A data.frame as returned by \[flag_offshore_calls()\].

- regulation:

  A list with \`citation\` and \`deadline_text\` elements, e.g.
  \`list(citation = "...", deadline_text = "...")\`. Defaults to the CBN
  2027 data localization circular. Pass a different value to cite a
  different rule (a future CBN update, a different regulator, or a
  routine post-deadline re-scan).

## Value

Character. A single paragraph of summary text.
