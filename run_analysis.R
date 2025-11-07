# ============================================================================
# Master Analysis Script
# ============================================================================
# This script runs the complete analysis pipeline
# Run this after installing packages with: source("requirements.R")
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("VICTORIAN ROAD CRASH ANALYSIS - MASTER SCRIPT\n")
cat("============================================================================\n")
cat("\n")
cat("This script will run the complete analysis pipeline:\n")
cat("  1. Load data from CSV files\n")
cat("  2. Clean and prepare data\n")
cat("  3. Exploratory data analysis\n")
cat("  4. Hotspot detection (DBSCAN)\n")
cat("  5. Temporal pattern analysis\n")
cat("\n")
cat("Note: Kafka streaming (scripts 06 and 07) must be run separately\n")
cat("============================================================================\n")
cat("\n")

# Ask for confirmation
response <- readline(prompt = "Continue? (y/n): ")

if(tolower(response) != "y") {
  cat("\nExiting. No analysis performed.\n")
  quit(save = "no")
}

# ============================================================================
# STEP 1: LOAD DATA
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("STEP 1/5: Loading Data\n")
cat("============================================================================\n")
cat("\n")

start_time_total <- Sys.time()
start_time_step <- Sys.time()

tryCatch({
  source("scripts/01_load_data.R")
  end_time_step <- Sys.time()
  step_time <- as.numeric(difftime(end_time_step, start_time_step, units = "secs"))
  cat("\n✓ Step 1 completed in", round(step_time, 2), "seconds\n")
}, error = function(e) {
  cat("\n✗ ERROR in Step 1:\n")
  cat(conditionMessage(e), "\n")
  cat("\nPlease check that all CSV files are in the data/ directory\n")
  quit(save = "no", status = 1)
})

# ============================================================================
# STEP 2: CLEAN DATA
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("STEP 2/5: Cleaning Data\n")
cat("============================================================================\n")
cat("\n")

start_time_step <- Sys.time()

tryCatch({
  source("scripts/02_clean_data.R")
  end_time_step <- Sys.time()
  step_time <- as.numeric(difftime(end_time_step, start_time_step, units = "secs"))
  cat("\n✓ Step 2 completed in", round(step_time, 2), "seconds\n")
}, error = function(e) {
  cat("\n✗ ERROR in Step 2:\n")
  cat(conditionMessage(e), "\n")
  quit(save = "no", status = 1)
})

# ============================================================================
# STEP 3: EXPLORATORY DATA ANALYSIS
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("STEP 3/5: Exploratory Data Analysis\n")
cat("============================================================================\n")
cat("\n")

start_time_step <- Sys.time()

tryCatch({
  source("scripts/03_eda.R")
  end_time_step <- Sys.time()
  step_time <- as.numeric(difftime(end_time_step, start_time_step, units = "secs"))
  cat("\n✓ Step 3 completed in", round(step_time, 2), "seconds\n")
}, error = function(e) {
  cat("\n✗ ERROR in Step 3:\n")
  cat(conditionMessage(e), "\n")
  quit(save = "no", status = 1)
})

# ============================================================================
# STEP 4: HOTSPOT DETECTION
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("STEP 4/5: Hotspot Detection (DBSCAN)\n")
cat("============================================================================\n")
cat("\n")

start_time_step <- Sys.time()

tryCatch({
  source("scripts/04_hotspots.R")
  end_time_step <- Sys.time()
  step_time <- as.numeric(difftime(end_time_step, start_time_step, units = "secs"))
  cat("\n✓ Step 4 completed in", round(step_time, 2), "seconds\n")
}, error = function(e) {
  cat("\n✗ ERROR in Step 4:\n")
  cat(conditionMessage(e), "\n")
  quit(save = "no", status = 1)
})

# ============================================================================
# STEP 5: TEMPORAL ANALYSIS
# ============================================================================

cat("\n")
cat("============================================================================\n")
cat("STEP 5/5: Temporal Pattern Analysis\n")
cat("============================================================================\n")
cat("\n")

start_time_step <- Sys.time()

tryCatch({
  source("scripts/05_temporal.R")
  end_time_step <- Sys.time()
  step_time <- as.numeric(difftime(end_time_step, start_time_step, units = "secs"))
  cat("\n✓ Step 5 completed in", round(step_time, 2), "seconds\n")
}, error = function(e) {
  cat("\n✗ ERROR in Step 5:\n")
  cat(conditionMessage(e), "\n")
  quit(save = "no", status = 1)
})

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

end_time_total <- Sys.time()
total_time <- as.numeric(difftime(end_time_total, start_time_total, units = "mins"))

cat("\n")
cat("============================================================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("============================================================================\n")
cat("\n")
cat("Total execution time:", round(total_time, 2), "minutes\n")
cat("\n")

cat("Generated Outputs:\n")
cat("------------------\n")
cat("Data Files:\n")
cat("  output/data/crashes_cleaned.rds\n")
cat("  output/data/hotspots_all.csv\n")
cat("  output/data/hotspots_top50.csv\n")
cat("  output/data/summary_*.csv\n")
cat("\n")

cat("Visualizations (", list.files("output/figures", pattern = "\\.png$") %>% length(), "plots ):\n")
cat("  output/figures/*.png\n")
cat("\n")

cat("Interactive Map:\n")
cat("  output/figures/interactive_hotspot_map.html\n")
cat("  (Open this file in a web browser)\n")
cat("\n")

cat("============================================================================\n")
cat("NEXT STEPS\n")
cat("============================================================================\n")
cat("\n")

cat("1. View Interactive Map:\n")
cat("   Open: output/figures/interactive_hotspot_map.html\n")
cat("\n")

cat("2. Launch Shiny Dashboard:\n")
cat("   library(shiny)\n")
cat("   runApp('shiny_app')\n")
cat("\n")

cat("3. Set up Kafka Streaming (Optional):\n")
cat("   a. Install Kafka:\n")
cat("      cd kafka_setup\n")
cat("      ./install_kafka_docker.sh\n")
cat("\n")
cat("   b. Start Producer (Terminal 1):\n")
cat("      Rscript scripts/06_kafka_producer.R\n")
cat("\n")
cat("   c. Start Consumer (Terminal 2):\n")
cat("      Rscript scripts/07_kafka_consumer.R\n")
cat("\n")

cat("4. View Results:\n")
cat("   - Cleaned data: output/data/\n")
cat("   - Visualizations: output/figures/\n")
cat("   - Summary statistics: output/data/summary_*.csv\n")
cat("\n")

cat("============================================================================\n")
cat("\n")

# Print file summary
cat("Generated Files Summary:\n")
cat("------------------------\n")

data_files <- list.files("output/data", full.names = FALSE)
cat("Data files (", length(data_files), "):\n")
for(f in head(data_files, 10)) {
  cat("  -", f, "\n")
}
if(length(data_files) > 10) {
  cat("  ... and", length(data_files) - 10, "more\n")
}
cat("\n")

figure_files <- list.files("output/figures", full.names = FALSE)
cat("Figure files (", length(figure_files), "):\n")
for(f in head(figure_files, 10)) {
  cat("  -", f, "\n")
}
if(length(figure_files) > 10) {
  cat("  ... and", length(figure_files) - 10, "more\n")
}
cat("\n")

cat("============================================================================\n")
cat("All Done! Your analysis is ready for review.\n")
cat("============================================================================\n")
cat("\n")
