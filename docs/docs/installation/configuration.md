# Configuration Guide

Comprehensive guide for configuring Studio Platform to meet your specific requirements and deployment environment.

## 📋 Configuration Overview

Studio Platform uses a layered configuration approach:

```mermaid
graph TD
    A[Environment Variables] --> B[Docker Compose]
    B --> C[Service Configuration]
    C --> D[Runtime Settings]
    
    E[Configuration Files] --> B
    F[Secrets Management] --> A
    G[Environment Profiles] --> A
```

## 🔧 Environment Variables

### **Core Configuration**

Create and configure your `.env` file:

```bash
# Copy template
cp .env.example .env

# Edit configuration
nano .env
```

### **Essential Variables**

#### **Database Configuration**
```bash
# PostgreSQL
POSTGRES_USER=studio_user
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=auditdb
POSTGRES_MULTIPLE_DATABASES="auditdb,kratos,prowler"

# Database URL (auto-generated)
DATABASE_URL=postgresql://studio_user:your_secure_password_here@postgres:5432/auditdb
```

#### **Security Secrets**
```bash
# JWT Secret (minimum 32 characters)
JWT_SECRET=your_jwt_secret_here_minimum_32_characters_long

# MinIO Object Storage
MINIO_ACCESS_KEY=your_minio_access_key
MINIO_SECRET_KEY=your_minio_secret_key_minimum_32_characters
MINIO_BUCKET=evidence
MINIO_USE_SSL=false

# Neo4j Graph Database
NEO4J_AUTH=neo4j/your_neo4j_password_here

# Fleet Database
FLEET_MYSQL_PASSWORD=your_fleet_mysql_password_here
```

#### **Application Settings**
```bash
# Environment
NODE_ENV=production
PUBLIC_URL=https://your-domain.com
COOKIE_DOMAIN=.your-domain.com

# Admin Credentials
ADMIN_EMAIL=admin@your-domain.com
ADMIN_PASSWORD=your_admin_password_here
```

### **AI Configuration**

#### **Google AI Services**
```bash
# Google API Key (required for AI features)
GOOGLE_API_KEY=your_google_api_key_here

# Google OAuth (optional, for social login)
GOOGLE_CLIENT_ID=your_google_oauth_client_id
GOOGLE_CLIENT_SECRET=your_google_oauth_client_secret

# AI Gateway (optional)
USE_AI_GATEWAY=true
AI_GATEWAY_URL=https://your-ai-gateway.com
```

#### **AI Model Configuration**
```bash
# Moonshot AI (optional)
MOONSHOT_API_KEY=your_moonshot_api_key
MOONSHOT_MODEL=moonshot-v1-8k

# Gemini Configuration
GEMINI_API_KEY=your_gemini_api_key
```

### **External Services**

#### **Fleet Management**
```bash
FLEET_URL=https://fleet.your-domain.com
FLEET_PUBLIC_URL=https://fleet.your-domain.com
FLEET_MYSQL_ADDRESS=fleet-db:3306
FLEET_MYSQL_USERNAME=fleet
FLEET_MYSQL_DATABASE=fleet
```

#### **Observability**
```bash
# Logging
LOKI_URL=http://loki:3100
FLUENT_BIT_URL=http://fluent-bit:9880/app-logs

# Tracing
TEMPO_URL=http://tempo:4318/v1/traces
OTEL_SERVICE_NAME=studio-backend

# Metrics
PROMETHEUS_URL=http://prometheus:9090
```

#### **Prowler Configuration**
```bash
PROWLER_API_VERSION=stable
PROWLER_POSTGRES_DB=prowler
PROWLER_MYSQL_ADDRESS=fleet-db:3306
```

## 🌍 Environment Profiles

### **Development Environment**

Create `.env.development`:

```bash
# Development overrides
NODE_ENV=development
WATCHPACK_POLLING=true
LOG_LEVEL=debug

# Development URLs
PUBLIC_URL=http://localhost:3000
FLEET_PUBLIC_URL=http://localhost:8080

# Development resources
MEMORY_LIMIT=1G
CPU_LIMIT=1.0

# Debug settings
DEBUG_MODE=true
ENABLE_PROFILING=true
```

### **Staging Environment**

Create `.env.staging`:

```bash
# Staging configuration
NODE_ENV=staging
LOG_LEVEL=info

# Staging URLs
PUBLIC_URL=https://staging.your-domain.com
COOKIE_DOMAIN=.staging.your-domain.com

# Staging resources
MEMORY_LIMIT=2G
CPU_LIMIT=2.0

# Monitoring enabled
MONITORING_ENABLED=true
METRICS_ENABLED=true
```

