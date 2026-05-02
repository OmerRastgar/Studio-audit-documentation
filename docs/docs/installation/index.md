# Installation Guide

This comprehensive guide covers all aspects of installing and configuring Studio Platform for different environments and use cases.

## 📋 Installation Overview

Studio Platform is designed to be deployed using Docker containers, providing consistency across development, staging, and production environments.

### **Deployment Options**

| Environment | Recommended Setup | Complexity |
|-------------|-------------------|------------|
| **Development** | Docker Compose | ![Easy](https://img.shields.io/badge/difficulty-Easy-green) |
| **Staging** | Docker Compose | ![Medium](https://img.shields.io/badge/difficulty-Medium-yellow) |
| **Production** | Kubernetes/Docker Swarm | ![Hard](https://img.shields.io/badge/difficulty-Hard-red) |
| **Cloud** | Managed Services | ![Medium](https://img.shields.io/badge/difficulty-Medium-yellow) |

## 🎯 Before You Begin

### **System Requirements**

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 cores | 8+ cores |
| **Memory** | 8 GB RAM | 16+ GB RAM |
| **Storage** | 50 GB SSD | 100+ GB SSD |
| **Network** | 100 Mbps | 1+ Gbps |
| **Docker** | 20.10+ | Latest stable |

### **Software Prerequisites**

- **Docker Engine** 20.10+ or **Docker Desktop**
- **Docker Compose** 2.0+
- **Git** for source code management
- **Text editor** (VS Code recommended)
- **OpenSSL** for certificate generation

### **Network Requirements**

- **Outbound internet access** for:
  - Container image downloads
  - AI API calls (Google Gemini)
  - Security scanner updates
- **Inbound access** for:
  - User traffic (ports 80/443)
  - Admin access (various management ports)

## 📦 Installation Methods

### **Method 1: Quick Start (Recommended for Development)**

Perfect for getting started quickly with default configurations.

```bash
# Clone repository
git clone https://github.com/OmerRastgar/studio.git
cd studio

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start platform
docker-compose up -d --build
```

**Pros:**
- Fast setup (5-10 minutes)
- Default configurations
- All services included

**Cons:**
- Not production-ready
- Default security settings
- Limited customization

### **Method 2: Custom Installation**

For staging and production environments with custom requirements.

```bash
# Clone repository
git clone https://github.com/OmerRastgar/studio.git
cd studio

# Create custom configuration
cp .env.example .env.production
cp docker-compose.yml docker-compose.production.yml

# Customize configurations
# Edit .env.production and docker-compose.production.yml

# Start with custom config
docker-compose -f docker-compose.production.yml up -d --build
```

**Pros:**
- Full customization
- Production-ready
- Security optimized

**Cons:**
- More complex setup
- Requires configuration knowledge
- Longer setup time

### **Method 3: Kubernetes Deployment**

For enterprise-scale deployments with high availability requirements.

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/services/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/ingress/
```

**Pros:**
- High availability
- Auto-scaling
- Enterprise features

**Cons:**
- Complex setup
- Kubernetes knowledge required
- More resources needed

## 🔧 Configuration Deep Dive

### **Environment Variables**

#### **Core Configuration**

```bash
# Database Settings
POSTGRES_USER=studio_user
POSTGRES_PASSWORD=secure_password_here
POSTGRES_DB=auditdb

# Security Secrets (REQUIRED)
JWT_SECRET=your_jwt_secret_minimum_32_characters
MINIO_SECRET_KEY=your_minio_secret_minimum_32_characters
NEO4J_AUTH=neo4j/your_neo4j_password

# Application Settings
NODE_ENV=production
PUBLIC_URL=https://your-domain.com
COOKIE_DOMAIN=.your-domain.com
```

#### **AI Configuration**

```bash
# Google AI (Optional but recommended)
GOOGLE_API_KEY=your_google_api_key_here
GOOGLE_CLIENT_ID=your_google_oauth_client_id
GOOGLE_CLIENT_SECRET=your_google_oauth_client_secret

# AI Gateway (Optional)
USE_AI_GATEWAY=true
AI_GATEWAY_URL=https://your-ai-gateway.com
```

#### **External Services**

```bash
# Fleet Management
FLEET_URL=https://fleet.your-domain.com
FLEET_PUBLIC_URL=https://fleet.your-domain.com
FLEET_MYSQL_PASSWORD=secure_fleet_password

# Observability (Optional)
LOKI_URL=http://loki:3100
TEMPO_URL=http://tempo:4318/v1/traces
FLUENT_BIT_URL=http://fluent-bit:9880/app-logs
```

### **Docker Compose Customization**

#### **Resource Limits**

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
```

#### **Network Configuration**

```yaml
networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### **Volume Management**

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres
```

## 🔒 Security Configuration

### **SSL/TLS Setup**

#### **Self-Signed Certificates (Development)**

```bash
# Generate certificates
./scripts/generate-certs.sh

# Certificate locations
./certs/cert.pem    # SSL Certificate
./certs/key.pem     # Private Key
./certs/ca.pem      # CA Certificate
```

#### **Let's Encrypt (Production)**

```bash
# Install certbot
sudo apt-get install certbot

# Generate certificates
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ./certs/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ./certs/key.pem
```

### **Firewall Configuration**

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# iptables (General)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

### **Access Control**

```yaml
# Kong API Gateway security
kong:
  environment:
    KONG_PLUGINS: "bundled,opa,cors,jwt,prometheus"
    KONG_Ratelimiting: "on"
    KONG_Ratelimiting_Limit: "100"
    KONG_Ratelimiting_Window: "60"
```

## 📊 Monitoring & Logging

### **Health Checks**

```yaml
# Example health check
backend:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:4000/api/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### **Log Configuration**

```yaml
# Fluent-bit configuration
fluent-bit:
  volumes:
    - ./observability/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
```

### **Metrics Collection**

```yaml
# Prometheus configuration
prometheus:
  volumes:
    - ./observability/prometheus.yml:/etc/prometheus/prometheus.yml
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--web.console.libraries=/etc/prometheus/console_libraries'
    - '--web.console.templates=/etc/prometheus/consoles'
```

## 🚀 Production Deployment

### **Pre-Deployment Checklist**

- [ ] **Environment variables** configured and secured
- [ ] **SSL certificates** installed and valid
- [ ] **Firewall rules** configured
- [ ] **Backup strategy** implemented
- [ ] **Monitoring** set up
- [ ] **Resource limits** defined
- [ ] **Security scanning** completed
- [ ] **Performance testing** done

### **Deployment Steps**

1. **Prepare Environment**
   ```bash
   # Create production environment file
   cp .env.example .env.production
   
   # Set production values
   NODE_ENV=production
   PUBLIC_URL=https://your-domain.com
   ```

2. **Generate Secrets**
   ```bash
   # Generate all required secrets
   ./scripts/generate-secrets.sh
   ```

3. **Setup SSL**
   ```bash
   # Generate or install certificates
   ./scripts/setup-ssl.sh
   ```

4. **Deploy Services**
   ```bash
   # Deploy with production configuration
   docker-compose -f docker-compose.production.yml up -d --build
   ```

5. **Verify Deployment**
   ```bash
   # Run health checks
   ./scripts/health-check.sh
   
   # Run security verification
   ./scripts/security-check.sh
   ```

### **Post-Deployment Tasks**

1. **Default User Setup**
   - Change default passwords
   - Configure user roles
   - Set up authentication methods

2. **Integration Configuration**
   - Connect external services
   - Configure APIs and webhooks
   - Set up automation workflows

3. **Backup Configuration**
   - Configure automated backups
   - Test restore procedures
   - Set up monitoring

## 🔄 Environment Management

### **Development Environment**

```bash
# Start development stack
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### **Staging Environment**

```bash
# Deploy to staging
docker-compose -f docker-compose.staging.yml up -d --build

# Run tests
./scripts/run-tests.sh staging

# Promote to production
./scripts/promote-to-production.sh
```

### **Production Environment**

```bash
# Zero-downtime deployment
./scripts/zero-downtime-deploy.sh

# Health monitoring
./scripts/monitor-health.sh

# Rollback if needed
./scripts/rollback.sh
```

## 📈 Performance Optimization

### **Database Optimization**

```sql
-- PostgreSQL optimization
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
SELECT pg_reload_conf();
```

### **Application Optimization**

```yaml
# Backend optimization
backend:
  environment:
    NODE_OPTIONS: "--max-old-space-size=4096"
    ENABLE_COMPRESSION: "true"
    CACHE_TTL: "3600"
```

### **Infrastructure Optimization**

```yaml
# Resource allocation
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

## 🆘 Troubleshooting

### **Common Issues**

| Issue | Cause | Solution |
|-------|-------|----------|
| **Services won't start** | Missing environment variables | Check `.env` file |
| **Port conflicts** | Ports already in use | Change port mappings |
| **Memory errors** | Insufficient RAM | Increase memory limits |
| **Network issues** | Docker network problems | Reset Docker networks |
| **Permission errors** | File permissions | Fix directory permissions |

### **Debug Commands**

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs [service-name]

# Debug specific service
docker-compose exec [service-name] bash

# Check resource usage
docker stats

# Network debugging
docker network ls
docker network inspect [network-name]
```

---

!!! tip "Need Help?"
    Check our [Troubleshooting Guide](../troubleshooting/) for detailed solutions to common issues, or contact our support team for assistance.

!!! note "Enterprise Support"
    For enterprise deployments, consider our [Professional Services](https://cybergaar.com/enterprise) for expert installation and configuration.
