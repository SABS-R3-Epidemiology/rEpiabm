# Environment setup and management functions for R package
local <- new.env()

#' Create and configure Python environment
#' @param env_name Character. Name of the virtual environment to create
#' @param python_version Character. Python version to use (e.g., "3.8")
#' @return Logical indicating success
#' @keywords internal
create_python_env <- function(
    env_name = "r-reticulate",
    python_version = "3.9") {
  tryCatch({
    # Check if virtualenv package is available
    if (!reticulate::virtualenv_exists(env_name)) {
      message(sprintf("Creating new Python virtual environment: %s", env_name))
      # Create virtual environment with system site packages to help with SSL
      reticulate::virtualenv_create(
        envname = env_name,
        version = python_version,
        packages = "pip",
        system_site_packages = TRUE
      )
    }
    # Activate the environment
    reticulate::use_virtualenv(env_name, required = TRUE)
    return(TRUE)
  }, error = function(e) {
    warning(sprintf("Failed to create/activate Python environment: %s",
                   e$message))
    return(FALSE)
  })
}

.onLoad <- function(libname, pkgname) {
  # Create and activate Python environment
  env_success <- create_python_env()
  if (!env_success) {
    warning("Failed to set up Python environment. 
    Some functionality may be limited.")
    return()
  }
  # Configure reticulate to use the package's environment
  reticulate::configure_environment(pkgname)
  # Install required packages if not present
  ensure_python_dependencies()
  # Import dependencies with error handling
  tryCatch({
    load_python_modules()
  }, error = function(e) {
    warning(sprintf(
      "Error loading Python dependencies: %s\nPlease 
      run check_python_env() to diagnose issues.",
      e$message
    ))
  })
}

#' Ensure all required Python dependencies are installed
#' @keywords internal
ensure_python_dependencies <- function() {
  # Upgrade pip
  reticulate::py_run_string("
import sys
import subprocess
subprocess.check_call([sys.executable
, '-m', 'pip', 'install', '--upgrade', 'pip'])
  ")
  # Install required packages
  reticulate::py_run_string("
import sys
import subprocess

# Install basic packages
packages = ['numpy', 'pandas', 'matplotlib']
for package in packages:
    subprocess.check_call([sys.executable, '-m', 'pip', 
    'install', '--upgrade', package])
# Install pyEpiabm from GitHub
subprocess.check_call([
    sys.executable, '-m', 'pip', 'install', '--upgrade',
    'git+https://github.com/SABS-R3-Epidemiology/
epiabm.git@main#egg=pyEpiabm&subdirectory=pyEpiabm'
])
  ")
  # Verify installations
  result <- reticulate::py_run_string("
import importlib.util

packages = ['numpy', 'pandas', 'matplotlib', 'pyEpiabm']
missing = []

for package in packages:
    if importlib.util.find_spec(package) is None:
        missing.append(package)
        
print('Missing packages:', missing if missing else 'None')
  ")
  if (length(result$missing) > 0) {
    stop("Failed to install required packages: ",
         paste(result$missing, collapse = ", "))
  }
  message("All required packages installed successfully")
}

#' Load Python modules into package environment
#' @keywords internal
load_python_modules <- function() {
  # Define modules to load
  modules <- list(
    os = "os",
    logging = "logging",
    pd = "pandas",
    plt = "matplotlib.pyplot",
    pe = "pyEpiabm"
  )
  # Import each module
  for (var_name in names(modules)) {
    module_name <- modules[[var_name]]
    tryCatch({
      module <- reticulate::import(module_name, delay_load = TRUE)
      assign(var_name, module, envir = parent.env(local))
    }, error = function(e) {
      warning(sprintf("Failed to load module %s: %s", module_name, e$message))
    })
  }
}

#' Check Python environment and package availability
#' @export
check_python_env <- function() {
  # Get Python configuration
  python_config <- reticulate::py_config()
  # Print Python information
  cat(sprintf("Python version: %s\n", reticulate::py_version()))
  cat(sprintf("Python path: %s\n", python_config$python))
  cat(sprintf("virtualenv: %s\n",
              if (is.null(python_config$virtualenv)) "None"
              else python_config$virtualenv))
  # Check required packages
  required_packages <- c("numpy", "pandas", "matplotlib", "pyEpiabm")
  cat("\nPackage Status:\n")
  pkg_status <- list()
  for (pkg in required_packages) {
    if (reticulate::py_module_available(pkg)) {
      # Try to get version information
      tryCatch({
        version <- reticulate::py_eval(
          sprintf("__import__('%s').__version__", pkg)
        )
        cat(sprintf("✓ %s (version %s)\n", pkg, version))
        pkg_status[[pkg]] <- TRUE
      }, error = function(e) {
        cat(sprintf("✓ %s (version unknown)\n", pkg))
        pkg_status[[pkg]] <- TRUE
      })
    } else {
      cat(sprintf("✗ %s is not available\n", pkg))
      pkg_status[[pkg]] <- FALSE
    }
  }
  # Return invisibly whether all packages are available
  invisible(all(unlist(pkg_status)))
}

#' Initialize or repair Python environment
#' @param force Logical. If TRUE, recreates the environment even if it exists
#' @export
initialize_python_env <- function(force = FALSE) {
  env_name <- "r-py-env"
  if (force && reticulate::virtualenv_exists(env_name)) {
    message("Removing existing Python environment...")
    reticulate::virtualenv_remove(env_name)
  }
  # Create and activate environment
  if (create_python_env(env_name)) {
    message("Python environment successfully created/activated")
    # Install dependencies
    ensure_python_dependencies()
    # Check environment
    check_python_env()
  } else {
    stop("Failed to initialize Python environment")
  }
}
