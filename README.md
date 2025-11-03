# Victorian Road Crash Analysis with Kafka Streaming

## Spatio-Temporal Hotspot Detection and Trend Analysis

**Academic Project** - Swinburne University, Big Data Analytics, Semester 4
**Timeline:** 1 Week Implementation
**Dataset:** Victorian Road Crash Data (191 MB, 2.2M records)

---

## Quick Start Guide

### Step 1: Install R Packages (10-15 minutes)

```r
# Open R or RStudio and run:
source("requirements.R")
```

This will install all necessary packages:
- Data manipulation: dplyr, tidyr, lubridate
- Spatial analysis: sf, leaflet, dbscan
- Visualization: ggplot2, plotly
- Dashboard: shiny, shinydashboard
- Kafka integration: jsonlite

### Step 2: Install Kafka (5-10 minutes)

**Option A: Docker (Recommended - Easiest)**
```bash
cd kafka_setup
./install_kafka_docker.sh
```

**Option B: Manual Installation**
See `kafka_setup/README.md` for detailed instructions

### Step 3: Run Analysis Scripts

```r
# 1. Load data
source("scripts/01_load_data.R")

# 2. Clean data
source("scripts/02_clean_data.R")

# 3. Exploratory analysis
source("scripts/03_eda.R")

# 4. Identify hotspots
source("scripts/04_hotspots.R")

# 5. Temporal analysis
source("scripts/05_temporal.R")
```

### Step 4: Run Kafka Streaming

**Terminal 1 - Start Producer:**
```bash
Rscript scripts/06_kafka_producer.R
```

**Terminal 2 - Start Consumer:**
```bash
Rscript scripts/07_kafka_consumer.R
```

### Step 5: Launch Dashboard

```r
library(shiny)
runApp("shiny_app")
```

---

## Project Structure

```
BigData/
├── README.md                       # This file
├── SIMPLE_1_WEEK_PLAN.md          # Detailed 1-week implementation plan
├── PROJECT_IMPLEMENTATION_PLAN.md  # Full project documentation
├── requirements.R                  # Package installation script
│
├── data/                           # Raw CSV files (already exists)
│   ├── accident.csv               # Primary crash data (182,040 rows)
│   ├── vehicle.csv                # Vehicle information (331,993 rows)
│   ├── person.csv                 # Person details (425,353 rows)
│   ├── accident_location.csv     # Location data
│   ├── node.csv                   # Geographic coordinates
│   ├── atmospheric_cond.csv      # Weather conditions
│   ├── road_surface_cond.csv     # Road conditions
│   └── ...                        # Additional supporting files
│
├── scripts/                        # R analysis scripts
│   ├── 01_load_data.R             # Load all CSV files
│   ├── 02_clean_data.R            # Data cleaning and preparation
│   ├── 03_eda.R                   # Exploratory data analysis
│   ├── 04_hotspots.R              # DBSCAN clustering for hotspots
│   ├── 05_temporal.R              # Temporal pattern analysis
│   ├── 06_kafka_producer.R        # Kafka producer (stream data)
│   └── 07_kafka_consumer.R        # Kafka consumer (detect hotspots)
│
├── kafka_setup/                    # Kafka installation files
│   ├── README.md                  # Kafka setup instructions
│   └── install_kafka_docker.sh    # Docker installation script
│
├── shiny_app/                      # Interactive dashboard
│   ├── app.R                      # Shiny application
│   └── www/                       # Static assets (CSS, images)
│
└── output/                         # Generated outputs
    ├── data/                      # Cleaned datasets (RDS & CSV)
    ├── figures/                   # Plots and visualizations
    ├── kafka_logs/                # Kafka streaming logs and alerts
    └── reports/                   # Final analysis reports
```

---

## Core Research Questions

This project addresses four key questions:

1. **Where are the most frequent and severe crash hotspots in Victoria?**
   - Method: DBSCAN spatial clustering
   - Output: Top 20-50 hotspot locations with severity scores

