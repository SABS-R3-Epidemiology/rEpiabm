# rEpiabm
rEpiabm enables users familiar with R to use Epiabm (ADD LINK). Epiabm is a simulation tool that models the progress of an epidemic across a specified region of interest within a specific timeframe. It has been developed in python for small-scale implementations and C++ for fast, large-scale simulations. PyEpiabm design is modular, with many options to configure specific requirements.

## Summary of Epiabm functionality

### Basic Architecture
To model an epidemic, contact events are represented by the population spatial structure. The transmission of the disease and its progression within host is represented by a compartment model. These two architectures are highly configurable; this allows us to study a wide range of simulation scenarios.

<div style="display: flex; gap: 20px;">
  <div style="flex: 1;">
    <img src="population_spatial_structure.png" alt="Population spatial structure" width="100%">
    <p>The environment is modelled using <a href="https://github.com/SABS-R3-Epidemiology/EpiGeoPop">EpiGeoPop</a>, which takes a region of interest, creates layers of sub-regions of different types and populates these with individuals.</p>
  </div>
  <div style="flex: 1;">
    <img src="infection_progression.png" alt="Infection progression" width="100%">
    <p>The infection progression is represented using a <a href="https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology">compartment model</a> which tracks the daily progress of the disease within an individual.</p>
  </div>
</div>
