# Quick Start Guide

Get Studio Platform running in minutes with this comprehensive quick start guide.

## 🚀 Prerequisites

### **System Requirements**

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 4 cores | 8 cores |
| **Memory** | 8 GB RAM | 16 GB RAM |
| **Storage** | 50 GB free | 100 GB free |
| **Docker** | 20.10+ | Latest |
| **Docker Compose** | 2.0+ | Latest |

### **Software Dependencies**

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Git** for cloning the repository
- **Text editor** for configuration (VS Code recommended)

## 📋 Step-by-Step Installation

### **Step 1: Clone the Repository**

```bash
# Clone the Studio repository
git clone https://github.com/OmerRastgar/studio.git
cd studio
```

### **Step 2: Configure Environment**

```bash
# Copy the example environment file
cp .env.example .env
```

Edit the `.env` file with your preferred text editor:

```bash
# Open in VS Code (recommended)
code .env

# Or use nano
nano .env
```

### **Step 3: Essential Environment Variables**

These are the **minimum required** variables to get Studio running:

```bash
# Database Configuration
POSTGRES_USER=studio_user
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=auditdb

# Security Secrets (Generate strong random strings)
JWT_SECRET=your_jwt_secret_here_32_chars_min
MINIO_SECRET_KEY=your_minio_secret_here_32_chars_min

# Neo4j Configuration
NEO4J_AUTH=neo4j/your_neo4j_password_here

# Fleet Database
FLEET_MYSQL_PASSWORD=your_fleet_mysql_password_here

# AI Configuration (Optional but recommended)
GOOGLE_API_KEY=your_google_api_key_here
```

!!! warning "Security Note"
    The application **will not start** if critical security secrets are missing. Use strong, unique passwords for all secrets.

!!! tip "Generating Secrets"
    Use these commands to generate secure secrets:
    ```bash
    # Generate JWT Secret
    openssl rand -base64 32
    
    # Generate Database Passwords
    openssl rand -base64 24
    ```

### **Step 4: Start the Platform**

```bash
# Build and start all services
docker-compose up -d --build
```

### **Step 5: Verify Installation**

```bash
# Check service status
docker-compose ps

# Run health verification
docker-compose exec backend node live-verification/live-all.js
```

## 🌐 Accessing Studio

Once the services are running, you can access Studio at:

| Service | URL | Description |
|----------|-----|-------------|
| **Main Application** | http://localhost | Studio Platform |
| **Fleet Console** | http://localhost:8080 | Device Management |
| **Grafana** | http://localhost:3002 | Monitoring Dashboard |
| **MinIO Console** | http://localhost:9001 | Object Storage |

### **Default Login Credentials**

| Role | Email | Password |
|------|-------|----------|
| **Admin** | admin@example.com | admin123# |
| **Manager** | manager@example.com | manager123# |
| **Customer** | customer@example.com | customer123# |

!!! warning "Security Warning"
    **Change default passwords immediately** after first login for production deployments.

## ✅ Verification Checklist

### **Service Health Check**

```bash
# Check all services are running
docker-compose ps

# Expected output should show "healthy" status for:
# - postgres
# - backend
# - frontend
# - kong
# - kratos
# - redis
# - neo4j
# - minio
```

### **Platform Functionality Test**

1. **Login** to the main application
2. **Create a new project** with a compliance framework
3. **Upload a sample evidence file**
4. **Test the AI assistant** with a compliance question
5. **View the risk dashboard**

### **API Health Check**

```bash
# Test backend API
curl http://localhost/api/health

# Test frontend
curl http://localhost/

# Expected: HTTP 200 OK responses
```

## 🔧 Common Setup Issues

### **Port Conflicts**

If you encounter port conflicts, modify the `docker-compose.yml`:

```yaml
# Example: Change frontend port
frontend:
  ports:
    - "3001:3000"  # Changed from 3000:3000
```

### **Permission Issues**

On Linux, you might need to adjust Docker permissions:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Restart Docker service
sudo systemctl restart docker
```

### **Memory Issues**

If services fail to start due to memory constraints:

1. **Increase Docker memory allocation** in Docker Desktop settings
2. **Or reduce resource limits** in `docker-compose.yml`:

```yaml
# Example: Reduce backend memory limits
backend:
  deploy:
    resources:
      limits:
        memory: 1G  # Reduced from 2G
```

### **Network Issues**

If services can't communicate:

```bash
# Reset Docker networks
docker network prune

# Restart services
docker-compose down
docker-compose up -d
```

## 🏗️ Production Considerations

### **Security Enhancements**

For production deployment, implement these security measures:

1. **SSL/TLS Certificates**
   ```bash
   # Generate SSL certificates
   ./scripts/generate-certs.sh
   ```

2. **Environment Variables**
   ```bash
   # Use production-ready secrets
   JWT_SECRET=$(openssl rand -base64 64)
   ```

3. **Network Security**
   - Use firewall rules
   - Implement VPN access
   - Configure intrusion detection

### **Performance Optimization**

1. **Resource Allocation**
   ```yaml
   # Increase limits for production
   backend:
     deploy:
       resources:
         limits:
           cpus: '2.0'
           memory: 4G
   ```

2. **Database Optimization**
   - Configure connection pooling
   - Enable query caching
   - Set up read replicas

### **Backup Strategy**

```bash
# Set up automated backups
./scripts/backup-setup.sh

# Manual backup
docker-compose exec postgres pg_dump -U studio_user auditdb > backup.sql
```

## 📚 Next Steps

### **Explore Features**

- **[User Guide](user-guide/)** - Learn about all platform features
- **[Admin Guide](admin-guide/)** - Configure system settings
- **[Developer Guide](developer-guide/)** - Explore APIs and integrations

### **Integrations**

- **[FleetDM Integration](integrations/fleetdm.md)** - Set up device management
- **[Prowler Integration](integrations/prowler.md)** - Configure cloud scanning
- **[n8n Workflows](integrations/n8n.md)** - Create automation workflows

### **Advanced Configuration**

- **[SSL/TLS Setup](installation/ssl-setup.md)** - Enable HTTPS
- **[Monitoring Setup](admin-guide/monitoring.md)** - Configure observability
- **[Backup & Recovery](admin-guide/backup-recovery.md)** - Set up data protection

## 🆘 Getting Help

### **Troubleshooting**

- **[Common Issues](troubleshooting/common-issues.md)** - Solutions to frequent problems
- **[Performance Issues](troubleshooting/performance.md)** - Optimization guides
- **[Security Issues](troubleshooting/security.md)** - Security troubleshooting

### **Community Support**

- **GitHub Issues** - Report bugs and request features
- **Documentation** - Browse comprehensive guides
- **Community Forums** - Connect with other users

### **Enterprise Support**

For enterprise customers:
- **Priority Support** - 24/7 assistance
- **Dedicated Account Manager** - Personalized guidance
- **Custom Training** - Team onboarding sessions

---

!!! success "Congratulations! 🎉"
    You now have Studio Platform running! Take some time to explore the features and check out our detailed guides for advanced configuration and usage.

!!! tip "Bookmark This Guide"
    Save this page for future reference. You'll need it when setting up additional environments or troubleshooting issues.