### **Production Environment**

Create `.env.production`:

```bash
# Production configuration
NODE_ENV=production
LOG_LEVEL=warn

# Production URLs
PUBLIC_URL=https://your-domain.com
COOKIE_DOMAIN=.your-domain.com

# Production resources
MEMORY_LIMIT=4G
CPU_LIMIT=4.0

# Security settings
SECURITY_HEADERS_ENABLED=true
RATE_LIMITING_ENABLED=true
SSL_ONLY=true
```

## 🔧 Service-Specific Configuration

### **Backend Configuration**

#### **API Settings**
```yaml
# docker-compose.yml backend service
backend:
  environment:
    PORT: 4000
    API_TIMEOUT: 30000
    RATE_LIMIT_WINDOW: 900000
    RATE_LIMIT_MAX: 100
    
    # Database connections
    DB_POOL_MIN: 2
    DB_POOL_MAX: 10
    DB_TIMEOUT: 30000
    
    # File uploads
    MAX_FILE_SIZE: 100MB
    UPLOAD_TIMEOUT: 60000
```

#### **Security Settings**
```yaml
backend:
  environment:
    # JWT Configuration
    JWT_EXPIRES_IN: 24h
    JWT_REFRESH_EXPIRES_IN: 7d
    
    # CORS Settings
    CORS_ORIGIN: https://your-domain.com
    CORS_CREDENTIALS: true
    
    # Security Headers
    HELMET_ENABLED: true
    CSP_ENABLED: true
```

### **Frontend Configuration**

#### **Next.js Settings**
```yaml
frontend:
  environment:
    # Build settings
    NODE_ENV: production
    NEXT_TELEMETRY_DISABLED: 1
    
    # API Configuration
    NEXT_PUBLIC_API_URL: /api
    BACKEND_URL: http://studio-backend:4000
    
    # Feature flags
    NEXT_PUBLIC_AI_ENABLED: true
    NEXT_PUBLIC_ANALYTICS_ENABLED: true
    
    # Performance
    NODE_OPTIONS: --max-old-space-size=2048
```

#### **UI Configuration**
```yaml
frontend:
  environment:
    # Theme
    NEXT_PUBLIC_THEME: default
    NEXT_PUBLIC_BRANDING: custom
    
    # Features
    NEXT_PUBLIC_DEMO_MODE: false
    NEXT_PUBLIC_BETA_FEATURES: true
    
    # Analytics
    NEXT_PUBLIC_GA_ID: your_google_analytics_id
    NEXT_PUBLIC_SENTRY_DSN: your_sentry_dsn
```

### **Database Configuration**

#### **PostgreSQL Optimization**
```yaml
postgres:
  environment:
    # Performance tuning
    POSTGRES_SHARED_BUFFERS: 256MB
    POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
    POSTGRES_WORK_MEM: 4MB
    POSTGRES_MAINTENANCE_WORK_MEM: 64MB
    
    # Connection settings
    POSTGRES_MAX_CONNECTIONS: 100
    POSTGRES_CHECKPOINT_COMPLETION_TARGET: 0.9
    
    # Logging
    POSTGRES_LOG_STATEMENT: all
    POSTGRES_LOG_MIN_DURATION_STATEMENT: 1000
```

#### **Neo4j Configuration**
```yaml
neo4j:
  environment:
    # Memory settings
    NEO4J_dbms_memory_heap_initial_size: 512m
    NEO4J_dbms_memory_heap_max_size: 2G
    NEO4J_dbms_memory_pagecache_size: 1G
    
    # Network settings
    NEO4J_dbms_connector_bolt_listen_address: :7687
    NEO4J_dbms_connector_http_listen_address: :7474
    
    # Security
    NEO4J_dbms_security_procedures_unrestricted: gds.*,apoc.*
    NEO4J_dbms_security_procedures_allowlist: gds.*,apoc.*
```

### **AI Service Configuration**

#### **AI Gateway Settings**
```yaml
ai-service:
  environment:
    # Service settings
    PORT: 5000
    MODEL_TIMEOUT: 60000
    MAX_CONCURRENT_REQUESTS: 10
    
    # AI Configuration
    DEFAULT_MODEL: gemini-2.5-flash
    TEMPERATURE: 0.7
    MAX_TOKENS: 4096
    
    # Caching
    CACHE_ENABLED: true
    CACHE_TTL: 3600
```

