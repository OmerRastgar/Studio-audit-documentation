# Deployment Guide for Studio Documentation

This guide covers deploying the Studio Platform documentation on a separate server, completely independent of the main application.

## 🎯 Deployment Overview

The documentation is designed to be **fully standalone** and can be deployed on any server with Docker. This separation allows for:

- **Independent scaling** - Documentation can be scaled separately from the main application
- **Different security zones** - Documentation can be placed in DMZ while main app stays internal
- **Simplified maintenance** - Documentation updates don't affect the main application
- **Domain flexibility** - Can be deployed on any domain or subdomain

## 🏗️ Architecture Options

### **Option 1: Single Server Deployment**
```
┌─────────────────┐
│   Server        │
│   ┌───────────┐ │
│   │ Nginx     │ │
│   │ (Port 80/443)│ │
│   └───────────┘ │
│   ┌───────────┐ │
│   │ MkDocs    │ │
│   │ (Port 8000)│ │
│   └───────────┘ │
└─────────────────┘
```

### **Option 2: Multi-Server with Load Balancer**
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Load Balancer│───▶│ Server 1    │    │ Server 2    │
│ (HAProxy/   │    │ Nginx +     │    │ Nginx +     │
│  Cloudflare) │    │ MkDocs      │    │ MkDocs      │
└─────────────┘    └─────────────┘    └─────────────┘
```

### **Option 3: Cloud Deployment**
```
┌─────────────────┐
│ Cloud Provider  │
│ ┌─────────────┐ │
│ │ CDN/Edge     │ │
│ │ (Cloudflare)│ │
│ └─────────────┘ │
│       │         │
│ ┌─────────────┐ │
│ │ App Server  │ │
│ │ (Docker)    │ │
│ └─────────────┘ │
└─────────────────┘
```

## 🚀 Step-by-Step Deployment

### **Phase 1: Server Preparation**

#### **1.1 System Requirements**

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 2 cores | 4 cores |
| **Memory** | 2 GB RAM | 4 GB RAM |
| **Storage** | 10 GB SSD | 20 GB SSD |
| **Network** | 100 Mbps | 1 Gbps |
| **OS** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

#### **1.2 Install Docker**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

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

#### **1.3 Configure Firewall**

```bash
# Configure UFW firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Verify firewall status
sudo ufw status
```

### **Phase 2: Documentation Setup**

#### **2.1 Clone Repository**

```bash
# Create documentation directory
sudo mkdir -p /opt/studio-docs
sudo chown $USER:$USER /opt/studio-docs
cd /opt/studio-docs

# Clone documentation repository
git clone https://github.com/OmerRastgar/studio-docs.git .
```

#### **2.2 Initial Configuration**

```bash
# Test build
docker-compose -f docker-compose.docs.yml build

# Start development server to test
docker-compose -f docker-compose.docs.yml up -d

# Verify it's working
curl http://localhost:8000/

# Stop development server
docker-compose -f docker-compose.docs.yml down
```

### **Phase 3: SSL Certificate Setup**

#### **3.1 Option A: Self-Signed (Development)**

```bash
# Generate self-signed certificates
docker-compose -f docker-compose.docs.yml --profile setup up cert-generator

# Verify certificates
ls -la ssl/
```

#### **3.2 Option B: Let's Encrypt (Production)**

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Generate certificates
sudo certbot certonly --standalone -d doc.cybergaar.com

# Copy certificates to documentation directory
sudo cp /etc/letsencrypt/live/doc.cybergaar.com/fullchain.pem ./ssl/cert.pem
sudo cp /etc/letsencrypt/live/doc.cybergaar.com/privkey.pem ./ssl/key.pem
sudo chown $USER:$USER ./ssl/*
```

#### **3.3 Option C: Cloudflare SSL (Recommended)**

```bash
# Configure Cloudflare
# 1. Add domain to Cloudflare
# 2. Enable SSL/TLS > Full (strict)
# 3. Generate origin certificate
# 4. Upload certificates to server

# Create SSL directory
mkdir -p ssl

# Copy your certificates here
cp your-cert.pem ssl/cert.pem
cp your-key.pem ssl/key.pem
```

### **Phase 4: Production Deployment**

#### **4.1 Configure Domain**

Update `nginx.conf` with your domain:

```bash
# Edit nginx configuration
nano nginx.conf

# Update this line:
server_name doc.cybergaar.com;
```

#### **4.2 Deploy Services**

```bash
# Deploy with production profile
docker-compose -f docker-compose.docs.yml --profile production up -d

# Verify deployment
docker-compose -f docker-compose.docs.yml ps
```

#### **4.3 Verify Deployment**

```bash
# Check documentation
curl -I http://localhost/

# Check HTTPS
curl -I https://doc.cybergaar.com/

# Check health endpoint
curl http://localhost/health
```

## 🔧 Advanced Configuration

### **Custom Nginx Configuration**

Enhanced `nginx.conf` for production:

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Performance settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=docs:10m rate=20r/s;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name doc.cybergaar.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name doc.cybergaar.com;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        # Modern SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # HSTS
        add_header Strict-Transport-Security "max-age=63072000" always;

        # Rate limiting
        limit_req zone=docs burst=40 nodelay;

        # Root directory
        root /usr/share/nginx/html;
        index index.html;

        # Main location
        location / {
            try_files $uri $uri/ $uri.html =404;
            
            # Cache static files
            location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
                add_header Vary Accept-Encoding;
            }
            
            # Cache HTML files
            location ~* \.html$ {
                expires 1h;
                add_header Cache-Control "public";
            }
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Security
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
}
```

### **Environment-Specific Configurations**

#### **Development Environment**

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  docs:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    volumes:
      - .:/app
      - docs_cache:/app/site
    environment:
      - MKDOCS_CONFIG=mkdocs.yml
      - PYTHONUNBUFFERED=1
    command: ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000", "--watch"]
```

