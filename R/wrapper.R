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
  return(pe$routine$FilePopulationFactory()$make_pop_from_file(epigeopop_file))
}

# Wrap python simulation function
run_simulation <- function(pe, sim_params, file_params, dem_file_params,
                           inf_history_params, pop_params = NULL,
                           epigeopop_file = "", seed = 42,
                           use_toy_example = FALSE) {
  # Set seed
  pe$routine$Simulation$set_random_seed(seed = as.integer(seed))
  # Create population or load from file
  if (epigeopop_file == "") {
    population <- create_toy_population(pe, pop_params)
  } else {
    population <- create_epigeopop_population(pe, epigeopop_file)
  }

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
