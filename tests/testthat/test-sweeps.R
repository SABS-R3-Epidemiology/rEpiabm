library(testthat)
library(mockery)
# library(rEpiabm)

test_that("sweep constructors delegate to pe$sweep", {
  pe <- list(sweep = list(
    InterventionSweep        = mock("Intervention"),
    PlaceSweep               = mock("Place"),
    QueueSweep               = mock("Queue"),
    SpatialSweep             = mock("Spatial"),
    TravelSweep              = mock("Travel"),
    UpdatePlaceSweep         = mock("UpdatePlace"),
    HostProgressionSweep     = mock("HostProgression"),
    HouseholdSweep           = mock("Household"),
    InitialDemographicsSweep = mock("InitDemo"),
    InitialHouseholdSweep    = mock("InitHH"),
    InitialInfectedSweep     = mock("InitInfected"),
    InitialisePlaceSweep     = mock("InitPlace"),
    InitialVaccineQueue      = mock("InitVax")
  ))

  expect_identical(InterventionSweep(pe), "Intervention")
  expect_called(pe$sweep$InterventionSweep, 1)

  expect_identical(PlaceSweep(pe), "Place")
  expect_called(pe$sweep$PlaceSweep, 1)

  expect_identical(QueueSweep(pe), "Queue")
  expect_called(pe$sweep$QueueSweep, 1)

  expect_identical(SpatialSweep(pe), "Spatial")
  expect_called(pe$sweep$SpatialSweep, 1)

  expect_identical(TravelSweep(pe), "Travel")
  expect_called(pe$sweep$TravelSweep, 1)

  expect_identical(UpdatePlaceSweep(pe), "UpdatePlace")
  expect_called(pe$sweep$UpdatePlaceSweep, 1)

  expect_identical(HostProgressionSweep(pe), "HostProgression")
  expect_called(pe$sweep$HostProgressionSweep, 1)

  expect_identical(HouseholdSweep(pe), "Household")
  expect_called(pe$sweep$HouseholdSweep, 1)

  expect_identical(InitialHouseholdSweep(pe), "InitHH")
  expect_called(pe$sweep$InitialHouseholdSweep, 1)

  expect_identical(InitialInfectedSweep(pe), "InitInfected")
  expect_called(pe$sweep$InitialInfectedSweep, 1)

  expect_identical(InitialisePlaceSweep(pe), "InitPlace")
  expect_called(pe$sweep$InitialisePlaceSweep, 1)

  expect_identical(InitialVaccineQueue(pe), "InitVax")
  expect_called(pe$sweep$InitialVaccineQueue, 1)

  # With arg
  expect_identical(InitialDemographicsSweep(pe, "dem.csv"), "InitDemo")
  expect_called(pe$sweep$InitialDemographicsSweep, 1)
  expect_args(pe$sweep$InitialDemographicsSweep, 1, "dem.csv")
})
