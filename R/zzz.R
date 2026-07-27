.onLoad <- function(libname, pkgname) {
  register_residency_source("db", scan_source_db)
  register_residency_source("api_logs", scan_source_api_logs)
  register_residency_source("backups", scan_source_backups)
  register_residency_source("third_party_calls", scan_source_third_party_calls)
}
