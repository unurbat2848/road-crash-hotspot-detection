# ============================================================================
# Victorian Road Crash Analysis - Shiny Dashboard
# ============================================================================
# Interactive dashboard for exploring crash hotspots and real-time streaming
# ============================================================================

library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(dplyr)
library(ggplot2)
library(plotly)

# ============================================================================
# Load Data
# ============================================================================

# Set paths
data_dir <- "../output/data"
figures_dir <- "../output/figures"
kafka_logs_dir <- "../output/kafka_logs"

# Load crash data
load_data <- function() {
  tryCatch({
    crashes <- readRDS(file.path(data_dir, "crashes_cleaned.rds"))
    hotspots <- read.csv(file.path(data_dir, "hotspots_top50.csv"))

    list(
      crashes = crashes,
      hotspots = hotspots,
      loaded = TRUE
    )
  }, error = function(e) {
    list(loaded = FALSE, error = as.character(e))
  })
}

data <- load_data()

# Check if data loaded
if(!data$loaded) {
  stop(paste("Error loading data:", data$error,
             "\n\nPlease run the analysis scripts first:",
             "\n  source('scripts/01_load_data.R')",
             "\n  source('scripts/02_clean_data.R')",
             "\n  source('scripts/04_hotspots.R')"))
}

crashes <- data$crashes
hotspots <- data$hotspots

# Calculate summary statistics
total_crashes <- nrow(crashes)
total_fatalities <- sum(crashes$NO_PERSONS_KILLED, na.rm = TRUE)
total_serious <- sum(crashes$NO_PERSONS_INJ_2, na.rm = TRUE)
total_other <- sum(crashes$NO_PERSONS_INJ_3, na.rm = TRUE)
date_range <- paste(min(crashes$ACCIDENT_DATE_PARSED), "to", max(crashes$ACCIDENT_DATE_PARSED))

# ============================================================================
# UI
# ============================================================================

