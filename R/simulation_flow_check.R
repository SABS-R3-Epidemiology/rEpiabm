library(reticulate)
library(here)
library(tidyr)
library(ggplot2)

# Initialize Python environment
initialize_simulation_env <- function(parameter_file= "simple_parameters.json") {
  source("R/zzz.R")
  initialize_python_env()
  check_python_env()
  
  # Import Python dependencies
  os <- import("os", delay_load = TRUE)
  logging <- import("logging", delay_load = TRUE)
  pd <- import("pandas", delay_load = TRUE)
  plt <- import("matplotlib.pyplot", delay_load = TRUE)
  pe <- import("pyEpiabm", delay_load = TRUE)

  pe$Parameters$set_file(here("data", parameter_file))
  
  return(pe)
}


# Run simulation
run_simulation <- function(pe, pop_params, sim_params, file_params, 
                         dem_file_params, inf_history_params, seed = 42) {
  # Set seed
  pe$routine$Simulation$set_random_seed(seed = as.integer(seed))
  
  # Create population
  population <- pe$routine$ToyPopulationFactory()$make_pop(pop_params)
  
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
    
  if(display) {
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

# Example usage:
run_complete_simulation <- function(output_dir = "simulation_outputs",
                                  output_file = "output.csv",
                                  plot_file = "simulation_flow_SIR_plot.png") {
  # Initialize environment
  pe <- initialize_simulation_env()
  
  # Create all parameter sets
  # Create all parameter sets
  pop_params <- list(
    population_size = as.integer(100),
    cell_number = as.integer(2),
    microcell_number = as.integer(2),
    household_number = as.integer(5),
    place_number = as.integer(2)
  )
  
  sim_params <- list(
    simulation_start_time = as.integer(0),
    simulation_end_time = as.integer(60),
    initial_infected_number = as.integer(10),
    include_waning = TRUE
  )
  
  file_params <- list(
    output_file = "output.csv",
    output_dir = here("simulation_outputs"),
    spatial_output = FALSE,
    age_stratified = FALSE
  )
  
  dem_file_params <- list(
    output_dir = here("simulation_outputs"),
    spatial_output = FALSE,
    age_output = FALSE
  )

  inf_history_params <- list(
    output_dir = here("simulation_outputs"),
    status_output = TRUE,
    infectiousness_output = TRUE,
    compress = FALSE
  )

  
  # Run simulation
  sim <- run_simulation(pe, pop_params, sim_params, file_params, 
                       dem_file_params, inf_history_params)
  
  # Process data and create plot
  df_long <- process_simulation_data(file.path(output_dir, output_file))
  plot <- create_sir_plot(df_long)
  
  # Save plot
  save_sir_plot(plot, file.path(output_dir, plot_file))
  
  return(list(simulation = sim, data = df_long, plot = plot))
}

results <- run_complete_simulation()