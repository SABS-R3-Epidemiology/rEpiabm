source("R/wrapper.R")
# Example usage:
# Run complete simulation
run_complete_simulation <- function(country="Andorra",
                                    output_file = "output.csv",
                                    sir_plot_file = "SIR_plot.png",
                                    rt_plot_file = "Rt_plot.png",
                                    si_plot_file = "SerialInterval_plot.png",
                                    simulation_duration = 60,
                                    initial_infected = 4) { 
  output_dir <- paste0("data/", country, "/simulation_outputs")

  # Initialize environment
  pe <- initialize_simulation_env()

  # User-defined variables
  input_dir <- paste0("data/", country, "/inputs")
  config_parameters <- paste0("data/", country, "_parameters.json")
  seed <- 42

  pe <- configure_parameters(pe, input_dir, config_parameters)

  sim_params <- list(
    simulation_start_time = as.integer(0),
    simulation_end_time = as.integer(simulation_duration),
    simulation_seed = TRUE,
    initial_infected_number = as.integer(initial_infected),
    initial_infect_cell = FALSE,
    include_waning = FALSE
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
  population <- create_epigeopop_population(pe, 
  paste0("data/", country, "/inputs/", country, 
  "_microcells.csv"))

  # Run simulation
  sim <- run_geopop_sim(pe, sim_params, 
  file_params, dem_file_params, population, 
  inf_history_params, seed)

  # Process data
  df_long <- process_simulation_data(file.path(output_dir, output_file))

  print(colnames(df_long))
  print(df_long)

  # Generate SIR plot
  sir_plot <- create_sir_plot(df_long, display = TRUE)
  save_sir_plot(sir_plot, file.path(output_dir, sir_plot_file))

  # Generate Rt plot
  rt_plot <- plot_rt_curves(file.path(output_dir, "secondary_infections.csv"), 
  location = file.path(output_dir, rt_plot_file))

  # Generate Serial Interval plot
  si_plot <- create_serial_interval_plot(file.path(output_dir, 
  "serial_intervals.csv"), display = TRUE, 
  location = file.path(output_dir, si_plot_file))
  
  return(list(simulation = sim, data = df_long, 
  sir_plot = sir_plot, rt_plot = rt_plot, si_plot = si_plot))
}

results <- run_complete_simulation()