library(reticulate)
library(here)
library(tidyr)
library(ggplot2)

#' Initialise the Python simulation environment
#'
#' @return The `pyEpiabm` Python module
initialize_simulation_env <- function(
  source_fn = base::source,
  import_fn = reticulate::import,
  init_fn   = initialize_python_env,
  check_fn  = check_python_env
) {
  source_fn("R/zzz.R")
  init_fn(force=FALSE)
  check_fn()

  import_fn("os", delay_load = TRUE)
  import_fn("logging", delay_load = TRUE)
  import_fn("pandas", delay_load = TRUE)
  import_fn("matplotlib.pyplot", delay_load = TRUE)
  pe <- import_fn("pyEpiabm", delay_load = TRUE)
  pe
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

#' Enhanced data processing function to ensure proper data types
#'
#' @param output_file Path to CSV output file
#'
#' @return A long-format data frame for plotting
process_simulation_data <- function(output_file) {
  df <- read.csv(here(output_file), stringsAsFactors = FALSE)
  
  # Define status columns
  status_columns <- c("InfectionStatus.Susceptible", "InfectionStatus.InfectMild",
                      "InfectionStatus.Recovered", "InfectionStatus.Dead")
  
  # Ensure time column is numeric
  if ("time" %in% colnames(df)) {
    df$time <- as.numeric(df$time)
  }
  
  # Convert status columns to numeric
  df[status_columns] <- lapply(df[status_columns], function(x) as.numeric(as.character(x)))
  
  # Create long format
  df_long <- pivot_longer(df, 
                         cols = all_of(status_columns), 
                         names_to = "Status", 
                         values_to = "Count")
  
  # Clean up status labels
  df_long$Status <- factor(df_long$Status, 
                          levels = status_columns,
                          labels = c("Susceptible", "Infected", "Recovered", "Dead"))
  
  # Remove any rows with missing values
  df_long <- df_long[complete.cases(df_long), ]
  
  return(df_long)
}

#' Create an SIR model plot (Fixed version with aggregation)
#'
#' @param df_long Data frame from `process_simulation_data`
#' @param title Title of the plot
#' @param display Logical; whether to print the plot
#'
#' @return A ggplot object
create_sir_plot <- function(df_long, title = "SIR Model Flow", display = TRUE) {
  # Ensure both time and Count are properly numeric
  df_long$time <- as.numeric(as.character(df_long$time))
  df_long$Count <- as.numeric(as.character(df_long$Count))
  
  # Remove any rows with NA values
  df_long <- df_long[complete.cases(df_long), ]
  
  # **Add aggregation step using base R - group by time and Status, sum the counts**
  df_long <- aggregate(Count ~ time + Status, data = df_long, FUN = sum, na.rm = TRUE)
  
  # Create the plot with explicit continuous scale for x-axis
  p <- ggplot(df_long, aes(x = time, y = Count, color = Status)) +
    geom_line(size = 1.2) +  # Removed the incorrect group = Count
    scale_x_continuous(name = "Time") +  # Explicitly set continuous scale
    scale_y_continuous(name = "Count") +
    scale_color_manual(values = c("Susceptible" = "blue", 
                                  "Infected" = "red", 
                                  "Recovered" = "green", 
                                  "Dead" = "black")) +
    theme_minimal() +
    labs(title = title, x = "Time", y = "Count") +
    theme(legend.position = "right", 
          plot.title = element_text(hjust = 0.5), 
          panel.grid.minor = element_blank(),
          legend.title = element_blank())  # Remove legend title for cleaner look
  
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
save_plot <- function(plot, filename, width = 10, height = 6, dpi = 300) {
  ggsave(filename = here(filename), plot = plot, width = width, height = height, dpi = dpi, )
}

#' Plot the R_t curve from CSV
#'
#' @param file_path Path to CSV file
#' @param location Save path for output plot
#'
#' @return A ggplot object for the R_t curve
plot_rt_curves <- function(file_path, location, max_points = 5000L) {
  stopifnot(file.exists(file_path))

  # 1) Read just the columns we need using base R
  #    (read header once to build a colClasses vector)
  hdr <- read.csv(file_path, nrows = 1, check.names = FALSE)
  cols <- names(hdr)
  if (!all(c("time", "R_t") %in% cols)) {
    stop("The CSV file must contain 'time' and 'R_t' columns (exact names).")
  }
  cc <- ifelse(cols %in% c("time", "R_t"), "numeric", "NULL")

  df <- read.csv(
    file_path,
    colClasses = cc,
    check.names = FALSE
  )
  # keep only finite, ordered rows
  df <- df[is.finite(df$time) & is.finite(df$R_t), , drop = FALSE]
  df <- df[order(df$time), , drop = FALSE]

  # 2) Optional light downsampling for huge files (native base R)
  n <- nrow(df)
  if (n > max_points) {
    idx <- unique(round(seq(1, n, length.out = max_points)))
    df <- df[idx, , drop = FALSE]
  }

  # 3) Plot with subscripted label and save as PNG
  gg <- ggplot(df, aes(x = time, y = R_t)) +
    geom_line(linewidth = 0.8) +
    labs(
      title = "Reproduction Number (R_t) Over Time",
      x = "Time",
      y = expression(R[t])   # <-- subscript t
    ) +
    theme_minimal()

  ggsave(filename = location, plot = gg, device = "png")
  gg
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
  save_plot(p, location)
  return(p)
}
