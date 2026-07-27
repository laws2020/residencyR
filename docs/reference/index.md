# Package index

## Run an audit

The main workflow: scan, flag, certify.

- [`scan_data_residency()`](https://laws2020.github.io/residencyR/reference/scan_data_residency.md)
  : Scan payment data residency across registered sources
- [`flag_offshore_calls()`](https://laws2020.github.io/residencyR/reference/flag_offshore_calls.md)
  : Flag offshore residency records
- [`gen_residency_certificate()`](https://laws2020.github.io/residencyR/reference/gen_residency_certificate.md)
  : Generate a data residency certificate
- [`gen_residency_certificate_pdf()`](https://laws2020.github.io/residencyR/reference/gen_residency_certificate_pdf.md)
  : Generate a data residency certificate as a PDF

## Ingest real data

Get infrastructure data into the audit pipeline.

- [`ingest_csv_inventory()`](https://laws2020.github.io/residencyR/reference/ingest_csv_inventory.md)
  : Build a scan_data_residency() config from a CSV inventory
- [`scan_from_csv()`](https://laws2020.github.io/residencyR/reference/scan_from_csv.md)
  : Run a full residency audit directly from a CSV inventory
- [`generate_csv_template()`](https://laws2020.github.io/residencyR/reference/generate_csv_template.md)
  : Generate a blank CSV inventory template

## Scan raw code (candidate findings)

Regex-based discovery from Terraform/config files – unverified, for
triage into a CSV inventory.

- [`scan_source_files()`](https://laws2020.github.io/residencyR/reference/scan_source_files.md)
  : Scan raw infra config files for candidate residency findings

## Individual scan sources

The building blocks scan_data_residency() dispatches to – callable
directly if you only need one.

- [`scan_source_db()`](https://laws2020.github.io/residencyR/reference/scan_source_db.md)
  : Scan database hosting residency
- [`scan_source_api_logs()`](https://laws2020.github.io/residencyR/reference/scan_source_api_logs.md)
  : Scan API call destination residency
- [`scan_source_backups()`](https://laws2020.github.io/residencyR/reference/scan_source_backups.md)
  : Scan backup and disaster-recovery storage residency
- [`scan_source_third_party_calls()`](https://laws2020.github.io/residencyR/reference/scan_source_third_party_calls.md)
  : Scan third-party vendor data flow residency

## Registry

Register and inspect scan sources.

- [`register_residency_source()`](https://laws2020.github.io/residencyR/reference/register_residency_source.md)
  : Register a residency scan source
- [`list_residency_sources()`](https://laws2020.github.io/residencyR/reference/list_residency_sources.md)
  : List registered residency scan sources

## License Management

Install and verify residencyR licenses.

- [`install_license()`](https://laws2020.github.io/residencyR/reference/install_license.md)
  : Install a residencyR license file
- [`verify_license()`](https://laws2020.github.io/residencyR/reference/verify_license.md)
  : Verify a residencyR license file

## Internals

Shared classification and reporting logic.

- [`classify_jurisdiction()`](https://laws2020.github.io/residencyR/reference/classify_jurisdiction.md)
  : Classify provider/region text as local, offshore, or unknown
- [`build_executive_summary()`](https://laws2020.github.io/residencyR/reference/build_executive_summary.md)
  : Build the executive summary paragraph for a residency certificate
