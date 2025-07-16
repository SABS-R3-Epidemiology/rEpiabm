library(readr)
library(dplyr)
library(pracma)

# Read the R_estimates_np.csv file
r_estimates_path <- "data/Andorra/simulation_outputs/R_estimates_np.csv"
r_estimates_df <- read_csv(r_estimates_path)

# Create a new column 't' corresponding to the range 5 to 57.
# The length of the sequence should match the number of rows in r_estimates_df
num_rows_r_estimates <- nrow(r_estimates_df)
t_values <- seq(from = 5, by = 1, length.out = num_rows_r_estimates)

r_estimates_df$t <- t_values

# Filter for the specified columns
filtered_r_df <- r_estimates_df %>%
  select(t, `Mean(R)`, `Quantile.0.025(R)`, `Quantile.0.975(R)`)

# Display first few rows of the filtered dataframe
print("Filtered R_estimates dataframe (first 6 rows):")
print(head(filtered_r_df))
print(paste("Number of rows in filtered_r_df:", nrow(filtered_r_df)))

# Read the secondary_infections.csv file
secondary_infections_path <- "data/Andorra/simulation_outputs/secondary_infections.csv"
secondary_infections_df <- read_csv(secondary_infections_path)

# Filter for "time" and "R_t" columns and filter time
filtered_secondary_df <- secondary_infections_df %>%
  select(time, R_t) %>%
  filter(time >= 5 & time <= 53)
print("Filtered secondary infections data:")
print(head(filtered_secondary_df))

# Drop the 'time' column
  filtered_secondary_df <- filtered_secondary_df %>%
    select(-time)
  print("The 'time' column has been dropped.")

# Display the first few rows of this filtered dataframe
print("Filtered secondary_infections dataframe (first 6 rows):")
print(head(filtered_secondary_df))
print(paste("Number of rows in filtered_secondary_df:", nrow(filtered_secondary_df)))


# --- Define and Apply Function Rt_inst_to_Rt_case ---

Rt_inst_to_Rt_case <- function(Rt_inst, f, t_start, t_end) {
  #' Converts instantaneous reproduction number to the case reproduction number
  #' at time t, given a generation time/serial interval distribution, f.
  #' This is because Epiestim outputs instantaneous R and Epiabm uses case R

  Rt_case <- c()
  dx <- 1 # Daily time steps

  for (t in 0:(t_end - t_start - 1)) {
    # Extract the relevant portions of Rt_inst and f
    Rt_subset <- Rt_inst[(t + 1):length(Rt_inst)]
    f_subset <- f[1:(t_end - t_start - t)]

    # Ensure vectors are same length (take minimum length)
    min_len <- min(length(Rt_subset), length(f_subset))
    if (min_len > 0) {
      Rt_subset <- Rt_subset[1:min_len]
      f_subset <- f_subset[1:min_len]
      print("Rt_subset and f_subset data examples")
      print(head(Rt_subset))
      print(head(f_subset))
      # Create x values for integration
      x_vals <- seq(t + t_start, by = 1.0, length.out = min_len)
      print("x_vals first 5 values")
      print(head(x_vals))
      # Calculate integrand
      print("x_vals first 5 values")
      integrand <- Rt_subset * f_subset
      print(head(integrand))
      # Perform Simpson's rule integration
      if (length(integrand) >= 3) {
        Rt_case_t <- pracma::trapz(x_vals, integrand)
      } else if (length(integrand) == 2) {
        # Use trapezoidal rule for 2 points
        Rt_case_t <- pracma::trapz(x_vals, integrand)
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


# Rt_inst: This will be the 'R_t' column from filtered_secondary_df
rt_instantaneous <- filtered_secondary_df$R_t

# f: Generation time distribution
# Read the generation_times.csv file
generation_times_path <- "data/Andorra/simulation_outputs/generation_times.csv"
f_distribution <- read_csv(generation_times_path)


# Call the function
rt_case_values <- Rt_inst_to_Rt_case(
  Rt_inst = rt_instantaneous,
  f = f_distribution,
  t_start = 2,
  t_end = 60
)

print("Calculated Rt_case values (first 10):")
print(head(rt_case_values, 10))

if (length(rt_case_values) > 0) {
  case_times <- seq(from = t_start_val, length.out = length(rt_case_values))
  results_df <- data.frame(
    time = case_times,
    Rt_case = rt_case_values
  )
  print("First few rows of results_df with Rt_case:")
  print(head(results_df))
} else {
  print("Rt_case_values vector is empty. No results to show or save.")
}

# --- Part 4: Plotting R_t Curves ---
print("Preparing data for plotting R_t curves...")

if (nrow(filtered_r_df) > 0 && nrow(results_df) > 0) {
  # Data for instantaneous R (from R_estimates_np.csv)
  plot_data_inst <- filtered_r_df %>%
    dplyr::rename(
      time = t,
      Rt_mean = `Mean(R)`,
      Rt_lower = `Quantile.0.025(R)`,
      Rt_upper = `Quantile.0.975(R)`
    ) %>%
    dplyr::select(time, Rt_mean, Rt_lower, Rt_upper)

  # Data for case R (converted from secondary_infections.csv)
  plot_data_case <- results_df %>%
    dplyr::rename(Rt_mean = Rt_case) %>%
    dplyr::select(time, Rt_mean)

  print("Plotting R_t curves using ggplot2...")
  rt_plot <- ggplot2::ggplot() +
    # Plot for Instantaneous R (Mean and CI)
    ggplot2::geom_line(data = plot_data_inst, 
                       aes(x = time, y = Rt_mean, color = "Mean Instantaneous R (EpiEstim)"), 
                       linewidth = 1) +
    ggplot2::geom_ribbon(data = plot_data_inst, 
                         aes(x = time, ymin = Rt_lower, ymax = Rt_upper, fill = "95% CI Instantaneous R"), 
                         alpha = 0.3) +
    # Plot for Case R (Converted)
    ggplot2::geom_line(data = plot_data_case, 
                       aes(x = time, y = Rt_mean, color = "Case R (Converted)"), 
                       linewidth = 1, linetype="dashed") + # Added linetype for better distinction
    
    ggplot2::labs(
      title = "Comparison of Reproduction Numbers (R_t) Over Time",
      x = "Time",
      y = "R_t Value",
      color = "R_t Series", # Legend title for color aesthetic
      fill = "Confidence Interval" # Legend title for fill aesthetic
    ) +
    ggplot2::scale_color_manual(
      values = c("Mean Instantaneous R (EpiEstim)" = "dodgerblue", "Case R (Converted)" = "firebrick")
    ) +
    ggplot2::scale_fill_manual(
      values = c("95% CI Instantaneous R" = "skyblue")
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(legend.position = "top", legend.box = "vertical")

  # Print the plot to the R graphics device
  print(rt_plot)

  # Save the plot
  plot_filename <- "Rt_comparison_plot.png"
  ggplot2::ggsave(plot_filename, plot = rt_plot, width = 10, height = 7, dpi = 300)
  print(paste("R_t comparison plot saved as", plot_filename))

} else {
  print("Skipping plotting: Not enough data. 'filtered_r_df' or 'results_df' is empty.")
  if(nrow(filtered_r_df) == 0) print("Reason: filtered_r_df (from R_estimates_np) has no rows or relevant data.")
  if(nrow(results_df) == 0) print("Reason: results_df (from Rt_case calculation) has no rows.")
}
