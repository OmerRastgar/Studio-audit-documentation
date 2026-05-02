# Environment Variables

Complete reference for all environment variables used by Studio Platform services.

## 📋 Variable Categories

Studio Platform uses environment variables for:

- **Database connections** and credentials
- **Service authentication** and security
- **AI service** configuration
- **External integrations**
- **Performance tuning**
- **Feature flags**

## 🔐 Security Variables

### **Core Security**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `JWT_SECRET` | ✅ Yes | - | JWT signing secret (min 32 chars) |
| `MINIO_SECRET_KEY` | ✅ Yes | - | MinIO encryption key (min 32 chars) |
| `COOKIE_DOMAIN` | No | localhost | Domain for authentication cookies |
| `SESSION_SECRET` | No | ${JWT_SECRET} | Additional session encryption |

### **Authentication**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_EMAIL` | ✅ Yes | admin@example.com | Default admin user email |
| `ADMIN_PASSWORD` | ✅ Yes | admin123# | Default admin user password |
| `GOOGLE_CLIENT_ID` | No | - | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | No | - | Google OAuth client secret |

### **SSL/TLS**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SSL_CERT_PATH` | No | /etc/secrets/cert.pem | SSL certificate file path |
| `SSL_KEY_PATH` | No | /etc/secrets/key.pem | SSL private key file path |
| `SSL_CA_PATH` | No | /etc/secrets/ca.pem | SSL CA certificate path |

## 🗄️ Database Variables

### **PostgreSQL**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_USER` | ✅ Yes | studio_user | PostgreSQL username |
| `POSTGRES_PASSWORD` | ✅ Yes | - | PostgreSQL password |
| `POSTGRES_DB` | No | auditdb | Primary database name |
| `POSTGRES_MULTIPLE_DATABASES` | No | auditdb,kratos,prowler | Additional databases |
| `DATABASE_URL` | Auto | - | Full PostgreSQL connection string |

### **PostgreSQL Performance**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_SHARED_BUFFERS` | No | 256MB | PostgreSQL shared memory |
| `POSTGRES_EFFECTIVE_CACHE_SIZE` | No | 1GB | Effective cache size |
| `POSTGRES_WORK_MEM` | No | 4MB | Work memory per query |
| `POSTGRES_MAX_CONNECTIONS` | No | 100 | Maximum connections |
| `POSTGRES_CHECKPOINT_COMPLETION_TARGET` | No | 0.9 | Checkpoint completion target |

### **Neo4j**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NEO4J_AUTH` | ✅ Yes | - | Neo4j authentication (neo4j/password) |
| `NEO4J_dbms_memory_heap_initial_size` | No | 512m | Initial heap size |
| `NEO4J_dbms_memory_heap_max_size` | No | 2G | Maximum heap size |
| `NEO4J_dbms_memory_pagecache_size` | No | 1G | Page cache size |

### **Redis**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `REDIS_URL` | Auto | redis://redis:6379 | Redis connection string |
| `REDIS_PASSWORD` | No | - | Redis authentication password |
| `REDIS_DB` | No | 0 | Redis database number |
| `REDIS_MAXMEMORY` | No | 2gb | Maximum memory usage |

### **MinIO Object Storage**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MINIO_ACCESS_KEY` | ✅ Yes | - | MinIO access key |
| `MINIO_SECRET_KEY` | ✅ Yes | - | MinIO secret key |
| `MINIO_BUCKET` | No | evidence | Default bucket name |
| `MINIO_ENDPOINT` | No | minio:9000 | MinIO server endpoint |
| `MINIO_USE_SSL` | No | false | Use SSL for MinIO |
| `MINIO_REGION` | No | us-east-1 | MinIO region |

## 🤖 AI Service Variables

### **Google AI**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GOOGLE_API_KEY` | ✅ Yes (for AI) | - | Google API key for AI services |
| `GOOGLE_CLIENT_ID` | No | - | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | No | - | Google OAuth client secret |
| `GOOGLE_PROJECT_ID` | No | - | Google Cloud project ID |

### **AI Model Configuration**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AI_DEFAULT_MODEL` | No | gemini-2.5-flash | Default AI model |
| `AI_TEMPERATURE` | No | 0.7 | AI model temperature |
| `AI_MAX_TOKENS` | No | 4096 | Maximum tokens per response |
| `AI_TIMEOUT` | No | 60000 | AI request timeout (ms) |

### **AI Gateway**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `USE_AI_GATEWAY` | No | false | Enable AI gateway |
| `AI_GATEWAY_URL` | No | - | AI gateway endpoint |
| `AI_GATEWAY_KEY` | No | - | AI gateway authentication key |