#### **Vector Store Configuration**
```yaml
vector-store:
  environment:
    # Model settings
    EMBEDDING_MODEL: sentence-transformers/all-MiniLM-L6-v2
    EMBEDDING_DIMENSION: 384
    
    # Performance
    BATCH_SIZE: 32
    MAX_WORKERS: 4
    
    # Storage
    CHROMA_PERSIST_DIR: /app/data
    ANONYMIZED_TELEMETRY: false
```

## 🔐 Security Configuration

### **SSL/TLS Configuration**

#### **Self-Signed Certificates (Development)**
```bash
# Generate certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Studio/CN=localhost"
```

#### **Let's Encrypt (Production)**
```bash
# Install certbot
sudo apt install certbot

# Generate certificates
sudo certbot certonly --standalone -d your-domain.com

# Copy to application
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem certs/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem certs/key.pem
```

#### **SSL Configuration**
```yaml
kong:
  environment:
    # SSL settings
    KONG_SSL_CERT: /etc/secrets/cert.pem
    KONG_SSL_CERT_KEY: /etc/secrets/key.pem
    KONG_SSL_CIPHERS: ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
    KONG_SSL_PROTOCOLS: TLSv1.2 TLSv1.3
```

### **Authentication Configuration**

#### **Ory Kratos Settings**
```yaml
kratos:
  environment:
    # URLs
    PUBLIC_URL: https://your-domain.com
    COOKIE_DOMAIN: .your-domain.com
    
    # Secrets
    SECRET_COOKIE: ${JWT_SECRET}
    SECRET_DEFAULT: ${JWT_SECRET}
    
    # Session settings
    SESSION_LIFETIME: 24h
    SESSION_COOKIE_PERSISTENT: true
```

#### **OAuth Configuration**
```yaml
kratos:
  environment:
    # Google OAuth
    GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID}
    GOOGLE_CLIENT_SECRET: ${GOOGLE_CLIENT_SECRET}
    
    # OAuth settings
    OAUTH2_PROVIDER_URL: https://accounts.google.com
    OAUTH2_REDIRECT_URL: https://your-domain.com/.ory/kratos/self-service/methods/oidc/callback/google
```

### **Authorization Configuration**

#### **OPA Policy Settings**
```yaml
opa:
  volumes:
    - ./gateway/opa/policies:/policies:ro
  
  environment:
    # Policy settings
    POLICY_PATH: /policies
    DECISION_LOG_PATH: /logs/decisions.log
    
    # Performance
    BUNDLE_SERVER: false
    BUNDLE_MODE: manual
```

## 📊 Performance Configuration

### **Resource Limits**

#### **CPU and Memory**
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
  
  frontend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
```

#### **Database Connections**
```yaml
backend:
  environment:
    # Connection pool settings
    DB_POOL_MIN: 5
    DB_POOL_MAX: 20
    DB_IDLE_TIMEOUT: 30000
    DB_CONNECTION_TIMEOUT: 10000
    
    # Query settings
    QUERY_TIMEOUT: 30000
    STATEMENT_TIMEOUT: 60000
```

### **Caching Configuration**

#### **Redis Settings**
```yaml
redis:
  environment:
    # Memory settings
    MAXMEMORY: 2gb
    MAXMEMORY_POLICY: allkeys-lru
    
    # Persistence
    SAVE: "900 1 300 10 60 10000"
    APPENDONLY: yes
    APPENDFSYNC: everysec
```

#### **Application Caching**
```yaml
backend:
  environment:
    # Cache settings
    CACHE_TTL: 3600
    CACHE_MAX_SIZE: 1000
    CACHE_CLEANUP_INTERVAL: 300
    
    # Session storage
    SESSION_STORE: redis
    SESSION_TTL: 86400
```

### **Load Balancing**

#### **Kong Configuration**
```yaml
kong:
  environment:
    # Load balancing
    KONG_UPSTREAM_KEEPALIVE: 60
    KONG_UPSTREAM_KEEPALIVE_REQUESTS: 100
    KONG_UPSTREAM_KEEPALIVE_TIMEOUT: 60
    
    # Health checks
    KONG_HEALTH_CHECKS_ACTIVE: true
    KONG_HEALTH_CHECKS_PASSIVE: true
