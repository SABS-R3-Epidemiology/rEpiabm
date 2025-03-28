output_dir <- "data/toy/simulation_outputs"

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

  # Initialise a probability array with zeros for missing values
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
    ggsave(file.path(output_dir, "Generation_plot.png"), plot = p, width = 8, height = 6, dpi = 300)
  
    cat("Generation plot saved\n")
  }
  
  # Save to file if location is provided, otherwise prompt
  if (!missing(location)) {
    write.table(prob_array, location, row.names = FALSE, col.names = FALSE, quote = FALSE)
    cat("Generation time distribution saved to:", location, "\n")
  } else {
    cat("No location for output given; please amend preprocess_epiestim.r")
  }
  
  return()
}

# Calculate incidence, based on 'Exposed', not 'Infected'
calculate_susceptible_differences <- function(file_path, display = TRUE, location) {
  # Read the CSV file
  data <- read.csv(file_path, header = TRUE)
  
  # Extract the Susceptible column
  susceptible <- data$InfectionStatus.Susceptible
  
  # Calculate consecutive differences (day-to-day changes)
  # Negative values indicate decreases in susceptible population (new infections)
  differences <- diff(susceptible)
  
  # Convert differences to positive values (for incidence)
  # We take the negative of differences because decreases in susceptible = new infections
  incidence <- -differences
  
  # Only keep positive values (representing new infections)
  incidence[incidence < 0] <- 0
  
  # Display results if requested
  if (display) {
    cat("\nTotal new infections detected:", sum(incidence), "\n")
    
    library(ggplot2)
    
    # Create a data frame for plotting
    plot_data <- data.frame(
      time = data$time[-1],  # Remove first time point as we have n-1 differences
      incidence = incidence
    )
    
    p <- ggplot(plot_data, aes(x = time, y = incidence)) +
      geom_bar(stat = "identity", fill = "firebrick") +
      labs(title = "Daily Incidence from Susceptible Population Changes",
           x = "Time",
           y = "New Infections") +
      theme_minimal()
    
    # Save the plot
    ggsave(file.path(output_dir, "Incidence_plot.png"), plot = p, width = 8, height = 6, dpi = 300)
    
    cat("Incidence plot saved\n")
  }
  
  # Save to file if location is provided
  if (!missing(location)) {
    write.table(incidence, location, row.names = FALSE, col.names = FALSE, quote = FALSE)
    cat("Incidence data saved to:", location, "\n")
  } else {
    cat("No location for output given; please specify output location\n")
  }
  
  return(incidence)
}

# Calculate incidence from changes in susceptible population
calculate_susceptible_differences(file.path(output_dir, "output.csv"), display = TRUE,
                                 location = file.path(output_dir, "incidence.csv"))
                                 
# Generate Generation_time distribution array and values
create_gen_time_array(file.path(output_dir, "generation_times.csv"), display = TRUE,
                                location = file.path(output_dir, "gen_time_dist.csv"))
