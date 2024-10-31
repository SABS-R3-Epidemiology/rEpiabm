# In zzz.R
local <- new.env()

.onLoad <- function(libname, pkgname) {
  # Configure reticulate to use any available Python
  reticulate::configure_environment(pkgname)
  
  # The required Python packages will be installed automatically based on 
  # Config/reticulate in DESCRIPTION if they're not found
  
  # Import dependencies with error handling
  tryCatch({
    os <- reticulate::import("os", delay_load = TRUE)
    logging <- reticulate::import("logging", delay_load = TRUE)
    pd <- reticulate::import("pandas", delay_load = TRUE)
    plt <- reticulate::import("matplotlib.pyplot", delay_load = TRUE)
    pe <- reticulate::import("pyEpiabm", delay_load = TRUE)
    
    # Assign to package environment
    assign("os", os, envir = parent.env(local))
    assign("logging", logging, envir = parent.env(local))
    assign("pd", pd, envir = parent.env(local))
    assign("plt", plt, envir = parent.env(local))
    assign("pe", pe, envir = parent.env(local))
    
  }, error = function(e) {
    warning(sprintf("Error loading Python dependencies: %s\nPlease ensure Python is installed and accessible.", e$message))
  })
}

# Function to verify Python environment
#' @export
check_python_env <- function() {
  python_path <- reticulate::py_config()$python
  
  cat(sprintf("Python version: %s\n", reticulate::py_version()))
  cat(sprintf("Python path: %s\n", python_path))
  
  required_packages <- c("os", "logging", "pandas", "matplotlib", "pyEpiabm")
  
  for (pkg in required_packages) {
    if (reticulate::py_module_available(pkg)) {
      cat(sprintf("✓ %s is available\n", pkg))
    } else {
      cat(sprintf("✗ %s is not available\n", pkg))
    }
  }
}