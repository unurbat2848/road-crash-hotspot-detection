#!/bin/bash
# ============================================================================
# Kafka Installation Script - Docker Method (EASIEST)
# ============================================================================
# This script sets up Apache Kafka using Docker
# Prerequisites: Docker must be installed
# ============================================================================

echo "============================================================================"
echo "Kafka Setup for Victorian Road Crash Analysis"
echo "============================================================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker is not installed!"
    echo "Please install Docker first:"
    echo "  - Windows/Mac: https://www.docker.com/products/docker-desktop"
    echo "  - Linux: sudo apt-get install docker.io"
    exit 1
fi

echo "✓ Docker is installed"
echo ""

# Stop and remove existing containers if any
echo "Cleaning up any existing Kafka containers..."
docker stop kafka zookeeper 2>/dev/null || true
docker rm kafka zookeeper 2>/dev/null || true
echo "✓ Cleanup complete"
echo ""

# Start Zookeeper
echo "Starting Zookeeper..."
docker run -d \
  --name zookeeper \
  -p 2181:2181 \
  zookeeper:latest

if [ $? -eq 0 ]; then
    echo "✓ Zookeeper started successfully"
else
    echo "❌ Failed to start Zookeeper"
    exit 1
fi

# Wait for Zookeeper to be ready
echo "Waiting for Zookeeper to initialize (10 seconds)..."
sleep 10

# Start Kafka
echo "Starting Kafka..."
docker run -d \
  --name kafka \
  -p 9092:9092 \
  --link zookeeper \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
  confluentinc/cp-kafka:latest

if [ $? -eq 0 ]; then
    echo "✓ Kafka started successfully"
else
    echo "❌ Failed to start Kafka"
    exit 1
fi

# Wait for Kafka to be ready
echo "Waiting for Kafka to initialize (15 seconds)..."
sleep 15

# Create topic
echo "Creating Kafka topic: victoria-crashes..."
docker exec kafka kafka-topics --create \
  --topic victoria-crashes \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1

if [ $? -eq 0 ]; then
    echo "✓ Topic created successfully"
else
    echo "⚠ Topic might already exist or Kafka not ready yet"
fi

# Verify setup
echo ""
echo "============================================================================"
echo "Verifying Kafka Setup..."
echo "============================================================================"

# List topics
echo "Available topics:"
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Check container status
echo ""
echo "Container status:"
docker ps | grep -E 'kafka|zookeeper'

echo ""
echo "============================================================================"
echo "Kafka Setup Complete!"
echo "============================================================================"
echo ""
echo "📊 Kafka is now running on localhost:9092"
echo "📊 Zookeeper is running on localhost:2181"
echo "📊 Topic 'victoria-crashes' is ready"
echo ""
echo "Next steps:"
echo "  1. Run R producer: Rscript scripts/06_kafka_producer.R"
echo "  2. Run R consumer: Rscript scripts/07_kafka_consumer.R"
echo ""
echo "To test manually:"
echo "  Producer: docker exec -it kafka kafka-console-producer --broker-list localhost:9092 --topic victoria-crashes"
echo "  Consumer: docker exec -it kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic victoria-crashes --from-beginning"
echo ""
echo "To stop Kafka:"
echo "  docker stop kafka zookeeper"
echo ""
echo "To start again later:"
echo "  docker start zookeeper && docker start kafka"
echo ""
echo "============================================================================"
