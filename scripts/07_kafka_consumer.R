# ============================================================================
# Script 07: Kafka Consumer - Real-time Hotspot Detection
# ============================================================================
# Purpose: Consume crash stream and detect emerging hotspots in real-time
# Input: Kafka topic "victoria-crashes"
# Output: Real-time hotspot alerts and logs
# ============================================================================
# PREREQUISITES:
#   - Kafka must be running
#   - Producer must be running (script 06)
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Kafka Consumer\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(dbscan)
  library(data.table)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

kafka_logs_dir <- "output/kafka_logs"

# Create kafka logs directory
if(!dir.exists(kafka_logs_dir)) {
  dir.create(kafka_logs_dir, recursive = TRUE)
}

cat("Working directory:", getwd(), "\n\n")

# ============================================================================
# Configuration
# ============================================================================

cat("============================================================================\n")
cat("Configuration\n")
cat("============================================================================\n\n")

KAFKA_BROKER <- "localhost:9092"
KAFKA_TOPIC <- "victoria-crashes"
WINDOW_SIZE <- 100  # Number of recent crashes to keep in memory
HOTSPOT_THRESHOLD <- 5  # Minimum crashes to trigger hotspot alert
DBSCAN_EPS <- 0.01  # DBSCAN radius (degrees)
DBSCAN_MINPTS <- 5  # DBSCAN minimum points
POLL_INTERVAL <- 2  # Seconds between polling
MAX_ITERATIONS <- 500  # Maximum iterations (for testing)

cat("Consumer Configuration:\n")
cat("  Broker:", KAFKA_BROKER, "\n")
cat("  Topic:", KAFKA_TOPIC, "\n")
cat("  Window size:", WINDOW_SIZE, "crashes\n")
cat("  Hotspot threshold:", HOTSPOT_THRESHOLD, "crashes\n")
cat("  DBSCAN eps:", DBSCAN_EPS, "degrees\n")
cat("  DBSCAN minPts:", DBSCAN_MINPTS, "\n")
cat("  Poll interval:", POLL_INTERVAL, "seconds\n\n")

# ============================================================================
# Check Kafka Availability
# ============================================================================

cat("============================================================================\n")
cat("Checking Kafka Availability...\n")
cat("============================================================================\n\n")

kafka_check <- system("docker ps | grep kafka", intern = TRUE, ignore.stderr = TRUE)

if(length(kafka_check) == 0) {
  cat("⚠ WARNING: Kafka container not detected\n")
  response <- readline(prompt = "Continue anyway? (y/n): ")
  if(tolower(response) != "y") {
    stop("Exiting. Please start Kafka first.")
  }
} else {
  cat("✓ Kafka container is running\n\n")
}

# ============================================================================
# Consumer Function
# ============================================================================

consume_messages <- function(n_messages = 10, timeout = 5) {
  # Read messages from Kafka using docker exec
  cmd <- sprintf(
    "timeout %d docker exec kafka kafka-console-consumer --bootstrap-server %s --topic %s --max-messages %d --from-beginning 2>/dev/null || true",
    timeout,
    KAFKA_BROKER,
    KAFKA_TOPIC,
    n_messages
  )

  messages <- system(cmd, intern = TRUE, ignore.stderr = TRUE)

  if(length(messages) == 0) {
    return(NULL)
  }

  # Parse JSON messages
  parsed_messages <- lapply(messages, function(msg) {
    tryCatch({
      fromJSON(msg)
    }, error = function(e) {
      NULL
    })
  })

  # Filter out failed parses
  parsed_messages <- Filter(Negate(is.null), parsed_messages)

  if(length(parsed_messages) == 0) {
    return(NULL)
  }

  # Combine into data frame
  df <- rbindlist(parsed_messages, fill = TRUE)

  return(as.data.frame(df))
}

# ============================================================================
# Hotspot Detection Function
# ============================================================================

