# Simplified 1-Week Implementation Plan (WITH KAFKA)

## Victorian Road Crash Analysis - Simplified Version

**Deadline:** 1 Week
**Focus:** Core analysis + Simple Kafka streaming

---

## Simplified Scope

### What We'll Do:
✓ Load and clean data
✓ Basic exploratory analysis
✓ Identify crash hotspots (DBSCAN clustering)
✓ Temporal pattern analysis (hourly, daily, seasonal)
✓ **Simple Kafka producer/consumer (simulated streaming)**
✓ Interactive map with Leaflet
✓ Basic visualizations
✓ Simple Shiny dashboard with live feed
✓ Final report with key findings

### What We'll Skip:
✗ Advanced predictive models (XGBoost, Random Forest)
✗ Animated visualizations (gganimate)
✗ 3D visualizations
✗ Complex forecasting (Prophet, ARIMA) - use simple trends only
✗ Multiple clustering methods comparison - stick to DBSCAN only

---

## Day-by-Day Plan

### Day 1: Setup & Data Preparation
**Time:** 4-5 hours

1. Create project structure
2. Install essential R packages
3. **Install Kafka (basic setup)**
4. Load all CSV files
5. Basic data cleaning and validation
6. Create master dataset

**Deliverable:** Cleaned data + Kafka installed

---

### Day 2: Exploratory Data Analysis
**Time:** 4-5 hours

1. Summary statistics
2. Temporal distributions (hourly, daily, monthly)
3. Severity analysis
4. Basic visualizations (ggplot2)
5. Identify data patterns

**Deliverable:** EDA report with key insights

---

### Day 3: Spatial Analysis + Simple Kafka Producer
**Time:** 5-6 hours

1. Extract coordinates from data
2. Run DBSCAN clustering
3. Identify top 20 hotspots
4. **Create simple Kafka producer** (stream historical data)
5. Create interactive Leaflet map

**Deliverable:** Hotspot list, map, and working Kafka producer

---

### Day 4: Kafka Consumer + Temporal Analysis
**Time:** 5-6 hours

1. **Create Kafka consumer** (read stream and detect hotspots)
2. **Simple real-time alerting** (console output)
3. Hour-of-day patterns
4. Day-of-week patterns
5. Seasonal trends

**Deliverable:** Working Kafka consumer with alerts + temporal analysis

---

### Day 5: Visualizations & Dashboard
**Time:** 5-6 hours

1. Create key visualizations (ggplot2, plotly)
2. Build Shiny dashboard (3 pages)
   - Overview with summary stats
   - Interactive map
   - **Real-time Kafka feed viewer**
3. Test dashboard

**Deliverable:** Working Shiny dashboard with Kafka integration

---

### Day 6: Report Writing
**Time:** 4-5 hours

1. Write analysis report (12-18 pages)
2. Include Kafka architecture section
3. Add visualizations
4. Policy recommendations
5. Create presentation slides (12-15 slides)

**Deliverable:** Final report and presentation

---

### Day 7: Finalization & Testing
**Time:** 2-3 hours

1. Review all outputs
2. Test dashboard and Kafka streaming
3. Proofread report
4. Final adjustments
5. Prepare for submission

**Deliverable:** Complete project ready for submission

---

## Simplified Project Structure

```
BigData/
├── data/                       # Raw data (existing)
├── scripts/
│   ├── 01_load_data.R         # Load all CSV files
│   ├── 02_clean_data.R        # Clean and prepare data
│   ├── 03_eda.R               # Exploratory analysis
│   ├── 04_hotspots.R          # DBSCAN clustering
│   ├── 05_temporal.R          # Temporal patterns
│   ├── 06_kafka_producer.R    # SIMPLE Kafka producer
│   └── 07_kafka_consumer.R    # SIMPLE Kafka consumer
├── kafka_setup/
│   ├── install_kafka.sh       # Installation script
│   └── README.md              # Setup instructions
├── shiny_app/
│   ├── app.R                  # Single-file Shiny app
│   └── www/                   # Static files
├── output/
│   ├── figures/               # Plots and maps
│   ├── data/                  # Cleaned data
│   ├── kafka_logs/            # Streaming logs
│   └── reports/               # Final report
├── requirements.R             # Package installation
├── SIMPLE_1_WEEK_PLAN.md     # This plan
└── run_analysis.R            # Master script (without Kafka)
```

