# Docker Setup

Complete guide for setting up Studio Platform using Docker containers for consistent deployment across all environments.

## 🐳 Docker Architecture Overview

Studio Platform uses a microservices architecture with Docker containers for each service:

```mermaid
graph TD
    Internet[Internet] --> LB[Load Balancer/Nginx]
    LB --> Frontend[Frontend Container]
    LB --> Backend[Backend Container]
    LB --> Gateway[API Gateway Container]
    
    Backend --> DB[(PostgreSQL Container)]
    Backend --> Graph[(Neo4j Container)]
    Backend --> Vector[(ChromaDB Container)]
    Backend --> Storage[(MinIO Container)]
    Backend --> Cache[(Redis Container)]
    
    Gateway --> Auth[Ory Kratos Container]
    Gateway --> Policy[OPA Container]
    
    subgraph "AI Services"
        AI[AI Service Container]
        RAG[Document RAG Container]
    end
    
    subgraph "Security Tools"
        Fleet[Fleet Service Container]
        Prowler[Prowler Container]
    end
    
    subgraph "Observability"
        Grafana[Grafana Container]
        Prometheus[Prometheus Container]
        Loki[Loki Container]
    end
```

## 📦 Container Components

### **Application Services**

| Container | Purpose | Image | Port |
|-----------|---------|-------|------|
| **frontend** | Next.js web interface | `studio/frontend` | 3000 |
| **backend** | Node.js API server | `studio/backend` | 4000 |
| **kong** | API gateway | `kong:latest` | 8000/8443 |
| **kratos** | Identity management | `ory/kratos:v1.1.0` | 4433/4434 |
| **opa** | Policy engine | `studio/opa` | 8181 |

### **Data Services**

| Container | Purpose | Image | Port |
|-----------|---------|-------|------|
| **postgres** | Primary database | `pgvector/pgvector:pg15` | 5432 |
| **neo4j** | Graph database | `neo4j:community` | 7474/7687 |
| **redis** | Cache/queue | `redis:latest` | 6379 |
| **minio** | Object storage | `minio/minio:latest` | 9000/9001 |
| **chroma** | Vector store | `studio/vector-store` | 8000 |

### **AI Services**

| Container | Purpose | Image | Port |
|-----------|---------|-------|------|
| **ai-service** | AI assistant | `studio/ai-service` | 5000 |
| **document-rag** | Document retrieval | `studio/document-rag` | 5002 |
| **chunking-worker** | Document processing | `studio/chunking-worker` | - |

### **Security & Monitoring**

| Container | Purpose | Image | Port |
|-----------|---------|-------|------|
| **fleet** | Device management | `fleetdm/fleet:latest` | 8080 |
| **prowler-api** | Cloud scanning | `prowlercloud/prowler-api` | 8888 |
| **grafana** | Monitoring dashboard | `grafana/grafana:latest` | 3002 |
| **prometheus** | Metrics collection | `prom/prometheus:latest` | 9090 |

## 🚀 Quick Docker Setup

### **1. Environment Preparation**

```bash
# Create Studio directory
mkdir -p ~/studio
cd ~/studio

# Clone repository
git clone https://github.com/OmerRastgar/studio.git .

# Copy environment template
cp .env.example .env
```

### **2. Configure Environment**

```bash
# Edit environment file
nano .env

# Essential variables to configure:
POSTGRES_USER=studio_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=auditdb

JWT_SECRET=your_jwt_secret_minimum_32_characters
MINIO_SECRET_KEY=your_minio_secret_minimum_32_characters
NEO4J_AUTH=neo4j/your_neo4j_password

GOOGLE_API_KEY=your_google_api_key_here
```

### **3. Start Services**

```bash
# Build and start all services
docker-compose up -d --build

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### **4. Verify Installation**

```bash
# Run health checks
docker-compose exec backend node live-verification/live-all.js

# Test API access
curl http://localhost/api/health

# Access web interface
open http://localhost
```

## ⚙️ Docker Compose Configuration

### **Main Configuration File**

The `docker-compose.yml` file defines all services, networks, and volumes:

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: pgvector/pgvector:pg15
    container_name: studio-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-auditdb}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/postgres-init:/docker-entrypoint-initdb.d
    networks:
      - core_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # More services...
```

### **Environment-Specific Configurations**

#### **Development Environment**
```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: development
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      NODE_ENV: development
      WATCHPACK_POLLING: "true"
    ports:
      - "3000:3000"
```

#### **Production Environment**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: production
    environment:
      NODE_ENV: production
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
```

## 🔧 Advanced Docker Configuration

### **Resource Management**

#### **CPU and Memory Limits**
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

#### **Disk Space Management**
```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres
  
  neo4j_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/neo4j
```

### **Network Configuration**

#### **Custom Networks**
```yaml
networks:
  core_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
  
  monitoring_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
```

#### **Network Isolation**
```yaml
services:
  postgres:
    networks:
      - core_network
    # No external access
  
  grafana:
    networks:
      - core_network
      - monitoring_network
    # Can access both networks
```

### **Health Checks**

#### **Custom Health Checks**
```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
  
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## 🗂️ Volume Management

### **Persistent Data Volumes**

```yaml
volumes:
  # Database data
  postgres_data:
    driver: local
  neo4j_data:
    driver: local
  
  # Application data
  minio_data:
    driver: local
  redis_data:
    driver: local
  
  # Monitoring data
  grafana_data:
    driver: local
  prometheus_data:
    driver: local
```

### **Bind Mounts for Development**

```yaml
services:
  frontend:
    volumes:
      - ./frontend:/app                 # Source code
      - /app/node_modules               # Prevent node_modules override
      - ./logs:/app/logs                # Log files
  
  backend:
    volumes:
      - ./backend:/app                  # Source code
      - /app/node_modules               # Prevent node_modules override
      - ./certs:/app/certs:ro           # SSL certificates
```

