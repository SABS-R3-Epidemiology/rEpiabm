library(testthat)
library(mockery)
# library(rEpiabm)

test_that("create_toy_population delegates to ToyPopulationFactory$make_pop", {
  make_pop_mock <- mock(list(ok = TRUE))
  pe <- list(routine = list(
    ToyPopulationFactory = function() list(make_pop = make_pop_mock)
  ))
  res <- create_toy_population(pe, list(n = 10))
  expect_true(is.list(res))
  expect_called(make_pop_mock, 1)
  expect_args(make_pop_mock, 1, list(n = 10))
})

test_that("create_epigeopop_population delegates to FilePopulationFactory$make_pop", {
  make_pop_mock <- mock(list(ok = TRUE))
  pe <- list(routine = list(
    FilePopulationFactory = function() list(make_pop = make_pop_mock)
  ))
  res <- create_epigeopop_population(pe, "pop.csv")
  expect_true(is.list(res))
  expect_called(make_pop_mock, 1)
  expect_args(make_pop_mock, 1, "pop.csv")
})
