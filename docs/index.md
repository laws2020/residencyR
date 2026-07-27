# residencyR

**Data residency auditing and compliance reporting, built entirely on
base R.**

residencyR audits where your infrastructure and transaction data
actually lives — across databases, API traffic, backups, and third-party
vendor connections — and turns that into a certificate you can hand to a
CISO, a board, or a regulator. It was built for Nigeria’s CBN payment
data localization deadline (1 January 2027), but the regulatory citation
is a parameter, not a hardcoded assumption, so it isn’t limited to that
one rule.

> **Independence notice:** residencyR is an independent, third-party
> auditing tool. It is not issued by, endorsed by, or affiliated with
> the Central Bank of Nigeria or any other regulator. Every certificate
> it generates states this explicitly.

------------------------------------------------------------------------

## Why residencyR

- **Zero-dependency audit engine.** Scanning, classification, and
  ingestion run entirely on base R (`grDevices`, `graphics`, `utils`) —
  nothing else to install to run an audit. Certificate generation is
  commercially licensed and additionally requires `openssl` for
  signature verification.
- **Runs completely offline.** No network calls, no live database
  connections, no API credentials. Point it at a CSV or a folder of
  config files on an air-gapped laptop and it works.
- **Fast at real scale.** A full audit — ingest, scan, flag, and PDF
  generation with charts — completes in about a second on 5,000
  infrastructure assets, far beyond what any single institution’s
  inventory is likely to contain.
- **Extensible by design.** New data sources register themselves into a
  shared dispatch registry. Adding a fifth source doesn’t mean touching
  the first four.
- **Honest about uncertainty.** A row that gives mixed signals (e.g. an
  AWS provider with a Nigerian-looking region string) is classified
  `"unknown"`, not silently resolved either way. Scanner failures are
  surfaced on the certificate itself, not buried in a console warning.
  Regex-based code scanning is labeled `"candidate"` and never blended
  into a certified audit table.

------------------------------------------------------------------------

## Installation

``` r
remotes::install_github("laws2020/residencyR")
```

------------------------------------------------------------------------

## Quick start

The whole workflow in five lines:

``` r
library(residencyR)

generate_csv_template("inventory.csv")             # 1. get a starter file
audit    <- scan_from_csv("inventory.csv")          # 2. ingest + scan
flagged  <- flag_offshore_calls(audit)              # 3. isolate what needs review
gen_residency_certificate_pdf(audit, flagged,       # 4. produce the report
  bank_name = "Example Bank Plc",
  output_file = "certificate.pdf")
```

