# ============================================================================
# R Package Requirements for Victorian Road Crash Analysis
# ============================================================================
# Project: Spatio-Temporal Hotspot Detection with Kafka Streaming
# Duration: 1 Week Implementation
# Last Updated: 2025-01-04
# ============================================================================

cat("Installing required R packages...\n")
cat("This may take 10-15 minutes depending on your system.\n\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# List of required packages
required_packages <- c(
  # ===== Data Manipulation =====
  "dplyr",          # Data manipulation (group_by, filter, mutate)
  "tidyr",          # Data tidying (pivot, separate, unite)
  "lubridate",      # Date/time handling
  "readr",          # Fast CSV reading
  "data.table",     # Fast data operations for large files

  # ===== Spatial Analysis =====
  "sf",             # Simple Features for spatial data
  "leaflet",        # Interactive maps
  "dbscan",         # DBSCAN clustering algorithm

  # ===== Visualization =====
  "ggplot2",        # Grammar of graphics plotting
  "plotly",         # Interactive plots
  "scales",         # Scale functions for visualization
  "viridis",        # Color palettes
  "RColorBrewer",   # Additional color palettes

  # ===== Dashboard =====
  "shiny",          # Interactive web applications
  "shinydashboard", # Dashboard layout for Shiny
  "DT",             # Interactive tables

  # ===== Kafka & JSON =====
  "jsonlite",       # JSON encoding/decoding

  # ===== Reporting =====
  "rmarkdown",      # R Markdown documents
  "knitr",          # Dynamic report generation

  # ===== Utilities =====
  "here",           # Path management
  "glue"            # String interpolation
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat(paste0("Installing ", pkg, "...\n"))
      install.packages(pkg, dependencies = TRUE)

      # Verify installation
      if (require(pkg, character.only = TRUE, quietly = TRUE)) {
        cat(paste0("  ✓ ", pkg, " installed successfully\n"))
      } else {
        cat(paste0("  ✗ ERROR: Failed to install ", pkg, "\n"))
      }
    } else {
      cat(paste0("  ✓ ", pkg, " already installed\n"))
    }
  }
}

# Install all required packages
install_if_missing(required_packages)

cat("\n============================================================================\n")
cat("Package installation complete!\n")
cat("============================================================================\n\n")

# Load all packages to verify
cat("Verifying package loading...\n")
success <- TRUE

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste0("  ✗ ERROR: Cannot load ", pkg, "\n"))
    success <- FALSE
  }
}

if (success) {
  cat("\n✓ All packages loaded successfully!\n")
  cat("\nYou are ready to start the analysis.\n")
} else {
  cat("\n✗ Some packages failed to load. Please check the errors above.\n")
}

cat("\n============================================================================\n")
cat("Installed Package Versions:\n")
cat("============================================================================\n")

# Print versions
for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    version <- packageVersion(pkg)
    cat(sprintf("%-20s %s\n", pkg, version))
  }
}

cat("\n============================================================================\n")
cat("R Session Info:\n")
cat("============================================================================\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Platform: %s\n", R.version$platform))
cat("\n")

cat("============================================================================\n")
cat("Next Steps:\n")
cat("============================================================================\n")
cat("1. Install Apache Kafka: Run scripts in kafka_setup/\n")
cat("2. Load data: source('scripts/01_load_data.R')\n")
cat("3. Clean data: source('scripts/02_clean_data.R')\n")
cat("4. Run analysis: source('scripts/03_eda.R')\n")
cat("============================================================================\n")