```

## 🔍 Monitoring Configuration

### **Logging Configuration**

#### **Application Logging**
```yaml
backend:
  environment:
    # Log level
    LOG_LEVEL: info
    
    # Log format
    LOG_FORMAT: json
    
    # Log rotation
    LOG_MAX_SIZE: 100MB
    LOG_MAX_FILES: 10
```

#### **System Logging**
```yaml
fluent-bit:
  volumes:
    - ./observability/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
  
  environment:
    # Output settings
    OUTPUT_PLUGIN: loki
    LOKI_URL: http://loki:3100
    
    # Processing
    PARSE_RULE: docker
    BUFFER_SIZE: 512KB
```

### **Metrics Configuration**

#### **Prometheus Settings**
```yaml
prometheus:
  volumes:
    - ./observability/prometheus.yml:/etc/prometheus/prometheus.yml
  
  environment:
    # Storage
    STORAGE_TSDB_PATH: /prometheus
    STORAGE_TSDB_RETENTION: 30d
    
    # Scraping
    SCRAPE_INTERVAL: 15s
    EVALUATION_INTERVAL: 15s
```

#### **Application Metrics**
```yaml
backend:
  environment:
    # Metrics settings
    METRICS_ENABLED: true
    METRICS_PORT: 9090
    METRICS_PATH: /metrics
    
    # Custom metrics
    CUSTOM_METRICS_ENABLED: true
    PERFORMANCE_TRACKING: true
```

## 🔄 Configuration Management

### **Environment-Specific Deployments**

#### **Development Deployment**
```bash
# Use development configuration
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.development up -d
```

#### **Staging Deployment**
```bash
# Use staging configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml --env-file .env.staging up -d
```

#### **Production Deployment**
```bash
# Use production configuration
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.production up -d
```

### **Configuration Validation**

#### **Environment Validation Script**
```bash
#!/bin/bash
# validate-config.sh

# Required variables
REQUIRED_VARS=(
  "POSTGRES_USER"
  "POSTGRES_PASSWORD"
  "JWT_SECRET"
  "MINIO_SECRET_KEY"
  "NEO4J_AUTH"
)

# Check each variable
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: $var is not set"
    exit 1
  fi
done

# Validate secret strength
if [ ${#JWT_SECRET} -lt 32 ]; then
  echo "ERROR: JWT_SECRET must be at least 32 characters"
  exit 1
fi

echo "Configuration validation passed"
```

#### **Service Health Validation**
```bash
#!/bin/bash
# validate-services.sh

# Wait for services to be ready
echo "Waiting for services..."
docker-compose ps

# Check each service
services=("postgres" "redis" "neo4j" "backend" "frontend")

for service in "${services[@]}"; do
  echo "Checking $service..."
  docker-compose exec $service healthcheck || {
    echo "ERROR: $service is not healthy"
    exit 1
  }
done

echo "All services are healthy"
```

### **Configuration Updates**

#### **Hot Reload Configuration**
```bash
# Update environment variables
docker-compose down
docker-compose up -d

# Or restart specific service
docker-compose restart backend
```

#### **Configuration Backup**
```bash
#!/bin/bash
# backup-config.sh

BACKUP_DIR="/backups/config/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup configuration files
cp .env* "$BACKUP_DIR/"
cp docker-compose*.yml "$BACKUP_DIR/"
cp -r gateway/ "$BACKUP_DIR/"

echo "Configuration backed up to $BACKUP_DIR"
```

## ✅ Configuration Checklist

### **Required Configuration**
- [ ] All required environment variables set
- [ ] Security secrets configured (32+ characters)
- [ ] Database credentials configured
- [ ] SSL certificates installed (production)
- [ ] Domain names configured

### **Optional Configuration**
- [ ] AI services configured
- [ ] External integrations set up
- [ ] Monitoring enabled
- [ ] Performance tuning applied
- [ ] Security hardening implemented

### **Validation**
- [ ] Configuration validation script passes
- [ ] Service health checks pass
- [ ] Database connectivity verified
- [ ] External services accessible
- [ ] SSL certificates valid

### **Documentation**
- [ ] Configuration documented
- [ ] Backup procedures documented
- [ ] Recovery procedures documented
- [ ] Contact information updated

---

!!! tip "Configuration Templates"
    Use the provided `.env.example` as a template and customize it for your specific requirements and environment.

!!! warning "Security Best Practices**
    Never commit secrets to version control. Use environment variables or secret management systems for sensitive configuration.

!!! question "Need Help?"
    Check our [Troubleshooting Guide](../troubleshooting/common-issues.md) for configuration-related issues and solutions.
