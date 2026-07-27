test_that("register_residency_source adds a source", {
  register_residency_source("dummy", function(cfg) NULL)
  expect_true("dummy" %in% list_residency_sources())
})

test_that("get_residency_source retrieves the registered function", {
  fn <- function(cfg) "ok"
  register_residency_source("dummy2", fn)
  retrieved <- get_residency_source("dummy2")
  expect_identical(retrieved("x"), "ok")
})

test_that("get_residency_source errors on unknown source", {
  expect_error(get_residency_source("nonexistent_source"), "Unknown residency source")
})

test_that("db source is registered by default on load", {
  expect_true("db" %in% list_residency_sources())
})
