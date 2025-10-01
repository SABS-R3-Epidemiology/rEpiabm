library(reticulate)
library(here)
library(tidyr)
library(ggplot2)

# Initialize Python environment
initialize_simulation_env <- function() {
  source("R/zzz.R")
  initialize_python_env()
  check_python_env()

  # Import Python dependencies
  os <- import("os", delay_load = TRUE)
  logging <- import("logging", delay_load = TRUE)
  pd <- import("pandas", delay_load = TRUE)
  plt <- import("matplotlib.pyplot", delay_load = TRUE)
  pe <- import("pyEpiabm", delay_load = TRUE)
  return(pe)
}

configure_parameters <- function(pe, input_dir, config_parameters) {
  pe$Parameters$set_file(here(input_dir, config_parameters))
  return(pe)
}

create_toy_population <- function(pe, pop_params) {
  return(pe$routine$ToyPopulationFactory()$make_pop(pop_params))
}

create_epigeopop_population <- function(pe, epigeopop_file) {
  return(pe$routine$FilePopulationFactory()$make_pop(epigeopop_file))
}

# Wrap python simulation function
run_simulation <- function(pe, sim_params, file_params, dem_file_params, population, inf_history_params, seed = 42) {
  # Set seed
  pe$routine$Simulation$set_random_seed(seed = as.integer(seed))

  # Create and configure simulation
  sim <- pe$routine$Simulation()
  sim$configure(
    population,
    list(
      pe$sweep$InitialInfectedSweep(),
      pe$sweep$InitialDemographicsSweep(dem_file_params)
    ),
    list(
      pe$sweep$HouseholdSweep(),
      pe$sweep$QueueSweep(),
      pe$sweep$HostProgressionSweep()
    ),
    sim_params,
    file_params,
    inf_history_params
  )

  # Run simulation
  sim$run_sweeps()
  sim$compress_csv()

  return(sim)
}

# Wrap python simulation function
run_geopop_sim <- function(pe, sim_params, file_params, dem_file_params, population, inf_history_params, seed = 42) {
  # Set seed
  pe$routine$Simulation$set_random_seed(seed = as.integer(seed))

  # Create and configure simulation
  sim <- pe$routine$Simulation()
  sim$configure(
    population,
    list(
      pe$sweep$InitialHouseholdSweep(),
      pe$sweep$InitialInfectedSweep(),
      pe$sweep$InitialisePlaceSweep(),
      pe$sweep$InitialDemographicsSweep(dem_file_params)
    ),
    list(
      pe$sweep$UpdatePlaceSweep(),
      pe$sweep$HouseholdSweep(),
      pe$sweep$PlaceSweep(),
      pe$sweep$SpatialSweep(),
      pe$sweep$QueueSweep(),
      pe$sweep$HostProgressionSweep()
    ),
    sim_params,
    file_params,
    inf_history_params
  )

  # Run simulation
  sim$run_sweeps()
  sim$compress_csv()

  return(sim)
}

# Process simulation data
process_simulation_data <- function(output_file) {
  df <- read.csv(here(output_file))

  status_columns <- c(
    "InfectionStatus.Susceptible",
    "InfectionStatus.InfectMild",
    "InfectionStatus.Recovered",
    "InfectionStatus.Dead"
  )
  df_long <- pivot_longer(
    df,
    cols = all_of(status_columns),
    names_to = "Status",
    values_to = "Count"
  )
  df_long$Status <- factor(
    df_long$Status,
    levels = status_columns,
    labels = c("Susceptible", "Infected", "Recovered", "Dead")
  )

  return(df_long)
}

# Create SIR plot
create_sir_plot <- function(df_long, title = "SIR Model Flow", display = TRUE) {
  p <- ggplot(df_long, aes(x = time, y = Count, color = Status)) +
    geom_line() +
    scale_color_manual(
      values = c(
        "Susceptible" = "blue",
        "Infected" = "red",
        "Recovered" = "green",
        "Dead" = "black"
      )
    ) +
    theme_minimal() +
    labs(
      title = title,
      x = "Time",
      y = "Count"
    ) +
    theme(
      legend.position = "right",
      plot.title = element_text(hjust = 0.5),
      panel.grid.minor = element_blank()
    )

  if (display) {
    print(p)
  }

  return(p)
}

# Save plot

save_sir_plot <- function(plot, filename, width = 10, height = 6, dpi = 300) {
  ggsave(
    filename = here(filename),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
}

plot_rt_curves <- function(file_path, location) {
  # Check if file exists
  if (!file.exists(file_path)) {
    stop("The file does not exist. Please provide a valid file path.")
  }

  # Read the CSV file
  data <- tryCatch({
    read.csv(file_path)
  }, error = function(e) {
    stop("Error reading the file. Ensure it's a valid CSV.")
  })

  # Filter for "time" and "R_t" columns
  if (!all(c("time", "R_t") %in% colnames(data))) {
    stop("The CSV file must contain 'time' and 'R_t' columns.")
  }
  data <- data[, c("time", "R_t")]

  # Remove rows with NaN values
  data <- na.omit(data)

  # Create the ggplot
  gg <- ggplot(data, aes(x = time, y = R_t)) +
    geom_line(color = "blue", size = 1) +
    labs(
      title = "Reproduction Number (R_t) Over Time",
      x = "Time",
      y = "R_t"
    ) +
    theme_minimal()

  # Print the plot
  print(gg)
  print("R_t plot generated successfully.")

  # Save the plot
  save_sir_plot(gg, location)

  return(gg)
}

# Create serial interval plot
create_serial_interval_plot <- function(file_path, title = "Serial Interval Distribution", display = TRUE, location) {
  # Read the CSV file and exclude the first row
  data <- read.csv(file_path, header = TRUE)[-1, ]
  
  # Convert the data to a 1D array
  data_1d <- as.numeric(unlist(data))
  
  # Remove NaNs
  data_1d <- na.omit(data_1d)
  
  # Create the histogram plot
  p <- ggplot(data.frame(Value = data_1d), aes(x = Value)) +
    geom_histogram(binwidth = 1, fill = "skyblue", color = "black", alpha = 0.7) +
    theme_minimal() +
    labs(
      title = title,
      x = "Serial Interval (days)",
      y = "Frequency"
    ) +
    theme(
      plot.title = element_text(hjust = 0.5),
      panel.grid.minor = element_blank()
    )

  if (display) {
    print(p)
  }

  # Save the plot
  save_sir_plot(p, location)

  return(p)
}
