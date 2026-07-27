# Build a scan_data_residency() config from a CSV inventory

Build a scan_data_residency() config from a CSV inventory

## Usage

``` r
ingest_csv_inventory(path)
```

## Arguments

- path:

  Character. Path to a CSV file with columns \`source\`, \`item\`,
  \`provider\`, \`region\` (case-insensitive, any order).

## Value

A named list suitable for passing as \`configs\` to
\[scan_data_residency()\], keyed by source name.
