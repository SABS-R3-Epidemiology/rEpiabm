#
# Example simulation script with data output
#

library(reticulate)
use_virtualenv("../../repiabm_env")

os <- import("os")
logging <- import("logging")
pd <- import("pandas")
plt <- import("matplotlib.pyplot")

pe <- import("pyEpiabm")

# Set config file for Parameters
pe$Parameters$set_file("data/simple_parameters.json")
