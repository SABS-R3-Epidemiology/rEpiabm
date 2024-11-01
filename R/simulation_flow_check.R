#
# Example simulation script with data output
#
# Import dependencies
source("R/zzz.R")
initialize_python_env()
check_python_env()

library(reticulate)
#library(rEpiabm)
library(here)
library(tidyr)

os <- import("os", delay_load = TRUE)
logging <- import("logging", delay_load = TRUE)
pd <- import("pandas", delay_load = TRUE)
plt <- import("matplotlib.pyplot", delay_load = TRUE)
pe <- import("pyEpiabm", delay_load = TRUE)

# Set working directory for relative directory references
base_dir <- here()

# Set config file for Parameters
pe$Parameters$set_file(here("data", "simple_parameters.json"))

# Method to set the seed at the start of the simulation, for reproducibility
pe$routine$Simulation$set_random_seed(seed=as.integer(42))

# Pop_params are used to configure the population structure being used in this
# simulation.
pop_params <- list(
  population_size = as.integer(100),
  cell_number = as.integer(2),
  microcell_number = as.integer(2),
  household_number = as.integer(5),
  place_number = as.integer(2)
)

# Create a population based on the parameters given.
population = pe$routine$ToyPopulationFactory()$make_pop(pop_params)

# sim_params
sim_params <- list(
  simulation_start_time = as.integer(0),
  simulation_end_time = as.integer(60),
  initial_infected_number = as.integer(10),
  include_waning = TRUE
)

# file_params
file_params <- list(
  output_file = "output.csv",
  output_dir = here("simulation_outputs"),
  spatial_output = FALSE,
  age_stratified = FALSE
)

# dem_file_params
dem_file_params <- list(
  output_dir = here("simulation_outputs"),
  spatial_output = FALSE,
  age_output = FALSE
)

# inf_history_params
inf_history_params <- list(
  output_dir = here("simulation_outputs"),
  status_output = TRUE,
  infectiousness_output = TRUE,
  compress = FALSE  # Set to TRUE if compression desired
)

# Create a simulation object
sim <- pe$routine$Simulation()

# Configure the simulation with parameters
sim$configure(
  population,
  list(
    pe$sweep$InitialInfectedSweep(),
    pe$sweep$InitialDemographicsSweep(dem_file_params)
  ),
  list(
    pe$sweep$HouseholdSweep(),
    pe$sweep$QueueSweep(),
    pe$sweep$HostProgressionSweep()
  ),
  sim_params,
  file_params,
  inf_history_params
)

# Run the simulation
sim$run_sweeps()
sim$compress_csv()

# Create dataframe for plots
filename <- here("simulation_outputs", "output.csv")
df <- pd$read_csv(filename)

# Convert pandas dataframe to R dataframe
df_r <- as.data.frame(df)

# Load library for plotting
library(ggplot2)

# Reshape the data from wide to long format using base R
status_columns <- c("InfectionStatus.Susceptible", 
                    "InfectionStatus.InfectMild",
                    "InfectionStatus.Recovered",
                    "InfectionStatus.Dead")

df_long <- pivot_longer(
  df_r,
  cols = all_of(status_columns),
  names_to = "Status",
  values_to = "Count"
)
df_long$Status <- factor(df_long$Status,
                        levels = status_columns,
                        labels = c("Susceptible", "Infected", "Recovered", "Dead"))

# Create the plot
p <- ggplot(df_long, aes(x = time, y = Count, color = Status)) +
  geom_line() +
  scale_color_manual(values = c("Susceptible" = "blue",
                                "Infected" = "red",
                                "Recovered" = "green",
                                "Dead" = "black")) +
  theme_minimal() +
  labs(title = "SIR Model Flow",
       x = "Time",
       y = "Count") +
  theme(legend.position = "right",
        plot.title = element_text(hjust = 0.5),
        panel.grid.minor = element_blank())

# Display the plot
print(p)

# Save the plot
ggsave(
  filename = here("simulation_outputs", "simulation_flow_SIR_plot.png"),
  plot = p,
  width = 10,
  height = 6,
  dpi = 300
)
