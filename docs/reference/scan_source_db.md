# Scan database hosting residency

Scan database hosting residency

## Usage

``` r
scan_source_db(config)
```

## Arguments

- config:

  List of DB endpoint descriptors. Each element must be a list with
  \`item\` (name), \`provider\`, and \`region\`. Example: list(list(item
  = "core_banking_db", provider = "MainOne", region = "Lagos-NG"))

## Value

A data.frame with columns: source, item, location, jurisdiction,
provider, status.
