# Project Implementation Plan

## Spatio-Temporal Hotspot Detection and Trend Analysis of Road Crashes in Victoria

**Course:** Big Data Analytics - Semester 4
**Institution:** Swinburne University of Technology
**Dataset:** Victorian Road Crash Data (191 MB, 2.2M rows)

---

## Project Overview

This project analyzes road crash patterns in Victoria, Australia, focusing on:

- **Identifying crash hotspots** across Victoria using spatial clustering techniques
- **Analyzing temporal patterns** (time of day, day of week, seasonal trends)
- **Detecting emerging high-risk areas** using trend analysis
- **Implementing real-time insights** using Apache Kafka for streaming data

### Core Guiding Questions

1. Where are the most frequent and severe crash hotspots?
2. When (time of day, day of week, season) do crashes peak in these locations?
3. How do crash trends evolve, and can we detect emerging high-risk areas?
4. Can real-time streaming data via Kafka provide alerts about crash trends?

---

## Current Project Status

**Status:** Initial Phase - Data Acquisition Complete

**Existing Assets:**
- ✓ Task requirements document
- ✓ Complete Victorian road crash dataset (10 CSV files)
  - accident.csv (182,040 rows)
  - vehicle.csv (331,993 rows)
  - person.csv (425,353 rows)
  - accident_location.csv (182,040 rows)
  - node.csv (184,829 rows)
  - atmospheric_cond.csv (184,409 rows)
  - road_surface_cond.csv (183,054 rows)
  - accident_event.csv (301,711 rows)
  - sub_dca.csv (261,417 rows)
  - dca_chart_and_sub_dca_codes.pdf (reference)

**To Be Implemented:**
- Project structure and scripts
- Data processing pipeline
- Analytical models
- Visualization dashboards
- Kafka streaming infrastructure
- Final reporting

---

## Phase 1: Environment Setup & Project Structure (Week 1)

### 1.1 Directory Structure

```
BigData/
├── data/                          # Raw data (already exists)
├── scripts/
│   ├── 01_data_loading.R          # Data import functions
│   ├── 02_data_cleaning.R         # Preprocessing and validation
│   ├── 03_eda.R                   # Exploratory data analysis
│   ├── 04_spatial_analysis.R      # Hotspot detection algorithms
│   ├── 05_temporal_analysis.R     # Time-series analysis
│   ├── 06_kafka_producer.R        # Kafka data producer
│   └── 07_kafka_consumer.R        # Kafka consumer and streaming analytics
├── visualizations/
│   ├── 01_static_plots.R          # ggplot2 visualizations
│   ├── 02_interactive_maps.R      # Leaflet maps
│   └── 03_animations.R            # gganimate visualizations
├── shiny_app/
│   ├── ui.R                       # Shiny UI
│   ├── server.R                   # Shiny server logic
│   └── global.R                   # Shared functions and data
├── output/
│   ├── figures/                   # Generated plots and maps
│   ├── models/                    # Saved models
│   └── reports/                   # Analysis reports
├── kafka_config/                  # Kafka configuration files
├── requirements.R                 # Package dependencies
├── README.md                      # Project documentation
└── PROJECT_IMPLEMENTATION_PLAN.md # This document
```

### 1.2 Required R Packages

```r
# Data manipulation
install.packages(c("dplyr", "tidyr", "lubridate", "data.table"))

# Spatial analysis
install.packages(c("sf", "sp", "rgdal", "leaflet", "ggmap", "dbscan"))

# Visualization
install.packages(c("ggplot2", "plotly", "gganimate", "viridis"))

# Time-series
install.packages(c("forecast", "tsibble", "prophet", "zoo"))

# Dashboard
install.packages(c("shiny", "shinydashboard", "DT"))

# Kafka integration
install.packages(c("rkafka", "jsonlite"))

# Statistical analysis
install.packages(c("cluster", "factoextra", "MASS"))
```

---

## Phase 2: Data Acquisition & Preparation (Week 1-2)

### 2.1 Data Loading Strategy

- Load all 10 CSV files using efficient read methods (data.table::fread)
- Validate data integrity (row counts, primary keys)
- Document data schemas and relationships

### 2.2 Data Cleaning Tasks

**Missing Values:**
- Identify and handle NAs in critical fields
- Document missing data patterns
- Apply appropriate imputation strategies

**Date/Time Conversion:**
- Parse ACCIDENT_DATE and ACCIDENT_TIME to proper datetime objects
- Extract temporal features (hour, day_of_week, month, season, year)
- Validate temporal consistency

**Categorical Encoding:**
- Standardize categorical variables (ACCIDENT_TYPE, ROAD_GEOMETRY, etc.)
- Create factor levels for analysis
- Document encoding schemes

**Geographic Validation:**
- Ensure NODE_ID links to valid locations
- Validate coordinate ranges for Victoria
- Handle missing or invalid geographic data

**Outlier Detection:**
- Identify anomalies in severity, speed zones
- Flag suspicious records for review
- Document outlier handling decisions

### 2.3 Data Integration

Join accident.csv with:
- accident_location.csv (location details via ACCIDENT_NO)
- node.csv (geographic coordinates via NODE_ID)
- vehicle.csv (vehicle information via ACCIDENT_NO)
- person.csv (casualty details via ACCIDENT_NO)
- atmospheric_cond.csv (weather conditions via ACCIDENT_NO)
- road_surface_cond.csv (road conditions via ACCIDENT_NO)

Create master analytical dataset with all relevant features.

### 2.4 Feature Engineering

**Severity Score:**
- Calculate composite severity: (NO_PERSONS_KILLED × 10) + (NO_PERSONS_INJ_2 × 2) + NO_PERSONS_INJ_3
- Categorize into severity levels (minor, moderate, severe, fatal)

**Time Features:**
- hour: Extract from ACCIDENT_TIME
- day_of_week: From ACCIDENT_DATE
- month: Numeric month (1-12)
- season: Summer, Autumn, Winter, Spring
- year: For trend analysis
- is_weekend: Boolean flag
- is_rush_hour: Boolean flag (7-9 AM, 4-7 PM)

**Location Features:**
- road_type: Categorize from ROAD_TYPE
- speed_zone: From SPEED_ZONE
- geometry_type: From ROAD_GEOMETRY
- intersection_flag: Whether accident at intersection

