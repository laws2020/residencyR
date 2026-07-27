# Scan API call destination residency

Scan API call destination residency

## Usage

``` r
scan_source_api_logs(config)
```

## Arguments

- config:

  List of API call descriptors. Each element must be a list with
  \`item\` (endpoint/vendor name), \`provider\`, and \`region\`.
  Example: list(list(item = "fraud_scoring_api", provider = "AWS",
  region = "eu-west-1"))

## Value

A data.frame with columns: source, item, location, jurisdiction,
provider, status.
