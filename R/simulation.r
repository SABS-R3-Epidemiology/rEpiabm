source("R/wrapper.R")
# Example usage:
run_complete_simulation <- function(output_dir="data/simulation_outputs",
                                    output_file = "output.csv",
                                    plot_file = "SIR_plot.png",
                                    use_toy_example = TRUE,
                                    simulation_duration = 60,
                                    initial_infected = 10) {
  # Initialize environment
  pe <- initialize_simulation_env()

  # User defined variables - see README for instructions
  input_dir <- ""
  config_parameters <- "data/simple_parameters.json"
  seed <- 42

  pe <- configure_parameters(pe, input_dir, config_parameters)

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
    simulation_end_time = as.integer(simulation_duration),
    simulation_seed = TRUE,
    initial_infected_number = as.integer(initial_infected),
    initial_infect_cell = TRUE,
    include_waning = TRUE
  )

  file_params <- list(
    output_file = output_file,
    output_dir = output_dir,
    spatial_output = FALSE,
    age_stratified = FALSE
  )

  dem_file_params <- list(
    output_dir = output_dir,
    spatial_output = FALSE,
    age_output = FALSE
  )

  inf_history_params <- list(
    output_dir = output_dir,
    status_output = TRUE,
    infectiousness_output = TRUE,
    compress = FALSE,
    secondary_infections_output = TRUE,
    generation_time_output = TRUE
  )

  # Create population
  population <- if (use_toy_example) {
    create_toy_population(pe, pop_params)
  } else {
    epigeopop_file <- "data/epigeopop.csv"  # Example path for epigeopop file
    create_epigeopop_population(pe, epigeopop_file)
  }

  # Run simulation
  sim <- run_simulation(pe, sim_params, file_params, dem_file_params, population, inf_history_params, seed)

  # Process data and create plot
  df_long <- process_simulation_data(file.path(output_dir, output_file))
  plot <- create_sir_plot(df_long)

  # Save plot
  save_sir_plot(plot, file.path(output_dir, plot_file))

  return(list(simulation = sim, data = df_long, plot = plot))
}

results <- run_complete_simulation()