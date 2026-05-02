# Prerequisites

Before installing Studio Platform, ensure your system meets the following requirements and dependencies.

## 🖥️ System Requirements

### **Minimum Requirements**

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 cores | 8+ cores |
| **Memory** | 8 GB RAM | 16+ GB RAM |
| **Storage** | 50 GB free SSD | 100+ GB free SSD |
| **Network** | 100 Mbps | 1+ Gbps |
| **Operating System** | Ubuntu 20.04+ / CentOS 8+ / Windows 10+ | Ubuntu 22.04 LTS |

### **Hardware Considerations**

#### **CPU Requirements**
- **4 cores minimum** for basic operations
- **8+ cores recommended** for:
  - Large team deployments (50+ users)
  - Heavy AI processing workloads
  - Multiple concurrent compliance scans

#### **Memory Requirements**
- **8 GB RAM minimum** for small teams (< 10 users)
- **16 GB RAM recommended** for:
  - Medium teams (10-50 users)
  - Heavy document processing
  - Concurrent AI operations

#### **Storage Requirements**
- **50 GB SSD minimum** for basic installation
- **100 GB SSD recommended** for:
  - Large document libraries
  - Extended log retention
  - Multiple compliance frameworks

## 🐳 Software Dependencies

### **Docker Requirements**

#### **Docker Engine**
```bash
# Check Docker version
docker --version
# Required: 20.10 or higher
```

#### **Docker Compose**
```bash
# Check Docker Compose version
docker-compose --version
# Required: 2.0 or higher
```

### **Installation Commands**

#### **Ubuntu/Debian**
```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### **CentOS/RHEL**
```bash
# Install prerequisites
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### **Windows**
```powershell
# Download and install Docker Desktop
# Visit: https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

#### **macOS**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Start Docker Desktop and verify
docker --version
docker-compose --version
```

## 🔧 Additional Tools

### **Required Tools**

#### **Git**
```bash
# Verify Git installation
git --version
# Required: 2.0 or higher

# Install if needed
# Ubuntu/Debian: sudo apt install git
# CentOS/RHEL: sudo yum install git
# macOS: brew install git
```

#### **Text Editor**
Recommended editors for configuration:
- **Visual Studio Code** (recommended)
- **Sublime Text**
- **Vim/Neovim**
- **Nano**

#### **OpenSSL** (for SSL certificates)
```bash
# Verify OpenSSL
openssl version

# Install if needed
# Ubuntu/Debian: sudo apt install openssl
# CentOS/RHEL: sudo yum install openssl
# macOS: brew install openssl
```

### **Optional Tools**

#### **Monitoring Tools**
```bash
# System monitoring
htop          # Process monitoring
iotop         # I/O monitoring
nethogs       # Network monitoring

# Docker monitoring
docker stats  # Container resource usage
```

#### **Network Tools**
```bash
# Network diagnostics
curl          # HTTP requests
wget          # File downloads
ping          # Network connectivity
nslookup      # DNS queries
```

## 🌐 Network Requirements

### **Port Requirements**

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| **80** | HTTP | Web access (redirect) | Production |
| **443** | HTTPS | Web access (secure) | Production |
| **8000** | HTTP | Development server | Development |
| **5432** | TCP | PostgreSQL (internal) | Internal |
| **6379** | TCP | Redis (internal) | Internal |
| **7687** | TCP | Neo4j (internal) | Internal |
| **9000** | HTTP | MinIO console (internal) | Internal |

### **Firewall Configuration**

#### **Ubuntu (UFW)**
```bash
# Allow essential ports
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

#### **CentOS (firewalld)**
```bash
# Allow essential ports
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Reload firewall
sudo firewall-cmd --reload

# Check status
sudo firewall-cmd --list-all
```

#### **Windows Firewall**
```powershell
# Allow essential ports through Windows Firewall
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

### **Internet Connectivity**

Studio Platform requires outbound internet access for:

#### **AI Services**
- **Google Gemini API** - AI assistant functionality
- **Cloudflare AI Gateway** - API management (optional)

#### **Security Services**
- **FleetDM updates** - Agent management
- **Prowler updates** - Cloud scanning rules
- **Security feed updates** - Threat intelligence

#### **Container Updates**
- **Docker Hub** - Container image downloads
- **Package repositories** - Dependency updates

