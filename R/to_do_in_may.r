Rt_inst_to_Rt_case <- function(Rt_inst, f, t_start, t_end) {
  #' Converts instantaneous reproduction number to the case reproduction number
  #' at time t, given a generation time/serial interval distribution, f.
  #' This is because Epiestim outputs instantaneous R and Epiabm uses case R
  #'
  #' @param Rt_inst Vector of instantaneous reproduction numbers
  #' @param f Vector representing generation time/serial interval distribution
  #' @param t_start Start time
  #' @param t_end End time
  #' @return Vector of case reproduction numbers

  # Load required library for numerical integration
  library(pracma)  # For simpson integration

  Rt_case <- c()
  dx <- 1

  for (t in 0:(t_end - t_start - 1)) {
    # Extract the relevant portions of Rt_inst and f
    Rt_subset <- Rt_inst[(t + 1):length(Rt_inst)]
    f_subset <- f[1:(t_end - t_start - t)]

    # Ensure vectors are same length (take minimum length)
    min_len <- min(length(Rt_subset), length(f_subset))
    if (min_len > 0) {
      Rt_subset <- Rt_subset[1:min_len]
      f_subset <- f_subset[1:min_len]

      # Create x values for integration
      x_vals <- seq(t + t_start, by = 1.0, length.out = min_len)

      # Calculate integrand
      integrand <- Rt_subset * f_subset

      # Perform Simpson's rule integration
      if (length(integrand) >= 3) {
        Rt_case_t <- simpson(x_vals, integrand)
      } else if (length(integrand) == 2) {
        # Use trapezoidal rule for 2 points
        Rt_case_t <- trapz(x_vals, integrand)
      } else if (length(integrand) == 1) {
        # Single point
        Rt_case_t <- integrand[1] * dx
      } else {
        Rt_case_t <- 0
      }
    } else {
      Rt_case_t <- 0
    }

    Rt_case <- c(Rt_case, Rt_case_t)
  }

  return(Rt_case)
}

# Main execution

# Load the saved data
epiestim_np_data <- readRDS("data/Andorra/simulation_outputs/R_extimates_np")

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
# Get R_estimate data
incidence_data <- calculate_susceptible_differences(
  file.path(output_dir, "output.csv"), 
  display = TRUE
)

# Get generation time distribution data
si_data <- create_gen_time_array(
  file.path(output_dir, "generation_times.csv"), 
  display = TRUE
)

# Combine and save data for EpiEstim
epiestim_data <- prepare_epiestim_data(
  incidence_data, 
  si_data, 
  file.path(output_dir, "epiestim_data.rds")
)



# Run EpiEstim
res_parametric_si <- estimate_R(
  incid = epiestim_data$incidence,
  method = "parametric_si",
  config = make_config(
    list(
      mean_si = epiestim_data$si_mean,
      std_si = epiestim_data$si_sd
    )
  )
)



# Need to run and produce plots to compare
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
      title = "Reproduction Case Number (R_t) Over Time",
      x = "Time",
      y = "R_t"
    ) +
    theme_minimal()

  # Print the plot
  print(gg)
  print("R_t plot generated successfully.")

  # Save the plot
  save_sir_plot(gg, "data/simulation_outputs/rt_comparison.png")

  return(gg)
}