# ============================================================================
# Script 01: Data Loading
# ============================================================================
# Purpose: Load all Victorian road crash CSV files into R
# Input: Raw CSV files from data/ directory
# Output: Raw R data objects saved to output/data/
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Data Loading\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(readr)
  library(data.table)
  library(dplyr)
})

# Set working directory to project root
# (Adjust if running from different location)
if(basename(getwd()) == "scripts") {
  setwd("..")
}

cat("Working directory:", getwd(), "\n\n")

# ============================================================================
# Define file paths
# ============================================================================

data_dir <- "data"
output_dir <- "output/data"

# Create output directory if it doesn't exist
if(!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created output directory:", output_dir, "\n\n")
}

data_files <- list(
  accident = file.path(data_dir, "accident.csv"),
  accident_event = file.path(data_dir, "accident_event.csv"),
  accident_location = file.path(data_dir, "accident_location.csv"),
  atmospheric_cond = file.path(data_dir, "atmospheric_cond.csv"),
  node = file.path(data_dir, "node.csv"),
  person = file.path(data_dir, "person.csv"),
  road_surface_cond = file.path(data_dir, "road_surface_cond.csv"),
  sub_dca = file.path(data_dir, "sub_dca.csv"),
  vehicle = file.path(data_dir, "vehicle.csv")
)

# ============================================================================
# Function to load and validate CSV files
# ============================================================================

load_csv <- function(file_path, name) {
  cat("Loading", name, "...\n")

  if(!file.exists(file_path)) {
    cat("  ✗ ERROR: File not found:", file_path, "\n")
    return(NULL)
  }

  # Get file size
  file_size_mb <- file.info(file_path)$size / 1024^2

  cat("  File size:", round(file_size_mb, 2), "MB\n")

  # Use fread for fast loading of large files
  start_time <- Sys.time()

  tryCatch({
    data <- fread(file_path, stringsAsFactors = FALSE)

    end_time <- Sys.time()
    load_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat("  ✓ Loaded successfully in", round(load_time, 2), "seconds\n")
    cat("  Dimensions:", nrow(data), "rows ×", ncol(data), "columns\n")
    cat("  Columns:", paste(colnames(data)[1:min(5, ncol(data))], collapse=", "),
        ifelse(ncol(data) > 5, "...", ""), "\n\n")

    return(data)

  }, error = function(e) {
    cat("  ✗ ERROR loading file:", conditionMessage(e), "\n\n")
    return(NULL)
  })
}

# ============================================================================
# Load all data files
# ============================================================================

cat("============================================================================\n")
cat("Loading Data Files...\n")
cat("============================================================================\n\n")

# Load each file
accident <- load_csv(data_files$accident, "Accident Data")
accident_event <- load_csv(data_files$accident_event, "Accident Event Data")
accident_location <- load_csv(data_files$accident_location, "Accident Location Data")
atmospheric_cond <- load_csv(data_files$atmospheric_cond, "Atmospheric Condition Data")
node <- load_csv(data_files$node, "Node Data")
person <- load_csv(data_files$person, "Person Data")
road_surface_cond <- load_csv(data_files$road_surface_cond, "Road Surface Condition Data")
sub_dca <- load_csv(data_files$sub_dca, "Sub DCA Data")
vehicle <- load_csv(data_files$vehicle, "Vehicle Data")

# ============================================================================
# Data Validation
# ============================================================================

cat("============================================================================\n")
cat("Data Validation Summary\n")
cat("============================================================================\n\n")

# Check if primary datasets loaded successfully
if(is.null(accident)) {
  stop("ERROR: Failed to load accident.csv - this is the primary dataset!")
}

# Display summary
cat("Successfully loaded datasets:\n")
cat("  1. accident:           ", nrow(accident), "rows\n")
cat("  2. accident_event:     ", nrow(accident_event), "rows\n")
cat("  3. accident_location:  ", nrow(accident_location), "rows\n")
cat("  4. atmospheric_cond:   ", nrow(atmospheric_cond), "rows\n")
cat("  5. node:               ", nrow(node), "rows\n")
cat("  6. person:             ", nrow(person), "rows\n")
cat("  7. road_surface_cond:  ", nrow(road_surface_cond), "rows\n")
cat("  8. sub_dca:            ", nrow(sub_dca), "rows\n")
cat("  9. vehicle:            ", nrow(vehicle), "rows\n\n")

total_rows <- nrow(accident) + nrow(accident_event) + nrow(accident_location) +
              nrow(atmospheric_cond) + nrow(node) + nrow(person) +
              nrow(road_surface_cond) + nrow(sub_dca) + nrow(vehicle)

