# Auditing Payment Data Residency with residencyR

## Motivation

CBN’s payment data localization directive requires payment transaction
data generated in Nigeria to be stored and managed locally by January 1,
2027. Before an examiner asks, it’s worth knowing the answer yourself:
where does your data actually sit today, and what still needs to move?

## Setup

``` r
library(residencyR)
```

`residencyR` has no dependency beyond base R — the config you pass in
describes what your infra inventory, cloud billing export, or DB config
already knows about each endpoint.

## Describing your data sources

Each source takes a list of entries, each with an `item` name, a
`provider`, and a `region`:

``` r
configs <- list(
  db = list(
    list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")
  ),
  api_logs = list(
    list(item = "fraud_scoring_api", provider = "AWS", region = "eu-west-1")
  ),
  backups = list(
    list(item = "dr_snapshot", provider = "Azure", region = "West Europe (Ireland)")
  ),
  third_party_calls = list(
    list(item = "chargeback_processor", provider = "Stripe", region = "us-east-1")
  )
)
```

## Running the audit

``` r
audit <- scan_data_residency(configs = configs)
audit
```

Every row gets classified as `local`, `offshore`, or `unknown` based on
the provider/region text, using the same logic across all four sources.

## Flagging offshore exposure

``` r
flagged <- flag_offshore_calls(audit)
flagged
```

`unknown` results are included alongside `offshore` ones — they usually
mean the region string didn’t clearly match a known local or offshore
signature, and are worth a manual look either way.

## Generating the certificate

``` r
gen_residency_certificate(
  audit, flagged,
  bank_name = "Example Bank",
  output_file = "residency-certificate.md"
)
```

This produces a markdown report with a summary, a per-source breakdown,
and an itemized list of anything flagged — ready to hand to Internal
Audit, your CISO, or CBN/NDPC directly.

## Running this as a compliance cadence

Since the deadline is January 2027, treat this as a recurring scan —
monthly or quarterly — rather than a one-off. Re-running
[`scan_data_residency()`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md)
against an updated config as infra changes gives you a running record of
progress rather than a single snapshot.

## Extending with a new source

New sources register themselves through the same registry:

``` r
register_residency_source("my_source", function(config) {
  # return a data.frame with columns: source, item, location,
  # jurisdiction, provider, status
})
```

Once registered, it’s picked up automatically by
[`scan_data_residency()`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md)
and flows through to the certificate the same way the built-in sources
do.