### **Alternative AI Services**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MOONSHOT_API_KEY` | No | - | Moonshot AI API key |
| `MOONSHOT_MODEL` | No | moonshot-v1-8k | Moonshot model |
| `GEMINI_API_KEY` | No | - | Gemini API key (alternative) |
| `OPENAI_API_KEY` | No | - | OpenAI API key (alternative) |

## 🔌 Integration Variables

### **FleetDM**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FLEET_URL` | No | https://fleet:8080 | Fleet server URL |
| `FLEET_PUBLIC_URL` | No | https://localhost:8080 | Public Fleet URL |
| `FLEET_MYSQL_PASSWORD` | ✅ Yes | - | Fleet MySQL password |
| `FLEET_MYSQL_ADDRESS` | No | fleet-db:3306 | Fleet MySQL address |
| `FLEET_MYSQL_USERNAME` | No | fleet | Fleet MySQL username |
| `FLEET_MYSQL_DATABASE` | No | fleet | Fleet MySQL database |

### **Prowler**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PROWLER_API_VERSION` | No | stable | Prowler API version |
| `PROWLER_POSTGRES_DB` | No | prowler | Prowler database name |
| `PROWLER_MYSQL_ADDRESS` | No | fleet-db:3306 | Prowler MySQL address |
| `PROWLER_ACCESS_KEY` | No | - | AWS access key |
| `PROWLER_SECRET_KEY` | No | - | AWS secret key |
| `PROWLER_SESSION_TOKEN` | No | - | AWS session token |

### **n8n Workflows**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `N8N_ENABLED` | No | false | Enable n8n workflows |
| `N8N_URL` | No | http://n8n:5678 | n8n server URL |
| `N8N_API_KEY` | No | - | n8n API key |
| `N8N_WEBHOOK_URL` | No | - | n8n webhook URL |

### **Third-Party Services**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SLACK_BOT_TOKEN` | No | - | Slack bot token |
| `SLACK_SIGNING_SECRET` | No | - | Slack signing secret |
| `JIRA_URL` | No | - | Jira server URL |
| `JIRA_USERNAME` | No | - | Jira username |
| `JIRA_API_TOKEN` | No | - | Jira API token |
| `WHATSAPP_PHONE_ID` | No | - | WhatsApp phone ID |
| `WHATSAPP_ACCESS_TOKEN` | No | - | WhatsApp access token |
| `TELEGRAM_BOT_TOKEN` | No | - | Telegram bot token |
| `MICROSOFT_CLIENT_ID` | No | - | Microsoft OAuth client ID |
| `MICROSOFT_CLIENT_SECRET` | No | - | Microsoft OAuth client secret |

## 🌐 Network Variables

### **URL Configuration**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PUBLIC_URL` | No | http://localhost | Public base URL |
| `BACKEND_URL` | No | http://backend:4000 | Backend service URL |
| `FRONTEND_URL` | No | http://frontend:3000 | Frontend service URL |
| `KONG_URL` | No | http://kong:8000 | Kong gateway URL |
| `COOKIE_DOMAIN` | No | localhost | Cookie domain |

### **Port Configuration**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `BACKEND_PORT` | No | 4000 | Backend service port |
| `FRONTEND_PORT` | No | 3000 | Frontend service port |
| `KONG_PROXY_PORT` | No | 8000 | Kong proxy port |
| `KONG_ADMIN_PORT` | No | 8001 | Kong admin port |
| `GRAFANA_PORT` | No | 3002 | Grafana port |

### **API Configuration**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `API_TIMEOUT` | No | 30000 | API request timeout (ms) |
| `API_RETRY_ATTEMPTS` | No | 3 | API retry attempts |
| `API_RETRY_DELAY` | No | 1000 | Retry delay (ms) |
| `RATE_LIMIT_MAX` | No | 100 | Rate limit max requests |
| `RATE_LIMIT_WINDOW` | No | 900000 | Rate limit window (ms) |

## 📊 Performance Variables

### **Resource Limits**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MEMORY_LIMIT` | No | 2G | Memory limit |
| `CPU_LIMIT` | No | 2.0 | CPU limit |
| `MEMORY_RESERVATION` | No | 1G | Memory reservation |
| `CPU_RESERVATION` | No | 1.0 | CPU reservation |

### **Caching**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CACHE_ENABLED` | No | true | Enable caching |
| `CACHE_TTL` | No | 3600 | Cache TTL (seconds) |
| `CACHE_MAX_SIZE` | No | 1000 | Maximum cache entries |
| `CACHE_CLEANUP_INTERVAL` | No | 300 | Cache cleanup interval |

