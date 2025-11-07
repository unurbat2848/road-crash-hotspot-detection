# ============================================================================
# Script 05: Temporal Pattern Analysis
# ============================================================================
# Purpose: Analyze crash patterns over time with detailed temporal insights
# Input: Cleaned data and hotspot data
# Output: Temporal analysis visualizations and trends
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Temporal Pattern Analysis\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(data.table)
  library(scales)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

output_dir <- "output/data"
figures_dir <- "output/figures"

cat("Working directory:", getwd(), "\n\n")

# ============================================================================
# Load Data
# ============================================================================

cat("============================================================================\n")
cat("Loading Data...\n")
cat("============================================================================\n\n")

crashes <- readRDS(file.path(output_dir, "crashes_cleaned.rds"))
cat("✓ Loaded", format(nrow(crashes), big.mark=","), "crash records\n")

hotspots <- fread(file.path(output_dir, "hotspots_top50.csv"))
cat("✓ Loaded", nrow(hotspots), "hotspots\n\n")

# Convert to data.table
crashes_dt <- as.data.table(crashes)

# ============================================================================
# 1. YEARLY TREND ANALYSIS
# ============================================================================

cat("============================================================================\n")
cat("1. YEARLY TREND ANALYSIS\n")
cat("============================================================================\n\n")

# Aggregate by year
yearly_trends <- crashes_dt[, .(
  n_crashes = .N,
  n_fatalities = sum(NO_PERSONS_KILLED),
  n_serious = sum(NO_PERSONS_INJ_2),
  n_other = sum(NO_PERSONS_INJ_3),
  avg_severity = mean(severity_score),
  fatal_crashes = sum(NO_PERSONS_KILLED > 0)
), by = year][order(year)]

cat("Yearly Statistics:\n")
print(yearly_trends)
cat("\n")

# Calculate year-over-year changes
if(nrow(yearly_trends) >= 2) {
  yearly_trends[, yoy_change := c(NA, diff(n_crashes))]
  yearly_trends[, yoy_pct := c(NA, (diff(n_crashes) / n_crashes[-.N]) * 100)]

  cat("Year-over-Year Changes:\n")
  print(yearly_trends[!is.na(yoy_change), .(year, n_crashes, yoy_change, yoy_pct)])
  cat("\n")
}

# Plot yearly trends
p1 <- ggplot(yearly_trends, aes(x = year)) +
  geom_line(aes(y = n_crashes, color = "Total Crashes"), size = 1.2) +
  geom_point(aes(y = n_crashes, color = "Total Crashes"), size = 3) +
  geom_line(aes(y = fatal_crashes * 10, color = "Fatal Crashes (×10)"), size = 1.2) +
  geom_point(aes(y = fatal_crashes * 10, color = "Fatal Crashes (×10)"), size = 3) +
  scale_color_manual(values = c("Total Crashes" = "#1f77b4", "Fatal Crashes (×10)" = "#d62728")) +
  scale_x_continuous(breaks = unique(yearly_trends$year)) +
  labs(
    title = "Yearly Crash Trends",
    subtitle = paste("Data from", min(yearly_trends$year), "to", max(yearly_trends$year)),
    x = "Year",
    y = "Number of Crashes",
    color = ""
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(figures_dir, "11_yearly_trends_detailed.png"), p1, width = 12, height = 7, dpi = 300)
cat("✓ Saved: 11_yearly_trends_detailed.png\n\n")

# ============================================================================
# 2. SEASONAL PATTERNS
# ============================================================================

cat("============================================================================\n")
cat("2. SEASONAL PATTERNS\n")
cat("============================================================================\n\n")

# Monthly analysis
monthly_patterns <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score),
  n_fatalities = sum(NO_PERSONS_KILLED)
), by = .(month, season)][order(month)]

cat("Monthly Patterns:\n")
print(monthly_patterns)
cat("\n")

# Seasonal summary
seasonal_summary <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score),
  n_fatalities = sum(NO_PERSONS_KILLED),
  fatal_rate = sum(NO_PERSONS_KILLED > 0) / .N * 100
), by = season][order(-n_crashes)]

cat("Seasonal Summary:\n")
print(seasonal_summary)
cat("\n")

# Plot seasonal patterns
p2 <- ggplot(monthly_patterns, aes(x = factor(month), y = n_crashes, fill = season)) +
  geom_col(alpha = 0.8) +
  scale_x_discrete(labels = month.abb) +
  scale_fill_manual(values = c(
    "Summer" = "#ff7f0e",
    "Autumn" = "#d62728",
    "Winter" = "#1f77b4",
    "Spring" = "#2ca02c"
  )) +
  labs(
    title = "Monthly Crash Distribution by Season",
    subtitle = "Southern Hemisphere seasons",
    x = "Month",
    y = "Number of Crashes",
    fill = "Season"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "12_seasonal_patterns.png"), p2, width = 12, height = 7, dpi = 300)