**Environmental Score:**
- Combine weather conditions, road surface, and light conditions
- Create risk score for environmental factors

---

## Phase 3: Exploratory Data Analysis (Week 2)

### 3.1 Descriptive Statistics

**Temporal Analysis:**
- Crash frequency by year (identify trends)
- Monthly patterns (seasonal variations)
- Day of week distributions
- Hourly distributions (identify peak times)

**Severity Analysis:**
- Fatality rates over time
- Injury severity distributions
- Correlation between severity and other factors

**Vehicle Analysis:**
- Most common vehicle types in crashes
- Vehicle age and crash involvement
- Vehicle make/model patterns

**Environmental Analysis:**
- Weather condition distributions
- Road surface condition impact
- Light condition correlations with severity

**Geographic Analysis:**
- Crash distribution by road type
- Speed zone analysis
- Road geometry patterns

### 3.2 Visualizations

**Temporal:**
- Line plots: Crashes over time (yearly, monthly, daily trends)
- Heatmaps: Hour × Day of week crash frequency
- Bar charts: Seasonal patterns

**Categorical:**
- Bar charts: Crash types, weather conditions, road types
- Pie charts: Severity distributions, vehicle types
- Stacked bars: Severity by factors

**Geographic:**
- Scatter plots: Initial spatial distribution
- Density plots: Geographic concentration
- Choropleth maps: Regional patterns

**Correlation:**
- Correlation heatmaps: Variable relationships
- Scatter plot matrices: Multivariate relationships

### 3.3 Key Insights to Extract

- Peak crash times and high-frequency locations
- High-risk vehicle types and road conditions
- Seasonal patterns and weather impacts
- Severity factors and contributing conditions
- Temporal trends (increasing/decreasing crash rates)

---

## Phase 4: Spatial Analysis - Hotspot Identification (Week 3)

### 4.1 Spatial Clustering Algorithms

#### Option A: DBSCAN (Density-Based Clustering)

**Advantages:**
- Identifies arbitrary-shaped clusters
- Handles noise effectively
- No need to specify number of clusters

**Implementation:**
```r
library(dbscan)
library(sf)

# Prepare spatial data
coords <- cbind(accidents$longitude, accidents$latitude)

# Run DBSCAN
clusters <- dbscan(coords, eps = 0.01, minPts = 10)

# Add cluster labels to data
accidents$cluster_id <- clusters$cluster

# Filter out noise points (cluster = 0)
hotspots <- accidents %>%
  filter(cluster_id > 0) %>%
  group_by(cluster_id) %>%
  summarise(
    n_crashes = n(),
    severity_score = sum(severity_score),
    avg_severity = mean(severity_score),
    center_lat = mean(latitude),
    center_lon = mean(longitude)
  )
```

#### Option B: K-means Clustering

**Advantages:**
- Fast computation
- Creates discrete, well-defined zones
- Easy to interpret

**Implementation:**
```r
# Determine optimal K using elbow method
set.seed(123)
wss <- sapply(1:20, function(k) {
  kmeans(coords, centers = k, nstart = 10)$tot.withinss
})

# Run K-means with optimal K
kmeans_result <- kmeans(coords, centers = 50, nstart = 25)

# Analyze cluster characteristics
accidents$cluster_id <- kmeans_result$cluster
```

#### Option C: Kernel Density Estimation (KDE)

**Advantages:**
- Smooth continuous heatmap
- Visually intuitive
- No discrete cluster assignments needed

**Implementation:**
```r
library(spatstat)
library(raster)

# Create point pattern object
accidents_ppp <- ppp(
  x = accidents$longitude,
  y = accidents$latitude,
  window = owin(xrange = range(accidents$longitude),
                yrange = range(accidents$latitude))
)

# Calculate KDE
kde_surface <- density(accidents_ppp, sigma = 0.01)

# Extract high-density regions (top 5%)
kde_raster <- raster(kde_surface)
hotspot_threshold <- quantile(values(kde_raster), 0.95, na.rm = TRUE)
hotspot_zones <- kde_raster > hotspot_threshold
```

### 4.2 Hotspot Validation

**Statistical Significance Testing:**
- Getis-Ord Gi* statistic to identify statistically significant hotspots
- Monte Carlo simulations for significance testing
- Compare observed clusters with random spatial distributions

**Severity Weighting:**
- Weight clusters by severity scores (not just frequency)
- Identify high-fatality vs high-frequency hotspots
- Create composite risk scores

**Temporal Stability:**
- Test if hotspots persist across time periods
- Identify emerging vs stable hotspots
- Cross-validation with different time windows

### 4.3 Deliverables

- **Hotspot Catalog:** Top 20-50 locations with:
  - Geographic coordinates (latitude, longitude)
  - Crash frequency
  - Severity scores
  - Temporal patterns
  - Contributing factors (road type, weather patterns)

- **Interactive Maps:**
  - Leaflet map with cluster markers
  - Click-to-view crash details
  - Heat map overlay
  - Filterable by time period and severity

- **Statistical Report:**
  - Cluster characteristics
  - Significance testing results
  - Comparison of different clustering methods

---

## Phase 5: Temporal Analysis (Week 3-4)

### 5.1 Time-of-Day Analysis

**Hourly Patterns:**
```r
hourly_crashes <- accidents %>%
  group_by(hour) %>%
  summarise(
    n_crashes = n(),
    avg_severity = mean(severity_score),
    n_fatal = sum(NO_PERSONS_KILLED > 0)
  )

# Identify rush hour peaks
rush_hours <- hourly_crashes %>%
  filter(n_crashes > quantile(n_crashes, 0.75))
```

**Visualizations:**
- Line chart: Crashes by hour of day
- Heatmap: Hour × Day of week
- Box plots: Severity distribution by time period

### 5.2 Seasonal Analysis

**Monthly Aggregation:**
```r
seasonal_analysis <- accidents %>%
  mutate(
    month = month(ACCIDENT_DATE),
    season = case_when(
      month %in% c(12, 1, 2) ~ "Summer",
      month %in% c(3, 4, 5) ~ "Autumn",
      month %in% c(6, 7, 8) ~ "Winter",
      month %in% c(9, 10, 11) ~ "Spring"
    )
  ) %>%
  group_by(season, month) %>%
  summarise(
    n_crashes = n(),
    avg_severity = mean(severity_score)
  )
```