### **Database Performance**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_POOL_MIN` | No | 5 | Minimum DB connections |
| `DB_POOL_MAX` | No | 20 | Maximum DB connections |
| `DB_TIMEOUT` | No | 30000 | DB timeout (ms) |
| `DB_IDLE_TIMEOUT` | No | 30000 | DB idle timeout |

## 🔍 Observability Variables

### **Logging**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LOG_LEVEL` | No | info | Log level (debug, info, warn, error) |
| `LOG_FORMAT` | No | json | Log format (json, text) |
| `LOG_MAX_SIZE` | No | 100MB | Maximum log file size |
| `LOG_MAX_FILES` | No | 10 | Maximum log files |

### **Metrics**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `METRICS_ENABLED` | No | true | Enable metrics collection |
| `METRICS_PORT` | No | 9090 | Metrics port |
| `METRICS_PATH` | No | /metrics | Metrics endpoint path |
| `PROMETHEUS_URL` | No | http://prometheus:9090 | Prometheus URL |

### **Tracing**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TEMPO_URL` | No | http://tempo:4318/v1/traces | Tempo tracing URL |
| `OTEL_SERVICE_NAME` | No | studio-backend | OpenTelemetry service name |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | No | http | OTLP protocol |
| `TRACING_ENABLED` | No | true | Enable tracing |

### **Monitoring**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LOKI_URL` | No | http://loki:3100 | Loki logging URL |
| `FLUENT_BIT_URL` | No | http://fluent-bit:9880/app-logs | Fluent-bit URL |
| `GRAFANA_URL` | No | http://grafana:3000 | Grafana URL |
| `GRAFANA_ADMIN_USER` | No | admin | Grafana admin user |
| `GRAFANA_ADMIN_PASSWORD` | No | admin | Grafana admin password |

## 🚀 Feature Flags

### **Application Features**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AI_ENABLED` | No | true | Enable AI features |
| `DEMO_MODE` | No | false | Enable demo mode |
| `BETA_FEATURES` | No | false | Enable beta features |
| `DEBUG_MODE` | No | false | Enable debug mode |
| `MAINTENANCE_MODE` | No | false | Enable maintenance mode |

### **Security Features**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RATE_LIMITING_ENABLED` | No | true | Enable rate limiting |
| `SECURITY_HEADERS_ENABLED` | No | true | Enable security headers |
| `CSP_ENABLED` | No | true | Enable Content Security Policy |
| `HELMET_ENABLED` | No | true | Enable Helmet.js |
| `SSL_ONLY` | No | false | Enforce SSL only |

### **Integration Features**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GOOGLE_INTEGRATION_ENABLED` | No | false | Enable Google integration |
| `SLACK_INTEGRATION_ENABLED` | No | false | Enable Slack integration |
| `JIRA_INTEGRATION_ENABLED` | No | false | Enable Jira integration |
| `WHATSAPP_INTEGRATION_ENABLED` | No | false | Enable WhatsApp integration |
| `TELEGRAM_INTEGRATION_ENABLED` | No | false | Enable Telegram integration |

## 🧪 Development Variables

### **Development Settings**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | No | development | Node environment |
| `WATCHPACK_POLLING` | No | false | Enable file watching |
| `HOT_RELOAD` | No | true | Enable hot reload |
| `SOURCE_MAPS` | No | true | Enable source maps |

### **Testing**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TEST_DATABASE_URL` | No | - | Test database URL |
| `TEST_REDIS_URL` | No | - | Test Redis URL |
| `MOCK_EXTERNAL_APIS` | No | true | Mock external APIs in tests |
| `COVERAGE_ENABLED` | No | false | Enable code coverage |

### **Debugging**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DEBUG_PORT` | No | 9229 | Debug port |
| `INSPECT_ENABLED` | No | false | Enable inspector |
| `PROFILING_ENABLED` | No | false | Enable profiling |
| `VERBOSE_LOGGING` | No | false | Enable verbose logging |

## 📝 Configuration Examples

### **Development Environment**
```bash
# Core configuration
NODE_ENV=development
POSTGRES_USER=studio_dev
POSTGRES_PASSWORD=dev_password_123
JWT_SECRET=dev_jwt_secret_minimum_32_characters
MINIO_SECRET_KEY=dev_minio_secret_minimum_32_characters
NEO4J_AUTH=neo4j/dev_password

# Development features
DEBUG_MODE=true
HOT_RELOAD=true
WATCHPACK_POLLING=true
LOG_LEVEL=debug

# URLs
PUBLIC_URL=http://localhost:3000
BACKEND_URL=http://localhost:4000
COOKIE_DOMAIN=localhost
```

