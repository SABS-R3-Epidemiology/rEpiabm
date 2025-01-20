# rEpiabm
rEpiabm enables users familiar with R to use Epiabm (ADD LINK). Epiabm is a simulation tool that models the progress of an epidemic across a specified region of interest within a specific timeframe. It has been developed in python for small-scale implementations and C++ for fast, large-scale simulations. PyEpiabm design is modular, with many options to configure specific requirements.

## Summary of Epiabm functionality

### Basic Architecture
To model an epidemic, contact events are represented by the population spatial structure. The transmission of the disease and its progression within host is represented by a compartment model. These two architectures are highly configurable; this allows us to study a wide range of simulation scenarios.

<div style="display: flex; gap: 20px;">
  <div style="flex: 1;">
    <img src="./images/population_spatial_structure.png" alt="Population spatial structure" width="100%">
    <p>The environment is modelled using <a href="https://github.com/SABS-R3-Epidemiology/EpiGeoPop">EpiGeoPop</a>, which takes a region of interest, creates layers of sub-regions of different types and populates these with individuals.</p>
  </div>
  <div style="flex: 1;">
    <img src="./images/infection_progression.jpg" alt="Infection progression" width="100%">
    <p>The infection progression is represented using a <a href="https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology">compartment model</a> which tracks the daily progress of the disease within an individual.</p>
  </div>
</div>

## Running a simulation
The overview below describes the  user-input needed to run a basic simulation, using default values for parameters for other options. There is a comprehensive jupyter notebook showing a detailed, more complex example here (ADD LINK).

### Step 1: Use EpiGeoPop to generate the population spatial structure
A user selects a region of interest eg. Oxford or UK, which is split into ‘cells’. These cells are split into ‘microcells’, which are subsequently split into  a quantity of ‘households’ and ‘places’ based on probabilistic distributions. ‘Places’ are spaces where individuals might meet other individuals from different households, a workplace or a public park for example. Movement around the spatial structure is modelled within the simulation.

The individuals are extracted for the region using Census data. These individuals populate the microcells, ready to be assigned within the simulation to ’households’  and possible ‘places’. 

In summary, at the end of this step, we have a spatial structure with details on the number of cells and microcells. Within each microcell, we know the number of households, places, and the number of individuals. This is exported as a csv file, noting the file location and name.

### Step 2: Configure the simulation
The following parameters are essential to run a simulation:
Name of the path to the file from EpiGeoPop
Number of infected individuals (Imild): enter the number of infected individuals at the start of the simulation.
Number of individuals per household (this should match the census household distribution for your region)
Time for the simulation to run (in days)
Select output options

There are many further optional parameters which are described in detail here: (link to wiki)
Possible adjustments:
Infected individuals are distributed across all cells, you may want to put them in one cell
Maximum infection radius: this sets a maximum distance for the infection to be able to spread from cell to cell
Age

### Step 3: Run the simulation
Once configured, the simulation takes the generated population and performs the following  ‘sweeps’:

**Initialisation sweeps:**
* InitialHouseholdSweep - Assign individuals to households
* InitialisePlaceSweep - Assign individuals to places
* InitialInfectedSweep - Assign which individuals are initially infected

There are optional modules such as recording demographics, which are described in detail here (ADD link to wiki).

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
A simulation produces a few standard graphs and a comprehensive range of data csv files. These data files can be used to produce plots for further analysis.

Default output file:
Infection status (S, E, I<sub>mild</sub>, etc) for each day by cell

Further optional files are available, details described here (ADD link to wiki) or see jupyter notebook with a detailed illustration here (ADD LINK)