**Weather Correlation:**
- Join with atmospheric conditions data
- Analyze crash rates by weather type
- Seasonal weather impact analysis

**Holiday Periods:**
- Identify major holidays (Christmas, Easter, long weekends)
- Compare crash rates during holidays vs regular periods

### 5.3 Time-Series Forecasting

**Prophet Model:**
```r
library(prophet)

# Prepare time-series data
ts_data <- accidents %>%
  group_by(date = as.Date(ACCIDENT_DATE)) %>%
  summarise(crashes = n()) %>%
  rename(ds = date, y = crashes)

# Fit Prophet model
model <- prophet(
  ts_data,
  yearly.seasonality = TRUE,
  weekly.seasonality = TRUE,
  daily.seasonality = FALSE
)

# Generate forecast
future <- make_future_dataframe(model, periods = 90)
forecast <- predict(model, future)

# Plot results
plot(model, forecast)
prophet_plot_components(model, forecast)
```

**ARIMA Models:**
```r
library(forecast)

# Convert to time-series object
ts_crashes <- ts(ts_data$y, frequency = 365)

# Auto ARIMA
arima_model <- auto.arima(ts_crashes)

# Forecast
arima_forecast <- forecast(arima_model, h = 90)
plot(arima_forecast)
```

### 5.4 Trend Detection

**Long-term Trends:**
```r
# Moving averages
library(zoo)

accidents_daily <- accidents %>%
  group_by(date = as.Date(ACCIDENT_DATE)) %>%
  summarise(crashes = n()) %>%
  mutate(
    ma_7 = rollmean(crashes, k = 7, fill = NA),
    ma_30 = rollmean(crashes, k = 30, fill = NA),
    ma_365 = rollmean(crashes, k = 365, fill = NA)
  )
```

**Change Point Detection:**
```r
library(changepoint)

# Detect significant changes in crash rates
cpt_analysis <- cpt.mean(ts_crashes, method = "PELT")
plot(cpt_analysis)

# Extract change points
change_dates <- cpts(cpt_analysis)
```

**Anomaly Detection:**
```r
# Identify unusual spikes or drops
library(anomalize)

accidents_daily %>%
  time_decompose(crashes) %>%
  anomalize(remainder) %>%
  time_recompose() %>%
  plot_anomalies()
```

---

## Phase 6: Apache Kafka Streaming Integration (Week 4-5)

### 6.1 Kafka Setup

#### Installation (Linux/WSL)

```bash
# Download Kafka
cd ~
wget https://downloads.apache.org/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xzf kafka_2.13-3.6.0.tgz
cd kafka_2.13-3.6.0

# Start Zookeeper (Terminal 1)
bin/zookeeper-server-start.sh config/zookeeper.properties

# Start Kafka Server (Terminal 2)
bin/kafka-server-start.sh config/server.properties

# Create topic for crash data (Terminal 3)
bin/kafka-topics.sh --create \
  --topic victoria-crashes \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Verify topic creation
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

#### Configuration Files

**kafka_config/producer.properties:**
```properties
bootstrap.servers=localhost:9092
key.serializer=org.apache.kafka.common.serialization.StringSerializer
value.serializer=org.apache.kafka.common.serialization.StringSerializer
acks=1
compression.type=gzip
```

**kafka_config/consumer.properties:**
```properties
bootstrap.servers=localhost:9092
group.id=crash-analytics-group
key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
value.deserializer=org.apache.kafka.common.serialization.StringDeserializer
auto.offset.reset=earliest
enable.auto.commit=true
```

### 6.2 Kafka Producer (R Script)

**scripts/06_kafka_producer.R:**

```r
library(rkafka)
library(jsonlite)
library(dplyr)

# Load cleaned accident data
accidents <- readRDS("output/cleaned_accidents.rds")

# Sort by date to simulate chronological streaming
accidents <- accidents %>% arrange(ACCIDENT_DATE, ACCIDENT_TIME)

# Initialize Kafka producer
producer <- kafkaProducer(
  brokers = "localhost:9092",
  topic = "victoria-crashes"
)

# Stream data
cat("Starting crash data stream...\n")

for (i in 1:nrow(accidents)) {
  # Convert row to JSON
  crash_event <- accidents[i, ] %>%
    select(
      ACCIDENT_NO, ACCIDENT_DATE, ACCIDENT_TIME,
      latitude, longitude, ACCIDENT_TYPE,
      severity_score, NO_PERSONS_KILLED, NO_PERSONS_INJ_2,
      SPEED_ZONE, ROAD_GEOMETRY, WEATHER
    ) %>%
    toJSON(auto_unbox = TRUE)

  # Send to Kafka
  produceMessage(
    producer,
    topic = "victoria-crashes",
    key = as.character(accidents$ACCIDENT_NO[i]),
    value = crash_event
  )

  # Progress indicator
  if (i %% 100 == 0) {
    cat(sprintf("Streamed %d/%d records (%.1f%%)\n",
                i, nrow(accidents), (i/nrow(accidents))*100))
  }

  # Simulate streaming delay (adjust as needed)
  Sys.sleep(0.05)  # 50ms delay = ~20 records/second
}

cat("Stream complete!\n")
closeProducer(producer)
```

### 6.3 Kafka Consumer (R Script)

**scripts/07_kafka_consumer.R:**

```r
library(rkafka)
library(jsonlite)
library(dplyr)
library(lubridate)

# Initialize consumer
consumer <- kafkaConsumer(
  brokers = "localhost:9092",
  topics = "victoria-crashes",
  group.id = "crash-analytics-group"
)

# Initialize sliding window buffer (24 hours)
crash_buffer <- list()
window_duration <- hours(24)

# Alert thresholds
HOTSPOT_THRESHOLD <- 10  # crashes in same area within 24h
SEVERITY_THRESHOLD <- 50  # severity score threshold

cat("Starting real-time crash monitoring...\n")

