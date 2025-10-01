library(testthat)
library(mockery)
library(here)

test_that("initialize_simulation_env wires calls and returns pyEpiabm", {
  # Arrange: mocks for the injected fns
  fake_pe <- list(tag = "pyEpiabm")
  importer <- mock(
    list(),                # "os"
    list(),                # "logging"
    list(),                # "pandas"
    list(),                # "matplotlib.pyplot"
    fake_pe                # "pyEpiabm"
  )
  src   <- mock(NULL)
  init  <- mock(NULL)
  check <- mock(NULL)

  # Act: inject ALL four parameters so the real file system isn't touched
  res <- initialize_simulation_env(
    source_fn = src,
    import_fn = importer,
    init_fn   = init,
    check_fn  = check
  )

  # Assert: return value is exactly the pyEpiabm object
  expect_identical(res, fake_pe)

  # Assert: order & args of the setup calls
  expect_called(src,   1)
  expect_args(src, 1, "R/zzz.R")

  expect_called(init,  1)
  expect_args(init, 1, force = FALSE)

  expect_called(check, 1)

  # Assert: 5 imports with delay_load=TRUE, last is "pyEpiabm"
  expect_called(importer, 5)
  expect_args(importer, 1, "os",                delay_load = TRUE)
  expect_args(importer, 2, "logging",           delay_load = TRUE)
  expect_args(importer, 3, "pandas",            delay_load = TRUE)
  expect_args(importer, 4, "matplotlib.pyplot", delay_load = TRUE)
  expect_args(importer, 5, "pyEpiabm",          delay_load = TRUE)
})
