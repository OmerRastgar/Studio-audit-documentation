# Domain Configuration Guide
## Deploying Studio Documentation to doc.cybergaar.com

This guide provides step-by-step instructions for configuring the domain `doc.cybergaar.com` and deploying the Studio Platform documentation.

## 🎯 Prerequisites

Before starting, ensure you have:
- Root or sudo access to the server
- Docker and Docker Compose installed
- Domain `doc.cybergaar.com` registered and accessible
- Server IP address (static IP recommended)

## 📋 Configuration Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   DNS Resolver  │───▶│   Server IP     │
│   doc.cybergaar.com │    │                 │    │   (Your Server) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   Nginx Proxy   │
                                              │   (SSL/TLS)     │
                                              └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   MkDocs Site   │
                                              │   (Container)   │
                                              └─────────────────┘
```

## 🌐 DNS Configuration

### Step 1: Configure DNS Records

Log into your domain registrar's DNS management panel and configure the following records:

#### A Record (Primary)
```dns
Type: A
Name: doc
Value: YOUR_SERVER_IP
TTL: 3600 (or 1 hour)
```

#### Optional: CNAME Record (if using subdomain alias)
```dns
Type: CNAME
Name: docs
Value: doc.cybergaar.com
TTL: 3600
```

#### Example Configuration
```
doc.cybergaar.com.    IN    A    192.168.1.100
docs.cybergaar.com.   IN    CNAME doc.cybergaar.com
```

### Step 2: Verify DNS Propagation

Use these commands to verify DNS propagation:

```bash
# Check A record
nslookup doc.cybergaar.com

# Check with specific DNS server
nslookup doc.cybergaar.com 8.8.8.8

# Check propagation status
dig doc.cybergaar.com
```

**Wait time**: DNS propagation can take 5-48 hours. Use online tools like:
- https://www.whatsmydns.net/
- https://dnschecker.org/

## 🔧 Server Configuration

### Step 3: Configure Firewall

Open necessary ports on your server:

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

### Step 4: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y nginx certbot python3-certbot-nginx
```

## 📦 Deployment Setup

### Step 5: Prepare Documentation Files

```bash
# Create deployment directory
sudo mkdir -p /opt/studio-docs
cd /opt/studio-docs

# Clone or copy documentation files
# Option 1: Clone from Git
git clone https://github.com/OmerRastgar/studio.git .

# Option 2: Copy from local machine
# scp -r ./docs user@server:/opt/studio-docs/

# Navigate to docs directory
cd docs
```

### Step 6: Configure Environment

```bash
# Make scripts executable
chmod +x deploy-docs.sh
chmod +x scripts/ssl-setup.sh

# Create necessary directories
mkdir -p ssl
mkdir -p logs
```

## 🔒 SSL Certificate Setup

### Option A: Development (Self-Signed)

```bash
./scripts/ssl-setup.sh dev
```

### Option B: Production (Let's Encrypt)

```bash
# Ensure domain is pointing to your server first
./scripts/ssl-setup.sh prod
```

## 🚀 Deployment

### Step 7: Deploy Documentation

```bash
# Full deployment
./deploy-docs.sh

# Or step by step
./deploy-docs.sh build
./deploy-docs.sh deploy
./deploy-docs.sh verify
```

### Step 8: Verify Deployment

```bash
# Check service status
docker-compose -f docker-compose.docs.yml ps

# Check logs
docker-compose -f docker-compose.docs.yml logs -f

# Test locally
curl http://localhost:8000
curl https://localhost:443
```

## 🔍 Testing and Validation

### Step 9: Comprehensive Testing

#### Local Tests
```bash
# Health check
curl http://localhost:8000/health
curl https://localhost/health

# Documentation access
curl -I http://localhost:8000
curl -I https://doc.cybergaar.com
```

#### External Tests
```bash
# From external machine
curl -I https://doc.cybergaar.com

# SSL certificate test
openssl s_client -connect doc.cybergaar.com:443 -servername doc.cybergaar.com
```

#### Browser Testing
1. Open `https://doc.cybergaar.com` in browser
2. Check SSL certificate validity
3. Test all navigation links
4. Test search functionality
5. Test mobile responsiveness

### Step 10: SSL Validation

Use these online tools to validate SSL:
- https://www.ssllabs.com/ssltest/
- https://www.digicert.com/help/
- https://certificate.chain.test/

## 📊 Monitoring Setup

### Step 11: Basic Monitoring

```bash
# Create monitoring script
cat > /opt/studio-docs/monitor.sh << 'EOF'
#!/bin/bash

# Health check endpoint
HEALTH_URL="https://doc.cybergaar.com/health"
LOG_FILE="/opt/studio-docs/logs/monitor.log"

# Check health
if curl -f -s "$HEALTH_URL" > /dev/null; then
    echo "$(date): Documentation is healthy" >> "$LOG_FILE"
else
    echo "$(date): Documentation is DOWN" >> "$LOG_FILE"
    # Send alert (configure your preferred method)
fi
EOF

chmod +x /opt/studio-docs/monitor.sh

# Add to crontab for every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/studio-docs/monitor.sh") | crontab -
```

## 🔧 Maintenance Procedures

### Daily Tasks
- Check service status: `docker-compose ps`
- Review logs: `docker-compose logs --tail=100`

### Weekly Tasks
- Check SSL certificate expiry: `./scripts/ssl-setup.sh status`
- Update documentation content
- Review monitoring logs

### Monthly Tasks
- Update Docker images: `docker-compose pull && docker-compose up -d`
- Backup SSL certificates
- Review and rotate logs

## 🚨 Troubleshooting

### Common Issues

#### DNS Not Propagating
```bash
# Check DNS resolution
nslookup doc.cybergaar.com
dig doc.cybergaar.com

# Flush local DNS cache
sudo systemctl restart systemd-resolved  # Ubuntu
```

#### SSL Certificate Issues
```bash
# Check certificate details
openssl x509 -in ssl/cert.pem -text -noout

# Renew certificate
./scripts/ssl-setup.sh renew

# Check nginx configuration
docker-compose -f docker-compose.docs.yml exec docs-nginx nginx -t
```

#### Service Not Starting
```bash
# Check logs
docker-compose -f docker-compose.docs.yml logs docs

# Check port conflicts
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Restart services
docker-compose -f docker-compose.docs.yml restart
```

## 📞 Support Contacts

- **Technical Support**: admin@cybergaar.com
- **Documentation Issues**: Create GitHub issue
- **Emergency Contact**: [Phone number]

## 📋 Final Checklist

Before going live, verify:

- [ ] DNS records are configured and propagated
- [ ] SSL certificates are installed and valid
- [ ] Firewall ports are open
- [ ] Documentation is accessible via HTTPS
- [ ] All internal links work correctly
- [ ] Search functionality works
- [ ] Mobile responsive design works
- [ ] Monitoring is configured
- [ ] Backup procedures are in place
- [ ] Maintenance schedule is defined

## 🎉 Success Criteria

Your deployment is successful when:

1. ✅ `https://doc.cybergaar.com` loads in browser without SSL warnings
2. ✅ All documentation pages are accessible
3. ✅ Search functionality works
4. ✅ Mobile responsive design works
5. ✅ SSL certificate gets A+ grade on SSL Labs test
6. ✅ Monitoring alerts are working
7. ✅ Backup and recovery procedures are tested

---

**Next Steps**: Once deployed, share the documentation URL with your team and gather feedback for continuous improvement.
