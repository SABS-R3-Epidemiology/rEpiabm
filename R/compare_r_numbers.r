library(dplyr)
library(pracma)
library(readr)
library(ggplot2)
library(zoo)

source("R/epiestim_epigeopop.r")

epiestim_dir <- "data/Andorra/epiestim"
epiabm_dir <- "data/Andorra/simulation_outputs"
# first_day is the end day of the first sliding window 
# eg. for a week sliding window, it will be 8
# last_day is the last day of the simulation
first_day <- 8
last_day <- 60

# Read the R_estimates.csv file
r_estimates_df <- read_csv(file.path(epiestim_dir, "R_estimates.csv"),
                           show_col_types = FALSE)

# Create a new column 't' corresponding to the range first_day to last_day.
# The length of the sequence should match the number of rows in r_estimates_df
num_rows_r_estimates <- nrow(r_estimates_df)
t_values <- seq(from = first_day, by = 1, length.out = num_rows_r_estimates)

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
  filter(time >= first_day & time <= last_day)
cat("\nFiltered secondary infections data:")
print(head(filtered_secondary_df))
print(paste("Number of rows in filtered_secondary_df:",
            nrow(filtered_secondary_df)))

# Linearly interpolate missing values
if(nrow(filtered_secondary_df) > 1) {
    filtered_secondary_df <- na.approx(filtered_secondary_df)
}

inst_to_case <- function(rt_inst, f, first_day, last_day) {
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

  for (t in 0:(last_day - first_day - 1)) {
    # Extract the relevant portions of rt_inst and f
    rt_subset <- rt_inst[(t + 1):length(rt_inst)]

    # Fix the indexing - R is 1-indexed, not 0-indexed
    # Also ensure we don't go beyond the length of f_vector
    f_end_idx <- min(last_day - first_day - t, length(f_vector))
    if (f_end_idx > 0) {
      f_subset <- f_vector[1:f_end_idx]
    } else {
      f_subset <- numeric(0)
    }

    # Ensure vectors are same length by padding with zeros
    max_len <- max(length(rt_subset), length(f_subset))

    if (max_len > 0) {
      # Pad both vectors to the same length
      rt_subset <- pad_with_zeros(rt_subset, max_len)
      f_subset <- pad_with_zeros(f_subset, max_len)

      # Create x values for integration
      x_vals <- seq(t + first_day, by = 1.0, length.out = max_len)

      # Calculate integrand
      integrand <- rt_subset * f_subset

      # Perform trapezoidal integration
      if (length(integrand) >= 2) {
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

# Generation time distribution
f_distribution <- read_csv(file.path(epiestim_dir, "gen_time_dist.csv"),
                           col_names = FALSE,
                           show_col_types = FALSE)

# --- Apply conversion function to mean, lower CI, and upper CI ---
# 1. Convert the mean instantaneous R
rt_case_mean <- inst_to_case(
  rt_inst = filtered_r_df$`Mean(R)`,
  f = f_distribution,
  first_day = first_day,
  last_day = last_day
)

# 2. Convert the lower bound of the CI
rt_case_lower <- inst_to_case(
  rt_inst = filtered_r_df$`Quantile.0.025(R)`,
  f = f_distribution,
  first_day = first_day,
  last_day = last_day
)

# 3. Convert the upper bound of the CI
rt_case_upper <- inst_to_case(
  rt_inst = filtered_r_df$`Quantile.0.975(R)`,
  f = f_distribution,
  first_day = first_day,
  last_day = last_day
)

# --- Combine all converted values into a single dataframe ---
if (length(rt_case_mean) > 0) {
  case_times <- seq(first_day, length.out = length(rt_case_mean))
  results_df <- data.frame(
    time = case_times,
    rt_case_mean = rt_case_mean,
    rt_case_lower = rt_case_lower,
    rt_case_upper = rt_case_upper
  )
  cat("\nFirst few rows of results_df with converted Case R and its CI:")
  print(head(results_df))
} else {
  cat("\nrt_case_values vector is empty. No results to show or save.")
  results_df <- data.frame(time = numeric(0), rt_case_mean = numeric(0),
                           rt_case_lower = numeric(0), rt_case_upper = numeric(0))
}


# --- Plotting R_t Curves ---
cat("\nPreparing data for plotting R_t curves...")

if (nrow(results_df) > 0) {

  print("Plotting R_t curves using ggplot2...")
  
  rt_plot <- ggplot2::ggplot() +
    # Plot for EpiABM Case R (Solid Blue Line)
    ggplot2::geom_line(data = filtered_secondary_df,
                       aes(x = time, y = R_t,
                           color = "EpiABM Case R"),
                      linewidth = 1) +
                      
    # Plot for Converted Case R (Dashed Red Line)
    ggplot2::geom_line(data = results_df, 
                       aes(x = time, y = rt_case_mean, color = "Case R (Converted from EpiEstim)"),
                       linewidth = 1, linetype = "dashed") +
                       
    # Plot for the Converted Case R Confidence Interval (Light Red Ribbon)
    ggplot2::geom_ribbon(data = results_df,
                         aes(x = time, ymin = rt_case_lower, ymax = rt_case_upper,
                             fill = "95% CI Case R (Converted)"),
                         alpha = 0.3) +
    
    # Labels and Theming
    ggplot2::labs(
      title = "Comparison of Case Reproduction Numbers (R_t) Over Time",
      x = "Time",
      y = "R_t Value",
      color = "R_t Series", 
      fill = "Confidence Interval"
    ) +
    ggplot2::scale_color_manual(
      name = "R_t Series",
      values = c("EpiABM Case R" = "dodgerblue",
                 "Case R (Converted from EpiEstim)" = "firebrick")
    ) +
    ggplot2::scale_fill_manual(
      name = "Confidence Interval",
      values = c("95% CI Case R (Converted)" = "lightcoral")
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
  cat("\nSkipping plotting: Not enough data. 'results_df' is empty.")
}