### **Volume Backup Strategy**

```bash
#!/bin/bash
# backup-volumes.sh

VOLUMES=(
  "studio_postgres_data"
  "studio_neo4j_data"
  "studio_minio_data"
  "studio_redis_data"
)

BACKUP_DIR="/backups/studio/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

for volume in "${VOLUMES[@]}"; do
  echo "Backing up $volume..."
  docker run --rm \
    -v "$volume":/volume \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf "/backup/${volume}.tar.gz" -C /volume .
done

echo "Backup completed: $BACKUP_DIR"
```

## 🔒 Security Configuration

### **Container Security**

#### **Non-Root Users**
```dockerfile
# Dockerfile example
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY . .

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

EXPOSE 4000
CMD ["npm", "start"]
```

#### **Read-Only Filesystems**
```yaml
services:
  frontend:
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
    volumes:
      - ./frontend/build:/app:ro
```

#### **Security Scanning**
```bash
# Scan images for vulnerabilities
docker scan studio/backend:latest
docker scan studio/frontend:latest

# Use Docker Bench Security
docker run -it --net host --pid host --cap-add audit_control \
    -v /var/lib:/var/lib \
    -v /etc:/etc \
    docker/docker-bench-security
```

### **Network Security**

#### **Internal Network Only**
```yaml
services:
  postgres:
    networks:
      - internal
    # No ports exposed externally
  
  backend:
    networks:
      - internal
      - external
    # Can access both networks
```

#### **Firewall Rules**
```bash
# Docker network firewall rules
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -s 172.20.0.0/16 -j ACCEPT  # Docker network
iptables -A INPUT -j DROP
```

## 📊 Monitoring and Logging

### **Container Monitoring**

#### **Resource Monitoring**
```bash
# View container resource usage
docker stats

# Continuous monitoring
docker stats --format "table &#123;&#123;.Container&#125;&#125;\t&#123;&#123;.CPUPerc&#125;&#125;\t&#123;&#123;.MemUsage&#125;&#125;\t&#123;&#123;.NetIO&#125;&#125;"

# Export metrics
docker stats --no-stream --format json > metrics.json
```

#### **Log Management**
```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service,environment"
```

#### **Centralized Logging**
```yaml
services:
  fluent-bit:
    image: fluent/fluent-bit:latest
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
    networks:
      - monitoring
```

### **Performance Optimization**

#### **Container Optimization**
```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER nodejs
CMD ["npm", "start"]
```

#### **Image Optimization**
```bash
# Remove unused images
docker image prune -a

# Optimize layer caching
docker build --cache-from studio/backend:latest .

# Use .dockerignore
echo "node_modules
.git
*.log
.env" > .dockerignore
```

## 🔄 Development Workflow

### **Hot Reload Development**

```yaml
# docker-compose.dev.yml
services:
  frontend:
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      CHOKIDAR_USEPOLLING: "true"
      WATCHPACK_POLLING: "true"
  
  backend:
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      NODEMON: "true"
```

### **Testing Integration**

```yaml
# docker-compose.test.yml
services:
  backend:
    environment:
      NODE_ENV: test
      DATABASE_URL: postgresql://test:test@postgres-test:5432/test
  
  postgres-test:
    image: postgres:15
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: test
```

### **CI/CD Integration**

```yaml
# .github/workflows/docker.yml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build images
        run: |
          docker-compose build
      
      - name: Run tests
        run: |
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit
      
      - name: Deploy
        run: |
          docker-compose up -d
```

## 🛠️ Troubleshooting Docker Issues

### **Common Problems**

#### **Container Won't Start**
```bash
# Check container logs
docker-compose logs backend

# Check container status
docker-compose ps

# Debug container
docker-compose exec backend bash
```

#### **Port Conflicts**
```bash
# Find process using port
sudo netstat -tulpn | grep :3000

# Kill process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "3001:3000"
```

#### **Resource Issues**
```bash
# Check system resources
free -h
df -h
docker system df

# Clean up Docker
docker system prune -a
docker volume prune
```

#### **Network Issues**
```bash
# Check networks
docker network ls

# Inspect network
docker network inspect studio_core_network

# Recreate network
docker network rm studio_core_network
docker-compose up -d
```

### **Debug Commands**

```bash
# Full system check
docker-compose ps
docker-compose logs
docker stats

# Service-specific debugging
docker-compose exec backend bash
docker-compose exec postgres psql -U studio_user -d auditdb

# Network debugging
docker-compose exec frontend ping backend
docker-compose exec backend ping postgres
```

## ✅ Docker Setup Checklist

### **Installation**
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.0+ installed
- [ ] User added to docker group
- [ ] Docker service running

### **Configuration**
- [ ] Environment variables configured
- [ ] docker-compose.yml customized
- [ ] Networks and volumes defined
- [ ] Health checks configured

### **Security**
- [ ] Non-root containers configured
- [ ] Resource limits set
- [ ] Network isolation implemented
- [ ] Secrets management configured

### **Monitoring**
- [ ] Logging configured
- [ ] Metrics collection set up
- [ ] Health checks implemented
- [ ] Backup strategy defined

### **Performance**
- [ ] Resource optimization
- [ ] Image optimization
- [ ] Caching configured
- [ ] Scaling strategy planned

---

!!! tip "Development vs Production"
    Use separate Docker Compose files for development and production environments to ensure proper isolation and configuration.

!!! warning "Resource Planning"
    Monitor resource usage during initial deployment and adjust limits accordingly to avoid performance issues.

!!! question "Need Help?"
    Check our [Troubleshooting Guide](../troubleshooting/common-issues.md) for Docker-specific issues and solutions.