# Main consumption loop
while (TRUE) {
  # Poll for new messages
  messages <- consumeMessages(consumer, n = 10, timeout = 1000)

  if (length(messages) > 0) {
    for (msg in messages) {
      # Parse JSON
      crash <- fromJSON(msg$value)
      crash$timestamp <- now()

      # Add to buffer
      crash_buffer[[length(crash_buffer) + 1]] <- crash

      cat(sprintf("[%s] New crash: %s at (%.4f, %.4f) - Severity: %.1f\n",
                  crash$ACCIDENT_TIME,
                  crash$ACCIDENT_TYPE,
                  crash$latitude,
                  crash$longitude,
                  crash$severity_score))
    }

    # Clean old records from buffer (older than 24 hours)
    current_time <- now()
    crash_buffer <- Filter(function(x) {
      difftime(current_time, x$timestamp, units = "hours") <= 24
    }, crash_buffer)

    # Perform hotspot detection on current window
    if (length(crash_buffer) >= 10) {
      recent_crashes <- bind_rows(crash_buffer)

      # Spatial clustering on recent data
      coords <- cbind(recent_crashes$longitude, recent_crashes$latitude)

      if (nrow(coords) >= 10) {
        clusters <- dbscan::dbscan(coords, eps = 0.01, minPts = 5)

        # Analyze clusters
        cluster_summary <- recent_crashes %>%
          mutate(cluster = clusters$cluster) %>%
          filter(cluster > 0) %>%
          group_by(cluster) %>%
          summarise(
            n_crashes = n(),
            total_severity = sum(severity_score),
            center_lat = mean(latitude),
            center_lon = mean(longitude),
            .groups = "drop"
          ) %>%
          filter(n_crashes >= HOTSPOT_THRESHOLD | total_severity >= SEVERITY_THRESHOLD)

        # Trigger alerts
        if (nrow(cluster_summary) > 0) {
          cat("\n*** ALERT: Emerging hotspot detected! ***\n")
          print(cluster_summary)

          # Send alert (integrate with email/SMS service)
          send_alert(cluster_summary)
        }
      }
    }
  }

  # Brief pause
  Sys.sleep(0.1)
}

closeConsumer(consumer)

# Alert function
send_alert <- function(hotspots) {
  # Log to file
  timestamp <- format(now(), "%Y%m%d_%H%M%S")
  alert_file <- sprintf("output/alerts/alert_%s.csv", timestamp)
  write.csv(hotspots, alert_file, row.names = FALSE)

  # Could integrate with:
  # - Email notifications (mailR package)
  # - SMS alerts (twilio API)
  # - Slack/Discord webhooks
  # - Database logging
}
```

### 6.4 Real-Time Analytics Features

**Sliding Window Aggregation:**
- Maintain 24-hour rolling window of crashes
- Hourly aggregations for trend detection
- Comparison with historical averages

**Dynamic Hotspot Detection:**
- Real-time DBSCAN clustering
- Alert when cluster density exceeds threshold
- Severity-weighted scoring

**Alert System:**
- Console notifications
- File logging (CSV export)
- Extensible to email/SMS integration
- Configurable thresholds

**Monitoring Dashboard:**
- Display active stream count
- Show recent crashes in real-time
- Visualize emerging hotspots on map
- Track alert history

---

## Phase 7: Interactive Shiny Dashboard (Week 5-6)

### 7.1 Dashboard Architecture

**File Structure:**
```
shiny_app/
├── global.R         # Load data, libraries, shared functions
├── ui.R             # User interface definition
├── server.R         # Server logic
├── www/             # Static assets (CSS, images)
│   └── custom.css
└── modules/         # Modular components
    ├── overview.R
    ├── spatial.R
    ├── temporal.R
    ├── streaming.R
    └── analysis.R
```

### 7.2 Dashboard Pages

#### Page 1: Overview Dashboard

**Components:**
```r
# ui.R - Overview tab
tabPanel(
  "Overview",
  fluidRow(
    valueBoxOutput("total_crashes"),
    valueBoxOutput("total_fatalities"),
    valueBoxOutput("total_injuries"),
    valueBoxOutput("avg_severity")
  ),
  fluidRow(
    box(
      title = "Crash Trends Over Time",
      plotlyOutput("trend_plot"),
      width = 8
    ),
    box(
      title = "Filters",
      dateRangeInput("date_range", "Date Range"),
      selectInput("severity_filter", "Severity", choices = c("All", "Fatal", "Serious")),
      selectInput("region_filter", "Region", choices = c("All", "Metro", "Regional")),
      width = 4
    )
  ),
  fluidRow(
    box(
      title = "Top 10 Hotspots",
      DTOutput("hotspots_table"),
      width = 12
    )
  )
)
```

#### Page 2: Spatial Analysis

**Interactive Map:**
```r
# ui.R - Spatial tab
tabPanel(
  "Spatial Analysis",
  fluidRow(
    box(
      leafletOutput("crash_map", height = 600),
      width = 9
    ),
    box(
      title = "Map Controls",
      checkboxGroupInput(
        "map_layers",
        "Layers",
        choices = c("Crash Points", "Heatmap", "Clusters", "Roads"),
        selected = c("Crash Points", "Clusters")
      ),
      sliderInput("cluster_radius", "Cluster Radius (km)", 0.5, 5, 1),
      selectInput("severity_color", "Color By", choices = c("Severity", "Type", "Time")),
      hr(),
      h4("Click a marker for details"),
      htmlOutput("selected_crash_info"),
      width = 3
    )
  )
)

