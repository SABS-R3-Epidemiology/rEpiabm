library(testthat)

mock_check_python_env <- function() {
  
}

mock_file_exists <- function(file) {
  return(TRUE)
}

mock_geom_histogram <- function(...) {
  return(NULL)
}

mock_geom_line <- function(...) {
  return(NULL)
}

mock_ggplot <- function(...) {
  return(NULL)
}

mock_ggsave <- function(filename, plot, width, height, dpi) {
  return(NULL)
}

mock_import <- function(module, delay_load = TRUE) {
  return(NULL)
}

mock_initialize_python_env <- function() {}

mock_labs <- function(...) {
  return(NULL)
}

mock_pe_Parameters_set_file <- function(file) {}

mock_pe_routine_FilePopulationFactory_make_pop <- function(file) {
  return(NULL)
}

mock_pe_routine_Simulation <- function() {
  return(list(
    configure = function(...) {},
    run_sweeps = function() {},
    compress_csv = function() {}
  ))
}

mock_pe_routine_Simulation_set_random_seed <- function(seed) {}

mock_pe_routine_ToyPopulationFactory_make_pop <- function(params) {
  return(NULL)
}

mock_pivot_longer <- function(df, cols, names_to, values_to) {
  return(df)  # Return unchanged for simplicity
}

mock_print <- function(...) {
  return(NULL)
}

mock_read_csv <- function(file) {
  return(data.frame())  # Return an empty data frame
}

mock_scale_color_manual <- function(...) {
  return(NULL)
}

mock_stop <- function(message) {
  return(NULL)
}

mock_theme_minimal <- function(...) {
  return(NULL)
}

mock_tryCatch <- function(expr, error) {
  return(NULL)
}