That’s a real, complete audit — not a demo stub. Replace `inventory.csv`
with your actual infrastructure data (see [Getting your data
in](#getting-your-data-in)) and the same five lines produce a real
result.

------------------------------------------------------------------------

## Core concepts

Every scan source returns rows in the same shape, which is what makes
the whole package composable:

| Column         | Meaning                                                                                                |
|----------------|--------------------------------------------------------------------------------------------------------|
| `source`       | Which scanner produced this row (`db`, `api_logs`, `backups`, `third_party_calls`, or a custom source) |
| `item`         | A human-readable name for the asset                                                                    |
| `location`     | The region/location string as reported                                                                 |
| `jurisdiction` | `"local"`, `"offshore"`, or `"unknown"`                                                                |
| `provider`     | The hosting or vendor provider                                                                         |
| `status`       | `"ok"` (local) or `"flagged"` (offshore or unknown)                                                    |

**Jurisdiction classification is deliberately conservative.**
[`classify_jurisdiction()`](https://laws2020.github.io/residencyR/reference/classify_jurisdiction.md)
checks provider/region text against known Nigerian and known offshore
signatures. If it matches *both* — a genuinely ambiguous case — the
result is `"unknown"`, not an automatic pass. A tool whose entire value
is catching things that don’t belong doesn’t get to wave through the
cases it isn’t sure about.

------------------------------------------------------------------------

## Getting your data in

You have three ways to feed residencyR real data, in order of how much
trust each deserves.

### 1. CSV inventory (the primary path)

``` r
generate_csv_template("inventory.csv")   # starter file with one example row per source
```

Fill it in with real values (`source, item, provider, region`), then:

``` r
audit <- scan_from_csv("inventory.csv")
```

or, if you want to build the config yourself instead of going through a
file:

``` r
configs <- ingest_csv_inventory("inventory.csv")
audit   <- scan_data_residency(sources = names(configs), configs = configs)
```

**Don’t know where the CSV data should come from?** The
`data-sourcing-guide` vignette maps each source to real console exports
— AWS Tag Editor and Cost & Usage Reports, Azure Resource Graph, API
gateway logs, VPC Flow/NAT logs — including how to mask sensitive fields
before sharing:

``` r
vignette("data-sourcing-guide", package = "residencyR")
```

### 2. Direct source calls

If you already have structured config in R (not a CSV), call a scan
source directly:

``` r
scan_source_db(list(
  list(item = "core_banking_db", provider = "MainOne", region = "Lagos-NG")
))
```

The four built-in sources —
[`scan_source_db()`](https://laws2020.github.io/residencyR/reference/scan_source_db.md),
[`scan_source_api_logs()`](https://laws2020.github.io/residencyR/reference/scan_source_api_logs.md),
[`scan_source_backups()`](https://laws2020.github.io/residencyR/reference/scan_source_backups.md),
[`scan_source_third_party_calls()`](https://laws2020.github.io/residencyR/reference/scan_source_third_party_calls.md)
— all take the same `list(item, provider, region)` shape and return the
same schema.

### 3. Raw code scanning (candidate findings only)

If an engineer hands you a Terraform/config repo instead of a CSV:

``` r
candidates <- scan_source_files("path/to/repo")
```

This regex-scans `.tf`, `.tfvars`, `.yml`, `.yaml`, `.env`, and `.json`
files for provider/region signatures — no JSON parsing, no new
dependency. **Read this carefully before using it in front of a
client:** every row comes back tagged `confidence = "candidate"`, and
this source is deliberately *not* registered in
[`scan_data_residency()`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md)
— it can never silently blend into a certified audit. It’s a heuristic
for faster triage before building the CSV, not a replacement for it. It
will miss dynamically-constructed values and can false-positive on
comments or dead code — treat its output as “worth checking,” not
“confirmed.”

------------------------------------------------------------------------

## Running the audit

``` r
audit <- scan_data_residency(sources = c("db", "api_logs"), configs = my_configs)
```

- Omit `sources` to scan everything currently registered.
- If a source fails (bad config, a broken custom extension), the audit
  doesn’t crash — the failure is caught, and recorded in a `scan_errors`
  attribute:

``` r
attr(audit, "scan_errors")
#> [1] "api_logs: connection timed out"
```

Both certificate generators check for this automatically and render a
prominent warning if present. An audit that quietly dropped a source and
looked smaller and cleaner than it should have is worse than one that
visibly failed — so it never happens silently.

``` r
flagged <- flag_offshore_calls(audit)   # offshore + unknown rows, for remediation
```

------------------------------------------------------------------------

## Generating reports

### Markdown certificate

``` r
gen_residency_certificate(audit, flagged, bank_name = "Example Bank Plc",
                           output_file = "certificate.md")
```

Produces a verdict line (`COMPLIANT` / `NON-COMPLIANT` / `UNKNOWN`), a
dynamic executive summary paragraph, a per-source breakdown, and a
numbered remediation list.

### PDF certificate

``` r
gen_residency_certificate_pdf(audit, flagged, bank_name = "Example Bank Plc",
                               output_file = "certificate.pdf")
```

The board-ready version: a jurisdiction donut chart, a per-source bar
chart, the same verdict and executive summary, a color-coded item table,
and automatic pagination for large audits. Built entirely with base R
graphics — no `rmarkdown`, no `pandoc`, no LaTeX.

### Making the citation match your situation

Every report cites a regulatory basis — by default, CBN’s circular:

``` r
gen_residency_certificate_pdf(audit, flagged, bank_name = "Example Bank Plc",
  output_file = "certificate.pdf",
  regulation = list(
    citation = "Some Future Circular or Different Regulator's Rule",
    deadline_text = "31 December 2030",
    regulator_name = "the relevant authority"
  ))
```

This is the whole reason the tool doesn’t expire when the January 2027
deadline passes, or if it’s ever used outside a CBN context: the
regulation is an argument, not an assumption baked into the code.

------------------------------------------------------------------------

## Extending the registry

New data sources plug into the same pipeline everything else uses:

``` r
register_residency_source("cloud_storage", function(config) {
  # must return a data.frame with columns:
  # source, item, location, jurisdiction, provider, status
})

list_residency_sources()
#> [1] "api_logs" "backups" "cloud_storage" "db" "third_party_calls"
```

Once registered,
[`scan_data_residency()`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md)
picks it up automatically — no changes needed anywhere else.

------------------------------------------------------------------------

## Interpreting results

| Verdict         | Meaning                                                             |
|-----------------|---------------------------------------------------------------------|
| `COMPLIANT`     | No offshore or unknown items found in this audit                    |
| `NON-COMPLIANT` | At least one flagged item — see the remediation list                |
| `UNKNOWN`       | No data was audited — check your config before trusting this result |

A `flagged` row with `jurisdiction = "unknown"` isn’t necessarily a
violation — it means the provider/region text didn’t clearly resolve
either way, and a human should look at it. Treat `"unknown"` as “needs a
decision,” not “guilty.”

------------------------------------------------------------------------

## Limitations, stated plainly

- **Accuracy depends on input quality.** The tool classifies whatever
  provider/region text it’s given. If the CSV says the wrong region, the
  certificate will say the wrong region — there is no independent
  verification against actual cloud infrastructure.
- **The code scanner is a heuristic, not an audit.** See the caveats
  above — it’s for triage, not certification.
- **No live cloud API integration.** By design — this is what makes the
  “runs on an air-gapped laptop” claim true. It also means residencyR
  never confirms your CSV or config files reflect current reality;
  that’s on your process, not the tool.
- **Terraform state (`.tfstate`) parsing isn’t built.** `.tf` source
  files are plain text and already supported via
  [`scan_source_files()`](https://laws2020.github.io/residencyR/reference/scan_source_files.md);
  `.tfstate` is JSON and would require a dependency (`jsonlite`) that
  hasn’t been added.
- **The classification indicator lists are not exhaustive.**
  `.ng_indicators` and `.offshore_indicators` in `classify.R` are a
  working set, verified against real providers as they’re added — not a
  complete registry of every Nigerian or offshore provider that exists.

------------------------------------------------------------------------

## Getting help

- **Vignettes:**
  [`vignette("residencyR")`](https://laws2020.github.io/residencyR/articles/residencyR.md)
  for a full worked example;
  [`vignette("data-sourcing-guide")`](https://laws2020.github.io/residencyR/articles/data-sourcing-guide.md)
  for where real infrastructure data actually comes from.
- **Function reference:** every exported function is documented —
  [`?scan_data_residency`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md),
  [`?gen_residency_certificate_pdf`](https://laws2020.github.io/residencyR/reference/gen_residency_certificate_pdf.md),
  etc.
- **Issues:** <https://github.com/laws2020/residencyR/issues>

------------------------------------------------------------------------

*residencyR — independent audit tooling. Not issued by, endorsed by, or
affiliated with the Central Bank of Nigeria or any other regulator.*
