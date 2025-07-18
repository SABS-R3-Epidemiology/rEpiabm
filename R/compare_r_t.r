library(dplyr)
library(pracma)
library(readr)
library(ggplot2)
library(zoo)

epiestim_dir <- "data/toy/simulation_outputs/epiestim"
epiabm_dir <- "data/toy/simulation_outputs"

# Read the R_estimates_np.csv file
r_estimates_df <- read_csv(file.path(epiestim_dir, "R_estimates_np.csv"),
                           show_col_types = FALSE)

# Create a new column 't' corresponding to the range 8 to 60.
# The length of the sequence should match the number of rows in r_estimates_df
num_rows_r_estimates <- nrow(r_estimates_df)
t_values <- seq(from = 8, by = 1, length.out = num_rows_r_estimates)

r_estimates_df$t <- t_values

# Filter for the specified columns
filtered_r_df <- r_estimates_df %>%
  select(t, `Mean(R)`, `Quantile.0.025(R)`, `Quantile.0.975(R)`)

# Display first few rows of the filtered dataframe
cat("Filtered R_estimates dataframe (first 6 rows):")
print(head(filtered_r_df))
print(paste("Number of rows in filtered_r_df:", nrow(filtered_r_df)))

# Read the secondary_infections.csv file
secondary_infections_df <- read_csv(file.path(epiabm_dir,
                                              "secondary_infections.csv"),
                                    show_col_types = FALSE)

# Filter for "time" and "R_t" columns and filter time
filtered_secondary_df <- secondary_infections_df %>%
  select(time, R_t) %>%
  filter(time >= 8 & time <= 60)
cat("\nFiltered secondary infections data:")
print(head(filtered_secondary_df))
print(paste("Number of rows in filtered_secondary_df:",
            nrow(filtered_secondary_df)))

# Linearly interpolate missing values
filtered_secondary_df <- na.approx(filtered_secondary_df)

inst_to_case <- function(rt_inst, f, t_start, t_end) {
  #' Converts instantaneous reproduction number to the case reproduction number
  #' at time t, given a generation time/serial interval distribution, f.
  #' This is because Epiestim outputs instantaneous R and Epiabm uses case R

  rt_case <- c()
  dx <- 1 # Daily time steps

  # Helper function to pad vectors with zeros
  pad_with_zeros <- function(vector, target_length) {
    if (length(vector) < target_length) {
      return(c(vector, rep(0, target_length - length(vector))))
    } else {
      return(vector[1:target_length])
    }
  }

  # Convert f to a vector if it's a dataframe
  if (is.data.frame(f)) {
    f_vector <- as.numeric(f[[1]])  # Take the first column
  } else {
    f_vector <- as.numeric(f)
  }

  for (t in 0:(t_end - t_start - 1)) {
    # Extract the relevant portions of rt_inst and f
    rt_subset <- rt_inst[(t + 1):length(rt_inst)]
    print(head(rt_subset))

    # Fix the indexing - R is 1-indexed, not 0-indexed
    # Also ensure we don't go beyond the length of f_vector
    f_end_idx <- min(t_end - t_start - t, length(f_vector))
    if (f_end_idx > 0) {
      f_subset <- f_vector[1:f_end_idx]
    } else {
      f_subset <- numeric(0)
    }
    print(head(f_subset))

    # Ensure vectors are same length by padding with zeros
    max_len <- max(length(rt_subset), length(f_subset))

    if (max_len > 0) {
      # Pad both vectors to the same length
      rt_subset <- pad_with_zeros(rt_subset, max_len)
      f_subset <- pad_with_zeros(f_subset, max_len)

      # Create x values for integration
      x_vals <- seq(t + t_start, by = 1.0, length.out = max_len)

      # Calculate integrand
      integrand <- rt_subset * f_subset

      # Perform Simpson's rule integration
      if (length(integrand) >= 3) {
        rt_case_t <- pracma::trapz(x_vals, integrand)
      } else if (length(integrand) == 2) {
        # Use trapezoidal rule for 2 points
        rt_case_t <- pracma::trapz(x_vals, integrand)
      } else if (length(integrand) == 1) {
        # Single point
        rt_case_t <- integrand[1] * dx
      } else {
        rt_case_t <- 0
      }
    } else {
      rt_case_t <- 0
    }

    rt_case <- c(rt_case, rt_case_t)
  }

  return(rt_case)
}


