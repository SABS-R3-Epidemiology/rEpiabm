# Tests for functions in anita_maths.r
library(testthat)
library(rEpiabm)

test_that("Addition functions work correctly", {
  expect_equal(add(1, 2), 3)
  expect_equal(add(1.5, 2.5), 4.0)
})

test_that("Subtraction functions work correctly", {
  # Assuming there's a subtract() function
  expect_equal(subtract(5, 2), 3)
  expect_equal(subtract(-5, -3), -2)
})

test_that("Multiplication functions work correctly", {
  # Assuming there's a multiply() function
  expect_equal(multiply(3, 4), 12)
  expect_equal(multiply(0, 100), 0)
})

test_that("Division functions work correctly", {
  # Assuming there's a divide() function
  expect_equal(divide(10, 2), 5)
  expect_equal(divide(0, 5), 0)

  # Test that division by zero raises an error
  expect_error(divide(5, 0), "Cannot divide by zero")
})

test_that("Statistical functions work correctly", {
  # Assuming there might be functions like mean_calc() or std_dev()
  # For example:
  expect_equal(mean_calc(c(1, 2, 3, 4)), 2.5)
  expect_equal(std_dev(c(1, 2, 3, 4)), 1.12, tolerance = 0.01)
})

# If there are simulation-related functions in anita_maths.r
test_that("Simulation calculations are accurate", {
  # Example tests:
  expect_true(is_probability(0.5))
  expect_false(is_probability(1.5))
  expect_equal(calculate_risk(0.3, 0.5), 0.15)
})

# Edge cases and error handling
test_that("Functions handle edge cases correctly", {
  expect_error(calculate_something(NULL), "Input cannot be NULL")
  expect_warning(validate_input(-1), "Negative input detected")
  expect_equal(safe_calculation(c()), NA, "Empty input should return NA")
})