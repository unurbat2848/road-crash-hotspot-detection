# ============================================================================
# Script 04: Crash Hotspot Detection using DBSCAN
# ============================================================================
# Purpose: Identify crash hotspots using spatial clustering
# Input: Cleaned data from output/data/crashes_cleaned.rds
# Output: Hotspot locations and interactive map
# ============================================================================
install.packages("dbscan")
install.packages("sf")
install.packages("leaflet") 
cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Hotspot Detection\n")
cat("============================================================================\n\n")

# Configuration: Choose hotspot detection method
# "dbscan" = Density-based clustering (default)
# "grid" = Grid-based analysis (faster, simpler)
# "both" = Run both methods
HOTSPOT_METHOD <- "both"

cat("Hotspot Detection Method:", HOTSPOT_METHOD, "\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(dbscan)
  library(sf)
  library(leaflet)
  library(data.table)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

output_dir <- "output/data"
figures_dir <- "output/figures"

cat("Working directory:", getwd(), "\n\n")

cat("============================================================================\n")
cat("Loading Cleaned Data...\n")
cat("============================================================================\n\n")

crashes <- readRDS(file.path(output_dir, "crashes_cleaned.rds"))
cat("✓ Loaded", format(nrow(crashes), big.mark=","), "crash records\n")

# Convert to data.table
crashes_dt <- as.data.table(crashes)

# Filter records with valid coordinates
crashes_spatial <- crashes_dt[!is.na(LATITUDE) & !is.na(LONGITUDE)]
cat("✓ Records with coordinates:", format(nrow(crashes_spatial), big.mark=","), "\n\n")



cat("============================================================================\n")
cat("Preparing Spatial Data...\n")
cat("============================================================================\n\n")

# Check if normalized coordinates exist
has_normalized <- all(c("lat_jittered", "lon_jittered") %in% colnames(crashes_spatial))

if(has_normalized) {
  cat("✓ Using jittered coordinates to prevent exact duplicates\n")
  cat("  (Original coordinates had",
      nrow(crashes_spatial[, .N, by = .(LATITUDE, LONGITUDE)][N > 1]),
      "duplicate locations)\n\n")

  # Use jittered coordinates for better clustering
  coords <- as.matrix(crashes_spatial[, .(lon_jittered, lat_jittered)])
} else {
  cat("⚠ Using original coordinates (consider running 02_clean_data.R with normalization)\n\n")
  coords <- as.matrix(crashes_spatial[, .(LONGITUDE, LATITUDE)])
}

cat("Coordinate ranges:\n")
cat("  Latitude: ", round(min(coords[,2]), 4), "to", round(max(coords[,2]), 4), "\n")
cat("  Longitude:", round(min(coords[,1]), 4), "to", round(max(coords[,1]), 4), "\n\n")

# Check for duplicate coordinates
coord_duplicates <- crashes_spatial[, .N, by = .(round(coords[,1], 6), round(coords[,2], 6))][N > 1]
if(nrow(coord_duplicates) > 0) {
  cat("Note: Found", nrow(coord_duplicates), "locations with multiple crashes\n")
  cat("      Max crashes at one location:", max(coord_duplicates$N), "\n\n")
}

# ============================================================================
# OPTION 1: Grid-Based Hotspot Analysis
# ============================================================================

if(HOTSPOT_METHOD %in% c("grid", "both")) {
  cat("============================================================================\n")
  cat("Grid-Based Hotspot Analysis\n")
  cat("============================================================================\n\n")

  # Check if grid columns exist
  has_grid <- all(c("lat_grid_medium", "lon_grid_medium") %in% colnames(crashes_spatial))

  if(has_grid) {
    cat("Using 550m grid cells for analysis\n\n")

    # Create grid-based hotspots
    grid_hotspots <- crashes_spatial[, .(
      n_crashes = .N,
      n_fatalities = sum(NO_PERSONS_KILLED),
      n_serious_injuries = sum(NO_PERSONS_INJ_2),
      n_other_injuries = sum(NO_PERSONS_INJ_3),
      total_severity = sum(severity_score),
      avg_severity = mean(severity_score),
      center_lat = mean(LATITUDE),
      center_lon = mean(LONGITUDE),
      min_year = min(year, na.rm = TRUE),
      max_year = max(year, na.rm = TRUE)
    ), by = .(lat_grid_medium, lon_grid_medium)][order(-total_severity)]

    # Filter to significant hotspots (10+ crashes)
    grid_hotspots <- grid_hotspots[n_crashes >= 10]
    grid_hotspots[, rank := .I]

    cat("Grid Analysis Results:\n")
    cat("  Grid cells with 10+ crashes:", nrow(grid_hotspots), "\n")
    cat("  Total crashes in hotspots:", sum(grid_hotspots$n_crashes), "\n")
    cat("  Top hotspot has", max(grid_hotspots$n_crashes), "crashes\n\n")

    # Save grid-based hotspots
    fwrite(grid_hotspots, file.path(output_dir, "hotspots_grid_based.csv"))
    cat("✓ Saved: hotspots_grid_based.csv\n\n")

  } else {
    cat("⚠ Grid columns not found. Run 02_clean_data.R first to create gridded coordinates.\n\n")
  }
}

# ============================================================================
# OPTION 2: DBSCAN Clustering
# ============================================================================

if(HOTSPOT_METHOD %in% c("dbscan", "both")) {
  cat("============================================================================\n")
  cat("Running DBSCAN Clustering...\n")
  cat("============================================================================\n\n")

  cat("DBSCAN Parameters:\n")
  cat("  eps (radius): 0.01 degrees (~1.1 km)\n")
  cat("  minPts: 10 crashes minimum per cluster\n\n")

  # Run DBSCAN
  # eps = 0.01 degrees ≈ 1.1 km in Victoria
  # minPts = 10 crashes minimum to form a cluster
  start_time <- Sys.time()

  dbscan_result <- dbscan(coords, eps = 0.01, minPts = 10)

  end_time <- Sys.time()
  clustering_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

  cat("✓ DBSCAN completed in", round(clustering_time, 2), "seconds\n\n")

  # Add cluster labels to data
  crashes_spatial[, cluster_id := dbscan_result$cluster]

  # Clustering results
  n_clusters <- max(dbscan_result$cluster)
  n_noise <- sum(dbscan_result$cluster == 0)
  n_clustered <- sum(dbscan_result$cluster > 0)

  cat("Clustering Results:\n")
  cat("  Total clusters identified:", n_clusters, "\n")
  cat("  Crashes in clusters:", format(n_clustered, big.mark=","),
      "(", round((n_clustered/nrow(crashes_spatial))*100, 1), "% )\n")
  cat("  Noise points (isolated):", format(n_noise, big.mark=","),
      "(", round((n_noise/nrow(crashes_spatial))*100, 1), "% )\n\n")


  cat("============================================================================\n")
  cat("Analyzing DBSCAN Hotspots...\n")
  cat("============================================================================\n\n")

  # Calculate statistics for each cluster
  hotspots <- crashes_spatial[cluster_id > 0, .(
    n_crashes = .N,
    n_fatalities = sum(NO_PERSONS_KILLED),
    n_serious_injuries = sum(NO_PERSONS_INJ_2),
    n_other_injuries = sum(NO_PERSONS_INJ_3),
    total_severity = sum(severity_score),
    avg_severity = mean(severity_score),
    center_lat = mean(LATITUDE),
    center_lon = mean(LONGITUDE),
    min_lat = min(LATITUDE),
    max_lat = max(LATITUDE),
    min_lon = min(LONGITUDE),
    max_lon = max(LONGITUDE)
  ), by = cluster_id][order(-total_severity)]

  # Add rank
  hotspots[, rank := .I]

  # Calculate cluster size (approximate radius in km)
  # 1 degree ≈ 111 km at equator, slightly less at Victoria's latitude
  hotspots[, cluster_radius_km := sqrt(
    ((max_lat - min_lat) * 111)^2 + ((max_lon - min_lon) * 95)^2
  ) / 2]

  cat("Top 20 Hotspots (by total severity):\n")
  cat("=====================================\n")
  print(hotspots[1:20, .(
    rank, cluster_id, n_crashes, n_fatalities, n_serious_injuries,
    total_severity, center_lat, center_lon
  )])
  cat("\n")

  # Summary statistics
  cat("Hotspot Summary Statistics:\n")
  cat("---------------------------\n")
  cat("Total hotspots:", nrow(hotspots), "\n")
  cat("Average crashes per hotspot:", round(mean(hotspots$n_crashes), 1), "\n")
  cat("Largest hotspot:", max(hotspots$n_crashes), "crashes\n")
  cat("Most severe hotspot:", max(hotspots$total_severity), "severity score\n\n")

  # Hotspot size distribution
  cat("Hotspot Size Distribution:\n")
  cat("--------------------------\n")
  print(hotspots[, .(
    "10-50 crashes" = sum(n_crashes >= 10 & n_crashes < 50),
    "50-100 crashes" = sum(n_crashes >= 50 & n_crashes < 100),
    "100-200 crashes" = sum(n_crashes >= 100 & n_crashes < 200),
    "200+ crashes" = sum(n_crashes >= 200)
  )])
  cat("\n")


  cat("============================================================================\n")
  cat("Adding Location Context...\n")
  cat("============================================================================\n\n")

  # Get most common road name for each cluster
  hotspot_roads <- crashes_spatial[cluster_id > 0, .(
    common_road = names(sort(table(ROAD_NAME), decreasing = TRUE))[1],
    n_road_types = uniqueN(ROAD_TYPE)
  ), by = cluster_id]

  hotspots <- merge(hotspots, hotspot_roads, by = "cluster_id", all.x = TRUE)

  cat("✓ Added location context\n\n")

  # ============================================================================
  # Save DBSCAN Hotspot Data
  # ============================================================================

  cat("============================================================================\n")
  cat("Saving DBSCAN Hotspot Data...\n")
  cat("============================================================================\n\n")

  # Save full hotspot data
  fwrite(hotspots, file.path(output_dir, "hotspots_dbscan_all.csv"))
  cat("✓ Saved: hotspots_dbscan_all.csv (", nrow(hotspots), "hotspots )\n")

  # Save top 50 hotspots
  top_hotspots_dbscan <- hotspots[1:min(50, nrow(hotspots))]
  fwrite(top_hotspots_dbscan, file.path(output_dir, "hotspots_dbscan_top50.csv"))
  cat("✓ Saved: hotspots_dbscan_top50.csv\n")

  # Save crashes with cluster assignments
  crashes_with_clusters <- crashes_spatial[, .(
    ACCIDENT_NO, ACCIDENT_DATE_PARSED, LATITUDE, LONGITUDE,
    cluster_id, severity_score, severity_category,
    NO_PERSONS_KILLED, NO_PERSONS_INJ_2
  )]
  fwrite(crashes_with_clusters, file.path(output_dir, "crashes_with_clusters.csv"))
  cat("✓ Saved: crashes_with_clusters.csv\n\n")

} # End of DBSCAN method

# ============================================================================
# Determine Which Hotspots to Use for Visualization
# ============================================================================

# Use grid-based hotspots if available, otherwise DBSCAN
#if(exists("grid_hotspots") && nrow(grid_hotspots) > 0) {
#  cat("Using grid-based hotspots for visualization\n")
#  hotspots_for_viz <- grid_hotspots
#} else if(exists("hotspots") && nrow(hotspots) > 0) {
  cat("Using DBSCAN hotspots for visualization\n")
  hotspots_for_viz <- hotspots
#} else {
#  stop("No hotspots generated. Check that at least one method completed successfully.")
#}

# ============================================================================
# Legacy Save (for backward compatibility)
# ============================================================================

cat("============================================================================\n")
cat("Saving Hotspot Data (legacy format)...\n")
cat("============================================================================\n\n")

# Save to legacy filenames for backward compatibility
fwrite(hotspots_for_viz, file.path(output_dir, "hotspots_all.csv"))
cat("✓ Saved: hotspots_all.csv\n")

top_hotspots <- hotspots_for_viz[1:min(50, nrow(hotspots_for_viz))]
fwrite(top_hotspots, file.path(output_dir, "hotspots_top50.csv"))
cat("✓ Saved: hotspots_top50.csv\n\n")

# ============================================================================
# Create Interactive Map
# ============================================================================

cat("============================================================================\n")
cat("Creating Interactive Map...\n")
cat("============================================================================\n\n")

# Prepare data for mapping
map_hotspots <- top_hotspots[1:min(30, nrow(top_hotspots))]  # Top 30 for cleaner map

# Create color palette for severity
severity_pal <- colorNumeric(
  palette = "YlOrRd",
  domain = map_hotspots$total_severity
)

# Build popup text dynamically based on available columns
build_popup <- function(data) {
  popup_base <- paste0(
    "<b>Hotspot Rank: ", data$rank, "</b><br>",
    "Total Crashes: ", data$n_crashes, "<br>",
    "Fatalities: ", data$n_fatalities, "<br>",
    "Serious Injuries: ", data$n_serious_injuries, "<br>",
    "Severity Score: ", round(data$total_severity, 1), "<br>",
    "Avg Severity: ", round(data$avg_severity, 2), "<br>"
  )

  # Add cluster_id if it exists (DBSCAN)
  if("cluster_id" %in% colnames(data)) {
    popup_base <- paste0(popup_base, "Cluster ID: ", data$cluster_id, "<br>")
  }

  # Add grid info if it exists
  if("lat_grid_medium" %in% colnames(data)) {
    popup_base <- paste0(popup_base, "Grid Cell: (", data$lat_grid_medium, ", ", data$lon_grid_medium, ")<br>")
  }

  # Add common road if it exists
  if("common_road" %in% colnames(data)) {
    popup_base <- paste0(popup_base, "Common Road: ", data$common_road, "<br>")
  }

  # Add location
  popup_base <- paste0(popup_base,
    "Location: (", round(data$center_lat, 4), ", ", round(data$center_lon, 4), ")"
  )

  return(popup_base)
}

map_hotspots$popup_text <- build_popup(map_hotspots)

# Create leaflet map
crash_map <- leaflet(map_hotspots) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  setView(lng = 145.0, lat = -37.8, zoom = 8) %>%

  # Add circle markers for hotspots
  addCircleMarkers(
    lng = ~center_lon,
    lat = ~center_lat,
    radius = ~sqrt(n_crashes),
    color = ~severity_pal(total_severity),
    fillColor = ~severity_pal(total_severity),
    fillOpacity = 0.7,
    stroke = TRUE,
    weight = 2,
    popup = ~popup_text,
    label = ~paste0("Rank ", rank, ": ", n_crashes, " crashes")
  ) %>%

  # Add legend
  addLegend(
    "bottomright",
    pal = severity_pal,
    values = ~total_severity,
    title = "Total Severity Score",
    opacity = 0.7
  ) %>%

  # Add title
  addControl(
    html = "<div style='background: white; padding: 10px; border-radius: 5px;'>
            <h4>Victorian Road Crash Hotspots</h4>
            <p>Top 30 crash hotspots identified by DBSCAN clustering</p>
            <p>Circle size = number of crashes | Color = severity</p>
            </div>",
    position = "topright"
  )

# Save map as HTML
library(htmlwidgets)
saveWidget(
  crash_map,
  file.path(figures_dir, "interactive_hotspot_map.html"),
  selfcontained = TRUE
)

cat("✓ Saved: interactive_hotspot_map.html\n")
cat("  Open this file in a web browser to view the interactive map\n\n")

# ============================================================================
# Generate Hotspot Report
# ============================================================================

cat("============================================================================\n")
cat("Generating Hotspot Report...\n")
cat("============================================================================\n\n")

# Create detailed report for top 10 hotspots
report_data <- list()

for(i in 1:min(10, nrow(hotspots))) {
  hotspot <- hotspots[i]
  cluster_crashes <- crashes_spatial[cluster_id == hotspot$cluster_id]

  report_data[[i]] <- list(
    rank = hotspot$rank,
    cluster_id = hotspot$cluster_id,
    n_crashes = hotspot$n_crashes,
    fatalities = hotspot$n_fatalities,
    serious_injuries = hotspot$n_serious_injuries,
    severity_score = hotspot$total_severity,
    center_coords = c(hotspot$center_lat, hotspot$center_lon),
    common_road = hotspot$common_road,
    crash_types = head(sort(table(cluster_crashes$ACCIDENT_TYPE), decreasing=TRUE), 3),
    peak_hour = names(sort(table(cluster_crashes$hour), decreasing=TRUE))[1],
    peak_day = names(sort(table(cluster_crashes$day_of_week), decreasing=TRUE))[1]
  )
}

saveRDS(report_data, file.path(output_dir, "hotspot_detailed_report.rds"))
cat("✓ Saved: hotspot_detailed_report.rds\n\n")

# Print summary of top 10
cat("Top 10 Hotspots Summary:\n")
cat("========================\n\n")

for(i in 1:min(10, length(report_data))) {
  hdata <- report_data[[i]]
  cat(sprintf("Rank %d - Cluster %d\n", hdata$rank, hdata$cluster_id))
  cat(sprintf("  Location: (%.4f, %.4f)\n", hdata$center_coords[1], hdata$center_coords[2]))
  cat(sprintf("  Road: %s\n", hdata$common_road))
  cat(sprintf("  Crashes: %d | Fatalities: %d | Serious Injuries: %d\n",
              hdata$n_crashes, hdata$fatalities, hdata$serious_injuries))
  cat(sprintf("  Severity Score: %.1f\n", hdata$severity_score))
  cat(sprintf("  Peak time: %s on %s\n", hdata$peak_hour, hdata$peak_day))
  cat("  Top crash types:", paste(names(hdata$crash_types)[1:min(2, length(hdata$crash_types))], collapse=", "), "\n\n")
}

# ============================================================================
# Visualize Cluster Distribution
# ============================================================================

cat("============================================================================\n")
cat("Creating Cluster Visualizations...\n")
cat("============================================================================\n\n")

library(ggplot2)

# Plot 1: Hotspot size distribution
p1 <- ggplot(hotspots, aes(x = n_crashes)) +
  geom_histogram(bins = 30, fill = "#1f77b4", alpha = 0.7) +
  geom_vline(xintercept = median(hotspots$n_crashes),
             color = "red", linetype = "dashed", size = 1) +
  labs(
    title = "Distribution of Hotspot Sizes",
    subtitle = paste("Median:", median(hotspots$n_crashes), "crashes per hotspot"),
    x = "Number of Crashes in Hotspot",
    y = "Frequency"
  ) +
  theme_minimal()

ggsave(file.path(figures_dir, "09_hotspot_size_distribution.png"), p1, width = 10, height = 6, dpi = 300)
cat("✓ Saved: 09_hotspot_size_distribution.png\n")

# Plot 2: Top 20 hotspots bar chart
p2 <- ggplot(hotspots[1:20], aes(x = reorder(paste("Cluster", cluster_id), -total_severity),
                                  y = total_severity)) +
  geom_col(aes(fill = n_fatalities > 0), alpha = 0.8) +
  scale_fill_manual(values = c("FALSE" = "#2ca02c", "TRUE" = "#d62728"),
                    labels = c("No fatalities", "Has fatalities")) +
  coord_flip() +
  labs(
    title = "Top 20 Crash Hotspots by Severity",
    subtitle = "Ranked by total severity score",
    x = "Hotspot",
    y = "Total Severity Score",
    fill = ""
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "10_top20_hotspots.png"), p2, width = 10, height = 8, dpi = 300)
cat("✓ Saved: 10_top20_hotspots.png\n\n")

# ============================================================================
# COMPLETION
# ============================================================================

cat("============================================================================\n")
cat("Hotspot Analysis Complete!\n")
cat("============================================================================\n\n")

cat("Summary:\n")
cat("  Total hotspots identified:", nrow(hotspots), "\n")
cat("  Crashes in hotspots:", format(sum(hotspots$n_crashes), big.mark=","), "\n")
cat("  Fatalities in hotspots:", sum(hotspots$n_fatalities), "\n")
cat("  Top hotspot has", max(hotspots$n_crashes), "crashes\n\n")

cat("============================================================================\n")
