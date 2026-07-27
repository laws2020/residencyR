# Verify a residencyR license file

Checks the license file's signature (RSA public-key verification –
confirms it was issued by the licensing backend and hasn't been tampered
with) and its expiry date.

## Usage

``` r
verify_license(path)
```

## Arguments

- path:

  Character or NULL. Path to a license file. Defaults to the standard
  per-user location used by \[install_license()\].

## Value

A list with \`valid\` (logical) and \`reason\` (character), plus
\`licensee\`, \`plan\`, and \`expires\` when valid.
