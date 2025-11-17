# Vault Server Configuration
# Production-ready with transit encryption

ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # TLS handled by Traefik
}

storage "file" {
  path = "/vault/data"
}

# API endpoint for external access
api_addr = "https://vault.smarterbot.cl"

# Cluster configuration
cluster_addr = "https://vault.smarterbot.cl:8201"

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = false
}

# Logging
log_level = "Info"
log_format = "json"

# Default lease times
default_lease_ttl = "168h" # 7 days
max_lease_ttl = "720h" # 30 days
