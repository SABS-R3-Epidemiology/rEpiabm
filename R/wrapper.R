library(reticulate)
library(here)
library(tidyr)
library(ggplot2)

#' Initialise the Python simulation environment
#'
#' @return The `pyEpiabm` Python module
initialize_simulation_env <- function() {
  source("R/zzz.R")
  initialize_python_env()
  check_python_env()
  
  os <- import("os", delay_load = TRUE)
  logging <- import("logging", delay_load = TRUE)
  pd <- import("pandas", delay_load = TRUE)
  plt <- import("matplotlib.pyplot", delay_load = TRUE)
  pe <- import("pyEpiabm", delay_load = TRUE)
  return(pe)
}

#' Configure simulation parameters
#'
#' @param pe The `pyEpiabm` module
#' @param input_dir Path to input directory
#' @param config_parameters Name of JSON config file
#'
#' @return The `pyEpiabm` module with parameters set
configure_parameters <- function(pe, input_dir, config_parameters) {
  pe$Parameters$set_file(here(input_dir, config_parameters))
  return(pe)
}

#' Create an Intervention sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `InterventionSweep` object
InterventionSweep <- function(pe) {
  return(pe$sweep$InterventionSweep())
}

#' Create a Place sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `PlaceSweep` object
PlaceSweep <- function(pe) {
  return(pe$sweep$PlaceSweep())
}

#' Create a Queue sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `QueueSweep` object
QueueSweep <- function(pe) {
  return(pe$sweep$QueueSweep())
}

#' Create a Spatial sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `SpatialSweep` object
SpatialSweep <- function(pe) {
  return(pe$sweep$SpatialSweep())
}

#' Create a Travel sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `TravelSweep` object
TravelSweep <- function(pe) {
  return(pe$sweep$TravelSweep())
}

#' Create an UpdatePlace sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `UpdatePlaceSweep` object
UpdatePlaceSweep <- function(pe) {
  return(pe$sweep$UpdatePlaceSweep())
}

#' Create a HostProgression sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `HostProgressionSweep` object
HostProgressionSweep <- function(pe) {
  return(pe$sweep$HostProgressionSweep())
}

#' Create a Household sweep object
#'
#' @param pe The `pyEpiabm` module
#' @return A new `HouseholdSweep` object
HouseholdSweep <- function(pe) {
  return(pe$sweep$HouseholdSweep())
}

#' Create an InitialDemographics sweep
#'
#' @param pe The `pyEpiabm` module
#' @param dem_file_params Demographic parameter file
#' @return A new `InitialDemographicsSweep` object
InitialDemographicsSweep <- function(pe, dem_file_params) {
  return(pe$sweep$InitialDemographicsSweep(dem_file_params))
}

#' Create an InitialHousehold sweep
#'
#' @param pe The `pyEpiabm` module
#' @return A new `InitialHouseholdSweep` object
InitialHouseholdSweep <- function(pe) {
  return(pe$sweep$InitialHouseholdSweep())
}

#' Create an InitialInfected sweep
#'
#' @param pe The `pyEpiabm` module
#' @return A new `InitialInfectedSweep` object
InitialInfectedSweep <- function(pe) {
  return(pe$sweep$InitialInfectedSweep())
}

#' Create an InitialisePlace sweep
#'
#' @param pe The `pyEpiabm` module
#' @return A new `InitialisePlaceSweep` object
InitialisePlaceSweep <- function(pe) {
  return(pe$sweep$InitialisePlaceSweep())
}

#' Create an InitialVaccineQueue sweep
#'
#' @param pe The `pyEpiabm` module
#' @return A new `InitialVaccineQueue` object
InitialVaccineQueue <- function(pe) {
  return(pe$sweep$InitialVaccineQueue())
}

#' Create a toy population
#'
#' @param pe The `pyEpiabm` module
#' @param pop_params Population parameters
#' @return The created population object
create_toy_population <- function(pe, pop_params) {
  return(pe$routine$ToyPopulationFactory()$make_pop(pop_params))
}

#' Create a population from epigeopop file
#'
#' @param pe The `pyEpiabm` module
#' @param epigeopop_file Path to epigeopop CSV file
#' @return The created population object
create_epigeopop_population <- function(pe, epigeopop_file) {
  return(pe$routine$FilePopulationFactory()$make_pop(epigeopop_file))
}

