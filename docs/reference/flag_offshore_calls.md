# Flag offshore residency records

Flag offshore residency records

## Usage

``` r
flag_offshore_calls(audit)
```

## Arguments

- audit:

  A data.frame as returned by \[scan_data_residency()\].

## Value

Subset of \`audit\` where jurisdiction is "offshore" or "unknown" (needs
manual review). Carries over any "scan_errors" attribute from \`audit\`.
