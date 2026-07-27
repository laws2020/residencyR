# Scan third-party vendor data flow residency

Scan third-party vendor data flow residency

## Usage

``` r
scan_source_third_party_calls(config)
```

## Arguments

- config:

  List of vendor descriptors. Each element must be a list with \`item\`
  (vendor/purpose name), \`provider\`, and \`region\`. Example:
  list(list(item = "chargeback_processor", provider = "Stripe", region =
  "US"))

## Value

A data.frame with columns: source, item, location, jurisdiction,
provider, status.
