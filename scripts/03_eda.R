# ============================================================================
# Script 03: Exploratory Data Analysis (EDA)
# ============================================================================
# Purpose: Explore crash data patterns and create visualizations
# Input: Cleaned data from output/data/crashes_cleaned.rds
# Output: Summary statistics and visualizations
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Exploratory Data Analysis\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(scales)
  library(data.table)
  library(viridis)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

output_dir <- "output/data"
figures_dir <- "output/figures"

# Create figures directory if it doesn't exist
if(!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

cat("Working directory:", getwd(), "\n\n")

# ============================================================================
# Load Cleaned Data
# ============================================================================

cat("============================================================================\n")
cat("Loading Cleaned Data...\n")
cat("============================================================================\n\n")

crashes <- readRDS(file.path(output_dir, "crashes_cleaned.rds"))
cat("✓ Loaded", nrow(crashes), "crash records\n\n")

# Convert to data.table for faster operations
crashes_dt <- as.data.table(crashes)

# ============================================================================
# 1. SUMMARY STATISTICS
# ============================================================================

cat("============================================================================\n")
cat("1. SUMMARY STATISTICS\n")
cat("============================================================================\n\n")

# Overall statistics
cat("Overall Statistics:\n")
cat("------------------\n")
cat("Total crashes:", format(nrow(crashes_dt), big.mark=","), "\n")
cat("Date range:", as.character(min(crashes_dt$ACCIDENT_DATE_PARSED)), "to",
    as.character(max(crashes_dt$ACCIDENT_DATE_PARSED)), "\n")
cat("Years covered:", length(unique(crashes_dt$year)), "years\n\n")

# Casualties
cat("Casualties:\n")
cat("-----------\n")
total_killed <- sum(crashes_dt$NO_PERSONS_KILLED, na.rm = TRUE)
total_serious <- sum(crashes_dt$NO_PERSONS_INJ_2, na.rm = TRUE)
total_other <- sum(crashes_dt$NO_PERSONS_INJ_3, na.rm = TRUE)

cat("Total fatalities:", format(total_killed, big.mark=","), "\n")
cat("Total serious injuries:", format(total_serious, big.mark=","), "\n")
cat("Total other injuries:", format(total_other, big.mark=","), "\n")
cat("Average fatalities per crash:", round(mean(crashes_dt$NO_PERSONS_KILLED, na.rm=TRUE), 3), "\n")
cat("Average severity score:", round(mean(crashes_dt$severity_score, na.rm=TRUE), 2), "\n\n")

# Severity distribution
cat("Severity Distribution:\n")
cat("---------------------\n")
print(crashes_dt[, .N, by=severity_category][order(-N)])
cat("\n")

# ============================================================================
# 2. TEMPORAL ANALYSIS
# ============================================================================

cat("============================================================================\n")
cat("2. TEMPORAL PATTERNS\n")
cat("============================================================================\n\n")

# Yearly trends
yearly_stats <- crashes_dt[, .(
  n_crashes = .N,
  n_killed = sum(NO_PERSONS_KILLED),
  n_serious = sum(NO_PERSONS_INJ_2),
  avg_severity = mean(severity_score)
), by = year][order(year)]

cat("Crashes by Year:\n")
print(yearly_stats)
cat("\n")

# Monthly patterns
monthly_stats <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = month][order(month)]

cat("Crashes by Month:\n")
print(monthly_stats)
cat("\n")

# Day of week
dow_stats <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = day_of_week][order(day_of_week_num)]

cat("Crashes by Day of Week:\n")
print(dow_stats[, .(day_of_week, n_crashes, avg_severity)])
cat("\n")

# Hour of day
hourly_stats <- crashes_dt[!is.na(hour), .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = hour][order(hour)]

cat("Top 5 Peak Hours:\n")
print(head(hourly_stats[order(-n_crashes)], 5))
cat("\n")

# ============================================================================
# 3. VISUALIZATIONS
# ============================================================================

cat("============================================================================\n")
cat("3. CREATING VISUALIZATIONS\n")
cat("============================================================================\n\n")

# Set theme for all plots
theme_set(theme_minimal(base_size = 12))

# --- Plot 1: Yearly Trend ---
cat("Creating Plot 1: Yearly Crash Trends...\n")

p1 <- ggplot(yearly_stats, aes(x = year)) +
  geom_line(aes(y = n_crashes, color = "Total Crashes"), size = 1.2) +
  geom_point(aes(y = n_crashes, color = "Total Crashes"), size = 3) +
  geom_line(aes(y = n_killed * 100, color = "Fatalities (×100)"), size = 1.2) +
  geom_point(aes(y = n_killed * 100, color = "Fatalities (×100)"), size = 3) +
  scale_color_manual(values = c("Total Crashes" = "#1f77b4", "Fatalities (×100)" = "#d62728")) +
  labs(
    title = "Road Crash Trends Over Time",
    subtitle = "Total crashes and fatalities by year",
    x = "Year",
    y = "Count",
    color = "Metric"
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "01_yearly_trends.png"), p1, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 01_yearly_trends.png\n")