# server.R - Spatial logic
output$crash_map <- renderLeaflet({
  filtered_data <- filter_data()

  leaflet(filtered_data) %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    addCircleMarkers(
      lng = ~longitude,
      lat = ~latitude,
      radius = ~severity_score / 2,
      color = ~severity_color_scale(severity_score),
      popup = ~paste(
        "<b>Accident:</b>", ACCIDENT_NO, "<br>",
        "<b>Date:</b>", ACCIDENT_DATE, "<br>",
        "<b>Type:</b>", ACCIDENT_TYPE, "<br>",
        "<b>Severity:</b>", severity_score
      ),
      clusterOptions = markerClusterOptions()
    ) %>%
    addHeatmap(
      lng = ~longitude,
      lat = ~latitude,
      intensity = ~severity_score,
      blur = 20,
      max = 0.5,
      radius = 15,
      group = "Heatmap"
    ) %>%
    addLayersControl(
      overlayGroups = c("Crash Points", "Heatmap"),
      options = layersControlOptions(collapsed = FALSE)
    )
})
```

#### Page 3: Temporal Patterns

**Time Analysis:**
```r
# ui.R - Temporal tab
tabPanel(
  "Temporal Patterns",
  fluidRow(
    box(
      title = "Hour of Day Distribution",
      plotlyOutput("hourly_heatmap"),
      width = 6
    ),
    box(
      title = "Day of Week Pattern",
      plotlyOutput("daily_bars"),
      width = 6
    )
  ),
  fluidRow(
    box(
      title = "Seasonal Trends",
      plotlyOutput("seasonal_plot"),
      width = 12
    )
  ),
  fluidRow(
    box(
      title = "Forecast",
      plotlyOutput("forecast_plot"),
      sliderInput("forecast_horizon", "Forecast Days", 30, 365, 90),
      actionButton("run_forecast", "Generate Forecast"),
      width = 12
    )
  )
)
```

#### Page 4: Real-Time Monitoring

**Live Stream Visualization:**
```r
# ui.R - Streaming tab
tabPanel(
  "Real-Time Monitoring",
  fluidRow(
    valueBoxOutput("stream_status"),
    valueBoxOutput("recent_crashes_count"),
    valueBoxOutput("active_alerts")
  ),
  fluidRow(
    box(
      title = "Live Crash Feed (Last 24 Hours)",
      leafletOutput("live_map", height = 400),
      width = 8
    ),
    box(
      title = "Recent Crashes",
      DTOutput("recent_crashes_table"),
      width = 4
    )
  ),
  fluidRow(
    box(
      title = "Active Alerts",
      DTOutput("alerts_table"),
      downloadButton("download_alerts", "Export Alerts"),
      width = 12
    )
  )
)

# server.R - Real-time updates
observe({
  # Auto-refresh every 5 seconds
  invalidateLater(5000)

  # Read latest data from Kafka consumer buffer
  recent_data <- read_recent_crashes()

  output$recent_crashes_table <- renderDT({
    datatable(
      recent_data %>% select(timestamp, ACCIDENT_TYPE, latitude, longitude, severity_score),
      options = list(pageLength = 10, order = list(list(0, 'desc')))
    )
  })

  # Update map
  leafletProxy("live_map") %>%
    clearMarkers() %>%
    addCircleMarkers(
      data = recent_data,
      lng = ~longitude,
      lat = ~latitude,
      radius = 5,
      color = "red",
      fillOpacity = 0.7
    )
})
```

#### Page 5: Detailed Analysis

**Custom Queries:**
```r
# ui.R - Analysis tab
tabPanel(
  "Detailed Analysis",
  fluidRow(
    box(
      title = "Vehicle Type Analysis",
      plotlyOutput("vehicle_plot"),
      width = 6
    ),
    box(
      title = "Weather Impact",
      plotlyOutput("weather_plot"),
      width = 6
    )
  ),
  fluidRow(
    box(
      title = "Road Condition Breakdown",
      plotlyOutput("road_condition_plot"),
      width = 6
    ),
    box(
      title = "Severity Factors",
      plotlyOutput("severity_factors_plot"),
      width = 6
    )
  ),
  fluidRow(
    box(
      title = "Custom Query Builder",
      selectInput("query_variable", "Analyze By:",
                  choices = c("Vehicle Type", "Road Type", "Speed Zone", "Weather")),
      selectInput("query_metric", "Metric:",
                  choices = c("Count", "Severity Score", "Fatality Rate")),
      actionButton("run_query", "Run Analysis"),
      hr(),
      plotlyOutput("custom_query_plot"),
      width = 12
    )
  )
)
```

### 7.3 Interactivity Features

**Filters & Controls:**
- Date range slider (min: 2012, max: latest date)
- Multi-select dropdowns (road type, weather, vehicle type)
- Severity level toggles
- Geographic boundary selection
- Time-of-day filter

**Downloads:**
- Export filtered data as CSV
- Download plots as PNG/PDF
- Generate PDF reports
- Export hotspot coordinates

**Bookmarks:**
- Save filter configurations
- Share dashboard URLs with specific views
- Restore previous sessions

**Responsiveness:**
- Mobile-friendly layout
- Adaptive plot sizing
- Touch-friendly controls

### 7.4 Deployment

**Local Testing:**
```r
# Run locally
library(shiny)
runApp("shiny_app")
```

**Cloud Deployment (shinyapps.io):**
```r
library(rsconnect)

# Configure account
setAccountInfo(name='your-account',
               token='your-token',
               secret='your-secret')

# Deploy
deployApp(appDir = "shiny_app",
          appName = "victoria-crash-analysis")
```

---

## Phase 8: Advanced Analytics (Week 6-7)

### 8.1 Spatio-Temporal Integration

**Animated Hotspot Evolution:**
```r
library(gganimate)
library(ggplot2)

# Aggregate by month and location
monthly_hotspots <- accidents %>%
  mutate(month = floor_date(ACCIDENT_DATE, "month")) %>%
  group_by(month, cluster_id) %>%
  summarise(
    n_crashes = n(),
    center_lat = mean(latitude),
    center_lon = mean(longitude),
    .groups = "drop"
  )

# Create animation
anim <- ggplot(monthly_hotspots, aes(x = center_lon, y = center_lat)) +
  geom_point(aes(size = n_crashes, color = n_crashes), alpha = 0.6) +
  scale_color_viridis_c() +
  transition_time(month) +
  labs(title = "Crash Hotspots Over Time: {frame_time}") +
  shadow_mark(alpha = 0.2)

animate(anim, nframes = 100, fps = 10)
anim_save("output/figures/hotspot_evolution.gif")
```

**3D Visualization:**
```r
library(plotly)

# Create 3D scatter: lat, lon, time
plot_ly(
  data = accidents,
  x = ~longitude,
  y = ~latitude,
  z = ~as.numeric(ACCIDENT_DATE),
  color = ~severity_score,
  type = "scatter3d",
  mode = "markers",
  marker = list(size = 2)
) %>%
  layout(
    title = "Spatio-Temporal Crash Distribution",
    scene = list(
      xaxis = list(title = "Longitude"),
      yaxis = list(title = "Latitude"),
      zaxis = list(title = "Date")
    )
  )
```

**Dynamic Clustering:**
```r
# Hotspots that vary by time of day
morning_rush <- accidents %>%
  filter(hour %in% 7:9) %>%
  select(longitude, latitude)

evening_rush <- accidents %>%
  filter(hour %in% 16:19) %>%
  select(longitude, latitude)

