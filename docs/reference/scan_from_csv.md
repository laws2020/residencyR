# Run a full residency audit directly from a CSV inventory

Convenience wrapper: reads the CSV, builds the config, and runs
\[scan_data_residency()\] in one call.

## Usage

``` r
scan_from_csv(path)
```

## Arguments

- path:

  Character. Path to the CSV inventory.

## Value

A data.frame, same shape as \[scan_data_residency()\].
