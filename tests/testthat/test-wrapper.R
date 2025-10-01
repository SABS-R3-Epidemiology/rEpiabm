library(testthat)
library(mockery)
library(here)
library(rEpiabm)

test_that("initialize_simulation_env returns mocked pyEpiabm module", {
  # Create a mock for the import() function that returns a fake pyEpiabm object
  fake_pyEpiabm <- list(name = "mocked_pyEpiabm")
  import_mock <- mock(fake_pyEpiabm)

  # Stub import() to use our mock, only for pyEpiabm
  stub(initialize_simulation_env, "import", import_mock)

  # Stub other functions if needed (e.g., initialize_python_env, check_python_env)
  stub(initialize_simulation_env, "initialize_python_env", function() NULL)
  stub(initialize_simulation_env, "check_python_env", function() NULL)

  result <- initialize_simulation_env()

  expect_equal(result$name, "mocked_pyEpiabm")
  expect_called(import_mock, 1)
  expect_args(import_mock, 1, "os", delay_load = TRUE)
})