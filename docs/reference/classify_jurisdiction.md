# Classify provider/region text as local, offshore, or unknown

Classify provider/region text as local, offshore, or unknown

## Usage

``` r
classify_jurisdiction(provider, region)
```

## Arguments

- provider:

  Character vector. Hosting provider name(s).

- region:

  Character vector. Region/location string(s), same length as
  \`provider\`.

## Value

Character vector, same length as the input: "local", "offshore", or
"unknown" per element. A row that matches both a local and an offshore
indicator (e.g. an AWS region string with an "ng-" prefix) resolves to
"unknown", not "local" – a mixed signal is exactly the kind of thing
worth a human's attention, not an automatic pass.