### **DNS Requirements**

Ensure your system can resolve:
- `docker.io` - Docker registry
- `github.com` - Source code repository
- `googleapis.com` - Google AI services
- `prowler.com` - Security scanner updates

## 🔒 Security Requirements

### **System Security**

#### **User Permissions**
- **Non-root user** for Docker operations
- **Sudo access** for system configuration
- **Docker group membership** for container management

#### **File Permissions**
```bash
# Set appropriate permissions for Studio directory
chmod 755 /path/to/studio
chown $USER:$USER /path/to/studio
```

### **SSL/TLS Certificates**

#### **Development**
- Self-signed certificates (acceptable)
- Generated automatically by setup scripts

#### **Production**
- **Let's Encrypt** (recommended)
- **Commercial certificates** (acceptable)
- **Cloudflare SSL** (recommended for cloud deployments)

### **Environment Security**

#### **Secret Management**
- **Strong passwords** for all services
- **Environment variables** for sensitive data
- **No hardcoded secrets** in configuration files

#### **Network Security**
- **Firewall rules** configured
- **VPN access** (recommended for admin)
- **Intrusion detection** (recommended)

## 📊 Performance Considerations

### **Database Performance**

#### **PostgreSQL Optimization**
```bash
# Recommended PostgreSQL settings for production
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

#### **Neo4j Optimization**
```bash
# Recommended Neo4j settings
dbms.memory.heap.initial_size=512m
dbms.memory.heap.max_size=2G
dbms.memory.pagecache.size=1G
```

### **Container Resource Limits**

#### **Memory Allocation**
```yaml
# Example docker-compose.yml resource limits
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

#### **CPU Allocation**
```yaml
# CPU limits for optimal performance
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
        reservations:
          cpus: '1.0'
```

## 🐛 Common Prerequisite Issues

### **Docker Issues**

#### **Permission Denied**
```bash
# Error: permission denied while trying to connect to Docker daemon
# Solution: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### **Docker Service Not Running**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

#### **Port Conflicts**
```bash
# Check if ports are in use
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Kill processes using ports
sudo kill -9 <PID>
```

### **Network Issues**

#### **DNS Resolution**
```bash
# Test DNS resolution
nslookup google.com
dig google.com

# Check /etc/resolv.conf
cat /etc/resolv.conf
```

#### **Firewall Blocking**
```bash
# Temporarily disable firewall for testing
sudo ufw disable
# Test connectivity
# Re-enable firewall
sudo ufw enable
```

### **Resource Issues**

#### **Insufficient Memory**
```bash
# Check available memory
free -h

# Check swap usage
swapon --show

# Add swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### **Disk Space**
```bash
# Check disk usage
df -h

# Clean up Docker if needed
docker system prune -a
```

## ✅ Prerequisites Checklist

### **System Requirements**
- [ ] CPU: 4+ cores (8+ recommended)
- [ ] Memory: 8+ GB RAM (16+ recommended)
- [ ] Storage: 50+ GB SSD (100+ recommended)
- [ ] Network: 100+ Mbps (1+ Gbps recommended)

### **Software Dependencies**
- [ ] Docker Engine 20.10+
- [ ] Docker Compose 2.0+
- [ ] Git 2.0+
- [ ] OpenSSL (for SSL)
- [ ] Text editor (VS Code recommended)

### **Network Configuration**
- [ ] Ports 80, 443 open (production)
- [ ] Port 8000 open (development)
- [ ] Internet connectivity available
- [ ] DNS resolution working
- [ ] Firewall configured

### **Security Setup**
- [ ] Non-root user configured
- [ ] Docker group membership
- [ ] SSH access configured
- [ ] SSL certificate plan (production)

### **Performance Optimization**
- [ ] Resource limits defined
- [ ] Database optimization planned
- [ ] Monitoring tools ready
- [ ] Backup strategy planned

---

!!! tip "System Verification"
    Run the verification script to ensure all prerequisites are met:
    ```bash
    ./scripts/verify-prerequisites.sh
    ```

!!! warning "Production Deployment"
    For production deployments, ensure you meet all recommended requirements and have proper security measures in place.

!!! question "Need Help?"
    Check our [Troubleshooting Guide](../troubleshooting/common-issues.md) if you encounter any prerequisite issues.
