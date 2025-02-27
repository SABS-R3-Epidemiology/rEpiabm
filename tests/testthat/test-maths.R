source("R/maths.R")

library(testthat)

test_that("Addition is correct",{
    expect_equal(addition(2,3),5)
    expect_equal(addition(1,2),3)
    expect_equal(addition(3,4),7)
})

test_that("Multiplication is correct",{
    expect_equal(multiply(2,3),6)
    expect_equal(multiply(1,2),2)
    expect_equal(multiply(3,4),12)
})

test_that("Division is correct",{
    expect_equal(divide(10,2),5)
    expect_equal(divide(6,3),2)
    expect_equal(divide(12,4),3)
})

