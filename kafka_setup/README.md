# Kafka Setup Guide - Simplified for 1 Week Project

## Quick Start (Choose One Method)

### Method 1: Docker (EASIEST - Recommended)

**Prerequisites:** Docker installed on your system

**Steps:**

1. **Start Zookeeper:**
```bash
docker run -d --name zookeeper -p 2181:2181 zookeeper:latest
```

2. **Start Kafka:**
```bash
docker run -d --name kafka -p 9092:9092 \
  --link zookeeper \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  confluentinc/cp-kafka:latest
```

3. **Create Topic:**
```bash
docker exec -it kafka kafka-topics --create \
  --topic victoria-crashes \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1
```

4. **Verify:**
```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Stop Kafka when done:**
```bash
docker stop kafka zookeeper
docker rm kafka zookeeper
```

---

### Method 2: Manual Installation (Windows WSL / Linux)

**Steps:**

1. **Download Kafka:**
```bash
cd ~
wget https://downloads.apache.org/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xzf kafka_2.13-3.6.0.tgz
cd kafka_2.13-3.6.0
```

2. **Start Zookeeper (Terminal 1):**
```bash
bin/zookeeper-server-start.sh config/zookeeper.properties
```

3. **Start Kafka (Terminal 2):**
```bash
bin/kafka-server-start.sh config/server.properties
```

4. **Create Topic (Terminal 3):**
```bash
bin/kafka-topics.sh --create \
  --topic victoria-crashes \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1
```

5. **Verify:**
```bash
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

---

## Testing Kafka

### Test Producer (Send a message)

```bash
# Docker
docker exec -it kafka bash
kafka-console-producer --broker-list localhost:9092 --topic victoria-crashes
# Type: {"test": "message"} and press Enter
# Press Ctrl+C to exit

# Manual installation
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic victoria-crashes
```

### Test Consumer (Read messages)

```bash
# Docker
docker exec -it kafka bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic victoria-crashes --from-beginning

# Manual installation
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic victoria-crashes --from-beginning
```

---

## Using Kafka in R

### Simple Approach: System Commands

```r
# Producer example
library(jsonlite)

crash_data <- data.frame(
  accident_no = "123",
  lat = -37.8136,
  lon = 144.9631,
  severity = 5
)

message <- toJSON(crash_data, auto_unbox = TRUE)

# Send to Kafka
system(paste0(
  "echo '", message, "' | docker exec -i kafka ",
  "kafka-console-producer --broker-list localhost:9092 --topic victoria-crashes"
))
```

```r
# Consumer example (read from file or pipe)
# The consumer will write messages to a file that R can read
system(paste0(
  "docker exec kafka kafka-console-consumer ",
  "--bootstrap-server localhost:9092 ",
  "--topic victoria-crashes ",
  "--max-messages 10 > output/kafka_logs/messages.json"
))

# Read messages
messages <- readLines("output/kafka_logs/messages.json")
crashes <- lapply(messages, fromJSON)
```

---

## Troubleshooting

### Issue: Cannot connect to Kafka

**Solution:**
- Check if Docker containers are running: `docker ps`
- Check if ports 2181 and 9092 are not in use
- Restart containers: `docker restart zookeeper kafka`

### Issue: Topic not found

**Solution:**
- List topics: `docker exec kafka kafka-topics --list --bootstrap-server localhost:9092`
- Recreate topic: See "Create Topic" section above

### Issue: Permission denied in WSL

**Solution:**
```bash
chmod +x kafka_2.13-3.6.0/bin/*.sh
```

---

## Project Integration

Once Kafka is running:

1. **Run Producer:** `Rscript scripts/06_kafka_producer.R`
2. **Run Consumer:** `Rscript scripts/07_kafka_consumer.R`
3. **View in Dashboard:** Open Shiny app

---

## Kafka Architecture for This Project

```
Historical Crash Data (CSV)
         ↓
    [R Producer]
         ↓
    [Kafka Topic: victoria-crashes]
         ↓
    [R Consumer]
         ↓
  DBSCAN Clustering (Real-time)
         ↓
    [Alert System]
         ↓
  [Log Files → Shiny Dashboard]
```

---

## Quick Reference

| Action | Command (Docker) |
|--------|------------------|
| Start Kafka | See Method 1 above |
| Stop Kafka | `docker stop kafka zookeeper` |
| List Topics | `docker exec kafka kafka-topics --list --bootstrap-server localhost:9092` |
| Delete Topic | `docker exec kafka kafka-topics --delete --topic victoria-crashes --bootstrap-server localhost:9092` |
| View Logs | `docker logs kafka` |

---

## For 1-Week Project

**Minimum Requirements:**
- Kafka running (Docker or manual)
- One topic created: `victoria-crashes`
- Producer sends crash records as JSON
- Consumer reads and detects hotspots
- Logs saved to files for dashboard

**You don't need:**
- Multiple partitions
- Replication
- Complex configuration
- Persistent storage beyond logs

**Keep it simple and focus on demonstrating the concept!**