morning_clusters <- dbscan(morning_rush, eps = 0.01, minPts = 10)
evening_clusters <- dbscan(evening_rush, eps = 0.01, minPts = 10)

# Compare cluster locations
```

### 8.2 Predictive Modeling

**Crash Risk Prediction:**
```r
library(randomForest)
library(xgboost)

# Feature engineering
model_data <- accidents %>%
  mutate(
    # Target: High severity crash (binary)
    high_severity = ifelse(severity_score > median(severity_score), 1, 0),

    # Features
    hour = hour(ACCIDENT_TIME),
    day_of_week = wday(ACCIDENT_DATE),
    month = month(ACCIDENT_DATE),
    is_weekend = ifelse(day_of_week %in% c(1, 7), 1, 0),
    is_rush_hour = ifelse(hour %in% c(7:9, 16:19), 1, 0)
  ) %>%
  select(
    high_severity,
    hour, day_of_week, month, is_weekend, is_rush_hour,
    SPEED_ZONE, ROAD_GEOMETRY, WEATHER, LIGHT_CONDITION,
    latitude, longitude
  )

# Split data
set.seed(123)
train_idx <- sample(1:nrow(model_data), 0.8 * nrow(model_data))
train_data <- model_data[train_idx, ]
test_data <- model_data[-train_idx, ]

# Random Forest
rf_model <- randomForest(
  high_severity ~ .,
  data = train_data,
  ntree = 500,
  importance = TRUE
)

# Predictions
rf_pred <- predict(rf_model, test_data)

# Evaluation
confusionMatrix(rf_pred, test_data$high_severity)

# Feature importance
varImpPlot(rf_model)
```

**XGBoost Model:**
```r
# Prepare data
train_matrix <- xgb.DMatrix(
  data = as.matrix(train_data %>% select(-high_severity)),
  label = train_data$high_severity
)

test_matrix <- xgb.DMatrix(
  data = as.matrix(test_data %>% select(-high_severity)),
  label = test_data$high_severity
)

# Train model
xgb_model <- xgb.train(
  data = train_matrix,
  nrounds = 100,
  objective = "binary:logistic",
  eval_metric = "auc",
  max_depth = 6,
  eta = 0.3
)

# Predictions
xgb_pred <- predict(xgb_model, test_matrix)

# Feature importance
importance_matrix <- xgb.importance(model = xgb_model)
xgb.plot.importance(importance_matrix)
```

**Model Deployment:**
```r
# Save model
saveRDS(rf_model, "output/models/crash_risk_rf.rds")

# Create prediction function
predict_crash_risk <- function(location, time, conditions) {
  # Prepare input
  input_data <- data.frame(
    latitude = location$lat,
    longitude = location$lon,
    hour = hour(time),
    day_of_week = wday(time),
    month = month(time),
    SPEED_ZONE = conditions$speed_zone,
    ROAD_GEOMETRY = conditions$road_geometry,
    WEATHER = conditions$weather,
    LIGHT_CONDITION = conditions$light
  )

  # Predict
  risk_score <- predict(rf_model, input_data, type = "prob")[, 2]

  return(list(
    risk_score = risk_score,
    risk_level = ifelse(risk_score > 0.7, "High",
                       ifelse(risk_score > 0.4, "Medium", "Low"))
  ))
}
```

### 8.3 Policy Insights & Recommendations

**Infrastructure Improvements:**
```r
# Identify top priority locations
priority_locations <- hotspots %>%
  filter(n_crashes > quantile(n_crashes, 0.9) |
         total_fatalities > 0) %>%
  arrange(desc(total_severity)) %>%
  head(20) %>%
  mutate(
    recommendation = case_when(
      road_geometry == "Cross intersection" ~ "Install traffic lights or roundabout",
      road_geometry == "T intersection" ~ "Improve visibility, add signage",
      SPEED_ZONE > 80 ~ "Consider speed reduction",
      LIGHT_CONDITION == "Dark" ~ "Improve street lighting",
      TRUE ~ "Comprehensive safety audit required"
    )
  )

# Export recommendations
write.csv(priority_locations, "output/reports/infrastructure_priorities.csv")
```

**Enforcement Strategies:**
```r
# Optimal times for traffic enforcement
enforcement_schedule <- accidents %>%
  group_by(hour, day_of_week) %>%
  summarise(
    n_crashes = n(),
    n_speeding = sum(grepl("speed", ACCIDENT_TYPE, ignore.case = TRUE)),
    n_dui = sum(grepl("alcohol", ACCIDENT_TYPE, ignore.case = TRUE)),
    .groups = "drop"
  ) %>%
  filter(n_crashes > quantile(n_crashes, 0.75))

# Identify high-DUI periods
dui_hotspots <- enforcement_schedule %>%
  filter(n_dui > 5) %>%
  arrange(desc(n_dui))

# Speed camera priorities
speed_hotspots <- accidents %>%
  filter(SPEED_ZONE > 0) %>%
  group_by(NODE_ID, SPEED_ZONE) %>%
  summarise(
    n_crashes = n(),
    avg_severity = mean(severity_score),
    .groups = "drop"
  ) %>%
  filter(n_crashes > 10) %>%
  arrange(desc(n_crashes))
```

**Resource Allocation:**
```r
# Ambulance station optimization
high_severity_zones <- accidents %>%
  filter(NO_PERSONS_KILLED > 0 | NO_PERSONS_INJ_2 > 0) %>%
  group_by(cluster_id) %>%
  summarise(
    n_severe = n(),
    center_lat = mean(latitude),
    center_lon = mean(longitude),
    avg_response_priority = mean(severity_score)
  ) %>%
  arrange(desc(avg_response_priority))

