library(EpiEstim)
library(ggplot2)

input_dir <- "rEpiabm/data/Andorra/simulation_outputs"
output_dir <- "rEpiabm/data/Andorra/simulation_outputs/epiestim"

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created output directory:", output_dir, "\n")
}

# Calculate count of Generation time distribution, std dev and mean
create_gen_time_array <- function(file_path, display = TRUE, location) {

  # Read the CSV file and exclude the first row
  data <- read.csv(file_path, header = TRUE)

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

  # Initialise a probability array with zeros for missing values
  prob_array <- numeric(length(all_values))

  # Fill in probabilities for values that exist
  for (i in seq_len(nrow(gen_time_dist))) {
    value <- gen_time_dist$value[i]
    prob_array[value] <- gen_time_dist$probability[i]
  }

  # EpiEstim requires that the probability of a 0-day serial interval is 0.
  # We set the first element (representing day 0) to 0 and re-normalise the rest.
  if (length(prob_array) > 0 && prob_array[1] > 0) {
    prob_array[1] <- 0
    prob_array <- prob_array / sum(prob_array)
  }

  # Calculate mean and standard deviation
  mean_gen_time <- mean(data_1d)
  sd_gen_time <- sd(data_1d)

  # Display statistic results
  if (display) {
    cat("\nMean Generation Time:", mean_gen_time, "\n")
    cat("Standard Deviation:", sd_gen_time, "\n")

    p <- ggplot(gen_time_dist, aes(x = value, y = probability)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      labs(title = "Generation Time Distribution", x = "Value",
           y = "Probability") + theme_minimal()

    # Save the plot
    ggsave(file.path(output_dir, "Generation_plot.png"), plot = p, width = 8,
           height = 6, dpi = 300)

    cat("Generation plot saved\n")
  }

  # Save to file if location is provided, otherwise prompt
  if (!missing(location)) {
    write.table(prob_array, location, row.names = FALSE,
                col.names = FALSE, quote = FALSE)
    cat("Generation time distribution saved to:", location, "\n")
  } else {
    cat("No location for output given; please amend preprocess_epiestim.r\n")
  }

  return(list(
    prob_array = prob_array,
    mean = mean_gen_time,
    sd = sd_gen_time
  ))
}

# Calculate incidence, based on 'Exposed', not 'Infected'
calculate_susceptible_diff <- function(file_path, display = TRUE,
                                       location) {
  # Read the detailed CSV file
  data <- read.csv(file_path, header = TRUE)

  # Aggregate the data to get total susceptibles per day
  daily_data <- data %>%
    group_by(time) %>%
    summarise(Total.Susceptible = sum(InfectionStatus.Susceptible), .groups = 'drop')

  # Print the aggregated data to the screen for verification
  cat("\n--- Aggregated Daily Susceptible Counts ---\n")
  print(head(daily_data))
  cat("-----------------------------------------\n\n")
  
  # Extract the aggregated Susceptible column
  susceptible <- daily_data$Total.Susceptible

  # Calculate consecutive differences (day-to-day changes)
  differences <- diff(susceptible)

  # Swap sign of differences, new infections are now positive
  # Set negative values to zero
  incidence <- -differences
  incidence[incidence < 0] <- 0

  # Display results if requested
  if (display) {
    cat("Total new infections detected:", sum(incidence), "\n")

    # Create a data frame for plotting
    plot_data <- data.frame(
      time = daily_data$time[-1],  # Remove first time point as n-1 differences
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

  # Save to file if location is provided
  if (!missing(location)) {
    write.table(incidence, location, row.names = FALSE, col.names = FALSE,
                quote = FALSE)
    cat("Incidence data saved to:", location, "\n")
  } else {
    cat("No location for output given; please specify output location\n")
  }

  return(list(
    incidence = incidence,
    total_incidence = sum(incidence)
  ))
}

# # Calculate incidence, based on 'Exposed', not 'Infected'
# calculate_susceptible_diff <- function(file_path, display = TRUE,
#                                        location) {
#   # Read the CSV file
#   data <- read.csv(file_path, header = TRUE)

#   # Extract the Susceptible column
#   susceptible <- data$InfectionStatus.Susceptible

#   # Calculate consecutive differences (day-to-day changes)
#   # Negative values mean decrease in susceptible population (new infections)
#   differences <- diff(susceptible)

#   # Swap sign of differences, new infections are now positive
#   # Set negative values to zero
#   incidence <- -differences
#   incidence[incidence < 0] <- 0

#   # Display results if requested
#   if (display) {
#     cat("\nTotal new infections detected:", sum(incidence), "\n")

#     # Create a data frame for plotting
#     plot_data <- data.frame(
#       time = data$time[-1],  # Remove first time point as n-1 differences
#       incidence = incidence
#     )

#     p <- ggplot(plot_data, aes(x = time, y = incidence)) +
#       geom_bar(stat = "identity", fill = "firebrick") +
#       labs(title = "Daily Incidence from Susceptible Population Changes",
#            x = "Time",
#            y = "New Infections") +
#       theme_minimal()

#     # Save the plot
#     ggsave(file.path(output_dir, "Incidence_plot.png"), plot = p, width = 8,
#            height = 6, dpi = 300)

#     cat("Incidence plot saved\n")
#   }

#   # Save to file if location is provided
#   if (!missing(location)) {
#     write.table(incidence, location, row.names = FALSE, col.names = FALSE,
#                 quote = FALSE)
#     cat("Incidence data saved to:", location, "\n")
#   } else {
#     cat("No location for output given; please specify output location\n")
#   }

#   return(list(
#     incidence = incidence,
#     total_incidence = sum(incidence)
#   ))
# }

# Function to combine and save incidence and SI data for EpiEstim
prepare_epiestim_data <- function(incidence_data, si_data, output_file) {
  # Create an incidence dataframe in the format EpiEstim expects
  incidence_df <- data.frame(
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
  cat("\nEpiEstim data saved to:", output_file, "\n")

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

# MAIN EXECUTION

# Calculate incidence from changes in susceptible population
incidence_data <- calculate_susceptible_diff(
  file.path(input_dir, "output.csv"),
  display = TRUE, location <- file.path(output_dir, "incidence.csv")
)

# Generate Generation_time distribution array and values
si_data <- create_gen_time_array(
  file.path(input_dir, "generation_times.csv"),
  display = TRUE, location <- file.path(output_dir, "gen_time_dist.csv")
)

# Combine and save data for EpiEstim
epiestim_data <- prepare_epiestim_data(
  incidence_data,
  si_data,
  file.path(output_dir, "epiestim_data.rds")
)

# # Run EpiEstim
# res_parametric_si <- estimate_R(
#   incid = epiestim_data$incidence,
#   method = "parametric_si",
#   config = make_config(
#     list(
#       mean_si = epiestim_data$si_mean,
#       std_si = epiestim_data$si_sd
#     )
#   )
# )

# # Print summary to console
# cat("\n\n===== SUMMARY OF EPIESTIM RESULTS =====\n\n")
# print(summary(res_parametric_si))

# # Save the R estimates to a CSV file
# r_estimates_file <- file.path(output_dir, "R_estimates.csv")
# write.csv(res_parametric_si$R, r_estimates_file)
# cat("\nR estimates saved to:", r_estimates_file, "\n")

# # Create and save plots
# png_file <- file.path(output_dir, "epiestim_detailed_plot.png")

# p <- ggplot(res_parametric_si$R) + 
#   geom_ribbon(aes(x = t_end, 
#                  ymin = `Quantile.0.025(R)`, 
#                  ymax = `Quantile.0.975(R)`), 
#              fill = "lightblue", alpha = 0.5) +
#   geom_line(aes(x = t_end, y = `Median(R)`), color = "blue") +
#   geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
#   labs(title = "Reproduction Number Estimates Over Time",
#        x = "Time Period", 
#        y = "Estimated R") +
#   theme_minimal()

# ggsave(png_file, p, width = 10, height = 6)
# cat("\nDetailed plot saved to:", png_file, "\n")

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

# Save the R estimates to a CSV file
r_estimates_file_np <- file.path(output_dir, "R_estimates_np.csv")
write.csv(res_non_parametric_si$R, r_estimates_file_np)
cat("\nR estimates saved to:", r_estimates_file_np, "\n")

# Create and save plot
png_file_np <- file.path(output_dir, "epiestim_detailed_plot_np.png")

p <- ggplot(res_non_parametric_si$R) +
  geom_ribbon(aes(x = t_end,
                  ymin = `Quantile.0.025(R)`,
                  ymax = `Quantile.0.975(R)`),
              fill = "lightblue", alpha = 0.5) +
  geom_line(aes(x = t_end, y = `Median(R)`), color = "blue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
  labs(title = "Reproduction Number Estimates Over Time",
       x = "Time Period",
       y = "Estimated R") +
  theme_minimal()

ggsave(png_file_np, p, width = 10, height = 6)
cat("\nDetailed plot saved to:", png_file_np, "\n")