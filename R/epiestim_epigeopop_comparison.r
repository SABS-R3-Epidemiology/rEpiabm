library(EpiEstim)
library(ggplot2)

output_dir <- "data/Andorra/simulation_outputs"

# Calculate count of Generation time distribution, std dev and mean
create_gen_time_array <- function(file_path, display = TRUE, location) {
  # Read the CSV file and exclude the first row
  data <- read.csv(file_path, header = TRUE)[-1, ]

  # Convert the data to a 1D array
  data_1d <- as.numeric(unlist(data))

  # Remove NaNs/NAs
  data_1d <- data_1d[!is.na(data_1d)]

  # Create a frequency table of values
  value_counts <- table(data_1d)

  # Convert to a data frame
  gen_time_dist <- data.frame(
    value = as.numeric(names(value_counts)),
    count = as.numeric(value_counts)
  )

  # Calculate probability distribution
  total_count <- sum(gen_time_dist$count)
  gen_time_dist$probability <- gen_time_dist$count / total_count

  # Create a sequence from 0 to max value observed
  max_value <- max(gen_time_dist$value)
  all_values <- 0:max_value

  # Initialize a probability array with zeros for missing values
  prob_array <- numeric(length(all_values))

  # Fill in probabilities for values that exist
  for (i in 1:nrow(gen_time_dist)) {
    value <- gen_time_dist$value[i]
    prob_array[value + 1] <- gen_time_dist$probability[i] 
    # +1 as R index starts at 1
  }

  # Calculate mean and standard deviation
  mean_gen_time <- mean(data_1d)
  sd_gen_time <- sd(data_1d)

  # Display statistic results
  if (display) {
    cat("\nMean Generation Time:", mean_gen_time, "\n")
    cat("Standard Deviation:", sd_gen_time, "\n")

    library(ggplot2)

    p <- ggplot(gen_time_dist, aes(x = value, y = probability)) +
        geom_bar(stat = "identity", fill = "steelblue") +
        labs(title = "Generation Time Distribution",
            x = "Value",
            y = "Probability") +
        theme_minimal()

    # Save the plot
    ggsave(file.path(output_dir, "Generation_plot.png"), plot = p,
          width = 8, height = 6, dpi = 300)

    cat("Generation plot saved\n")
  }

  return(list(
    prob_array = prob_array,
    mean = mean_gen_time,
    sd = sd_gen_time
  ))
}

# Calculate incidence, based on changes in Susceptible
calculate_susceptible_differences <- function(file_path, output_dir = ".",
                                              display = TRUE) {
  # Read the CSV file
  data <- read.csv(file_path, header = TRUE)

  # Group by time and sum the Susceptible column
  library(dplyr)

  # Aggregate data by time, summing the Susceptible column
  grouped_data <- data %>%
    group_by(time) %>%
    summarize(susceptible = sum(InfectionStatus.Susceptible)) %>%
    arrange(time)

  # Extract the susceptible column from grouped data
  susceptible <- grouped_data$susceptible

  # Calculate consecutive differences (day-to-day changes)
  # Negative values indicate decreases in susceptible pop (new infections)
  differences <- diff(susceptible)

  # Convert differences to positive values (for incidence)
  # Take negative of diff because decreases in susceptible = new infections
  incidence <- -differences

  # Only keep positive values (representing new infections)
  incidence[incidence < 0] <- 0

  # Create time series for incidence (using the time column from grouped data)
  time_points <- grouped_data$time[-1]  # Remove 1st time pt as we have n-1 diff

  # Display results if requested
  if (display) {
    cat("\nTotal new infections detected:", sum(incidence), "\n")

    library(ggplot2)

    # Create a data frame for plotting
    plot_data <- data.frame(
      time = time_points,
      incidence = incidence
    )

    p <- ggplot(plot_data, aes(x = time, y = incidence)) +
      geom_bar(stat = "identity", fill = "firebrick") +
      labs(title = "Daily Incidence from Susceptible Population Changes",
           x = "Time",
           y = "New Infections") +
      theme_minimal()

    # Save the plot
    ggsave(file.path(output_dir, "Incidence_plot.png"), plot = p, width = 8, 
      height = 6, dpi = 300)

    cat("Incidence plot saved\n")
  }

  return(list(
    time = time_points,
    incidence = incidence,
    total_incidence = sum(incidence)
  ))
}

