#!/bin/bash
# Redpanda Topic Initialization Script
# Creates all SmarterOS base topics with proper configurations

set -e

BROKER="redpanda:9092"
REPLICATION_FACTOR=1  # Single node for now
PARTITIONS=3

echo "🚀 Initializing SmarterOS Redpanda Topics..."
echo "=============================================="

# Wait for broker to be fully ready
echo "⏳ Waiting for Redpanda broker..."
for i in {1..30}; do
  if rpk cluster health --brokers $BROKER 2>/dev/null | grep -q "Healthy"; then
    echo "✅ Broker is healthy"
    break
  fi
  echo "  Attempt $i/30..."
  sleep 2
done

# Function to create topic with configs
create_topic() {
  local topic=$1
  local retention_ms=$2
  local cleanup_policy=$3
  
  echo ""
  echo "📝 Creating topic: $topic"
  
  if rpk topic create "$topic" \
    --brokers $BROKER \
    --partitions $PARTITIONS \
    --replicas $REPLICATION_FACTOR \
    --topic-config retention.ms=$retention_ms \
    --topic-config cleanup.policy=$cleanup_policy \
    --topic-config compression.type=snappy \
    --topic-config min.insync.replicas=1 2>/dev/null; then
    echo "  ✅ Created: $topic"
  else
    echo "  ⚠️  Already exists or failed: $topic"
  fi
}

# Core Event Stream Topics
echo ""
echo "🔷 Core Event Streams"
create_topic "smarteros.events" "604800000" "delete"  # 7 days, delete old
create_topic "smarteros.events.dlq" "2592000000" "delete"  # 30 days dead-letter queue

# N8N Automation Topics
echo ""
echo "⚙️  N8N Automation"
create_topic "n8n.automation.trigger" "86400000" "delete"  # 1 day
create_topic "n8n.automation.result" "604800000" "delete"  # 7 days
create_topic "n8n.automation.error" "2592000000" "delete"  # 30 days

# MCP Agent Topics
echo ""
echo "🤖 MCP Agent Actions"
create_topic "mcp.agent.actions" "604800000" "delete"  # 7 days
create_topic "mcp.agent.responses" "604800000" "delete"  # 7 days
create_topic "mcp.agent.telemetry" "259200000" "delete"  # 3 days

# Odoo Business Events
echo ""
echo "📊 Odoo Business Events"
create_topic "odoo.business.events" "2592000000" "delete"  # 30 days
create_topic "odoo.invoices" "7776000000" "compact"  # 90 days, compacted
create_topic "odoo.customers" "2592000000" "compact"  # 30 days, compacted

# Clerk Auth Events
echo ""
echo "🔐 Clerk Authentication"
create_topic "clerk.auth.events" "604800000" "delete"  # 7 days
create_topic "clerk.user.updates" "2592000000" "compact"  # 30 days, compacted

# Analytics & Telemetry
echo ""
echo "📈 Analytics & Observability"
create_topic "analytics.events" "2592000000" "delete"  # 30 days
create_topic "telemetry.metrics" "604800000" "delete"  # 7 days
create_topic "telemetry.traces" "259200000" "delete"  # 3 days
create_topic "telemetry.logs" "259200000" "delete"  # 3 days

# Multi-Tenant Topics
echo ""
echo "🏢 Multi-Tenant Operations"
create_topic "tenant.provisioning" "2592000000" "delete"  # 30 days
create_topic "tenant.events" "604800000" "delete"  # 7 days
create_topic "tenant.metrics" "2592000000" "delete"  # 30 days

# List all created topics
echo ""
echo "=============================================="
echo "✅ Topic initialization complete!"
echo ""
echo "📋 Created topics:"
rpk topic list --brokers $BROKER

echo ""
echo "🎯 Redpanda Cluster Status:"
rpk cluster info --brokers $BROKER

echo ""
echo "✨ SmarterOS Event-Driven Architecture is ready!"