cat("✓ Saved: 12_seasonal_patterns.png\n\n")

# ============================================================================
# 3. HOURLY PATTERNS BY DAY TYPE
# ============================================================================

cat("============================================================================\n")
cat("3. HOURLY PATTERNS BY DAY TYPE\n")
cat("============================================================================\n\n")

# Analyze by weekend vs weekday
hourly_by_daytype <- crashes_dt[!is.na(hour), .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = .(hour, is_weekend)][order(hour, is_weekend)]

hourly_by_daytype[, day_type := ifelse(is_weekend == 1, "Weekend", "Weekday")]

cat("Peak Hours:\n")
cat("Weekday peak:", hourly_by_daytype[day_type=="Weekday"][which.max(n_crashes), hour], ":00 (",
    hourly_by_daytype[day_type=="Weekday"][which.max(n_crashes), n_crashes], "crashes )\n")
cat("Weekend peak:", hourly_by_daytype[day_type=="Weekend"][which.max(n_crashes), hour], ":00 (",
    hourly_by_daytype[day_type=="Weekend"][which.max(n_crashes), n_crashes], "crashes )\n\n")

# Plot hourly patterns
p3 <- ggplot(hourly_by_daytype, aes(x = hour, y = n_crashes, color = day_type, group = day_type)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  scale_color_manual(values = c("Weekday" = "#1f77b4", "Weekend" = "#e377c2")) +
  labs(
    title = "Hourly Crash Patterns: Weekday vs Weekend",
    subtitle = "Different temporal patterns between weekdays and weekends",
    x = "Hour of Day (24-hour format)",
    y = "Average Number of Crashes",
    color = "Day Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "13_hourly_weekday_weekend.png"), p3, width = 12, height = 7, dpi = 300)
cat("✓ Saved: 13_hourly_weekday_weekend.png\n\n")

# ============================================================================
# 4. RUSH HOUR ANALYSIS
# ============================================================================

cat("============================================================================\n")
cat("4. RUSH HOUR ANALYSIS\n")
cat("============================================================================\n\n")

# Define time periods
crashes_dt[, time_category := fcase(
  hour >= 6 & hour < 9, "Morning Rush",
  hour >= 9 & hour < 15, "Daytime",
  hour >= 15 & hour < 18, "Evening Rush",
  hour >= 18 & hour < 22, "Evening",
  default = "Night"
)]

time_period_stats <- crashes_dt[!is.na(hour), .(
  n_crashes = .N,
  pct = .N / nrow(crashes_dt[!is.na(hour)]) * 100,
  avg_severity = mean(severity_score),
  n_fatal = sum(NO_PERSONS_KILLED > 0)
), by = time_category][order(-n_crashes)]

cat("Time Period Statistics:\n")
print(time_period_stats)
cat("\n")

# Rush hour severity
rush_hour_data <- crashes_dt[!is.na(hour), .(
  is_rush = ifelse(hour %in% c(7,8,16,17), "Rush Hour", "Non-Rush"),
  severity_score, NO_PERSONS_KILLED
)]

rush_comparison <- rush_hour_data[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score),
  fatal_rate = sum(NO_PERSONS_KILLED > 0) / .N * 100
), by = is_rush]

cat("Rush Hour vs Non-Rush Comparison:\n")
print(rush_comparison)
cat("\n")

# ============================================================================
# 5. LONG-TERM TRENDS
# ============================================================================

cat("============================================================================\n")
cat("5. LONG-TERM TRENDS\n")
cat("============================================================================\n\n")

# Monthly time series
monthly_ts <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = .(year, month)][order(year, month)]

monthly_ts[, date := as.Date(paste(year, month, "01", sep="-"))]

# Calculate 12-month moving average
monthly_ts <- monthly_ts[order(date)]
monthly_ts[, ma_12 := frollmean(n_crashes, n = 12, align = "right")]

# Plot long-term trends
p4 <- ggplot(monthly_ts, aes(x = date)) +
  geom_line(aes(y = n_crashes), color = "gray70", alpha = 0.5) +
  geom_line(aes(y = ma_12, color = "12-Month Moving Average"), size = 1.5) +
  scale_color_manual(values = c("12-Month Moving Average" = "#1f77b4")) +
  labs(
    title = "Long-term Crash Trends",
    subtitle = "Monthly crashes with 12-month moving average",
    x = "Date",
    y = "Number of Crashes",
    color = ""
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "14_longterm_trends.png"), p4, width = 12, height = 7, dpi = 300)
cat("✓ Saved: 14_longterm_trends.png\n\n")

# ============================================================================
# 6. TEMPORAL PATTERNS IN HOTSPOTS
# ============================================================================

