# Scan backup and disaster-recovery storage residency

Scan backup and disaster-recovery storage residency

## Usage

``` r
scan_source_backups(config)
```

## Arguments

- config:

  List of backup target descriptors. Each element must be a list with
  \`item\` (backup set name), \`provider\`, and \`region\`. Example:
  list(list(item = "dr_snapshot", provider = "Azure", region = "West
  Europe (Netherlands)"))

## Value

A data.frame with columns: source, item, location, jurisdiction,
provider, status.
