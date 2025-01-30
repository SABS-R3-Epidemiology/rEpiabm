ADD BADGES
# rEpiabm
rEpiabm enables users familiar with R to use [Epiabm](https://github.com/SABS-R3-Epidemiology/epiabm). Epiabm is a simulation tool that models the progress of an epidemic across a specified region of interest within a specific timeframe. It has been developed in python (PyEpiabm) for small-scale implementations and C++ (cEpiabm) for fast, large-scale simulations. PyEpiabm has a modular design, with many options to configure specific requirements.

## Summary of Epiabm functionality

### Basic Architecture
To model an epidemic, contact events occur within the population spatial structure (see Figure 1.). A compartmental model is used for the progression of the disease within-host (see Figure 2.). These two architectures are highly configurable which allows us to study a wide range of simulation scenarios.

<div style="display: flex; gap: 20px;">
  <div style="flex: 1;">
    <img src="./images/population_spatial_structure.png" alt="Population spatial structure" width="100%">
    <p><figcaption><i><b>Figure 1.</b> Population Spatial Structure: The environment is modelled using <a href="https://github.com/SABS-R3-Epidemiology/EpiGeoPop">EpiGeoPop</a>, which takes a region of interest, creates layers of sub-regions of different types and populates these with individuals.</p><figcaption></i>
  </div>
  <div style="flex: 1;">
    <img src="./images/infection_progression.jpg" alt="Infection progression" width="100%">
    <p><figcaption><i><b>Figure 2.</b> Infection Progression: The infection progression is represented using a <a href="https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology">compartment model</a> which tracks the daily progress of the disease within an individual.</i><figcaption></p>
  </div>
</div>

## Running a simulation

The basic flow of a simulation is described below; a more detailed, complex example is illustrated [in this Jupyter notebook](./walk_through/detailed_example.ipynb). We give instructions to run a basic simulation for both a toy population and a population extracted by [EpiGeoPop](https://github.com/SABS-R3-Epidemiology/EpiGeoPop), using 'Andorra' as an example of the region of interest. Also, [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model) details optional parameters available to the user as well as those whose values are mentioned, but changing them is not recommended.


### Step 1: Set up rEpiabm
Before running a simulation, rEpiabm needs to be installed with all dependencies mentioned in the DESCRIPTION file. Also, the input folder structure used by the R program file needs to be set up.

**Instructions:**
1. Clone the Github rEpiabm repository
2. Create a GitHub Personal Access Token (fine-grained)
3. Configure RStudio with your token
4. Install required R packages
  ```bash
  install.packages("devtools")
  devtools::install_github("SABS-R3-Epidemiology/rEpiabm")
  ```
5. You now have two different simulation options:

    5.1 *An Epigeopop based simulation* 
    
    This uses **real** data to create the Population spatial structure*: Copy the example `Andorra` folder structure within the data folder and name it with your region of interest. Include the `.json` file as you will need to edit this later for your simulation.

    OR

    5.2 *A toy simulation*

    Users can specify population parameter values (usually small quantities) to create the Population spatial structure*: Copy the example `toy` folder structure within the data folder and name it with your region of interest. Include the `.json` file as you will need to edit this later for your simulation.<br><br>

You are now ready to generate or configure the population for your simulation. 

### Step 2: Generate the population spatial structure
As shown in Figure 1, the region of interest is broken into a spatial structure:
* *Cells* - largest areas, based on a fixed width
* *Microcells* - cells are split into microcells which contain smaller areas containing individuals
* *Households* - quantity per microcell is based on a probabilistic distribution. All individuals are assigned to one household and do not move households during the simulation.
* *Places* - quantity per microcell is based on a probabilistic distribution. These are spaces where individuals might meet other individuals from different households, a workplace or a public park for example.

> [!IMPORTANT]  
> Follow **Step 2.1** instructions for an Epigeopop simulation or **Step 2.2** for a toy simulation.


**Step 2.1 Using EpiGeoPop**

The structure is created using [EpiGeoPop](https://github.com/SABS-R3-Epidemiology/EpiGeoPop). The user states a region of interest, Oxford or UK for example, and the tool extracts information from [Natural Earth](https://www.naturalearthdata.com/) and [JRC](https://data.jrc.ec.europa.eu/csv), providing a csv file as output. This file contains one line per microcell for each cell, with the number of households, places and individuals to be used in the simulation (the quantity of individuals are extracted from Census data).

**Instructions:**

1. Go to [EpiGeoPop](https://github.com/SABS-R3-Epidemiology/EpiGeoPop) repository and follow the instructions to extract a csv file of your required region.

**NB:** The json file which you amend to put the name your country also needs the proportion of households with 1 individual, 2 individuals, 3 individuals... upto 10 individuals. This information is usually found using census data (or equivalent) for your region. Amend the json file as described [in this Jupyter notebook](./walk_through/detailed_example.ipynb). 

2. Copy the extracted file to the new folder data/<your_country>/inputs

**NB:** At the time of writing, the tool did not extract the data successfully. Please follow the instructions [in this Jupyter notebook](./walk_through/detailed_example.ipynb).

In summary, the spatial structure for a region is generated using EpiGeoPop. This tool exports into a csv file the number of households, places, and individuals for each microcell. It also produces a Population Density map in the ```outputs/countries/<your_country>.pdf```, an example of Andorra shown in Figure 3.

<figure>
    <img src="./images/Andorra.png" alt="Population density map of Andorra">
    <figcaption><i>Figure 3. Example output: Population density map of Andorra.</i></figcaption>
</figure>


**Step 2.2 Using User-defined values** 

The user defines population values to generate a toy population spatial structure for the simulation. No region is specified but can be named to distinguish different simulation runs. This option is commonly used to *play* with different configurations of the simulation using small populations.

**Instructions:**

1. Open simulation.R and amend the following parameters (these are the default values):
  ```
  population_size = as.integer(100),
  cell_number = as.integer(2),
  microcell_number = as.integer(2),
  household_number = as.integer(5),
  place_number = as.integer(2)
  population_seed = as.integer(42)
  ```
2. Save simulation.R

### Step 3: Configure the simulation
Once the data for your country has been extracted, the simulation can be configured and run. An overview of the program workflow is illustrated in Figure 4. 

<figure>
    <img src="./images/program_workflow.png" alt="Overview of simulation workflow">
    <figcaption><i>Figure 4. Overview of simulation workflow: These steps are required to run a simulation.</i></figcaption>
</figure>
&nbsp;

The following parameters are essential and need to be stated by the user to run a simulation:

* Name of the path to the csv file from EpiGeoPop
* Number of infected individuals (Imild): enter the number of infected individuals at the start of the simulation.
* Proportion of households with 1 individual, 2 individuals, 3 individuals... upto 10 individuals. This information is usually found using census data (or equivalent) for your country.
* Time for the simulation to run (in days)
* Select any output options required

**Instructions:**
1. Open your version of *Andorra_parameters.json*
 (copied from ```Andorra``` in Step 1 above) and save with *<your_country>*'s name (keep first letter capitalised).
2. Amend the parameter array household_size_distribution to have your countries' distribution used in step 2. 
 3. Open `simulation_epigeopop.R` and amend:
    * `input_dir`: the absolute path to your csv file exported from EpiGeoPop
    * `initial_infected`: enter the number of infected individuals at the start of the simulation.
    * ``: enter the time for the simulation to run (in days)
    * ```Andorra``` in final line: change to *<your_country>*.

 More detailed instructions are available [in this Jupyter notebook](./walk_through/detailed_example.ipynb) and further optional parameters are described in [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model)

**Common adjustments:**
* At the start, infected individuals are distributed across all cells by default, you may want to put them in one cell.
* Maximum infection radius: this sets a maximum distance for the infection to be able to spread from cell to cell
* Age distribution used is required
* Outputs to evaluate simulation (see Step 5: Evaluate Results)

### Step 4: Run the simulation
Once configured, the simulation takes the generated population and performs the following  ‘sweeps’:

**Initialisation sweeps:**
* InitialHouseholdSweep - Assign individuals to households
* InitialisePlaceSweep - Assign individuals to places
* InitialInfectedSweep - Assign which individuals are initially infected

There are optional modules such as recording demographics, which are described in [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model)

**Simulation sweeps:**

Individual’s location and infection status is updated each day:
* UpdatePlaceSweep - Account for movement of individuals by refreshing their ‘place’ assignments
* Check each infected individual to see if they infect others:
  * HouseholdSweep - At a household
  * PlaceSweep - At a place
* SpatialSweep - Between cells
* QueueSweep - Any successful infections will update the newly infected person’s status from S (Susceptible) to E (Exposed).
* HostProgressionSweep - Individual’s Infection progress is updated using the compartmental model

**Instructions:**
1. After saving the configured file, either `simulation_epigeopop.R` or `simulation_toy.R`, run this code!

### Step 5: Evaluate results
A simulation produces one csv output file by default, found in the directory `data/<your_country>/simulation_outputs`. This file contains the number of individuals for each infection status (S, E, I<sub>mild</sub>, etc) for each day.

It also produces a SI<sub>mild</sub>RD plot, which shows the overall progression of each status for the duration of the simulation.

Further optional files are available, details described in [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model) or see [this Jupyter notebook](./walk_through/detailed_example.ipynb) with a detailed illustration here . These data files can be used to produce plots for further analysis.