cat("Total records across all files:", format(total_rows, big.mark=","), "\n\n")

# ============================================================================
# Preview Data Structure
# ============================================================================

cat("============================================================================\n")
cat("Preview: Accident Data Structure\n")
cat("============================================================================\n\n")

cat("Column names and types:\n")
str(accident, list.len = 20)

cat("\n\nFirst 3 rows:\n")
print(head(accident, 3))

# ============================================================================
# Check for Key Columns
# ============================================================================

cat("\n============================================================================\n")
cat("Checking Key Columns\n")
cat("============================================================================\n\n")

# Check accident table
required_cols_accident <- c("ACCIDENT_NO", "ACCIDENT_DATE", "ACCIDENT_TIME")
missing_cols <- setdiff(required_cols_accident, colnames(accident))

if(length(missing_cols) > 0) {
  cat("⚠ WARNING: Missing columns in accident data:", paste(missing_cols, collapse=", "), "\n")
} else {
  cat("✓ All required columns present in accident data\n")
}

# Check for location data
if(!is.null(node) && "NODE_ID" %in% colnames(node)) {
  cat("✓ Node location data available\n")
}

# Check date range
if("ACCIDENT_DATE" %in% colnames(accident)) {
  # Try to parse dates
  date_sample <- head(accident$ACCIDENT_DATE, 100)
  cat("\nSample dates:", paste(head(date_sample, 3), collapse=", "), "\n")
}

cat("\n")

# ============================================================================
# Save Raw Data Objects
# ============================================================================

cat("============================================================================\n")
cat("Saving Raw Data Objects\n")
cat("============================================================================\n\n")

# Save as RDS (R binary format - faster to load)
saveRDS(accident, file.path(output_dir, "accident_raw.rds"))
cat("✓ Saved: accident_raw.rds\n")

saveRDS(accident_event, file.path(output_dir, "accident_event_raw.rds"))
cat("✓ Saved: accident_event_raw.rds\n")

saveRDS(accident_location, file.path(output_dir, "accident_location_raw.rds"))
cat("✓ Saved: accident_location_raw.rds\n")

saveRDS(atmospheric_cond, file.path(output_dir, "atmospheric_cond_raw.rds"))
cat("✓ Saved: atmospheric_cond_raw.rds\n")

saveRDS(node, file.path(output_dir, "node_raw.rds"))
cat("✓ Saved: node_raw.rds\n")

saveRDS(person, file.path(output_dir, "person_raw.rds"))
cat("✓ Saved: person_raw.rds\n")

saveRDS(road_surface_cond, file.path(output_dir, "road_surface_cond_raw.rds"))
cat("✓ Saved: road_surface_cond_raw.rds\n")

saveRDS(sub_dca, file.path(output_dir, "sub_dca_raw.rds"))
cat("✓ Saved: sub_dca_raw.rds\n")

saveRDS(vehicle, file.path(output_dir, "vehicle_raw.rds"))
cat("✓ Saved: vehicle_raw.rds\n")

cat("\n")

# ============================================================================
# Summary Statistics
# ============================================================================

cat("============================================================================\n")
cat("Quick Summary Statistics\n")
cat("============================================================================\n\n")

# Accident severity
if("NO_PERSONS_KILLED" %in% colnames(accident)) {
  total_fatalities <- sum(accident$NO_PERSONS_KILLED, na.rm = TRUE)
  cat("Total fatalities:", total_fatalities, "\n")
}

if("NO_PERSONS_INJ_2" %in% colnames(accident)) {
  total_serious_injuries <- sum(accident$NO_PERSONS_INJ_2, na.rm = TRUE)
  cat("Total serious injuries:", total_serious_injuries, "\n")
}

# Unique accidents
cat("Unique accidents:", length(unique(accident$ACCIDENT_NO)), "\n")

# Vehicle count
if(!is.null(vehicle)) {
  cat("Total vehicles involved:", nrow(vehicle), "\n")
}

# Person count
if(!is.null(person)) {
  cat("Total persons involved:", nrow(person), "\n")
}

cat("\n")

# ============================================================================
# Completion
# ============================================================================

cat("============================================================================\n")
cat("Data Loading Complete!\n")
cat("============================================================================\n\n")

cat("Next steps:\n")
cat("  1. Run data cleaning: source('scripts/02_clean_data.R')\n")
cat("  2. Explore data: source('scripts/03_eda.R')\n")
cat("\n")

cat("All raw data saved to:", output_dir, "\n")
cat("============================================================================\n")