### **Staging Environment**
```bash
# Core configuration
NODE_ENV=staging
POSTGRES_USER=studio_staging
POSTGRES_PASSWORD=staging_secure_password
JWT_SECRET=staging_jwt_secret_minimum_32_characters
MINIO_SECRET_KEY=staging_minio_secret_minimum_32_characters
NEO4J_AUTH=neo4j/staging_password

# Staging features
BETA_FEATURES=true
METRICS_ENABLED=true
LOG_LEVEL=info

# URLs
PUBLIC_URL=https://staging.your-domain.com
BACKEND_URL=https://api-staging.your-domain.com
COOKIE_DOMAIN=.staging.your-domain.com
```

### **Production Environment**
```bash
# Core configuration
NODE_ENV=production
POSTGRES_USER=studio_prod
POSTGRES_PASSWORD=production_secure_password_here
JWT_SECRET=production_jwt_secret_minimum_32_characters
MINIO_SECRET_KEY=production_minio_secret_minimum_32_characters
NEO4J_AUTH=neo4j/production_password

# Production features
AI_ENABLED=true
RATE_LIMITING_ENABLED=true
SECURITY_HEADERS_ENABLED=true
SSL_ONLY=true
LOG_LEVEL=warn

# URLs
PUBLIC_URL=https://your-domain.com
BACKEND_URL=https://api.your-domain.com
COOKIE_DOMAIN=.your-domain.com

# External services
GOOGLE_API_KEY=your_production_google_api_key
SLACK_BOT_TOKEN=your_production_slack_token
JIRA_API_TOKEN=your_production_jira_token
```

## 🔧 Variable Validation

### **Required Variables Check**
```bash
#!/bin/bash
# check-required-vars.sh

REQUIRED_VARS=(
  "POSTGRES_USER"
  "POSTGRES_PASSWORD"
  "JWT_SECRET"
  "MINIO_SECRET_KEY"
  "NEO4J_AUTH"
)

MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    MISSING_VARS+=("$var")
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo "ERROR: Missing required variables:"
  printf '  %s\n' "${MISSING_VARS[@]}"
  exit 1
fi

echo "All required variables are set"
```

### **Secret Strength Validation**
```bash
#!/bin/bash
# check-secret-strength.sh

# Check JWT secret
if [ ${#JWT_SECRET} -lt 32 ]; then
  echo "ERROR: JWT_SECRET must be at least 32 characters"
  exit 1
fi

# Check MinIO secret
if [ ${#MINIO_SECRET_KEY} -lt 32 ]; then
  echo "ERROR: MINIO_SECRET_KEY must be at least 32 characters"
  exit 1
fi

echo "Secret strength validation passed"
```

### **URL Validation**
```bash
#!/bin/bash
# check-urls.sh

URLS=(
  "$PUBLIC_URL"
  "$BACKEND_URL"
  "$KONG_URL"
)

for url in "${URLS[@]}"; do
  if [[ $url =~ ^https?:// ]]; then
    echo "✓ $url - Valid format"
  else
    echo "✗ $url - Invalid format"
    exit 1
  fi
done

echo "URL validation passed"
```

## ✅ Environment Setup Checklist

### **Required Variables**
- [ ] `POSTGRES_USER` and `POSTGRES_PASSWORD` configured
- [ ] `JWT_SECRET` (32+ characters) configured
- [ ] `MINIO_SECRET_KEY` (32+ characters) configured
- [ ] `NEO4J_AUTH` configured
- [ ] `ADMIN_EMAIL` and `ADMIN_PASSWORD` configured

### **Optional Variables**
- [ ] `GOOGLE_API_KEY` configured (for AI features)
- [ ] Integration tokens configured (Slack, Jira, etc.)
- [ ] Monitoring variables configured
- [ ] Performance tuning variables set

### **Validation**
- [ ] Required variables validation passes
- [ ] Secret strength validation passes
- [ ] URL format validation passes
- [ ] Service connectivity tests pass

### **Security**
- [ ] No secrets in version control
- [ ] Strong passwords used
- [ ] SSL certificates configured
- [ ] Environment-specific configurations isolated

---

!!! tip "Environment Templates"
    Use `.env.example` as a starting point and create environment-specific files (`.env.development`, `.env.staging`, `.env.production`).

!!! warning "Security Best Practices**
    Never commit actual secrets to version control. Use secret management systems or environment-specific configuration files that are excluded from Git.

!!! question "Need Help?"
    Check our [Configuration Guide](configuration.md) for detailed setup instructions and best practices.
