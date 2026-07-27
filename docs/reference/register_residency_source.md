# Register a residency scan source

Register a residency scan source

## Usage

``` r
register_residency_source(name, scan_fn)
```

## Arguments

- name:

  Character. Unique source name (e.g. "db", "api_logs"). Matching is
  case-insensitive and whitespace-tolerant.

- scan_fn:

  Function. Takes a config list, returns a data.frame with columns:
  source, item, location, jurisdiction, provider, status.
