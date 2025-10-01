library(testthat)
library(mockery)

# helper to fabricate a minimal 'pe' with sweep functions used by run_simulation
.make_pe_for_run <- function() {
  sweep <- list(
    InitialHouseholdSweep     = mock("InitHH"),
    InitialInfectedSweep      = mock("InitInf"),
    HouseholdSweep            = mock("HH"),
    QueueSweep                = mock("Q"),
    HostProgressionSweep      = mock("HP"),
    InitialisePlaceSweep      = mock("InitPlace"),
    InitialDemographicsSweep  = mock("InitDemo"),
    UpdatePlaceSweep          = mock("UpdPlace"),
    PlaceSweep                = mock("Place"),
    SpatialSweep              = mock("Spatial")
  )
  list(sweep = sweep, routine = list())  # routine is unused thanks to stubs below
}

test_that("run_simulation errors on invalid type", {
  pe <- .make_pe_for_run()
  # Stub helpers so we never touch real Python-ish objects
  stub(run_simulation, ".set_sim_seed", function(pe, seed) NULL)
  stub(run_simulation, ".make_simulation", function(pe) list(
    configure = function(...) NULL,
    run_sweeps = function() NULL,
    compress_csv = function() NULL
  ))

  expect_error(
    run_simulation(pe, list(), list(), list(), list(), simulation_type = "nope"),
    "simulation_type must be either 'toy' or 'epigeopop'"
  )
})

test_that("run_simulation (toy default) builds lists and runs lifecycle", {
  pe <- .make_pe_for_run()

  # Track that lifecycle methods are called
  conf <- mock(NULL); runm <- mock(NULL); comp <- mock(NULL)
  sim_obj <- list(configure = conf, run_sweeps = runm, compress_csv = comp)

  stub(run_simulation, ".set_sim_seed", function(pe, seed) NULL)
  stub(run_simulation, ".make_simulation", function(pe) sim_obj)

  sim_params <- list(a=1); file_params <- list(b=2); inf_params <- list(c=3)
  population <- list(pop=TRUE)

  sim <- run_simulation(
    pe, sim_params, file_params, inf_params, population,
    simulation_type = "toy", sweep_params = NULL, dem_file_params = NULL, seed = 42
  )

  # lifecycle calls
  expect_called(conf, 1)
  expect_called(runm, 1)
  expect_called(comp, 1)

  # sweep constructors invoked
  expect_called(pe$sweep$InitialHouseholdSweep, 1)
  expect_called(pe$sweep$InitialInfectedSweep, 1)
  expect_called(pe$sweep$HouseholdSweep, 1)
  expect_called(pe$sweep$QueueSweep, 1)
  expect_called(pe$sweep$HostProgressionSweep, 1)
})

test_that("run_simulation (toy + demographics) requires dem_file_params", {
  pe <- .make_pe_for_run()
  stub(run_simulation, ".set_sim_seed", function(pe, seed) NULL)
  stub(run_simulation, ".make_simulation", function(pe) list(
    configure = function(...) NULL,
    run_sweeps = function() NULL,
    compress_csv = function() NULL
  ))

  expect_error(
    run_simulation(
      pe, list(), list(), list(), list(),
      simulation_type = "toy",
      sweep_params = list(InitialDemographicsSweep = TRUE),
      dem_file_params = NULL
    ),
    "dem_file_params is required when InitialDemographicsSweep = TRUE"
  )
})

test_that("run_simulation (epigeopop) includes place/spatial/update sweeps", {
  pe <- .make_pe_for_run()

  conf <- mock(NULL); runm <- mock(NULL); comp <- mock(NULL)
  sim_obj <- list(configure = conf, run_sweeps = runm, compress_csv = comp)

  stub(run_simulation, ".set_sim_seed", function(pe, seed) NULL)
  stub(run_simulation, ".make_simulation", function(pe) sim_obj)

  sim <- run_simulation(
    pe,
    sim_params = list(),
    file_params = list(),
    inf_history_params = list(),
    population = list(),
    simulation_type = "epigeopop",
    dem_file_params = "dem.csv",
    seed = 7
  )

  expect_called(pe$sweep$InitialHouseholdSweep, 1)
  expect_called(pe$sweep$InitialInfectedSweep, 1)
  expect_called(pe$sweep$InitialisePlaceSweep, 1)
  expect_called(pe$sweep$InitialDemographicsSweep, 1)
  expect_args(pe$sweep$InitialDemographicsSweep, 1, "dem.csv")

  expect_called(pe$sweep$UpdatePlaceSweep, 1)
  expect_called(pe$sweep$HouseholdSweep, 1)
  expect_called(pe$sweep$PlaceSweep, 1)
  expect_called(pe$sweep$SpatialSweep, 1)
  expect_called(pe$sweep$QueueSweep, 1)
  expect_called(pe$sweep$HostProgressionSweep, 1)

  expect_called(conf, 1)
  expect_called(runm, 1)
  expect_called(comp, 1)
})