---

## Essential R Packages

```r
# Data manipulation
install.packages(c("dplyr", "tidyr", "lubridate", "readr"))

# Spatial analysis
install.packages(c("sf", "leaflet", "dbscan"))

# Visualization
install.packages(c("ggplot2", "plotly"))

# Dashboard
install.packages(c("shiny", "shinydashboard", "DT"))

# Kafka (SIMPLE approach - use system calls or simple library)
install.packages(c("jsonlite"))  # For JSON formatting

# Reporting
install.packages(c("rmarkdown", "knitr"))
```

---

## Simplified Kafka Implementation

### Approach: Keep It Simple!

**Strategy:**
- Install Kafka locally (or use Docker for easy setup)
- Create SIMPLE producer in R (streams historical data line by line)
- Create SIMPLE consumer in R (reads stream, aggregates recent crashes)
- Basic alerting: Print to console when hotspot detected
- Log everything to CSV files for dashboard

### Kafka Setup (Easy Method)

```bash
# Option 1: Docker (EASIEST - 5 minutes)
docker run -d --name zookeeper -p 2181:2181 zookeeper
docker run -d --name kafka -p 9092:9092 \
  --link zookeeper \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  confluentinc/cp-kafka

# Option 2: Direct install (if no Docker)
# Download and extract Kafka
# Start Zookeeper and Kafka server
```

### Simple Kafka Producer (R)

```r
# Use system calls to Kafka command line (simplest approach)
# OR use kafkaR package for basic operations

library(jsonlite)

# Read cleaned data
crashes <- readRDS("output/data/cleaned_crashes.rds")

# Stream each row as a message
for (i in 1:nrow(crashes)) {
  # Convert to JSON
  message <- toJSON(crashes[i, ], auto_unbox = TRUE)

  # Write to file that Kafka producer reads
  # OR use system command
  system(paste0(
    "echo '", message, "' | ",
    "kafka-console-producer.sh --broker-list localhost:9092 --topic crashes"
  ))

  Sys.sleep(0.1)  # Simulate streaming
}
```

### Simple Kafka Consumer (R)

```r
# Read from Kafka and detect hotspots in real-time

library(dplyr)
library(dbscan)

# Buffer for recent crashes (last 1 hour)
crash_buffer <- data.frame()

while(TRUE) {
  # Read messages from Kafka
  # Use system command or kafkaR
  new_messages <- read_kafka_messages()

  if(nrow(new_messages) > 0) {
    crash_buffer <- rbind(crash_buffer, new_messages)

    # Keep only last 1 hour
    crash_buffer <- crash_buffer %>%
      filter(timestamp > Sys.time() - 3600)

    # Run DBSCAN on recent data
    if(nrow(crash_buffer) >= 10) {
      coords <- cbind(crash_buffer$lon, crash_buffer$lat)
      clusters <- dbscan(coords, eps = 0.01, minPts = 5)

      # Check for hotspots
      hotspots <- crash_buffer %>%
        mutate(cluster = clusters$cluster) %>%
        filter(cluster > 0) %>%
        group_by(cluster) %>%
        summarise(n = n(), severity = sum(severity_score))

      if(any(hotspots$n >= 5)) {
        cat("*** ALERT: Hotspot detected! ***\n")
        print(hotspots)

        # Log to file
        write.csv(hotspots,
                  paste0("output/kafka_logs/alert_", Sys.time(), ".csv"))
      }
    }
  }

  Sys.sleep(1)  # Check every second
}
```

---

## Simplified Dashboard with Kafka

### 3-Page Dashboard

**Page 1: Overview**
- Total crashes, fatalities, injuries
- Trend chart
- Top 10 hotspots table

