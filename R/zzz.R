# Environment setup and management functions for R package
local <- new.env()

# One place to control the env name + Python version
.PY_ENV_NAME <- getOption("mypkg.python.env", "r-py-env")
.PY_VERSION  <- getOption("mypkg.python.version", "3.9")

#' Create and configure Python environment
#' Only creates a new env if it does not exist; otherwise just uses it.
#' @keywords internal
create_python_env <- function(
    env_name = .PY_ENV_NAME,
    python_version = .PY_VERSION) {
  tryCatch({
    if (!reticulate::virtualenv_exists(env_name)) {
      message(sprintf("Creating new Python virtual environment: %s", env_name))
      reticulate::virtualenv_create(
        envname = env_name,
        version = python_version,
        packages = "pip",
        system_site_packages = TRUE
      )
    }
    reticulate::use_virtualenv(env_name, required = TRUE)
    TRUE
  }, error = function(e) {
    warning(sprintf("Failed to create/activate Python environment: %s", e$message))
    FALSE
  })
}

.onLoad <- function(libname, pkgname) {
  env_success <- create_python_env(env_name = .PY_ENV_NAME, python_version = .PY_VERSION)
  if (!env_success) {
    warning("Failed to set up Python environment. Some functionality may be limited.")
    return()
  }

  reticulate::configure_environment(pkgname)
  ensure_python_dependencies()

  tryCatch({
    load_python_modules()
  }, error = function(e) {
    warning(sprintf(
      "Error loading Python dependencies: %s\nPlease run check_python_env() to diagnose issues.",
      e$message
    ))
  })
}

#' Ensure all required Python dependencies are installed
#' @keywords internal
ensure_python_dependencies <- function() {
  # Keep installs minimal; avoid upgrades unless asked to
  reticulate::py_install("pip", pip = TRUE, pip_ignore_installed = FALSE, upgrade = FALSE)

  core_pkgs <- c("numpy", "pandas", "matplotlib")
  # Install only if missing
  missing_core <- core_pkgs[!vapply(core_pkgs, reticulate::py_module_available, logical(1))]
  if (length(missing_core)) {
    reticulate::py_install(missing_core, pip = TRUE, pip_ignore_installed = FALSE, upgrade = FALSE)
  }

  # pyEpiabm from GitHub — install only if missing
  if (!reticulate::py_module_available("pyEpiabm")) {
    reticulate::py_install(
      packages = "git+https://github.com/SABS-R3-Epidemiology/epiabm.git@main#egg=pyEpiabm&subdirectory=pyEpiabm",
      pip = TRUE,
      pip_ignore_installed = FALSE,
      upgrade = FALSE
    )
  }

  required <- c(core_pkgs, "pyEpiabm")
  available <- vapply(required, reticulate::py_module_available, logical(1))
  if (!all(available)) {
    stop("Failed to install required packages: ", paste(required[!available], collapse = ", "))
  }
  message("All required packages installed successfully")
}

#' Load Python modules into package environment
#' @keywords internal
load_python_modules <- function() {
  modules <- list(
    os      = "os",
    logging = "logging",
    np      = "numpy",
    pd      = "pandas",
    plt     = "matplotlib.pyplot",
    pe      = "pyEpiabm"
  )

  imported <- mapply(
    function(var_name, module_name) {
      tryCatch(
        reticulate::import(module_name, delay_load = TRUE),
        error = function(e) {
          warning(sprintf("Failed to load module %s: %s", module_name, e$message))
          NULL
        }
      )
    },
    names(modules),
    unname(unlist(modules)),
    SIMPLIFY = FALSE, USE.NAMES = TRUE
  )

  imported <- imported[!vapply(imported, is.null, logical(1))]
  if (length(imported)) list2env(imported, envir = parent.env(local))
}

#' Check Python environment and package availability
#' @export
check_python_env <- function() {
  python_config <- reticulate::py_config()

  cat(sprintf("Python version: %s\n", reticulate::py_version()))
  cat(sprintf("Python path: %s\n", python_config$python))
  cat(sprintf("virtualenv: %s\n",
              if (is.null(python_config$virtualenv)) "None" else python_config$virtualenv))

  required <- c("numpy", "pandas", "matplotlib", "pyEpiabm")
  cat("\nPackage Status:\n")

  available <- vapply(required, reticulate::py_module_available, logical(1))

  pkgs_df <- reticulate::py_list_packages()
  names(pkgs_df) <- tolower(names(pkgs_df))
  versions <- setNames(pkgs_df$version, pkgs_df$package)

  lines <- ifelse(
    available,
    paste0("✓ ", required, " (version ",
           ifelse(is.na(versions[required]), "unknown", versions[required]), ")"),
    paste0("✗ ", required, " is not available")
  )
  cat(paste(lines, collapse = "\n"), "\n")

  invisible(all(available))
}

#' Initialize or repair Python environment
#' @param force Logical. If TRUE, recreates the environment even if it exists
#' @export
initialize_python_env <- function(force = FALSE) {
  env_name <- .PY_ENV_NAME

  if (force && reticulate::virtualenv_exists(env_name)) {
    message("Removing existing Python environment...")
    reticulate::virtualenv_remove(env_name)
  }

  if (create_python_env(env_name = env_name, python_version = .PY_VERSION)) {
    message("Python environment successfully created/activated")
    ensure_python_dependencies()
    check_python_env()
  } else {
    stop("Failed to initialize Python environment")
  }
}