#' Run a full simulation
#'
#' @param pe The `pyEpiabm` module
#' @param sim_params Simulation parameters
#' @param file_params Output file parameters
#' @param inf_history_params Infection history parameters
#' @param population The population object
#' @param simulation_type Either "toy" or "epigeopop"
#' @param sweep_params Optional list of sweep flags for toy simulation
#' @param dem_file_params Demographic file parameters
#' @param seed Random seed
#'
#' @return A `Simulation` object after running
run_simulation <- function(pe, sim_params, file_params, inf_history_params, population,
                          simulation_type = "toy", sweep_params = NULL, dem_file_params = NULL, seed = 42) {
  
  pe$routine$Simulation$set_random_seed(seed = as.integer(seed))
  
  if (simulation_type == "toy") {
    default_sweeps <- list(InitialDemographicsSweep = FALSE)
    if (!is.null(sweep_params)) {
      for (name in names(sweep_params)) {
        if (name %in% names(default_sweeps)) {
          default_sweeps[[name]] <- sweep_params[[name]]
        } else {
          warning(paste("Sweep", name, "is not available for toy simulation"))
        }
      }
    }

    initial_sweeps <- list(
      InitialHouseholdSweep(pe),
      InitialInfectedSweep(pe)
    )

    if (default_sweeps$InitialDemographicsSweep) {
      if (is.null(dem_file_params)) {
        stop("dem_file_params is required when InitialDemographicsSweep = TRUE")
      }
      initial_sweeps <- append(initial_sweeps, InitialDemographicsSweep(pe, dem_file_params))
    }

    daily_sweeps <- list(
      HouseholdSweep(pe),
      QueueSweep(pe),
      HostProgressionSweep(pe)
    )
    
  } else if (simulation_type == "epigeopop") {
    initial_sweeps <- list(
      InitialHouseholdSweep(pe),
      InitialInfectedSweep(pe),
      InitialisePlaceSweep(pe),
      InitialDemographicsSweep(pe, dem_file_params)
    )

    daily_sweeps <- list(
      UpdatePlaceSweep(pe),
      HouseholdSweep(pe),
      PlaceSweep(pe),
      SpatialSweep(pe),
      QueueSweep(pe),
      HostProgressionSweep(pe)
    )
    
  } else {
    stop("simulation_type must be either 'toy' or 'epigeopop'")
  }

  sim <- pe$routine$Simulation()
  sim$configure(population, initial_sweeps, daily_sweeps, sim_params, file_params, inf_history_params)
  sim$run_sweeps()
  sim$compress_csv()
  return(sim)
}

#' Process simulation CSV output
#'
#' @param output_file Path to CSV output file
#'
#' @return A long-format data frame for plotting
process_simulation_data <- function(output_file) {
  df <- read.csv(here(output_file))
  status_columns <- c("InfectionStatus.Susceptible", "InfectionStatus.InfectMild",
                      "InfectionStatus.Recovered", "InfectionStatus.Dead")
  df_long <- pivot_longer(df, cols = all_of(status_columns), names_to = "Status", values_to = "Count")
  df_long$Status <- factor(df_long$Status, levels = status_columns,
                           labels = c("Susceptible", "Infected", "Recovered", "Dead"))
  return(df_long)
}

#' Create an SIR model plot
#'
#' @param df_long Data frame from `process_simulation_data`
#' @param title Title of the plot
#' @param display Logical; whether to print the plot
#'
#' @return A ggplot object
create_sir_plot <- function(df_long, title = "SIR Model Flow", display = TRUE) {
  p <- ggplot(df_long, aes(x = time, y = Count, color = Status)) +
    geom_line() +
    scale_color_manual(values = c("Susceptible" = "blue", "Infected" = "red", "Recovered" = "green", "Dead" = "black")) +
    theme_minimal() +
    labs(title = title, x = "Time", y = "Count") +
    theme(legend.position = "right", plot.title = element_text(hjust = 0.5), panel.grid.minor = element_blank())
  
  if (display) print(p)
  return(p)
}

#' Save an SIR plot
#'
#' @param plot A ggplot object
#' @param filename File path to save the plot
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Dots per inch for resolution
save_sir_plot <- function(plot, filename, width = 10, height = 6, dpi = 300) {
  ggsave(filename = here(filename), plot = plot, width = width, height = height, dpi = dpi)
}

#' Plot the R_t curve from CSV
#'
#' @param file_path Path to CSV file
#' @param location Save path for output plot
#'
#' @return A ggplot object for the R_t curve
plot_rt_curves <- function(file_path, location) {
  if (!file.exists(file_path)) stop("The file does not exist. Please provide a valid file path.")
  
  data <- tryCatch(read.csv(file_path), error = function(e) stop("Error reading the file. Ensure it's a valid CSV."))
  if (!all(c("time", "R_t") %in% colnames(data))) stop("The CSV file must contain 'time' and 'R_t' columns.")
  
  data <- na.omit(data[, c("time", "R_t")])
  
  gg <- ggplot(data, aes(x = time, y = R_t)) +
    geom_line(color = "blue", size = 1) +
    labs(title = "Reproduction Number (R_t) Over Time", x = "Time", y = "R_t") +
    theme_minimal()
  
  print(gg)
  print("R_t plot generated successfully.")
  
  save_sir_plot(gg, location)
  return(gg)
}

#' Create a serial interval distribution plot
#'
#' @param file_path Path to CSV file
#' @param title Plot title
#' @param display Logical; whether to print the plot
#' @param location Path to save the plot
#'
#' @return A ggplot histogram object
create_serial_interval_plot <- function(file_path, title = "Serial Interval Distribution", display = TRUE, location) {
  data <- read.csv(file_path, header = TRUE)[-1, ]
  data_1d <- na.omit(as.numeric(unlist(data)))

  p <- ggplot(data.frame(Value = data_1d), aes(x = Value)) +
    geom_histogram(binwidth = 1, fill = "skyblue", color = "black", alpha = 0.7) +
    theme_minimal() +
    labs(title = title, x = "Serial Interval (days)", y = "Frequency") +
    theme(plot.title = element_text(hjust = 0.5), panel.grid.minor = element_blank())
  
  if (display) print(p)
  save_sir_plot(p, location)
  return(p)
}
