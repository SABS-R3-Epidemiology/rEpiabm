library(testthat)
library(mockery)
library(withr)
# library(rEpiabm)

test_that("configure_parameters calls Parameters$set_file with here() path", {
  td <- local_tempdir()
  local_dir(td)  # so here() resolves inside tempdir
  cfg_name <- "config.json"
  writeLines("{}", file.path(td, cfg_name))

  pe <- list(Parameters = list(set_file = mock(NULL)))

  res <- configure_parameters(pe, input_dir = ".", config_parameters = cfg_name)

  expect_identical(res, pe)
  expect_called(pe$Parameters$set_file, 1)
  expect_args(pe$Parameters$set_file, 1, here(".", cfg_name))
})
