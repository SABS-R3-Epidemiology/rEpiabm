output_dir <- "data/toy/simulation_outputs"
# Calculate incidence, based on 'Exposed', not 'Infected'

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
  
  # Calculate mean and standard deviation
  mean_gen_time <- mean(data_1d)
  sd_gen_time <- sd(data_1d)
  
  # Display results if requested
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
  
  # Save to file if location is provided
  if (!missing(location)) {
    write.csv(gen_time_dist, location, row.names = FALSE)
    cat("Generation time distribution saved to:", location, "\n")
  } else {
    cat("No location for output given; please amend preprocess_epiestim.r")
  }
  
  # Return the distribution and statistics
  return()
}
  
# Generate Generation_time distribution array and values
create_gen_time_array(file.path(output_dir, "generation_times.csv"), display = TRUE,
                                location = file.path(output_dir, "gen_time_dist.csv"))