detect_hotspots <- function(crash_buffer) {
  if(nrow(crash_buffer) < DBSCAN_MINPTS) {
    return(NULL)
  }

  # Extract coordinates
  coords <- as.matrix(crash_buffer[, c("LONGITUDE", "LATITUDE")])

  # Run DBSCAN
  clusters <- dbscan(coords, eps = DBSCAN_EPS, minPts = DBSCAN_MINPTS)

  # Analyze clusters
  crash_buffer$cluster_id <- clusters$cluster

  # Filter to actual clusters (exclude noise points, cluster_id = 0)
  clustered <- crash_buffer[crash_buffer$cluster_id > 0, ]

  if(nrow(clustered) == 0) {
    return(NULL)
  }

  # Summarize clusters
  hotspot_summary <- clustered %>%
    group_by(cluster_id) %>%
    summarise(
      n_crashes = n(),
      center_lat = mean(LATITUDE, na.rm = TRUE),
      center_lon = mean(LONGITUDE, na.rm = TRUE),
      total_severity = sum(severity_score, na.rm = TRUE),
      avg_severity = mean(severity_score, na.rm = TRUE),
      n_killed = sum(NO_PERSONS_KILLED, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(n_crashes >= HOTSPOT_THRESHOLD) %>%
    arrange(desc(total_severity))

  if(nrow(hotspot_summary) == 0) {
    return(NULL)
  }

  return(as.data.frame(hotspot_summary))
}

# ============================================================================
# Initialize State
# ============================================================================

cat("============================================================================\n")
cat("Initializing Consumer...\n")
cat("============================================================================\n\n")

# Crash buffer (sliding window)
crash_buffer <- data.frame()

# Alerts log
alerts_log <- data.frame(
  timestamp = character(),
  cluster_id = integer(),
  n_crashes = integer(),
  center_lat = numeric(),
  center_lon = numeric(),
  total_severity = numeric(),
  stringsAsFactors = FALSE
)

# Recent crashes log
recent_crashes_file <- file.path(kafka_logs_dir, "recent_crashes.csv")
alerts_file <- file.path(kafka_logs_dir, "alerts.csv")

# Initialize files
write.csv(crash_buffer, recent_crashes_file, row.names = FALSE)
write.csv(alerts_log, alerts_file, row.names = FALSE)

cat("✓ Consumer initialized\n")
cat("✓ Logs will be saved to:", kafka_logs_dir, "\n\n")

# ============================================================================
# Start Consuming
# ============================================================================

cat("============================================================================\n")
cat("Starting Real-time Hotspot Detection...\n")
cat("============================================================================\n\n")

cat("Listening to Kafka topic:", KAFKA_TOPIC, "\n")
cat("Press Ctrl+C to stop\n\n")

# Counters
total_messages <- 0
total_alerts <- 0
iteration <- 0
start_time <- Sys.time()

# Main consumption loop
repeat {
  iteration <- iteration + 1

  # Break if max iterations reached
  if(iteration > MAX_ITERATIONS) {
    cat("\nReached maximum iterations. Stopping.\n")
    break
  }

  # Poll for new messages
  new_messages <- tryCatch({
    consume_messages(n_messages = 10, timeout = POLL_INTERVAL)
  }, error = function(e) {
    NULL
  })

  if(!is.null(new_messages) && nrow(new_messages) > 0) {
    # Add to buffer
    crash_buffer <- rbind(crash_buffer, new_messages)
    total_messages <- total_messages + nrow(new_messages)

    # Maintain sliding window
    if(nrow(crash_buffer) > WINDOW_SIZE) {
      crash_buffer <- tail(crash_buffer, WINDOW_SIZE)
    }

    cat(sprintf("[%s] Received %d new crashes | Buffer: %d crashes | Total: %d\n",
                format(Sys.time(), "%H:%M:%S"),
                nrow(new_messages),
                nrow(crash_buffer),
                total_messages))

    # Run hotspot detection
    hotspots <- detect_hotspots(crash_buffer)

    if(!is.null(hotspots) && nrow(hotspots) > 0) {
      cat("\n*** ALERT: Emerging hotspot(s) detected! ***\n")
      print(hotspots[, c("cluster_id", "n_crashes", "center_lat", "center_lon", "total_severity")])
      cat("\n")

      # Log alerts
      for(i in 1:nrow(hotspots)) {
        alerts_log <- rbind(alerts_log, data.frame(
          timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          cluster_id = hotspots$cluster_id[i],
          n_crashes = hotspots$n_crashes[i],
          center_lat = hotspots$center_lat[i],
          center_lon = hotspots$center_lon[i],
          total_severity = hotspots$total_severity[i]
        ))
      }

      total_alerts <- total_alerts + nrow(hotspots)
    }

    # Save updated logs
    if(total_messages %% 50 == 0) {
      write.csv(crash_buffer, recent_crashes_file, row.names = FALSE)
      write.csv(alerts_log, alerts_file, row.names = FALSE)
    }

  } else {
    cat(sprintf("[%s] No new messages | Buffer: %d crashes\n",
                format(Sys.time(), "%H:%M:%S"),
                nrow(crash_buffer)))
  }

  # Brief pause
  Sys.sleep(1)
}

# ============================================================================
# Save Final State
# ============================================================================

cat("\n============================================================================\n")
cat("Consumer Stopped\n")
cat("============================================================================\n\n")

# Save final logs
write.csv(crash_buffer, recent_crashes_file, row.names = FALSE)
write.csv(alerts_log, alerts_file, row.names = FALSE)

# Statistics
end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

cat("Summary:\n")
cat("  Total messages consumed:", total_messages, "\n")
cat("  Total hotspot alerts:", total_alerts, "\n")
cat("  Running time:", round(total_time, 2), "seconds\n")
cat("  Average rate:", round(total_messages / total_time, 2), "messages/second\n\n")

cat("Logs saved:\n")
cat("  Recent crashes:", recent_crashes_file, "\n")
cat("  Alerts:", alerts_file, "\n\n")

cat("Next steps:\n")
cat("  1. View alerts: View the", alerts_file, "file\n")
cat("  2. Visualize: Open Shiny dashboard (runApp('shiny_app'))\n")
cat("\n")

cat("============================================================================\n")