# --- Plot 2: Monthly Pattern ---
cat("Creating Plot 2: Monthly Patterns...\n")

p2 <- ggplot(monthly_stats, aes(x = factor(month), y = n_crashes)) +
  geom_col(fill = "#2ca02c", alpha = 0.8) +
  geom_text(aes(label = format(n_crashes, big.mark=",")), vjust = -0.5, size = 3) +
  scale_x_discrete(labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")) +
  labs(
    title = "Seasonal Crash Patterns",
    subtitle = "Total crashes by month (all years combined)",
    x = "Month",
    y = "Number of Crashes"
  )

ggsave(file.path(figures_dir, "02_monthly_patterns.png"), p2, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 02_monthly_patterns.png\n")

# --- Plot 3: Day of Week ---
cat("Creating Plot 3: Day of Week Distribution...\n")

p3 <- ggplot(crashes_dt[, .N, by = day_of_week], aes(x = day_of_week, y = N)) +
  geom_col(fill = "#ff7f0e", alpha = 0.8) +
  geom_text(aes(label = format(N, big.mark=",")), vjust = -0.5, size = 3.5) +
  labs(
    title = "Crashes by Day of Week",
    subtitle = "Total crashes for each day of the week",
    x = "Day of Week",
    y = "Number of Crashes"
  )

ggsave(file.path(figures_dir, "03_day_of_week.png"), p3, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 03_day_of_week.png\n")

# --- Plot 4: Hourly Distribution ---
cat("Creating Plot 4: Hourly Distribution...\n")

p4 <- ggplot(hourly_stats, aes(x = hour, y = n_crashes)) +
  geom_line(color = "#9467bd", size = 1.5) +
  geom_point(color = "#9467bd", size = 3) +
  geom_area(fill = "#9467bd", alpha = 0.2) +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  labs(
    title = "Crash Distribution by Hour of Day",
    subtitle = "Peak times: Morning rush (7-9 AM) and Evening rush (3-6 PM)",
    x = "Hour of Day (24-hour format)",
    y = "Number of Crashes"
  )

ggsave(file.path(figures_dir, "04_hourly_distribution.png"), p4, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 04_hourly_distribution.png\n")

# --- Plot 5: Hour × Day Heatmap ---
cat("Creating Plot 5: Hour × Day Heatmap...\n")

heatmap_data <- crashes_dt[!is.na(hour), .N, by = .(hour, day_of_week)]

p5 <- ggplot(heatmap_data, aes(x = hour, y = day_of_week, fill = N)) +
  geom_tile(color = "white") +
  scale_fill_viridis(option = "plasma", name = "Crashes") +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  labs(
    title = "Crash Patterns: Hour × Day of Week",
    subtitle = "Darker colors indicate more crashes",
    x = "Hour of Day",
    y = "Day of Week"
  ) +
  theme(legend.position = "right")

ggsave(file.path(figures_dir, "05_heatmap_hour_day.png"), p5, width = 12, height = 6, dpi = 300)
cat("  ✓ Saved: 05_heatmap_hour_day.png\n")

# --- Plot 6: Severity Distribution ---
cat("Creating Plot 6: Severity Distribution...\n")

severity_data <- crashes_dt[, .N, by = severity_category][order(-N)]

p6 <- ggplot(severity_data, aes(x = reorder(severity_category, -N), y = N, fill = severity_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = format(N, big.mark=",")), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c(
    "Fatal" = "#d62728",
    "Serious Injury" = "#ff7f0e",
    "Other Injury" = "#ffbb78",
    "Non-Injury" = "#98df8a"
  )) +
  labs(
    title = "Crash Severity Distribution",
    subtitle = paste("Total crashes:", format(nrow(crashes_dt), big.mark=",")),
    x = "Severity Category",
    y = "Number of Crashes"
  ) +
  theme(legend.position = "none")

ggsave(file.path(figures_dir, "06_severity_distribution.png"), p6, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 06_severity_distribution.png\n")

# --- Plot 7: Time Period Distribution ---
cat("Creating Plot 7: Time Period Distribution...\n")

time_period_data <- crashes_dt[, .N, by = time_period][order(-N)]

p7 <- ggplot(time_period_data, aes(x = reorder(time_period, -N), y = N)) +
  geom_col(fill = "#17becf", alpha = 0.8) +
  geom_text(aes(label = format(N, big.mark=",")), vjust = -0.5, size = 3.5) +
  labs(
    title = "Crashes by Time Period",
    subtitle = "Distribution across different times of day",
    x = "Time Period",
    y = "Number of Crashes"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(figures_dir, "07_time_periods.png"), p7, width = 10, height = 6, dpi = 300)
cat("  ✓ Saved: 07_time_periods.png\n")

# --- Plot 8: Weekend vs Weekday ---
cat("Creating Plot 8: Weekend vs Weekday Comparison...\n")

weekend_data <- crashes_dt[, .(
  n_crashes = .N,
  avg_severity = mean(severity_score)
), by = is_weekend]

weekend_data[, type := ifelse(is_weekend == 1, "Weekend", "Weekday")]

p8 <- ggplot(weekend_data, aes(x = type, y = n_crashes, fill = type)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = format(n_crashes, big.mark=",")), vjust = -0.5, size = 5) +
  scale_fill_manual(values = c("Weekend" = "#e377c2", "Weekday" = "#7f7f7f")) +
  labs(
    title = "Weekend vs Weekday Crashes",
    subtitle = sprintf("Average severity - Weekend: %.2f, Weekday: %.2f",
                       weekend_data[type=="Weekend", avg_severity],
                       weekend_data[type=="Weekday", avg_severity]),
    x = "",
    y = "Number of Crashes"
  ) +
  theme(legend.position = "none")

ggsave(file.path(figures_dir, "08_weekend_vs_weekday.png"), p8, width = 8, height = 6, dpi = 300)
cat("  ✓ Saved: 08_weekend_vs_weekday.png\n")

cat("\n")

# ============================================================================
# 4. KEY INSIGHTS
# ============================================================================

cat("============================================================================\n")
cat("4. KEY INSIGHTS\n")
cat("============================================================================\n\n")

# Peak crash times
peak_hour <- hourly_stats[which.max(n_crashes), hour]
peak_day <- dow_stats[which.max(n_crashes), day_of_week]
peak_month <- monthly_stats[which.max(n_crashes), month]

cat("Temporal Patterns:\n")
cat("------------------\n")
cat("Peak hour:", peak_hour, ":00 (", hourly_stats[hour==peak_hour, n_crashes], "crashes )\n")
cat("Peak day:", as.character(peak_day), "(", dow_stats[day_of_week==peak_day, n_crashes], "crashes )\n")
cat("Peak month:", month.name[peak_month], "(", monthly_stats[month==peak_month, n_crashes], "crashes )\n\n")

# Severity insights
fatal_pct <- (nrow(crashes_dt[severity_category == "Fatal"]) / nrow(crashes_dt)) * 100
serious_pct <- (nrow(crashes_dt[severity_category == "Serious Injury"]) / nrow(crashes_dt)) * 100

cat("Severity Insights:\n")
cat("------------------\n")
cat("Fatal crashes:", round(fatal_pct, 2), "%\n")
cat("Serious injury crashes:", round(serious_pct, 2), "%\n")
cat("Average persons killed per crash:", round(mean(crashes_dt$NO_PERSONS_KILLED), 4), "\n\n")

# Trend analysis
if(nrow(yearly_stats) >= 2) {
  first_year_crashes <- yearly_stats[1, n_crashes]
  last_year_crashes <- yearly_stats[nrow(yearly_stats), n_crashes]
  trend_pct <- ((last_year_crashes - first_year_crashes) / first_year_crashes) * 100

  cat("Trends:\n")
  cat("-------\n")
  cat("First year (", yearly_stats[1, year], "):", first_year_crashes, "crashes\n")
  cat("Last year (", yearly_stats[nrow(yearly_stats), year], "):", last_year_crashes, "crashes\n")
  cat("Overall trend:", ifelse(trend_pct > 0, "+", ""), round(trend_pct, 1), "%\n\n")
}

# ============================================================================
# 5. SAVE SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("5. SAVING SUMMARY DATA\n")
cat("============================================================================\n\n")

# Save summary tables
fwrite(yearly_stats, file.path(output_dir, "summary_yearly.csv"))
cat("✓ Saved: summary_yearly.csv\n")

fwrite(monthly_stats, file.path(output_dir, "summary_monthly.csv"))
cat("✓ Saved: summary_monthly.csv\n")

fwrite(hourly_stats, file.path(output_dir, "summary_hourly.csv"))
cat("✓ Saved: summary_hourly.csv\n")

fwrite(dow_stats, file.path(output_dir, "summary_day_of_week.csv"))
cat("✓ Saved: summary_day_of_week.csv\n")

cat("\n")

# ============================================================================
# COMPLETION
# ============================================================================

cat("============================================================================\n")
cat("Exploratory Data Analysis Complete!\n")
cat("============================================================================\n\n")

cat("Generated outputs:\n")
cat("  Visualizations: 8 plots saved to", figures_dir, "\n")
cat("  Summary tables: 4 CSV files saved to", output_dir, "\n\n")

cat("Next steps:\n")
cat("  1. Hotspot analysis: source('scripts/04_hotspots.R')\n")
cat("  2. Temporal analysis: source('scripts/05_temporal.R')\n")
cat("\n")

cat("============================================================================\n")