2. **When do crashes peak in these locations?**
   - Method: Temporal aggregation (hourly, daily, seasonal)
   - Output: Time-of-day and seasonal pattern analysis

3. **How do crash trends evolve over time?**
   - Method: Time-series analysis and trend detection
   - Output: Year-over-year comparisons and emerging hotspots

4. **Can real-time streaming with Kafka provide crash alerts?**
   - Method: Kafka producer/consumer with real-time DBSCAN
   - Output: Live dashboard with hotspot alerts

---

## Technology Stack

| Category | Technologies |
|----------|-------------|
| Programming | R (4.x+) |
| Data Processing | dplyr, tidyr, data.table, lubridate |
| Spatial Analysis | sf, leaflet, dbscan |
| Visualization | ggplot2, plotly |
| Dashboard | Shiny, shinydashboard |
| Streaming | Apache Kafka |
| Reporting | R Markdown, knitr |

---

## Dataset Overview

### Primary Files

**accident.csv** (182,040 records)
- Core crash information
- Date, time, location, type
- Severity (killed, injured)
- Road conditions, weather, light

**vehicle.csv** (331,993 records)
- Vehicle details (make, model, year)
- Vehicle type and condition
- Damage level

**person.csv** (425,353 records)
- Individual person records
- Age, gender, road user type
- Injury severity

**node.csv** (184,829 records)
- Geographic coordinates (latitude, longitude)
- Location identifiers

**Supporting Files:**
- accident_location.csv - Road names and types
- atmospheric_cond.csv - Weather conditions
- road_surface_cond.csv - Road surface details
- accident_event.csv - Event details
- sub_dca.csv - DCA code subcategories

---

## Analysis Workflow

### Phase 1: Data Preparation
1. Load 10 CSV files (~191 MB)
2. Clean and validate data
3. Parse dates/times, extract temporal features
4. Calculate severity scores
5. Join tables (accident + location + node + conditions)
6. Filter valid records (with coordinates)

**Output:** `crashes_cleaned.rds` (~182K records with complete data)

### Phase 2: Exploratory Analysis
1. Summary statistics (fatalities, injuries)
2. Temporal distributions (hour, day, month, year)
3. Severity analysis
4. Vehicle and road condition patterns
5. Basic visualizations

**Output:** EDA report with key insights

### Phase 3: Spatial Analysis (Hotspots)
1. Extract coordinates (latitude, longitude)
2. Run DBSCAN clustering (eps=0.01, minPts=10)
3. Identify clusters (dense crash areas)
4. Calculate cluster severity scores
5. Rank and select top 20-50 hotspots
6. Create interactive Leaflet map

**Output:** Hotspot catalog + interactive map

### Phase 4: Temporal Analysis
1. Hour-of-day analysis (identify rush hours)
2. Day-of-week patterns (weekday vs weekend)
3. Monthly and seasonal trends
4. Year-over-year comparisons
5. Time-series visualizations

**Output:** Temporal pattern report

### Phase 5: Kafka Streaming
1. **Producer:** Stream historical crash data as JSON messages
2. **Consumer:** Read stream, maintain sliding window (1 hour)
3. **Real-time clustering:** Run DBSCAN on recent crashes
4. **Alerting:** Detect emerging hotspots, log alerts
5. **Dashboard integration:** Display live feed

**Output:** Real-time monitoring system

### Phase 6: Dashboard
1. Overview page (summary stats, trend charts)
2. Interactive hotspot map (Leaflet with filters)
3. Real-time stream viewer (Kafka feed)
4. Temporal pattern charts
5. Export functionality

**Output:** Working Shiny web application

### Phase 7: Reporting
1. Write analysis report (12-18 pages)
2. Include all visualizations
3. Document Kafka architecture
4. Provide policy recommendations
5. Create presentation slides (12-15 slides)

