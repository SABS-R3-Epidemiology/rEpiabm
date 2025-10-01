library(testthat)
library(withr)
library(mockery)

test_that("process_simulation_data coerces and reshapes", {
  td <- local_tempdir()

  # Create the CSV in the temp dir
  f <- file.path(td, "out.csv")
  write.csv(data.frame(
    time = c("0","1","2"),
    InfectionStatus.Susceptible = c("10","8","6"),
    InfectionStatus.InfectMild  = c("0","2","3"),
    InfectionStatus.Recovered   = c("0","0","1"),
    InfectionStatus.Dead        = c("0","0","0")
  ), f, row.names = FALSE)

  # Force process_simulation_data() to resolve here("out.csv") -> file.path(td, "out.csv")
  stub(process_simulation_data, "here", function(...) file.path(td, ...))

  df <- process_simulation_data("out.csv")

  expect_s3_class(df, "data.frame")
  expect_true(all(c("time","Status","Count") %in% names(df)))
  expect_true(all(levels(df$Status) %in% c("Susceptible","Infected","Recovered","Dead")))
  expect_type(df$time, "double")
  expect_type(df$Count, "double")
})


test_that("create_sir_plot returns a ggplot; save_plot writes a file", {
  df <- data.frame(
    time   = rep(0:3, each = 2),
    Status = rep(c("Susceptible","Infected"), times = 4),
    Count  = c(10,0,9,1,7,2,6,3)
  )
  p <- create_sir_plot(df, display = FALSE)
  expect_s3_class(p, "ggplot")

  td <- local_tempdir()
  out <- file.path(td, "sir.png")
  save_plot(p, out)
  expect_true(file.exists(out))
})

test_that("plot_rt_curves validates columns and writes PNG", {
  td <- local_tempdir()
  f <- file.path(td, "rt.csv")
  write.csv(data.frame(
    time = 1:5, R_t = seq(1.2, 0.8, length.out = 5)
  ), f, row.names = FALSE)

  out <- file.path(td, "rt.png")
  p <- plot_rt_curves(f, out)
  expect_s3_class(p, "ggplot")
  expect_true(file.exists(out))
})

test_that("create_serial_interval_plot flattens CSV and writes", {
  td <- local_tempdir()
  f <- file.path(td, "si.csv")
  # First row is header; function drops first row, then unlists
  write.csv(rbind(c("V1","V2"), c(1,2), c(3,NA), c(4,5)), f, row.names = FALSE)
  out <- file.path(td, "si.png")
  p <- create_serial_interval_plot(f, display = FALSE, location = out)
  expect_s3_class(p, "ggplot")
  expect_true(file.exists(out))
})
