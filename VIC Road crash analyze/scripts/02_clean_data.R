# ============================================================================
# Script 02: Data Cleaning and Preparation
# ============================================================================
# Purpose: Clean and prepare data for analysis
# Input: Raw RDS files from output/data/
# Output: Cleaned master dataset
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Data Cleaning\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(data.table)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

output_dir <- "output/data"

cat("Working directory:", getwd(), "\n\n")

cat("============================================================================\n")
cat("Loading Raw Data...\n")
cat("============================================================================\n\n")

accident <- readRDS(file.path(output_dir, "accident_raw.rds"))
cat("✓ Loaded accident data:", nrow(accident), "rows\n")

accident_location <- readRDS(file.path(output_dir, "accident_location_raw.rds"))
cat("✓ Loaded location data:", nrow(accident_location), "rows\n")

node <- readRDS(file.path(output_dir, "node_raw.rds"))
cat("✓ Loaded node data:", nrow(node), "rows\n")

atmospheric_cond <- readRDS(file.path(output_dir, "atmospheric_cond_raw.rds"))
cat("✓ Loaded atmospheric data:", nrow(atmospheric_cond), "rows\n")

road_surface_cond <- readRDS(file.path(output_dir, "road_surface_cond_raw.rds"))
cat("✓ Loaded road surface data:", nrow(road_surface_cond), "rows\n")

vehicle <- readRDS(file.path(output_dir, "vehicle_raw.rds"))
cat("✓ Loaded vehicle data:", nrow(vehicle), "rows\n")

person <- readRDS(file.path(output_dir, "person_raw.rds"))
cat("✓ Loaded person data:", nrow(person), "rows\n")

cat("\n")


cat("============================================================================\n")
cat("Cleaning Accident Data...\n")
cat("============================================================================\n\n")

# Convert to data.table for faster operations
accident_dt <- as.data.table(accident)

# Parse dates and times
cat("Parsing dates and times...\n")

# Handle different date formats
accident_dt[, ACCIDENT_DATE_PARSED := as.Date(ACCIDENT_DATE, format = "%d/%m/%Y")]

# If first format fails, try alternative
if(sum(is.na(accident_dt$ACCIDENT_DATE_PARSED)) > nrow(accident_dt) * 0.5) {
  accident_dt[, ACCIDENT_DATE_PARSED := as.Date(ACCIDENT_DATE)]
}

cat("  ✓ Dates parsed:", sum(!is.na(accident_dt$ACCIDENT_DATE_PARSED)), "valid dates\n")

# Parse time
accident_dt[, ACCIDENT_TIME_PARSED := substr(ACCIDENT_TIME, 1, 5)]  # Get HH:MM

# Extract temporal features
cat("Extracting temporal features...\n")

