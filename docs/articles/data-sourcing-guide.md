# Sourcing Inventory Data From Existing Cloud Tools

## Why this matters

Asking a bank’s security team for console access or API credentials
triggers procurement review, NDAs, and months of delay. This tool never
needs any of that – it reads a CSV. This guide is for the person on the
other side of the table: what to actually ask an infra or cloud team to
export, using buttons that already exist in tools they use daily.

Start from a template:

``` r

generate_csv_template("inventory.csv")
```

This produces a four-row example (one per source) showing the exact
column shape
[`ingest_csv_inventory()`](https://laws2020.github.io/residencyR/reference/ingest_csv_inventory.md)
expects: `source`, `item`, `provider`, `region`.

## Where each source’s data actually comes from

### `db` and `backups` — cloud resource inventory

- **AWS**: Resource Groups console -\> Tag Editor -\> select “All
  supported resource types” across all regions -\> Search resources -\>
  Export to CSV.
- **Azure**: All Resources blade, or Azure Resource Graph Explorer with
  a query listing VMs and storage accounts -\> Download as CSV.

A cost/billing export works as a fallback or cross-check: AWS Cost &
Usage Report (CUR) or Azure Cost Management export lists every resource
alongside its billing region, which catches anything a manual inventory
missed.

### `api_logs` — gateway and load balancer logs

A short log sample from the API management layer (AWS API Gateway,
Apigee, MuleSoft) exported from CloudWatch or Azure Monitor gives
destination URLs and routing metadata – enough to classify where API
calls actually terminate.

### `third_party_calls` — outbound vendor traffic

NAT Gateway or firewall egress logs (VPC Flow Logs, Palo Alto, Check
Point) record the destination IP/domain for every outbound request –
this is what reveals a vendor integration quietly routing through a
foreign region.

## Mapping an export to the CSV format

Whatever export you get back rarely matches the four required columns
exactly. The usual mapping:

| CSV column | Typically found as |
|----|----|
| `item` | resource name / tag / description |
| `provider` | AWS / Azure / GCP / vendor name |
| `region` | region code or data center location column |
| `source` | not usually present – you assign this based on which export the row came from (inventory -\> `db`/`backups`, gateway logs -\> `api_logs`, egress logs -\> `third_party_calls`) |

## Asking for it safely

Security teams are understandably cautious about handing over raw
exports. What actually gets shared can be masked first without losing
anything the scan needs:

- Internal resource names can be renamed (`prod-core-banking-db-01` -\>
  `database_source_01`) – `item` is a label, not a lookup key.
  - Secrets, account IDs, and credentials can be stripped entirely –
    none of the four columns need them.
  - The only columns that matter for classification are provider and
    region – everything else is for human readability in the resulting
    certificate.

## Running the scan

Once the CSV is assembled and columns are mapped:

``` r

audit <- scan_from_csv("inventory.csv")
flagged <- flag_offshore_calls(audit)
gen_residency_certificate_pdf(audit, flagged, bank_name = "Bank Name",
                               output_file = "certificate.pdf")
```

Everything runs locally – no network calls, no data leaving the machine
it’s run on.
