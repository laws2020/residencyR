# Scan raw infra config files for candidate residency findings

Recursively scans text-based config files for provider/region
signatures. Results are unverified candidates for human review – see the
"confidence" column, always "candidate" – and are meant to be triaged
into a real CSV inventory, not treated as a certified audit on their
own.

## Usage

``` r
scan_source_files(path, extensions, recursive)
```

## Arguments

- path:

  Character. Directory to scan.

- extensions:

  Character vector of file extensions to include (without the dot).
  Defaults to common infra config types.

- recursive:

  Logical. Scan subdirectories. Default TRUE.

## Value

A data.frame with columns: source, item, location, provider,
jurisdiction, confidence, file, line. Empty (with a warning) if no
matching files or no matches are found.