accident_dt[, `:=`(
  year = year(ACCIDENT_DATE_PARSED),
  month = month(ACCIDENT_DATE_PARSED),
  day = day(ACCIDENT_DATE_PARSED),
  day_of_week_num = wday(ACCIDENT_DATE_PARSED),
  day_of_week = factor(weekdays(ACCIDENT_DATE_PARSED), 
                       levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")),
  week_of_year = week(ACCIDENT_DATE_PARSED)
)]

# Extract hour from time
accident_dt[, hour := as.integer(substr(ACCIDENT_TIME_PARSED, 1, 2))]

# Create time periods
accident_dt[, time_period := fcase(
  hour >= 6 & hour < 9, "Morning Rush (6-9AM)",
  hour >= 9 & hour < 12, "Morning (9AM-12PM)",
  hour >= 12 & hour < 15, "Afternoon (12-3PM)",
  hour >= 15 & hour < 18, "Evening Rush (3-6PM)",
  hour >= 18 & hour < 21, "Evening (6-9PM)",
  hour >= 21 | hour < 6, "Night (9PM-6AM)",
  default = "Unknown"
)]

# Weekend flag
accident_dt[, is_weekend := ifelse(day_of_week_num %in% c(1, 7), 1, 0)]

# Season (Southern Hemisphere)
accident_dt[, season := fcase(
  month %in% c(12, 1, 2), "Summer",
  month %in% c(3, 4, 5), "Autumn",
  month %in% c(6, 7, 8), "Winter",
  month %in% c(9, 10, 11), "Spring",
  default = "Unknown"
)]

cat("  ✓ Temporal features extracted\n\n")

# Calculate severity score
cat("Calculating severity scores...\n")

# Handle missing values
accident_dt[is.na(NO_PERSONS_KILLED), NO_PERSONS_KILLED := 0]
accident_dt[is.na(NO_PERSONS_INJ_2), NO_PERSONS_INJ_2 := 0]
accident_dt[is.na(NO_PERSONS_INJ_3), NO_PERSONS_INJ_3 := 0]

# Severity score: Killed x 10 + Serious injury x 2 + Other injury x 1
accident_dt[, severity_score := (NO_PERSONS_KILLED * 10) +
                                  (NO_PERSONS_INJ_2 * 2) +
                                  (NO_PERSONS_INJ_3 * 1)]

# Severity category
accident_dt[, severity_category := fcase(
  NO_PERSONS_KILLED > 0, "Fatal",
  NO_PERSONS_INJ_2 > 0, "Serious Injury",
  NO_PERSONS_INJ_3 > 0, "Other Injury",
  default = "Non-Injury"
)]

cat("  ✓ Severity scores calculated\n")
cat("  Severity distribution:\n")
print(accident_dt[, .N, by = severity_category][order(-N)])
cat("\n")


cat("============================================================================\n")
cat("Joining with Location Data...\n")
cat("============================================================================\n\n")

# Join accident with location
accident_location_dt <- as.data.table(accident_location)

accident_full <- merge(
  accident_dt,
  accident_location_dt,
  by = "ACCIDENT_NO",
  all.x = TRUE
)

cat("✓ Joined accident with location:", nrow(accident_full), "rows\n")

# Join with node for coordinates
node_dt <- as.data.table(node)

# Select key columns from node
if("LATITUDE" %in% colnames(node_dt) && "LONGITUDE" %in% colnames(node_dt)) {
  node_coords <- node_dt[, .(ACCIDENT_NO, LATITUDE, LONGITUDE)]

  accident_full <- merge(
    accident_full,
    node_coords,
    by = "ACCIDENT_NO",
    all.x = TRUE
  )

  cat("✓ Joined with node coordinates\n")
  cat("  Records with coordinates:", sum(!is.na(accident_full$LATITUDE)), "\n")
} else {
  cat("⚠ WARNING: LATITUDE/LONGITUDE not found in node data\n")
  cat("  Available columns:", paste(colnames(node_dt)[1:min(10, ncol(node_dt))], collapse=", "), "\n")
}

cat("\n")


cat("============================================================================\n")
cat("Joining with Atmospheric Conditions...\n")
cat("============================================================================\n\n")

atmospheric_dt <- as.data.table(atmospheric_cond)

if("ATMOSPH_COND" %in% colnames(atmospheric_dt)) {
  atmospheric_simple <- atmospheric_dt[, .(ACCIDENT_NO, ATMOSPH_COND)]

  accident_full <- merge(
    accident_full,
    atmospheric_simple,
    by = "ACCIDENT_NO",
    all.x = TRUE
  )

  cat("✓ Joined atmospheric conditions\n")
}


cat("============================================================================\n")
cat("Joining with Road Surface Conditions...\n")
cat("============================================================================\n\n")

road_surface_dt <- as.data.table(road_surface_cond)

if("SURFACE_COND" %in% colnames(road_surface_dt)) {
  road_surface_simple <- road_surface_dt[, .(ACCIDENT_NO, SURFACE_COND)]

  accident_full <- merge(
    accident_full,
    road_surface_simple,
    by = "ACCIDENT_NO",
    all.x = TRUE
  )

  cat("✓ Joined road surface conditions\n")
}

cat("\n")


cat("============================================================================\n")
cat("Data Quality Checks...\n")
cat("============================================================================\n\n")

# Check missing values in key columns
key_cols <- c("ACCIDENT_NO", "ACCIDENT_DATE_PARSED", "LATITUDE", "LONGITUDE", "severity_score")

cat("Missing values in key columns:\n")
for(col in key_cols) {
  if(col %in% colnames(accident_full)) {
    missing_count <- sum(is.na(accident_full[[col]]))
    missing_pct <- (missing_count / nrow(accident_full)) * 100
    cat(sprintf("  %-25s: %6d (%.1f%%)\n", col, missing_count, missing_pct))
  }
}

cat("\n")

# Date range
cat("Date range:\n")
cat("  Earliest:", as.character(min(accident_full$ACCIDENT_DATE_PARSED, na.rm = TRUE)), "\n")
cat("  Latest:", as.character(max(accident_full$ACCIDENT_DATE_PARSED, na.rm = TRUE)), "\n")
cat("\n")

# Coordinate ranges (Victoria boundaries approximately)
if("LATITUDE" %in% colnames(accident_full)) {
  cat("Coordinate ranges:\n")
  cat("  Latitude: ", round(min(accident_full$LATITUDE, na.rm = TRUE), 4),
      "to", round(max(accident_full$LATITUDE, na.rm = TRUE), 4), "\n")
  cat("  Longitude:", round(min(accident_full$LONGITUDE, na.rm = TRUE), 4),
      "to", round(max(accident_full$LONGITUDE, na.rm = TRUE), 4), "\n")

  # Flag outliers (coordinates outside Victoria)
  vic_lat_min <- -39.5
  vic_lat_max <- -34.0
  vic_lon_min <- 140.0
  vic_lon_max <- 150.0

  outliers <- accident_full[
    !is.na(LATITUDE) & !is.na(LONGITUDE) & (
      LATITUDE < vic_lat_min | LATITUDE > vic_lat_max |
      LONGITUDE < vic_lon_min | LONGITUDE > vic_lon_max
    )
  ]

  if(nrow(outliers) > 0) {
    cat("  ⚠ WARNING:", nrow(outliers), "records with coordinates outside Victoria\n")
  } else {
    cat("  ✓ All coordinates within Victoria boundaries\n")
  }
}

cat("\n")


cat("============================================================================\n")
cat("Filtering Valid Records...\n")
cat("============================================================================\n\n")

# Keep records with valid date, coordinates, and severity
crashes_clean <- accident_full[
  !is.na(ACCIDENT_DATE_PARSED) &
  !is.na(LATITUDE) &
  !is.na(LONGITUDE) &
  !is.na(severity_score) &
  LATITUDE > vic_lat_min & LATITUDE < vic_lat_max &
  LONGITUDE > vic_lon_min & LONGITUDE < vic_lon_max
]

cat("Records before filtering:", nrow(accident_full), "\n")
cat("Records after filtering:", nrow(crashes_clean), "\n")
cat("Removed:", nrow(accident_full) - nrow(crashes_clean), "records\n")
cat("Retention rate:", round((nrow(crashes_clean) / nrow(accident_full)) * 100, 1), "%\n\n")


cat("============================================================================\n")
cat("Normalizing Coordinates for Spatial Analysis...\n")
cat("============================================================================\n\n")

# Check for duplicate coordinates
coord_counts <- crashes_clean[, .N, by = .(LATITUDE, LONGITUDE)][order(-N)]
cat("Coordinate Analysis:\n")
cat("  Total unique coordinate pairs:", nrow(coord_counts), "\n")
cat("  Max crashes at single coordinate:", coord_counts$N[1], "\n")
cat("  Coordinates with 10+ crashes:", sum(coord_counts$N >= 10), "\n")
cat("  Coordinates with 50+ crashes:", sum(coord_counts$N >= 50), "\n\n")

# Display top 10 most frequent coordinates
cat("Top 10 most frequent exact coordinates:\n")
print(coord_counts[1:10])
cat("\n")

# Strategy: Create multiple normalized coordinate columns for different analysis scales
# 1 decimal = ~11km, 2 decimals = ~1.1km, 3 decimals = ~110m, 4 decimals = ~11m

cat("Creating gridded coordinates at multiple scales...\n")

# Fine grid: 0.001 degrees (~110 meters) - for detailed local analysis
crashes_clean[, `:=`(
  lat_grid_fine = round(LATITUDE, 3),
  lon_grid_fine = round(LONGITUDE, 3)
)]

# Medium grid: 0.005 degrees (~550 meters) - for neighborhood analysis
crashes_clean[, `:=`(
  lat_grid_medium = round(LATITUDE / 0.005) * 0.005,
  lon_grid_medium = round(LONGITUDE / 0.005) * 0.005
)]

# Coarse grid: 0.01 degrees (~1.1 km) - for regional analysis
crashes_clean[, `:=`(
  lat_grid_coarse = round(LATITUDE, 2),
  lon_grid_coarse = round(LONGITUDE, 2)
)]

# Add small random jitter to exact duplicates to prevent perfect overlap
# This helps visualization and some clustering algorithms
set.seed(42)  # For reproducibility
crashes_clean[, `:=`(
  lat_jittered = LATITUDE + runif(.N, -0.0001, 0.0001),  # ~10m jitter
  lon_jittered = LONGITUDE + runif(.N, -0.0001, 0.0001)
)]

# Calculate grid statistics
cat("\nGrid Statistics:\n")
cat("  Fine grid (110m):\n")
cat("    Unique cells:", uniqueN(crashes_clean[, .(lat_grid_fine, lon_grid_fine)]), "\n")
cat("    Avg crashes per cell:",
    round(nrow(crashes_clean) / uniqueN(crashes_clean[, .(lat_grid_fine, lon_grid_fine)]), 2), "\n")

cat("  Medium grid (550m):\n")
cat("    Unique cells:", uniqueN(crashes_clean[, .(lat_grid_medium, lon_grid_medium)]), "\n")
cat("    Avg crashes per cell:",
    round(nrow(crashes_clean) / uniqueN(crashes_clean[, .(lat_grid_medium, lon_grid_medium)]), 2), "\n")

cat("  Coarse grid (1.1km):\n")
cat("    Unique cells:", uniqueN(crashes_clean[, .(lat_grid_coarse, lon_grid_coarse)]), "\n")
cat("    Avg crashes per cell:",
    round(nrow(crashes_clean) / uniqueN(crashes_clean[, .(lat_grid_coarse, lon_grid_coarse)]), 2), "\n\n")

# Create a grid-based summary for hotspot analysis
cat("Creating grid-based crash summaries...\n")

# Medium grid summary (recommended for hotspot analysis)
grid_summary <- crashes_clean[, .(
  n_crashes = .N,
  n_fatalities = sum(NO_PERSONS_KILLED),
  n_serious_injuries = sum(NO_PERSONS_INJ_2),
  n_other_injuries = sum(NO_PERSONS_INJ_3),
  total_severity = sum(severity_score),
  avg_severity = mean(severity_score),
  center_lat = mean(LATITUDE),
  center_lon = mean(LONGITUDE),
  min_year = min(year),
  max_year = max(year),
  most_common_type = names(sort(table(ACCIDENT_TYPE), decreasing = TRUE))[1]
), by = .(lat_grid_medium, lon_grid_medium)][order(-total_severity)]

# Add rank
grid_summary[, rank := .I]

cat("  ✓ Created grid summary with", nrow(grid_summary), "cells\n")
cat("  Top grid cell has", grid_summary$n_crashes[1], "crashes\n")

# Save grid summary
fwrite(grid_summary, file.path(output_dir, "grid_summary_550m.csv"))
cat("  ✓ Saved: grid_summary_550m.csv\n\n")

cat("✓ Coordinate normalization complete!\n")
cat("  Added columns: lat/lon_grid_fine, lat/lon_grid_medium, lat/lon_grid_coarse\n")
cat("  Added columns: lat/lon_jittered (for visualization)\n\n")


cat("============================================================================\n")
cat("Saving Cleaned Data...\n")
cat("============================================================================\n\n")

# Save as RDS
saveRDS(crashes_clean, file.path(output_dir, "crashes_cleaned.rds"))
cat("✓ Saved: crashes_cleaned.rds\n")

# Save as CSV for easy viewing
fwrite(crashes_clean, file.path(output_dir, "crashes_cleaned.csv"))
cat("✓ Saved: crashes_cleaned.csv\n")

# Save summary statistics
summary_stats <- list(
  total_records = nrow(crashes_clean),
  date_range = c(
    min = as.character(min(crashes_clean$ACCIDENT_DATE_PARSED)),
    max = as.character(max(crashes_clean$ACCIDENT_DATE_PARSED))
  ),
  total_fatalities = sum(crashes_clean$NO_PERSONS_KILLED),
  total_serious_injuries = sum(crashes_clean$NO_PERSONS_INJ_2),
  total_other_injuries = sum(crashes_clean$NO_PERSONS_INJ_3),
  severity_distribution = table(crashes_clean$severity_category)
)

saveRDS(summary_stats, file.path(output_dir, "summary_stats.rds"))
cat("✓ Saved: summary_stats.rds\n\n")


cat("============================================================================\n")
cat("Cleaned Data Summary\n")
cat("============================================================================\n\n")

cat("Total crashes:", format(nrow(crashes_clean), big.mark=","), "\n")
cat("Date range:", summary_stats$date_range["min"], "to", summary_stats$date_range["max"], "\n")
cat("Total fatalities:", format(summary_stats$total_fatalities, big.mark=","), "\n")
cat("Total serious injuries:", format(summary_stats$total_serious_injuries, big.mark=","), "\n")
cat("Total other injuries:", format(summary_stats$total_other_injuries, big.mark=","), "\n\n")

cat("Top 5 columns in cleaned dataset:\n")
print(head(crashes_clean[, .(ACCIDENT_NO, ACCIDENT_DATE_PARSED, LATITUDE, LONGITUDE,
                              severity_score, severity_category, ACCIDENT_TYPE)], 5))

cat("\n============================================================================\n")
cat("Data Cleaning Complete!\n")
cat("============================================================================\n\n")