**Output:** Final report (PDF/HTML) + presentation

---

## Key Outputs & Deliverables

### Code
- [x] 7 R analysis scripts (load, clean, eda, hotspots, temporal, kafka)
- [x] 1 Shiny dashboard application
- [x] Kafka setup and configuration files
- [x] Requirements and documentation

### Analysis Results
- [ ] Cleaned master dataset (~182K crash records)
- [ ] Top 20-50 crash hotspots with coordinates
- [ ] Summary statistics and trends
- [ ] 10+ key visualizations (maps, charts, heatmaps)

### Kafka Streaming
- [ ] Working Kafka producer (streams crash data)
- [ ] Working Kafka consumer (detects hotspots in real-time)
- [ ] Alert logs (CSV files with detected hotspots)
- [ ] Live dashboard integration

### Dashboard
- [ ] 3-page Shiny application:
  - Overview with summary metrics
  - Interactive hotspot map with filters
  - Real-time Kafka stream viewer
- [ ] Auto-refreshing data display
- [ ] Export functionality

### Reports
- [ ] Analysis report (12-18 pages, PDF/HTML)
- [ ] Presentation slides (12-15 slides)
- [ ] README and documentation
- [ ] Code comments and annotations

---

## Running the Project

### Prerequisites

**Required:**
- R (4.0+) - [Download](https://www.r-project.org/)
- RStudio (recommended) - [Download](https://www.rstudio.com/)
- Docker (for Kafka) - [Download](https://www.docker.com/)

**Disk Space:**
- Data: 200 MB
- R packages: 500 MB
- Kafka (Docker): 1 GB
- Outputs: 100 MB
- **Total: ~2 GB**

**Time Required:**
- Setup (packages + Kafka): 30 minutes
- Data loading & cleaning: 30 minutes
- Analysis & visualization: 2-3 hours
- Kafka implementation: 1-2 hours
- Dashboard development: 2-3 hours
- Report writing: 3-4 hours
- **Total: 1 week (20-30 hours)**

### Execution Order

**Day 1: Setup (3-4 hours)**
```r
# Install packages
source("requirements.R")

# Install Kafka
# See kafka_setup/README.md

# Load data
source("scripts/01_load_data.R")

# Clean data
source("scripts/02_clean_data.R")
```

**Day 2-3: Analysis (8-10 hours)**
```r
# Exploratory analysis
source("scripts/03_eda.R")

# Hotspot detection
source("scripts/04_hotspots.R")

# Temporal patterns
source("scripts/05_temporal.R")
```

**Day 4: Kafka Streaming (4-6 hours)**
```bash
# Terminal 1: Producer
Rscript scripts/06_kafka_producer.R

# Terminal 2: Consumer
Rscript scripts/07_kafka_consumer.R
```

**Day 5: Dashboard (4-5 hours)**
```r
# Run dashboard
library(shiny)
runApp("shiny_app")
```

**Day 6-7: Report & Finalization (6-8 hours)**
- Write analysis report
- Create presentation
- Test all components
- Final review

---

## Simplified Kafka Architecture

```
[Historical CSV Data]
        ↓
  [R Producer Script]
        ↓
  Converts each crash record to JSON
        ↓
  Streams to Kafka topic: "victoria-crashes"
        ↓
  [Kafka Broker] (localhost:9092)
        ↓
  [R Consumer Script]
        ↓
  Maintains 1-hour sliding window
        ↓
  Runs DBSCAN clustering every second
        ↓
  Detects hotspots (5+ crashes in cluster)
        ↓
  Logs alerts to CSV files
        ↓
  [Shiny Dashboard] displays real-time feed
```

---

## Troubleshooting

### Issue: R packages fail to install

**Solution:**
```r
# Update R
install.packages("installr")
library(installr)
updateR()

# Install system dependencies (Linux/WSL)
sudo apt-get install libgdal-dev libproj-dev libgeos-dev libudunits2-dev
```

### Issue: Kafka won't start

**Solution:**
```bash
# Check Docker status
docker ps

# Restart containers
docker restart zookeeper kafka

# Check logs
docker logs kafka

# Recreate containers
docker stop kafka zookeeper
docker rm kafka zookeeper
# Run install script again
```

### Issue: Data files not found

**Solution:**
- Ensure all CSV files are in the `data/` directory
- Check file paths in scripts
- Verify working directory: `getwd()`

### Issue: Out of memory

**Solution:**
```r
# Increase memory limit (Windows)
memory.limit(size=16000)

# Use data.table instead of data.frame
library(data.table)

# Process data in chunks
```

### Issue: Shiny dashboard won't load

**Solution:**
```r
# Check if data files exist
file.exists("output/data/crashes_cleaned.rds")

# Run scripts in order first
source("scripts/01_load_data.R")
source("scripts/02_clean_data.R")

# Check for errors in console
```

---

## Expected Results

### Hotspot Analysis
- Identify 20-50 high-frequency crash locations
- Melbourne CBD, major highways, and intersections
- Severity scores showing high-risk areas
- Interactive map with cluster visualization

### Temporal Patterns
- Peak crash times: Morning rush (7-9 AM), evening rush (4-6 PM)
- Weekends: Different patterns (Friday/Saturday nights)
- Seasonal: Higher in summer months (Dec-Feb)
- Long-term: Slight declining trend in recent years

### Kafka Streaming
- Producer streams ~20 records/second
- Consumer processes in real-time
- Alerts triggered when 5+ crashes in same area within 1 hour
- Dashboard shows live feed with auto-refresh

### Policy Recommendations
- Top 20 locations for infrastructure improvements
- Optimal times for traffic enforcement
- Resource allocation for emergency services
- Public awareness campaign focus areas

---

## Next Steps After Completion

1. **Model Enhancement:**
   - Add predictive models (Random Forest, XGBoost)
   - Incorporate external data (traffic volume, demographics)
   - Weather forecasting integration

2. **Dashboard Improvements:**
   - User authentication
   - Advanced filters and queries
   - Mobile-responsive design
   - Email/SMS alerts

3. **Kafka Scaling:**
   - Multiple consumers (parallel processing)
   - Persistent storage (Kafka Connect)
   - Integration with external systems

4. **Deployment:**
   - Cloud deployment (AWS, Azure)
   - Production Kafka cluster
   - Automated data pipelines
   - Continuous monitoring

---

## References & Resources

### Documentation
- [R Documentation](https://www.r-project.org/)
- [Apache Kafka](https://kafka.apache.org/documentation/)
- [Shiny](https://shiny.rstudio.com/)
- [DBSCAN Algorithm](https://en.wikipedia.org/wiki/DBSCAN)

### Tutorials
- [Leaflet for R](https://rstudio.github.io/leaflet/)
- [Data Manipulation with dplyr](https://dplyr.tidyverse.org/)
- [Kafka Quick Start](https://kafka.apache.org/quickstart)

### Academic Papers
- Ester, M., et al. (1996). "A density-based algorithm for discovering clusters"
- Getis, A., & Ord, J. K. (1992). "The analysis of spatial association"

---

## Project Team

**Student:** [Your Name]
**Course:** Big Data Analytics - Semester 4
**Institution:** Swinburne University of Technology
**Supervisor:** [Supervisor Name]

---

## License & Data Usage

**Dataset:** Victorian Road Crash Data
**Source:** Victorian Government
**Usage:** Educational purposes only

---

## Contact & Support

For questions or issues:
1. Check this README first
2. Review `SIMPLE_1_WEEK_PLAN.md` for detailed steps
3. Check `kafka_setup/README.md` for Kafka issues
4. Contact course coordinator

---

**Last Updated:** 2025-01-04
**Version:** 1.0 - Simplified 1-Week Implementation