cat("============================================================================\n")
cat("6. TEMPORAL PATTERNS IN HOTSPOTS\n")
cat("============================================================================\n\n")

# Load crashes with cluster assignments
if(file.exists(file.path(output_dir, "crashes_with_clusters.csv"))) {
  crashes_clustered <- fread(file.path(output_dir, "crashes_with_clusters.csv"))

  # Get top 5 hotspots
  top5_clusters <- hotspots[1:5, cluster_id]

  # Analyze temporal patterns in top hotspots
  hotspot_temporal <- crashes_dt[, .(
    cluster_id = cluster_id,
    hour, day_of_week, season
  )]

  hotspot_temporal <- hotspot_temporal[cluster_id %in% top5_clusters & !is.na(hour)]

  # Peak times for each hotspot
  hotspot_peaks <- hotspot_temporal[, .(
    peak_hour = names(sort(table(hour), decreasing=TRUE))[1],
    peak_day = names(sort(table(day_of_week), decreasing=TRUE))[1],
    peak_season = names(sort(table(season), decreasing=TRUE))[1],
    n_crashes = .N
  ), by = cluster_id][order(-n_crashes)]

  cat("Temporal Patterns in Top 5 Hotspots:\n")
  print(hotspot_peaks)
  cat("\n")
}

# ============================================================================
# 7. SAVE TEMPORAL ANALYSIS RESULTS
# ============================================================================

cat("============================================================================\n")
cat("7. SAVING RESULTS\n")
cat("============================================================================\n\n")

# Save yearly trends
fwrite(yearly_trends, file.path(output_dir, "temporal_yearly.csv"))
cat("✓ Saved: temporal_yearly.csv\n")

# Save monthly patterns
fwrite(monthly_patterns, file.path(output_dir, "temporal_monthly.csv"))
cat("✓ Saved: temporal_monthly.csv\n")

# Save seasonal summary
fwrite(seasonal_summary, file.path(output_dir, "temporal_seasonal.csv"))
cat("✓ Saved: temporal_seasonal.csv\n")

# Save hourly patterns
fwrite(hourly_by_daytype, file.path(output_dir, "temporal_hourly_daytype.csv"))
cat("✓ Saved: temporal_hourly_daytype.csv\n")

# Save time period stats
fwrite(time_period_stats, file.path(output_dir, "temporal_time_periods.csv"))
cat("✓ Saved: temporal_time_periods.csv\n\n")

# ============================================================================
# 8. KEY INSIGHTS SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("8. KEY INSIGHTS\n")
cat("============================================================================\n\n")

cat("Temporal Insights:\n")
cat("------------------\n")
cat("1. Peak crash season:", seasonal_summary[1, season], "with",
    format(seasonal_summary[1, n_crashes], big.mark=","), "crashes\n")
cat("2. Peak crash month:", month.name[monthly_patterns[which.max(n_crashes), month]], "\n")
cat("3. Weekday peak hour:", hourly_by_daytype[day_type=="Weekday"][which.max(n_crashes), hour], ":00\n")
cat("4. Weekend peak hour:", hourly_by_daytype[day_type=="Weekend"][which.max(n_crashes), hour], ":00\n")

if(exists("yearly_trends") && nrow(yearly_trends) >= 2) {
  first_year <- yearly_trends[1, year]
  last_year <- yearly_trends[nrow(yearly_trends), year]
  trend_pct <- yearly_trends[nrow(yearly_trends), yoy_pct]

  if(!is.na(trend_pct)) {
    cat("5. Recent trend (", last_year, "):", ifelse(trend_pct > 0, "+", ""),
        round(trend_pct, 1), "% vs previous year\n", sep="")
  }
}

cat("\nRush Hour Impact:\n")
cat("-----------------\n")
rush_pct <- rush_comparison[is_rush=="Rush Hour", n_crashes] /
            sum(rush_comparison$n_crashes) * 100
cat("Rush hour crashes:", round(rush_pct, 1), "% of all crashes\n")
cat("Rush hour avg severity:", round(rush_comparison[is_rush=="Rush Hour", avg_severity], 2), "\n")
cat("Non-rush avg severity:", round(rush_comparison[is_rush=="Non-Rush", avg_severity], 2), "\n\n")

# ============================================================================
# COMPLETION
# ============================================================================

cat("============================================================================\n")
cat("Temporal Analysis Complete!\n")
cat("============================================================================\n\n")

cat("Generated outputs:\n")
cat("  Visualizations: 4 plots\n")
cat("  Data files: 5 CSV files with temporal statistics\n\n")

cat("Next steps:\n")
cat("  1. Set up Kafka: See kafka_setup/README.md\n")
cat("  2. Run Kafka producer: Rscript scripts/06_kafka_producer.R\n")
cat("  3. Run Kafka consumer: Rscript scripts/07_kafka_consumer.R\n")
cat("\n")

cat("============================================================================\n")
