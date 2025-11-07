# ============================================================================
# Script 06: Kafka Producer - Stream Crash Data
# ============================================================================
# Purpose: Stream historical crash data to Kafka topic
# Input: Cleaned crash data
# Output: JSON messages to Kafka topic "victoria-crashes"
# ============================================================================
# PREREQUISITES:
#   - Kafka must be running (see kafka_setup/README.md)
#   - Topic "victoria-crashes" must be created
# ============================================================================

cat("\n============================================================================\n")
cat("Victorian Road Crash Analysis - Kafka Producer\n")
cat("============================================================================\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(data.table)
})

# Set working directory
if(basename(getwd()) == "scripts") {
  setwd("..")
}

output_dir <- "output/data"
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
STREAM_RATE <- 0.05  # seconds between messages (20 messages/second)
MAX_MESSAGES <- 1000  # Maximum messages to send (for testing)

cat("Kafka Configuration:\n")
cat("  Broker:", KAFKA_BROKER, "\n")
cat("  Topic:", KAFKA_TOPIC, "\n")
cat("  Stream rate:", STREAM_RATE, "seconds/message (~", round(1/STREAM_RATE), "msg/sec )\n")
cat("  Max messages:", MAX_MESSAGES, "(set to Inf for all data)\n\n")

# ============================================================================
# Check Kafka Availability
# ============================================================================

cat("============================================================================\n")
cat("Checking Kafka Availability...\n")
cat("============================================================================\n\n")

# Check if Kafka is running via Docker
kafka_check <- system("docker ps | grep kafka", intern = TRUE, ignore.stderr = TRUE)

if(length(kafka_check) == 0) {
  cat("⚠ WARNING: Kafka container not detected via Docker\n")
  cat("   Make sure Kafka is running:\n")
  cat("   1. Docker method: cd kafka_setup && ./install_kafka_docker.sh\n")
  cat("   2. Manual method: See kafka_setup/README.md\n\n")

  response <- readline(prompt = "Continue anyway? (y/n): ")
  if(tolower(response) != "y") {
    stop("Exiting. Please start Kafka first.")
  }
} else {
  cat("✓ Kafka container is running\n\n")
}

# ============================================================================
# Load Crash Data
# ============================================================================

cat("============================================================================\n")
cat("Loading Crash Data...\n")
cat("============================================================================\n\n")

crashes <- readRDS(file.path(output_dir, "crashes_cleaned.rds"))
cat("✓ Loaded", format(nrow(crashes), big.mark=","), "crash records\n")

# Convert to data.table
crashes_dt <- as.data.table(crashes)

# Select relevant columns for streaming
stream_data <- crashes_dt[, .(
  ACCIDENT_NO,
  ACCIDENT_DATE = as.character(ACCIDENT_DATE_PARSED),
  ACCIDENT_TIME = ACCIDENT_TIME_PARSED,
  LATITUDE,
  LONGITUDE,
  ACCIDENT_TYPE,
  severity_score,
  NO_PERSONS_KILLED,
  NO_PERSONS_INJ_2,
  NO_PERSONS_INJ_3,
  SPEED_ZONE,
  ROAD_GEOMETRY,
  hour,
  day_of_week = as.character(day_of_week),
  season
)]

# Sort by date to simulate chronological streaming
stream_data <- stream_data[order(ACCIDENT_DATE, ACCIDENT_TIME)]

# Limit data if MAX_MESSAGES is set
if(is.finite(MAX_MESSAGES)) {
  stream_data <- stream_data[1:min(MAX_MESSAGES, nrow(stream_data))]
  cat("  Streaming first", nrow(stream_data), "records (limited by MAX_MESSAGES)\n")
}

cat("✓ Prepared", nrow(stream_data), "records for streaming\n\n")

# ============================================================================
# Producer Function (using Docker exec)
# ============================================================================

produce_message <- function(message, broker = KAFKA_BROKER, topic = KAFKA_TOPIC) {
  # Escape quotes in JSON message
  message_escaped <- gsub('"', '\\\\"', message)
  message_escaped <- gsub("'", "\\\\'", message_escaped)

  # Send to Kafka using docker exec
  cmd <- sprintf(
    "echo '%s' | docker exec -i kafka kafka-console-producer --broker-list %s --topic %s 2>/dev/null",
    message,
    broker,
    topic
  )

  result <- system(cmd, intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)

  return(result == 0)
}

# ============================================================================
# Start Streaming
# ============================================================================

cat("============================================================================\n")
cat("Starting Stream...\n")
cat("============================================================================\n\n")

cat("Streaming crash data to Kafka topic:", KAFKA_TOPIC, "\n")
cat("Press Ctrl+C to stop\n\n")

# Initialize counters
messages_sent <- 0
messages_failed <- 0
start_time <- Sys.time()

# Create log file
log_file <- file.path(kafka_logs_dir, paste0("producer_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
log_data <- data.frame(
  timestamp = character(),
  accident_no = character(),
  latitude = numeric(),
  longitude = numeric(),
  severity = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

# Streaming loop
for(i in 1:nrow(stream_data)) {
  row <- stream_data[i, ]

  # Convert row to JSON
  json_message <- toJSON(row, auto_unbox = TRUE, pretty = FALSE)

  # Send to Kafka
  success <- tryCatch({
    produce_message(json_message)
  }, error = function(e) {
    FALSE
  })

  # Update counters
  if(success) {
    messages_sent <- messages_sent + 1

    # Log successful messages
    log_data <- rbind(log_data, data.frame(
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      accident_no = row$ACCIDENT_NO,
      latitude = row$LATITUDE,
      longitude = row$LONGITUDE,
      severity = row$severity_score,
      status = "sent"
    ))
  } else {
    messages_failed <- messages_failed + 1
  }

  # Progress update every 100 messages
  if(i %% 100 == 0) {
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    rate <- i / elapsed_time

    cat(sprintf("[%s] Sent: %d/%d (%.1f%%) | Rate: %.1f msg/sec | Failed: %d\n",
                format(Sys.time(), "%H:%M:%S"),
                i,
                nrow(stream_data),
                (i / nrow(stream_data)) * 100,
                rate,
                messages_failed))

    # Save log periodically
    if(i %% 500 == 0) {
      fwrite(log_data, log_file)
    }
  }

  # Sleep to control streaming rate
  Sys.sleep(STREAM_RATE)
}

# Final statistics
end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

# Save final log
fwrite(log_data, log_file)

# ============================================================================
# Summary
# ============================================================================

cat("\n============================================================================\n")
cat("Streaming Complete!\n")
cat("============================================================================\n\n")

cat("Summary:\n")
cat("  Total messages sent:", messages_sent, "\n")
cat("  Failed messages:", messages_failed, "\n")
cat("  Success rate:", round((messages_sent / (messages_sent + messages_failed)) * 100, 2), "%\n")
cat("  Total time:", round(total_time, 2), "seconds\n")
cat("  Average rate:", round(messages_sent / total_time, 2), "messages/second\n\n")

cat("Log saved to:", log_file, "\n\n")

cat("Next steps:\n")
cat("  1. In another terminal, run consumer: Rscript scripts/07_kafka_consumer.R\n")
cat("  2. View logs in:", kafka_logs_dir, "\n")
cat("\n")

cat("============================================================================\n")