# rt_inst: This will be the 'Mean(R)' column from filtered_r_df
rt_instantaneous <- filtered_r_df$`Mean(R)`

# f: Generation time distribution
# Read the generation_times.csv file
f_distribution <- read_csv(file.path(epiestim_dir, "gen_time_dist.csv"),
                           col_names = FALSE,
                           show_col_types = FALSE)
print(head(f_distribution))

# Call the function
rt_case_values <- inst_to_case(
  rt_inst = rt_instantaneous,
  f = f_distribution,
  t_start = 8,
  t_end = 60
)

cat("\nCalculated rt_case values (first 10):")
print(head(rt_case_values, 10))

if (length(rt_case_values) > 0) {
  case_times <- seq(8, length.out = length(rt_case_values))
  results_df <- data.frame(
    time = case_times,
    rt_case = rt_case_values
  )
  cat("\nFirst few rows of results_df with rt_case:")
  print(head(results_df))
} else {
  cat("\nrt_case_values vector is empty. No results to show or save.")
  results_df <- data.frame(time = numeric(0), rt_case = numeric(0))
}

# --- Part 4: Plotting R_t Curves ---
cat("\nPreparing data for plotting R_t curves...")

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

  # Data for case R (results_df is from Epiestim)
  plot_data_case <- results_df %>%
    dplyr::rename(Rt_mean = rt_case) %>%
    dplyr::select(time, Rt_mean)

  print("Plotting R_t curves using ggplot2...")
  rt_plot <- ggplot2::ggplot() +
    # Plot for Instantaneous R (Mean and CI)
    ggplot2::geom_line(data = plot_data_inst,
                       aes(x = time, y = Rt_mean,
                           color = "Mean Instantaneous R (EpiEstim)"),
                       linewidth = 1) +
    ggplot2::geom_line(data = filtered_secondary_df,
                       aes(x = time, y = R_t,
                           color = "Epiabm case R_t"),
                      linewidth = 1, linetype = "dotted") +
    ggplot2::geom_ribbon(data = plot_data_inst,
                         aes(x = time, ymin = Rt_lower, ymax = Rt_upper,
                             fill = "95% CI Instantaneous R"),
                         alpha = 0.3) +
    # Plot for Case R (Converted)
    ggplot2::geom_line(data = plot_data_case, 
                       aes(x = time, y = Rt_mean, color = "Case R (Converted)"),
                       linewidth = 1, linetype = "dashed") +
    # Added linetype for better distinction
    ggplot2::labs(
      title = "Comparison of Reproduction Numbers (R_t) Over Time",
      x = "Time",
      y = "R_t Value",
      color = "R_t Series", # Legend title for color aesthetic
      fill = "Confidence Interval" # Legend title for fill aesthetic
    ) +
    ggplot2::scale_color_manual(
      values = c("Mean Instantaneous R (EpiEstim)" = "dodgerblue",
                 "Case R (Converted)" = "firebrick",
                 "Epiabm case R_t" = "goldenrod")
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
  ggplot2::ggsave(file.path(epiestim_dir, plot_filename),
                  plot = rt_plot, width = 10, height = 7,
                  dpi = 300)
  print(paste("R_t comparison plot saved as", plot_filename))

} else {
  cat("\nSkipping plotting: Not enough data. 'filtered_r_df' or 'results_df'
         is empty.")
  if (nrow(filtered_r_df) == 0) print("Reason: filtered_r_df 
                                      (from R_estimates_np)
                                      has no rows or relevant data.")
  if (nrow(results_df) == 0) print("Reason: results_df 
                                  (from rt_case calculation) has no rows.")
}