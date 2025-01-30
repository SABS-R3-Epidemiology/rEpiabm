source("R/wrapper.R")
# Example usage:
# Run complete simulation
run_complete_simulation <- function(output_dir="data/simulation_outputs",
                                    output_file = "output.csv",
                                    sir_plot_file = "SIR_plot.png",
                                    rt_plot_file = "Rt_plot.png",
                                    si_plot_file = "SerialInterval_plot.png",
                                    simulation_duration = 60,
                                    initial_infected = 100) {
  # Initialize environment
  pe <- initialize_simulation_env()

  # User-defined variables
  input_dir <- "data/Andorra/inputs"
  config_parameters <- "data/Andorra_parameters.json"
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
    initial_infect_cell = FALSE,
    include_waning = TRUE
  )

  file_params <- list(
    output_file = output_file,
    output_dir = output_dir,
    spatial_output = TRUE,
    age_stratified = TRUE
  )

  dem_file_params <- list(
    output_dir = output_dir,
    spatial_output = TRUE,
    age_output = TRUE
  )

  inf_history_params <- list(
    output_dir = output_dir,
    status_output = TRUE,
    infectiousness_output = TRUE,
    compress = FALSE,
    secondary_infections_output = TRUE,
    generation_time_output = TRUE,
    serial_interval_output = TRUE
  )

  # Use Andorra population data
  population <- create_epigeopop_population(pe, "data/Andorra/inputs/Andorra_microcells.csv")

  # Run simulation
  sim <- run_geopop_sim(pe, sim_params, file_params, dem_file_params, population, inf_history_params, seed)

  # Process data
  df_long <- process_simulation_data(file.path(output_dir, output_file))

  print(colnames(df_long))
  print(df_long)

  # Generate SIR plot
  sir_plot <- create_sir_plot(df_long, display = TRUE)
  save_sir_plot(sir_plot, file.path(output_dir, sir_plot_file))


  plot_rt_curves("data/simulation_outputs/secondary_infections.csv")

  create_serial_interval_plot("data/simulation_outputs/serial_intervals.csv", display = TRUE)
  
  return(list(simulation = sim, data = df_long, sir_plot = sir_plot, rt_plot = "", si_plot = ""))
}

results <- run_complete_simulation()