# Function to combine and save incidence and SI data for EpiEstim
prepare_epiestim_data <- function(incidence_data, si_data, output_file) {
  # Create an incidence dataframe in the format EpiEstim expects
  incidence_df <- data.frame(
    dates = incidence_data$time,  # Dates/times
    I = incidence_data$incidence  # Incidence values
  )

  # Create SI distribution data
  si_distr <- si_data$prob_array

  # Create the output list with required components
  output_data <- list(
    incidence = incidence_df,
    si_distr = si_distr,
    si_mean = si_data$mean,
    si_sd = si_data$sd
  )

  # Save the data to an RDS file to be directly loaded by EpiEstim
  saveRDS(output_data, file = output_file)
  cat("EpiEstim data saved to:", output_file, "\n")

  # Also save a text summary for reference
  sink(paste0(output_file, "_summary.txt"))
  cat("Incidence Data:\n")
  print(head(incidence_df, 10))
  cat("\nSerial Interval Distribution:\n")
  print(si_distr)
  cat("\nSerial Interval Mean:", si_data$mean, "\n")
  cat("Serial Interval SD:", si_data$sd, "\n")
  sink()

  return(output_data)
}

# Main execution

# Get incidence data
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


# Load the saved data
epiestim_data <- readRDS("data/Andorra/simulation_outputs/epiestim_data.rds")

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

# Print summary to console
cat("\n\n===== SUMMARY OF EPIESTIM RESULTS =====\n\n")
print(summary(res_parametric_si))

# Print the first few rows of R estimates
cat("\n\n===== FIRST ROWS OF R ESTIMATES =====\n\n")
print(head(res_parametric_si$R))

# Save the R estimates to a CSV file
r_estimates_file <- "data/Andorra/simulation_outputs/R_estimates.csv"
write.csv(res_parametric_si$R, r_estimates_file)
cat("\nR estimates saved to:", r_estimates_file, "\n")

# Save plots to files
pdf_file <- "data/Andorra/simulation_outputs/epiestim_plot.pdf"
pdf(pdf_file)
plot(res_parametric_si)
dev.off()
cat("\nPlot saved to:", pdf_file, "\n")

# Create and save a more detailed ggplot
png_file <- "data/Andorra/simulation_outputs/epiestim_detailed_plot.png"
library(ggplot2)

p <- ggplot(res_parametric_si$R) + 
  geom_ribbon(aes(x = t_start, 
                 ymin = `Quantile.0.025(R)`, 
                 ymax = `Quantile.0.975(R)`), 
             fill = "lightblue", alpha = 0.5) +
  geom_line(aes(x = t_start, y = `Median(R)`), color = "blue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  labs(title = "Reproduction Number Estimates Over Time",
       x = "Time Period", 
       y = "Estimated R") +
  theme_minimal()

ggsave(png_file, p, width = 10, height = 6)
cat("\nDetailed plot saved to:", png_file, "\n")

#==============================================================

# With the SI distribution directly
res_non_parametric_si <- estimate_R(
  incid = epiestim_data$incidence,
  method = "non_parametric_si",
  config = make_config(
    list(
      si_distr = epiestim_data$si_distr
    )
  )
)

# Print summary to console
cat("\n\n===== SUMMARY OF EPIESTIM RESULTS =====\n\n")
print(summary(res_non_parametric_si))

# Print the first few rows of R estimates
cat("\n\n===== FIRST ROWS OF R ESTIMATES =====\n\n")
print(head(res_non_parametric_si$R))

# Save the R estimates to a CSV file
r_estimates_file_np <- "data/Andorra/simulation_outputs/R_estimates_np.csv"
write.csv(res_non_parametric_si$R, r_estimates_file_np)
cat("\nR estimates saved to:", r_estimates_file_np, "\n")

# Save plots to files
pdf_file_np <- "data/Andorra/simulation_outputs/epiestim_plot_np.pdf"
pdf(pdf_file_np)
plot(res_non_parametric_si)
dev.off()
cat("\nPlot saved to:", pdf_file_np, "\n")

# Create and save a more detailed ggplot
png_file_np <- "data/Andorra/simulation_outputs/epiestim_detailed_plot_np.png"
library(ggplot2)

p <- ggplot(res_non_parametric_si$R) + 
  geom_ribbon(aes(x = t_start, 
                 ymin = `Quantile.0.025(R)`, 
                 ymax = `Quantile.0.975(R)`), 
             fill = "lightblue", alpha = 0.5) +
  geom_line(aes(x = t_start, y = `Median(R)`), color = "blue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  labs(title = "Reproduction Number Estimates Over Time",
       x = "Time Period", 
       y = "Estimated R") +
  theme_minimal()

ggsave(png_file_np, p, width = 10, height = 6)
cat("\nDetailed plot saved to:", png_file_np, "\n")