# Identify underserved areas
# (Compare with existing emergency service locations)
```

---

## Phase 9: Reporting & Documentation (Week 7-8)

### 9.1 Final Report Structure

**Executive Summary (1-2 pages)**
- Project objectives and scope
- Key findings (3-5 bullet points)
- Top hotspot locations (map visualization)
- Critical recommendations (prioritized list)
- Expected impact of recommendations

**1. Introduction (2-3 pages)**
- Background on Victorian road safety
- Project motivation and objectives
- Research questions
- Dataset overview (size, timeframe, sources)
- Report organization

**2. Methodology (4-5 pages)**

*2.1 Data Sources*
- Victorian road crash database description
- 10 CSV files overview
- Data quality assessment
- Temporal and geographic coverage

*2.2 Data Preprocessing*
- Data cleaning procedures
- Missing value handling
- Feature engineering
- Data integration strategy

*2.3 Analytical Techniques*
- Spatial clustering (DBSCAN, K-means, KDE)
  - Algorithm selection rationale
  - Parameter tuning
  - Validation methods
- Temporal analysis
  - Time-series decomposition
  - Forecasting models (Prophet, ARIMA)
  - Trend detection methods
- Statistical testing
  - Significance testing
  - Hotspot validation

*2.4 Technology Stack*
- R packages and versions
- Apache Kafka architecture
  - Producer/consumer design
  - Real-time processing pipeline
- Shiny dashboard implementation

**3. Exploratory Data Analysis (5-6 pages)**

*3.1 Temporal Patterns*
- Yearly trends (2012-present)
- Seasonal variations
- Day-of-week patterns
- Hourly distributions
- Key insights and visualizations

*3.2 Crash Characteristics*
- Severity distributions
- Crash type frequencies
- Vehicle involvement patterns
- Injury statistics

*3.3 Environmental Factors*
- Weather conditions impact
- Road surface analysis
- Light condition correlations
- Speed zone relationships

*3.4 Geographic Overview*
- Regional distribution
- Urban vs rural patterns
- Road type analysis

**4. Spatial Analysis Results (8-10 pages)**

*4.1 Hotspot Identification*
- Top 50 crash hotspots (table with coordinates)
- Clustering methodology comparison
- Severity-weighted rankings
- Statistical significance results

*4.2 Hotspot Characteristics*
- Geographic distribution map
- Cluster size and density analysis
- Contributing factors for each major hotspot
- Temporal stability analysis

*4.3 High-Risk Locations*
- Detailed profiles of top 10 hotspots:
  - Location details
  - Crash frequency and severity
  - Common crash types
  - Environmental conditions
  - Contributing factors
  - Existing infrastructure

*4.4 Visualizations*
- Interactive maps (include screenshots)
- Heat maps
- Cluster dendrograms
- Kernel density surfaces

**5. Temporal Analysis Results (6-8 pages)**

*5.1 Time-of-Day Patterns*
- Rush hour peaks
- Night-time crash severity
- Hour × Day heatmap
- Hourly patterns by location

*5.2 Seasonal Analysis*
- Monthly crash frequencies
- Seasonal trends
- Weather correlation results
- Holiday period analysis

*5.3 Long-term Trends*
- Year-over-year changes
- Moving average trends
- Change point detection results
- Emerging patterns

*5.4 Forecasting Results*
- 90-day forecast with confidence intervals
- Seasonal decomposition
- Model performance metrics (MAPE, RMSE)
- Validation results

**6. Real-Time Streaming Analytics (4-5 pages)**

*6.1 Apache Kafka Implementation*
- Architecture diagram
- Producer/consumer design
- Data flow description
- Performance metrics

*6.2 Streaming Analytics*
- Sliding window analysis
- Real-time hotspot detection algorithm
- Alert generation logic
- Processing latency measurements

*6.3 Use Cases*
- Emergency response optimization
- Dynamic resource allocation
- Real-time public alerts
- Operational dashboard

*6.4 Results & Validation*
- Alert accuracy
- False positive/negative analysis
- System performance
- Scalability considerations

**7. Predictive Modeling (3-4 pages)**

*7.1 Model Development*
- Feature engineering
- Model selection (Random Forest, XGBoost)
- Training procedure
- Hyperparameter tuning

*7.2 Model Performance*
- Accuracy, precision, recall, F1-score
- ROC curves and AUC
- Confusion matrices
- Cross-validation results

*7.3 Feature Importance*
- Most influential factors
- Interaction effects
- Interpretation

*7.4 Risk Prediction*
- Risk score calculation
- Geographic risk maps
- Temporal risk profiles

**8. Policy Recommendations (6-8 pages)**

*8.1 Infrastructure Improvements*
- Priority list (20 locations)
- Specific interventions for each location:
  - Traffic signal installation
  - Roundabout construction
  - Street lighting upgrades
  - Road geometry modifications
  - Signage improvements
- Cost-benefit analysis
- Expected impact

*8.2 Enforcement Strategies*
- Optimal deployment schedules
- DUI checkpoint recommendations
- Speed camera placements
- Resource allocation guidance

*8.3 Public Awareness Campaigns*
- Target demographics
- High-risk time periods
- Geographic focus areas
- Messaging recommendations

*8.4 Emergency Response*
- Ambulance station optimization
- Response route planning
- Resource pre-positioning

*8.5 Implementation Roadmap*
- Short-term actions (0-6 months)
- Medium-term initiatives (6-18 months)
- Long-term strategies (18+ months)

**9. Interactive Dashboard (2-3 pages)**
- Dashboard features and capabilities
- User guide (screenshots)
- Access instructions
- Use cases for different stakeholders

**10. Limitations & Future Work (2-3 pages)**

*10.1 Limitations*
- Data constraints
- Methodological limitations
- Generalizability concerns

*10.2 Future Research Directions*
- Additional data sources (traffic volume, demographics)
- Advanced modeling techniques (deep learning, GIS integration)
- Causal inference studies
- Intervention evaluation

**11. Conclusion (1-2 pages)**
- Summary of key findings
- Answers to research questions
- Expected impact
- Final remarks

**References**
- Academic papers
- Technical documentation
- Data sources

**Appendices**
- Appendix A: Data dictionary
- Appendix B: Code repository structure
- Appendix C: Additional visualizations
- Appendix D: Statistical tables
- Appendix E: Dashboard screenshots

### 9.2 Technical Documentation

**README.md:**
```markdown
# Victorian Road Crash Spatio-Temporal Analysis

## Project Overview
[Brief description]

## Dataset
- Source: Victorian Government
- Size: 191 MB, 2.2M rows
- Time period: 2012-present
- 10 CSV files

## Requirements
### R Packages
[List all packages]

### Apache Kafka
- Version: 3.6.0
- Installation instructions: [link]

## Project Structure
[Directory tree]

## Usage

### Data Preparation
```r
source("scripts/01_data_loading.R")
source("scripts/02_data_cleaning.R")
```