**Page 2: Hotspot Map**
- Interactive Leaflet map
- Click markers for details
- Filter by date, severity

**Page 3: Real-Time Stream (KAFKA)**
- Display recent crashes (last hour)
- Show when consumer detects hotspots
- Alert log table
- Stream status indicator

### Shiny App Structure

```r
# app.R (single file for simplicity)

library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(dplyr)

# Load data
crashes <- readRDS("output/data/cleaned_crashes.rds")
hotspots <- read.csv("output/data/hotspots.csv")

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Victoria Crash Analysis"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview"),
      menuItem("Hotspot Map", tabName = "map"),
      menuItem("Live Stream", tabName = "stream")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview", ...),
      tabItem(tabName = "map", ...),
      tabItem(tabName = "stream",
        fluidRow(
          valueBoxOutput("stream_status"),
          valueBoxOutput("recent_count")
        ),
        fluidRow(
          box(title = "Recent Crashes (Last Hour)",
              DTOutput("recent_table"), width = 12)
        ),
        fluidRow(
          box(title = "Alerts Log",
              DTOutput("alerts_table"), width = 12)
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  # Auto-refresh every 5 seconds
  autoInvalidate <- reactiveTimer(5000)

  observe({
    autoInvalidate()

    # Read latest Kafka logs
    recent <- read.csv("output/kafka_logs/recent_crashes.csv")
    alerts <- read.csv("output/kafka_logs/alerts.csv")

    output$recent_table <- renderDT({
      datatable(recent)
    })

    output$alerts_table <- renderDT({
      datatable(alerts)
    })
  })
}

shinyApp(ui, server)
```

---

## Simplified Report Structure (12-18 pages)

1. **Executive Summary** (1 page)
2. **Introduction** (1-2 pages)
3. **Methodology** (3-4 pages)
   - Data preparation
   - DBSCAN clustering
   - **Kafka streaming architecture (SIMPLIFIED)**
4. **Results** (6-8 pages)
   - Spatial analysis & hotspots
   - Temporal patterns
   - **Real-time streaming results**
5. **Recommendations** (1-2 pages)
6. **Conclusion** (1 page)

**Kafka Section (Simplified):**
- Architecture diagram (simple: Producer → Kafka → Consumer)
- What data is streamed (crash records as JSON)
- How consumer detects hotspots (DBSCAN on sliding window)
- Example alerts generated
- Screenshot of live dashboard

---

## Answers to Core Questions

### Q1: Where are crash hotspots?
- Use DBSCAN clustering
- Identify top 20 locations
- Show on interactive map

### Q2: When do crashes peak?
- Analyze hour-of-day distribution
- Day-of-week patterns
- Monthly trends

### Q3: How do trends evolve?
- Simple year-over-year comparison
- Monthly trend lines
- Identify increasing/decreasing areas

### Q4: Real-time streaming with Kafka?
- **YES! Simple producer/consumer**
- Stream historical data as simulation
- Consumer detects hotspots in real-time
- Dashboard shows live feed
- Alerts logged to files

---

## Time Management

### Critical Path:
1. **Days 1-2:** Data prep + EDA (foundation)
2. **Day 3:** Kafka setup + Producer (must work)
3. **Day 4:** Consumer + Alerting (core requirement)
4. **Day 5:** Dashboard integration (show it works)
5. **Days 6-7:** Report + polish

### If Running Out of Time:
- Use Docker for Kafka (fastest setup)
- Keep producer/consumer VERY simple (even bash scripts if needed)
- Dashboard can just read log files (no real-time connection needed)
- Focus on demonstrating the concept works

---

## Success Criteria

✓ Identify 20+ crash hotspots
✓ Document temporal patterns
✓ **Working Kafka producer that streams data**
✓ **Working Kafka consumer that detects hotspots**
✓ **Dashboard shows live stream data**
✓ 12+ page report with Kafka architecture
✓ All code runs without errors

---

**This plan includes Kafka while keeping it achievable in 1 week!**

Next Steps: Let's start Day 1 implementation now.