ui <- dashboardPage(
  skin = "blue",

  # Header
  dashboardHeader(
    title = "Victorian Crash Analysis",
    titleWidth = 300
  ),

  # Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Hotspot Map", tabName = "map", icon = icon("map-marked-alt")),
      menuItem("Temporal Patterns", tabName = "temporal", icon = icon("chart-line")),
      menuItem("Live Stream (Kafka)", tabName = "stream", icon = icon("stream")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),

    br(),
    div(style = "padding: 15px;",
        h5("Data Summary"),
        p(strong("Total Crashes:"), format(total_crashes, big.mark = ",")),
        p(strong("Date Range:"), br(), date_range),
        p(strong("Hotspots:"), nrow(hotspots))
    )
  ),

  # Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f4f4; }
        .box { border-top: 3px solid #3c8dbc; }
        .small-box { border-radius: 5px; }
      "))
    ),

    tabItems(
      # ===================================================================
      # TAB 1: OVERVIEW
      # ===================================================================
      tabItem(
        tabName = "overview",

        h2("Victorian Road Crash Analysis Dashboard"),
        p("Spatio-Temporal Hotspot Detection and Trend Analysis"),

        br(),

        # Value boxes
        fluidRow(
          valueBoxOutput("box_crashes", width = 3),
          valueBoxOutput("box_fatalities", width = 3),
          valueBoxOutput("box_serious", width = 3),
          valueBoxOutput("box_hotspots", width = 3)
        ),

        br(),

        # Charts
        fluidRow(
          box(
            title = "Crash Trends Over Time",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("plot_yearly_trend", height = 300)
          ),
          box(
            title = "Severity Distribution",
            status = "warning",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("plot_severity", height = 300)
          )
        ),

        fluidRow(
          box(
            title = "Hourly Crash Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_hourly", height = 300)
          ),
          box(
            title = "Top 10 Hotspots",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            DTOutput("table_top_hotspots")
          )
        )
      ),

      # ===================================================================
      # TAB 2: HOTSPOT MAP
      # ===================================================================
      tabItem(
        tabName = "map",

        h2("Interactive Hotspot Map"),

        fluidRow(
          box(
            title = "Victorian Crash Hotspots",
            status = "primary",
            solidHeader = TRUE,
            width = 9,
            leafletOutput("hotspot_map", height = 600)
          ),
          box(
            title = "Map Controls",
            status = "info",
            solidHeader = TRUE,
            width = 3,
            sliderInput(
              "map_top_n",
              "Number of hotspots to display:",
              min = 10,
              max = 50,
              value = 30,
              step = 5
            ),
            selectInput(
              "map_color_by",
              "Color by:",
              choices = c("Total Severity" = "total_severity",
                         "Number of Crashes" = "n_crashes",
                         "Fatalities" = "n_fatalities"),
              selected = "total_severity"
            ),
            hr(),
            h5("Legend"),
            p("🔴 Circle size = Number of crashes"),
            p("🎨 Color intensity = Selected metric"),
            p("📍 Click markers for details")
          )
        ),

        fluidRow(
          box(
            title = "Hotspot Details",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            DTOutput("table_hotspots")
          )
        )
      ),

      # ===================================================================
      # TAB 3: TEMPORAL PATTERNS
      # ===================================================================
      tabItem(
        tabName = "temporal",

        h2("Temporal Patterns Analysis"),

        fluidRow(
          box(
            title = "Day of Week Distribution",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_day_of_week", height = 350)
          ),
          box(
            title = "Monthly Patterns",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_monthly", height = 350)
          )
        ),

        fluidRow(
          box(
            title = "Hour × Day Heatmap",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("plot_heatmap", height = 400)
          )
        )
      ),

      # ===================================================================
      # TAB 4: LIVE STREAM (KAFKA)
      # ===================================================================
      tabItem(
        tabName = "stream",

        h2("Real-Time Crash Stream (Kafka)"),
        p("Displaying data from Kafka consumer"),

        fluidRow(
          valueBoxOutput("box_stream_status", width = 4),
          valueBoxOutput("box_recent_crashes", width = 4),
          valueBoxOutput("box_total_alerts", width = 4)
        ),

        br(),

        fluidRow(
          box(
            title = "Recent Crashes (Last 100)",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            actionButton("refresh_stream", "Refresh Data", icon = icon("refresh")),
            hr(),
            DTOutput("table_recent_crashes")
          )
        ),

        fluidRow(
          box(
            title = "Hotspot Alerts Log",
            status = "danger",
            solidHeader = TRUE,
            width = 12,
            p("Alerts generated by real-time DBSCAN clustering"),
            DTOutput("table_alerts")
          )
        ),

        fluidRow(
          box(
            title = "How to Use Kafka Streaming",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            h4("Setup Instructions:"),
            tags$ol(
              tags$li("Start Kafka: ", tags$code("cd kafka_setup && ./install_kafka_docker.sh")),
              tags$li("In Terminal 1: ", tags$code("Rscript scripts/06_kafka_producer.R")),
              tags$li("In Terminal 2: ", tags$code("Rscript scripts/07_kafka_consumer.R")),
              tags$li("Click 'Refresh Data' button above to view latest stream")
            )
          )
        )
      ),

      # ===================================================================
      # TAB 5: ABOUT
      # ===================================================================
      tabItem(
        tabName = "about",

        h2("About This Project"),

        box(
          title = "Project Information",
          status = "primary",
          solidHeader = TRUE,
          width = 12,

          h3("Victorian Road Crash Spatio-Temporal Analysis"),
          p("This dashboard provides interactive exploration of road crash patterns in Victoria, Australia."),

          h4("Research Questions:"),
          tags$ul(
            tags$li("Where are the most frequent and severe crash hotspots?"),
            tags$li("When (time of day, day of week, season) do crashes peak?"),
            tags$li("How do crash trends evolve over time?"),
            tags$li("Can real-time streaming with Kafka provide crash alerts?")
          ),

          h4("Technologies Used:"),
          tags$ul(
            tags$li("R - Data analysis and visualization"),
            tags$li("DBSCAN - Spatial clustering for hotspot detection"),
            tags$li("Apache Kafka - Real-time data streaming"),
            tags$li("Shiny - Interactive web dashboard"),
            tags$li("Leaflet - Interactive maps")
          ),

          h4("Dataset:"),
          p("Victorian Road Crash Data (2012-present)"),
          p(paste("Total crashes analyzed:", format(total_crashes, big.mark = ","))),
          p(paste("Date range:", date_range)),

          h4("Project Structure:"),
          tags$ul(
            tags$li("Data loading and cleaning"),
            tags$li("Exploratory data analysis"),
            tags$li("Spatial hotspot detection (DBSCAN)"),
            tags$li("Temporal pattern analysis"),
            tags$li("Kafka streaming implementation"),
            tags$li("Interactive dashboard")
          ),

          br(),
          p(strong("Academic Project"), " - Swinburne University, Big Data Analytics, Semester 4"),
          p("For more information, see the project README.md file.")
        )
      )
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {

  # ===================================================================
  # OVERVIEW TAB
  # ===================================================================

  # Value boxes
  output$box_crashes <- renderValueBox({
    valueBox(
      value = format(total_crashes, big.mark = ","),
      subtitle = "Total Crashes",
      icon = icon("car-crash"),
      color = "blue"
    )
  })

  output$box_fatalities <- renderValueBox({
    valueBox(
      value = total_fatalities,
      subtitle = "Total Fatalities",
      icon = icon("heart-broken"),
      color = "red"
    )
  })

  output$box_serious <- renderValueBox({
    valueBox(
      value = format(total_serious, big.mark = ","),
      subtitle = "Serious Injuries",
      icon = icon("ambulance"),
      color = "orange"
    )
  })

  output$box_hotspots <- renderValueBox({
    valueBox(
      value = nrow(hotspots),
      subtitle = "Identified Hotspots",
      icon = icon("map-pin"),
      color = "green"
    )
  })

  # Yearly trend plot
  output$plot_yearly_trend <- renderPlotly({
    yearly_data <- crashes %>%
      group_by(year) %>%
      summarise(n_crashes = n(), .groups = "drop")

    plot_ly(yearly_data, x = ~year, y = ~n_crashes, type = "scatter", mode = "lines+markers",
            line = list(color = "#1f77b4", width = 3),
            marker = list(size = 8, color = "#1f77b4")) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Crashes"),
        hovermode = "closest"
      )
  })

  # Severity distribution
  output$plot_severity <- renderPlotly({
    severity_data <- crashes %>%
      group_by(severity_category) %>%
      summarise(n = n(), .groups = "drop") %>%
      arrange(desc(n))

    plot_ly(severity_data, labels = ~severity_category, values = ~n, type = "pie",
            marker = list(colors = c("#d62728", "#ff7f0e", "#ffbb78", "#98df8a"))) %>%
      layout(showlegend = TRUE)
  })

  # Hourly distribution
  output$plot_hourly <- renderPlotly({
    hourly_data <- crashes %>%
      filter(!is.na(hour)) %>%
      group_by(hour) %>%
      summarise(n_crashes = n(), .groups = "drop")

    plot_ly(hourly_data, x = ~hour, y = ~n_crashes, type = "bar",
            marker = list(color = "#2ca02c")) %>%
      layout(
        xaxis = list(title = "Hour of Day"),
        yaxis = list(title = "Number of Crashes")
      )
  })

  # Top 10 hotspots table
  output$table_top_hotspots <- renderDT({
    hotspots %>%
      arrange(desc(total_severity)) %>%
      head(10) %>%
      select(rank, n_crashes, n_fatalities, total_severity, center_lat, center_lon) %>%
      datatable(
        options = list(pageLength = 10, dom = "t"),
        rownames = FALSE,
        colnames = c("Rank", "Crashes", "Fatalities", "Severity", "Latitude", "Longitude")
      ) %>%
      formatRound(columns = c("center_lat", "center_lon"), digits = 4) %>%
      formatRound(columns = "total_severity", digits = 1)
  })

  # ===================================================================
  # HOTSPOT MAP TAB
  # ===================================================================

  # Reactive hotspot data based on inputs
  map_hotspots <- reactive({
    hotspots %>%
      arrange(desc(total_severity)) %>%
      head(input$map_top_n)
  })

  # Create color palette
  color_pal <- reactive({
    colorNumeric(
      palette = "YlOrRd",
      domain = map_hotspots()[[input$map_color_by]]
    )
  })

  # Render map
  output$hotspot_map <- renderLeaflet({
    data <- map_hotspots()
    pal <- color_pal()

    leaflet(data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = 145.0, lat = -37.8, zoom = 8) %>%
      addCircleMarkers(
        lng = ~center_lon,
        lat = ~center_lat,
        radius = ~sqrt(n_crashes) * 1.5,
        color = ~pal(data[[input$map_color_by]]),
        fillColor = ~pal(data[[input$map_color_by]]),
        fillOpacity = 0.7,
        stroke = TRUE,
        weight = 2,
        popup = ~paste0(
          "<b>Rank: ", rank, "</b><br>",
          "Crashes: ", n_crashes, "<br>",
          "Fatalities: ", n_fatalities, "<br>",
          "Serious Injuries: ", n_serious_injuries, "<br>",
          "Total Severity: ", round(total_severity, 1), "<br>",
          "Location: (", round(center_lat, 4), ", ", round(center_lon, 4), ")"
        ),
        label = ~paste0("Rank ", rank, ": ", n_crashes, " crashes")
      ) %>%
      addLegend(
        "bottomright",
        pal = pal,
        values = ~data[[input$map_color_by]],
        title = gsub("_", " ", tools::toTitleCase(input$map_color_by)),
        opacity = 0.7
      )
  })

  # Hotspot details table
  output$table_hotspots <- renderDT({
    map_hotspots() %>%
      select(rank, cluster_id, n_crashes, n_fatalities, n_serious_injuries,
             total_severity, avg_severity, center_lat, center_lon, common_road) %>%
      datatable(
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE,
        colnames = c("Rank", "Cluster", "Crashes", "Fatal", "Serious", "Total Sev",
                    "Avg Sev", "Lat", "Lon", "Road")
      ) %>%
      formatRound(columns = c("center_lat", "center_lon"), digits = 4) %>%
      formatRound(columns = c("total_severity", "avg_severity"), digits = 2)
  })

  # ===================================================================
  # TEMPORAL TAB
  # ===================================================================

  # Day of week plot
  output$plot_day_of_week <- renderPlotly({
    dow_data <- crashes %>%
      group_by(day_of_week) %>%
      summarise(n_crashes = n(), .groups = "drop")

    plot_ly(dow_data, x = ~day_of_week, y = ~n_crashes, type = "bar",
            marker = list(color = "#ff7f0e")) %>%
      layout(
        xaxis = list(title = "Day of Week"),
        yaxis = list(title = "Number of Crashes")
      )
  })

  # Monthly plot
  output$plot_monthly <- renderPlotly({
    monthly_data <- crashes %>%
      group_by(month) %>%
      summarise(n_crashes = n(), .groups = "drop")

    plot_ly(monthly_data, x = ~month, y = ~n_crashes, type = "bar",
            marker = list(color = "#2ca02c")) %>%
      layout(
        xaxis = list(title = "Month", tickvals = 1:12, ticktext = month.abb),
        yaxis = list(title = "Number of Crashes")
      )
  })

  # Heatmap
  output$plot_heatmap <- renderPlotly({
    heatmap_data <- crashes %>%
      filter(!is.na(hour)) %>%
      group_by(hour, day_of_week) %>%
      summarise(n_crashes = n(), .groups = "drop")

    plot_ly(heatmap_data, x = ~hour, y = ~day_of_week, z = ~n_crashes,
            type = "heatmap", colors = "YlOrRd") %>%
      layout(
        xaxis = list(title = "Hour of Day"),
        yaxis = list(title = "Day of Week")
      )
  })

  # ===================================================================
  # KAFKA STREAM TAB
  # ===================================================================

  # Load Kafka logs
  load_kafka_data <- reactive({
    # Trigger on refresh button
    input$refresh_stream

    recent_file <- file.path(kafka_logs_dir, "recent_crashes.csv")
    alerts_file <- file.path(kafka_logs_dir, "alerts.csv")

    recent <- if(file.exists(recent_file)) {
      tryCatch(read.csv(recent_file), error = function(e) data.frame())
    } else {
      data.frame()
    }

    alerts <- if(file.exists(alerts_file)) {
      tryCatch(read.csv(alerts_file), error = function(e) data.frame())
    } else {
      data.frame()
    }

    list(recent = recent, alerts = alerts)
  })

  # Stream status
  output$box_stream_status <- renderValueBox({
    kafka_data <- load_kafka_data()
    status <- if(nrow(kafka_data$recent) > 0) "Active" else "Inactive"
    color <- if(status == "Active") "green" else "red"

    valueBox(
      value = status,
      subtitle = "Kafka Stream",
      icon = icon("signal"),
      color = color
    )
  })

  # Recent crashes count
  output$box_recent_crashes <- renderValueBox({
    kafka_data <- load_kafka_data()

    valueBox(
      value = nrow(kafka_data$recent),
      subtitle = "Crashes in Buffer",
      icon = icon("database"),
      color = "blue"
    )
  })

  # Total alerts
  output$box_total_alerts <- renderValueBox({
    kafka_data <- load_kafka_data()

    valueBox(
      value = nrow(kafka_data$alerts),
      subtitle = "Total Alerts",
      icon = icon("exclamation-triangle"),
      color = "orange"
    )
  })

  # Recent crashes table
  output$table_recent_crashes <- renderDT({
    kafka_data <- load_kafka_data()

    if(nrow(kafka_data$recent) == 0) {
      return(datatable(data.frame(Message = "No data available. Start Kafka producer and consumer.")))
    }

    kafka_data$recent %>%
      select(ACCIDENT_NO, ACCIDENT_DATE, LATITUDE, LONGITUDE, severity_score) %>%
      datatable(
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE
      ) %>%
      formatRound(columns = c("LATITUDE", "LONGITUDE", "severity_score"), digits = 4)
  })

  # Alerts table
  output$table_alerts <- renderDT({
    kafka_data <- load_kafka_data()

    if(nrow(kafka_data$alerts) == 0) {
      return(datatable(data.frame(Message = "No alerts yet.")))
    }

    kafka_data$alerts %>%
      datatable(
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE
      ) %>%
      formatRound(columns = c("center_lat", "center_lon", "total_severity"), digits = 4)
  })
}

# ============================================================================
# RUN APP
# ============================================================================

shinyApp(ui = ui, server = server)