#### **Production Environment**

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  docs:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - docs_cache:/app/site
    environment:
      - MKDOCS_CONFIG=mkdocs.yml
      - PYTHONUNBUFFERED=1
    command: ["mkdocs", "build", "--clean"]
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - docs_cache:/usr/share/nginx/html
    depends_on:
      - docs
```

## 📊 Monitoring & Maintenance

### **Health Monitoring**

```bash
# Create health check script
cat > /opt/studio-docs/health-check.sh << 'EOF'
#!/bin/bash

# Check if containers are running
if ! docker-compose -f docker-compose.docs.yml ps | grep -q "Up"; then
    echo "ERROR: Containers are not running"
    exit 1
fi

# Check if documentation is accessible
if ! curl -f -s http://localhost/health > /dev/null; then
    echo "ERROR: Documentation is not accessible"
    exit 1
fi

echo "OK: All services are healthy"
EOF

chmod +x /opt/studio-docs/health-check.sh
```

### **Automated Backups**

```bash
# Create backup script
cat > /opt/studio-docs/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/backups/studio-docs"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    docker-compose.docs.yml \
    nginx.conf \
    mkdocs.yml \
    requirements.txt

# Backup SSL certificates
if [ -d "ssl" ]; then
    tar -czf $BACKUP_DIR/ssl_$DATE.tar.gz ssl/
fi

# Backup documentation content
tar -czf $BACKUP_DIR/docs_$DATE.tar.gz docs/

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /opt/studio-docs/backup.sh
```

### **Log Rotation**

```bash
# Create logrotate configuration
sudo cat > /etc/logrotate.d/studio-docs << 'EOF'
/opt/studio-docs/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/studio-docs/docker-compose.docs.yml restart docs-nginx
    endscript
}
EOF
```

## 🔒 Security Hardening

### **System Security**

```bash
# Install security updates
sudo apt update && sudo apt upgrade -y

# Configure automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Harden SSH
sudo nano /etc/ssh/sshd_config

# Recommended SSH settings:
# Port 2222
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes
```

### **Container Security**

```bash
# Create non-root user for containers
# Add to Dockerfile:
# RUN addgroup -g 1001 -S docs && \
#     adduser -S docs -u 1001
# USER docs

# Use read-only filesystem
# Add to docker-compose.yml:
# read_only: true
# tmpfs:
#   - /tmp
#   - /var/cache
```

### **Network Security**

```bash
# Configure fail2ban
sudo apt install fail2ban

# Create jail configuration
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
EOF

sudo systemctl restart fail2ban
```

## 🚀 CI/CD Integration

### **GitHub Actions Workflow**

```yaml
# .github/workflows/deploy-docs.yml
name: Deploy Documentation

on:
  push:
    branches: [main]
    paths: ['docs/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Deploy to server
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/studio-docs
            git pull origin main
            docker-compose -f docker-compose.docs.yml build
            docker-compose -f docker-compose.docs.yml up -d
            ./health-check.sh
```

### **Automated Testing**

```bash
# Create test script
cat > /opt/studio-docs/test-deployment.sh << 'EOF'
#!/bin/bash

# Test documentation accessibility
echo "Testing documentation accessibility..."
curl -f -s http://localhost/ > /dev/null || exit 1
curl -f -s https://doc.cybergaar.com/ > /dev/null || exit 1

# Test SSL certificate
echo "Testing SSL certificate..."
openssl s_client -connect doc.cybergaar.com:443 -servername doc.cybergaar.com < /dev/null > /dev/null 2>&1 || exit 1

# Test health endpoint
echo "Testing health endpoint..."
curl -f -s http://localhost/health > /dev/null || exit 1

echo "All tests passed!"
EOF

chmod +x /opt/studio-docs/test-deployment.sh
```

## 📈 Performance Optimization

### **Caching Strategy**

```nginx
# Add to nginx.conf
# Browser caching
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
}

# HTML caching
location ~* \.html$ {
    expires 1h;
    add_header Cache-Control "public";
}
```

### **CDN Integration**

```bash
# Configure Cloudflare
# 1. Add domain to Cloudflare
# 2. Enable CDN
# 3. Configure caching rules
# 4. Enable security features
```

### **Performance Monitoring**

```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor container performance
docker stats studio-docs

# Monitor disk usage
df -h
du -sh /opt/studio-docs/
```

## 🆘 Troubleshooting

### **Common Issues and Solutions**

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Container won't start** | Docker compose fails | Check logs, verify ports, check resources |
| **SSL certificate errors** | HTTPS not working | Verify certificate paths, regenerate certs |
| **High memory usage** | Slow performance | Increase resources, optimize images |
| **DNS issues** | Domain not resolving | Check DNS settings, propagation time |
| **Permission errors** | Access denied | Fix file permissions, check user rights |

### **Debug Commands**

```bash
# Check container status
docker-compose -f docker-compose.docs.yml ps

# View container logs
docker-compose -f docker-compose.docs.yml logs docs
docker-compose -f docker-compose.docs.yml logs docs-nginx

# Enter container for debugging
docker-compose -f docker-compose.docs.yml exec docs bash

# Check network connectivity
docker network ls
docker network inspect studio_docs_network

# Test nginx configuration
docker-compose -f docker-compose.docs.yml exec docs-nginx nginx -t
```

---

This deployment guide ensures your Studio documentation can be deployed completely independently on any server, with proper security, monitoring, and maintenance procedures in place.
