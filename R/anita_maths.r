#' Add two numbers together
#'
#' @param x First number
#' @param y Second number
#' @return The sum of x and y
#' @examples
#' add(1, 2)
#' add(-1, 1)
add <- function(x, y) {
  return(x + y)
}

#' Subtract the second number from the first
#'
#' @param x First number
#' @param y Second number
#' @return The result of x - y
#' @examples
#' subtract(5, 2)
#' subtract(-5, -3)
subtract <- function(x, y) {
  return(x - y)
}

#' Multiply two numbers
#'
#' @param x First number
#' @param y Second number
#' @return The product of x and y
#' @examples
#' multiply(3, 4)
#' multiply(-2, 5)
multiply <- function(x, y) {
  return(x * y)
}

#' Divide the first number by the second
#'
#' @param x Numerator
#' @param y Denominator
#' @return The result of x / y
#' @examples
#' divide(10, 2)
#' divide(0, 5)
divide <- function(x, y) {
  if (y == 0) {
    stop("Cannot divide by zero")
  }
  return(x / y)
}

#' Calculate the arithmetic mean of a vector
#'
#' @param x A numeric vector
#' @return The arithmetic mean
#' @examples
#' mean_calc(c(1, 2, 3, 4))
#' mean_calc(c(10, 20))
mean_calc <- function(x) {
  return(sum(x) / length(x))
}

#' Calculate the standard deviation of a vector
#'
#' @param x A numeric vector
#' @return The standard deviation
#' @examples
#' std_dev(c(1, 2, 3, 4))
#' std_dev(c(5, 5, 5))
std_dev <- function(x) {
  mean_x <- mean_calc(x)
  variance <- sum((x - mean_x)^2) / length(x)
  return(sqrt(variance))
}

#' Check if a value is a valid probability (between 0 and 1)
#'
#' @param p Value to check
#' @return TRUE if valid probability, FALSE otherwise
#' @examples
#' is_probability(0.5)
#' is_probability(1.5)
is_probability <- function(p) {
  return(p >= 0 && p <= 1)
}

#' Calculate risk based on probability and risk factor
#'
#' @param prob Probability value
#' @param factor Risk factor
#' @return Calculated risk
#' @examples
#' calculate_risk(0.3, 0.5)
#' calculate_risk(0.1, 0.2)
calculate_risk <- function(prob, factor) {
  if (!is_probability(prob) || !is_probability(factor)) {
    warning("Inputs should be valid probabilities")
  }
  return(prob * factor)
}

#' Calculate something with validation
#'
#' @param input Input value
#' @return Calculated result
#' @examples
#' calculate_something(5)
#' calculate_something(10)
calculate_something <- function(input) {
  if (is.null(input)) {
    stop("Input cannot be NULL")
  }
  return(input * 2)
}

#' Validate input value
#'
#' @param input Input value to validate
#' @return Validated input
#' @examples
#' validate_input(5)
#' validate_input(-1)
validate_input <- function(input) {
  if (input < 0) {
    warning("Negative input detected")
  }
  return(abs(input))
}

#' Perform a safe calculation with error handling
#'
#' @param input Input vector
#' @return Calculation result or NA for empty inputs
#' @examples
#' safe_calculation(c(1, 2, 3))
#' safe_calculation(c())
safe_calculation <- function(input) {
  if (length(input) == 0) {
    return(NA)
  }
  return(sum(input))
}