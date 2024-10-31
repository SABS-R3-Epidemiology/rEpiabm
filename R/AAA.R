local <- new.env()

.onAttach <- function(libname, pkgname) {
  if(!grepl(x = R.Version()$arch, pattern = "64")){
    warning("This package only works on 64bit architectures due to dependencies. You are not running a 64bit version of R.")
  }
}

.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)
  
  # Load required Python modules
  oldwd <- getwd()
  on.exit(setwd(oldwd))
  
  # Import core Python dependencies
  os <- reticulate::import("os", convert = TRUE, delay_load = TRUE)
  logging <- reticulate::import("logging", convert = TRUE, delay_load = TRUE)
  pd <- reticulate::import("pandas", convert = TRUE, delay_load = TRUE)
  plt <- reticulate::import("matplotlib.pyplot", convert = TRUE, delay_load = TRUE)
  pe <- reticulate::import("pyEpiabm", convert = TRUE, delay_load = TRUE)
  
  # Assign imported modules to parent environment
  assign("os", value = os, envir = parent.env(local))
  assign("logging", value = logging, envir = parent.env(local))
  assign("pd", value = pd, envir = parent.env(local))
  assign("plt", value = plt, envir = parent.env(local))
  assign("pe", value = pe, envir = parent.env(local))
  
  # Set up default parameters
  simulation_params <- list(
    pop_params = list(
      population_size = as.integer(100),
      cell_number = as.integer(2),
      microcell_number = as.integer(2),
      household_number = as.integer(5),
      place_number = as.integer(2)
    ),
    sim_params = list(
      simulation_start_time = as.integer(0),
      simulation_end_time = as.integer(60),
      initial_infected_number = as.integer(10),
      include_waning = TRUE
    )
  )
  
  assign("default_params", value = simulation_params, envir = parent.env(local))
}

#' @import reticulate
#' @import here
#' @import ggplot2
NULL