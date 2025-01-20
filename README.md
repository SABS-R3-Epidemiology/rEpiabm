ADD BADGES
# rEpiabm
rEpiabm enables users familiar with R to use Epiabm (ADD LINK). Epiabm is a simulation tool that models the progress of an epidemic across a specified region of interest within a specific timeframe. It has been developed in python for small-scale implementations and C++ for fast, large-scale simulations. PyEpiabm design is modular, with many options to configure specific requirements.

## Summary of Epiabm functionality

### Basic Architecture
To model an epidemic, contact events are represented by the population spatial structure (see Figure 1.). The transmission of the disease and its progression within host is represented by a compartment model (see Figure 2.). These two architectures are highly configurable; this allows us to study a wide range of simulation scenarios.

<div style="display: flex; gap: 20px;">
  <div style="flex: 1;">
    <img src="./images/population_spatial_structure.png" alt="Population spatial structure" width="100%">
    <p>Figure 1. Population Spatial Structure: The environment is modelled using <a href="https://github.com/SABS-R3-Epidemiology/EpiGeoPop">EpiGeoPop</a>, which takes a region of interest, creates layers of sub-regions of different types and populates these with individuals.</p>
  </div>
  <div style="flex: 1;">
    <img src="./images/infection_progression.jpg" alt="Infection progression" width="100%">
    <p>Figure 2. Infection Progression: The infection progression is represented using a <a href="https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology">compartment model</a> which tracks the daily progress of the disease within an individual.</p>
  </div>
</div>

## Running a simulation
The overview below describes how the simulation works and the user-input required to run a basic simulation. A more detailed, complex example is illustrated in this jupyter notebook (ADD LINK). Also, [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model) details optional parameters available to the user as well as those whose values are mentioned, but changing them is not recommended.

### Step 1: Use EpiGeoPop to generate the population spatial structure
As shown in Figure 1, the region of interest is broken into a spatial structure:
* *Cells* - largest areas, based on a fixed width
* *Microcells* - cells are split into microcells which contain smaller areas containing individuals
* *Households* - quantity per microcell is based on a probabilistic distribution. All individuals are assigned to one household and do not move households during the simulation.
* *Places* - quantity per microcell is based on a probabilistic distribution. These are spaces where individuals might meet other individuals from different households, a workplace or a public park for example.

This structure is created using [EpiGeoPop](https://github.com/SABS-R3-Epidemiology/EpiGeoPop). The user states a region of interest, Oxford or UK for example, and the tool extracts information from [Natural Earth](https://www.naturalearthdata.com/) and [JRC](https://data.jrc.ec.europa.eu/csv), providing a csv file as output. This file contains one line per microcell for each cell, with the number of households, places and individuals to be used in the simulation (the quantity of individuals are extracted from Census data).

In summary, the spatial structure for a region is generated using EpiGeoPop. This tool exports into a csv file the number of households, places, and individuals for each microcell.

### Step 2: Configure the simulation
The following parameters are essential and need to be stated by the user to run a simulation:

* Name of the path to the csv file from EpiGeoPop
* Number of infected individuals (Imild): enter the number of infected individuals at the start of the simulation.
* Number of individuals per household (this should match the census household distribution for your region)
* Time for the simulation to run (in days)
* Select any output options required
 
There are many further optional parameters which are described in [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model)

**Common adjustments:**
* At the start, infected individuals are distributed across all cells by default, you may want to put them in one cell.
* Maximum infection radius: this sets a maximum distance for the infection to be able to spread from cell to cell
* Age distribution used is required
* Outputs to evaluate simulation (see Step 4: Evaluate Results)

### Step 3: Run the simulation
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

### Step 4: Evaluate results
A simulation produces one output file by default:

Infection status (S, E, I<sub>mild</sub>, etc) for each day by cell

Further optional files are available, details described in [the Wiki](https://github.com/SABS-R3-Epidemiology/epiabm/wiki/Overview-of-the-Ferguson-Model) or see jupyter notebook with a detailed illustration here . These data files can be used to produce plots for further analysis.