### Analysis
```r
source("scripts/03_eda.R")
source("scripts/04_spatial_analysis.R")
source("scripts/05_temporal_analysis.R")
```

### Kafka Streaming
[Terminal commands]

### Shiny Dashboard
```r
runApp("shiny_app")
```

## Results
- Top 50 hotspots: `output/hotspots.csv`
- Visualizations: `output/figures/`
- Models: `output/models/`

## Contributors
[Your name and contact]

## License
[License information]
```

**Code Documentation:**
- Roxygen2 comments for all functions
- Inline comments for complex logic
- README files in each subdirectory

### 9.3 Presentation (15-20 slides)

**Slide Structure:**
1. Title slide
2. Agenda
3. Problem statement & motivation
4. Dataset overview
5. Methodology overview
6. Key findings - Spatial (with map)
7. Key findings - Temporal (with charts)
8. Top 10 hotspots (interactive map)
9. Kafka streaming demo
10. Shiny dashboard demo (screenshots)
11. Predictive modeling results
12. Policy recommendations (prioritized)
13. Expected impact
14. Technical achievements
15. Future work
16. Q&A

**Presentation Tips:**
- Use high-quality visualizations
- Include live demo of Shiny app
- Show Kafka streaming in action
- Focus on actionable insights
- Quantify potential impact

### 9.4 Deliverables Checklist

**Code & Scripts:**
- [ ] All R scripts documented and organized
- [ ] requirements.R with all dependencies
- [ ] Kafka configuration files
- [ ] Shiny app fully functional
- [ ] README.md complete

**Analysis Outputs:**
- [ ] Cleaned datasets (RDS/CSV)
- [ ] Hotspot catalog (CSV with coordinates)
- [ ] All visualizations (PNG/PDF)
- [ ] Statistical test results
- [ ] Saved models (RDS)
- [ ] Forecast outputs

**Reports:**
- [ ] Final report (PDF/HTML)
- [ ] Executive summary (2-page PDF)
- [ ] Technical documentation
- [ ] Presentation slides (PPTX/PDF)

**Dashboard:**
- [ ] Shiny app deployed (shinyapps.io URL)
- [ ] User guide document
- [ ] Demo video (optional)

**Streaming:**
- [ ] Kafka setup guide
- [ ] Producer/consumer scripts tested
- [ ] Alert logs
- [ ] Performance benchmarks

---

## Timeline Summary

| Week | Phase | Key Activities | Deliverables |
|------|-------|----------------|--------------|
| **1** | Setup & Data Prep | Environment setup, install packages, load data, initial cleaning | Project structure, cleaned datasets |
| **2** | EDA | Descriptive statistics, visualizations, data exploration | EDA report, initial plots |
| **3** | Spatial Analysis | Implement clustering algorithms, identify hotspots, create maps | Hotspot catalog, spatial visualizations |
| **4** | Temporal Analysis & Kafka | Time-series analysis, forecasting, Kafka setup | Temporal analysis report, Kafka infrastructure |
| **5** | Kafka Integration & Shiny Start | Producer/consumer implementation, start dashboard | Working streaming system, dashboard skeleton |
| **6** | Shiny Development | Build all dashboard pages, integrate data and visualizations | Fully functional dashboard |
| **7** | Advanced Analytics & Reporting | Predictive modeling, animations, start final report | Models, advanced visualizations, draft report |
| **8** | Finalization | Complete report, prepare presentation, testing, deployment | Final report, presentation, deployed dashboard |

---

## Success Criteria

### Question 1: Where are the most frequent and severe crash hotspots?
✓ Identify and validate top 20-50 crash hotspots
✓ Provide geographic coordinates and severity scores
✓ Statistical significance testing completed
✓ Interactive map visualization available

### Question 2: When do crashes peak in these locations?
✓ Document hourly, daily, and seasonal patterns
✓ Identify rush hour peaks and high-risk periods
✓ Correlation with environmental factors
✓ Temporal heatmaps and visualizations

### Question 3: How do crash trends evolve?
✓ Detect 3-5 emerging high-risk areas
✓ Long-term trend analysis (2012-present)
✓ 90-day forecast with confidence intervals
✓ Change point detection completed

### Question 4: Can Kafka provide real-time alerts?
✓ Working Kafka producer and consumer
✓ Real-time hotspot detection operational
✓ Alert system functional (with logging)
✓ Demonstrated in live dashboard

### Overall Deliverables
✓ Comprehensive final report (40-60 pages)
✓ Interactive Shiny dashboard (5+ pages)
✓ Policy recommendations (20+ specific actions)
✓ All code documented and reproducible
✓ Presentation ready (15-20 slides)
✓ Technical documentation complete

---

## Key Technologies Summary

| Category | Technologies |
|----------|-------------|
| **Programming** | R (primary language) |
| **Data Processing** | dplyr, tidyr, data.table, lubridate |
| **Spatial Analysis** | sf, sp, leaflet, ggmap, dbscan |
| **Visualization** | ggplot2, plotly, gganimate, viridis |
| **Time-Series** | forecast, tsibble, prophet, zoo |
| **Machine Learning** | randomForest, xgboost, caret |
| **Dashboard** | Shiny, shinydashboard, DT |
| **Streaming** | Apache Kafka, rkafka, jsonlite |
| **Reporting** | R Markdown, knitr |

---

## Resources & References

### Documentation
- R Documentation: https://www.r-project.org/
- Apache Kafka: https://kafka.apache.org/documentation/
- Shiny: https://shiny.rstudio.com/
- Victorian Road Crash Data: [data source URL]

### Key Papers & Methods
- DBSCAN: Ester et al. (1996)
- Kernel Density Estimation: Silverman (1986)
- Prophet Forecasting: Taylor & Letham (2018)
- Spatial Statistics: Getis-Ord Gi* statistic

### Tutorials
- Leaflet for R: https://rstudio.github.io/leaflet/
- Time Series with R: https://otexts.com/fpp3/
- Kafka with R: [relevant tutorials]

---

## Contact & Support

**Project Owner:** [Your Name]
**Email:** [Your Email]
**Institution:** Swinburne University of Technology
**Course:** Big Data Analytics - Semester 4

**Project Repository:** [GitHub URL]
**Dashboard URL:** [Shiny app URL]

---

**Document Version:** 1.0
**Last Updated:** 2025-01-04
**Status:** Planning Phase
