# SSL/TLS Setup Guide

This guide covers SSL/TLS certificate setup, configuration, and management for securing the Studio Platform with HTTPS encryption.

## 🔐 SSL/TLS Overview

### **Why SSL/TLS is Essential**
- **Data Encryption** - Protects sensitive data in transit
- **Authentication** - Verifies server identity
- **Data Integrity** - Prevents data tampering
- **Compliance** - Required for most compliance frameworks
- **Trust** - Builds user confidence

### **SSL/TLS Components**
- **Certificate** - Digital identity document
- **Private Key** - Secret key for decryption
- **Certificate Authority (CA)** - Trusted certificate issuer
- **Chain of Trust** - Hierarchy of certificates

## 📋 Prerequisites

### **Domain Requirements**
- Registered domain name (e.g., `studio.example.com`)
- DNS configuration pointing to your server
- Administrative access to DNS settings

### **Server Requirements**
- Dedicated IP address (for some certificate types)
- Open port 443 (HTTPS)
- Root or sudo access to server
- Web server (Nginx, Apache, or similar)

### **Software Requirements**
- OpenSSL (for certificate generation)
- Certbot (for Let's Encrypt certificates)
- Web server with SSL module enabled

## 🚀 Certificate Options

### **Let's Encrypt (Recommended)**
- **Free** certificates
- **90-day** validity period
- **Automated** renewal
- **Domain validation** only

### **Commercial CA**
- **Paid** certificates
- **1-2 year** validity
- **Extended validation** options
- **Warranty** and support

### **Self-Signed**
- **Free** certificates
- **Custom** validity period
- **Not trusted** by browsers
- **Development/testing** only

## 🔧 Let's Encrypt Setup

### **Step 1: Install Certbot**

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update

# Install Certbot and Nginx plugin
sudo apt install certbot python3-certbot-nginx -y
```

#### CentOS/RHEL
```bash
# Install EPEL repository
sudo yum install epel-release -y

# Install Certbot
sudo yum install certbot python3-certbot-nginx -y
```

#### Docker
```bash
# Pull Certbot image
docker pull certbot/certbot

# Create volume for certificates
docker volume create certbot_certs
```

### **Step 2: Generate Certificate**

#### Automatic Nginx Configuration
```bash
# Generate certificate and configure Nginx automatically
sudo certbot --nginx -d studio.example.com -d www.studio.example.com
```

#### Manual Certificate Generation
```bash
# Generate certificate only (manual Nginx configuration)
sudo certbot certonly --nginx -d studio.example.com -d www.studio.example.com

# Or use webroot method
sudo certbot certonly --webroot -w /var/www/html -d studio.example.com
```

#### Docker Method
```bash
# Generate certificate using Docker
docker run -it --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -p 80:80 \
  certbot/certbot certonly \
  --standalone -d studio.example.com
```

### **Step 3: Configure Nginx**

#### Nginx SSL Configuration
```nginx
# /etc/nginx/sites-available/studio
server {
    listen 80;
    server_name studio.example.com www.studio.example.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name studio.example.com www.studio.example.com;
    
    # SSL Certificate Configuration
    ssl_certificate /etc/letsencrypt/live/studio.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/studio.example.com/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Application Configuration
    root /var/www/studio;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files
    location /static/ {
        alias /var/www/studio/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Media files
    location /media/ {
        alias /var/www/studio/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
```

### **Step 4: Test Configuration**

#### Test Nginx Configuration
```bash
# Test Nginx configuration
sudo nginx -t

# If successful, reload Nginx
sudo systemctl reload nginx
```

#### Test SSL Certificate
```bash
# Test certificate
sudo certbot certificates

# Test SSL connection
openssl s_client -connect studio.example.com:443 -servername studio.example.com

# Check SSL rating
curl -I https://studio.example.com
```

## 🔧 Commercial Certificate Setup

### **Step 1: Generate CSR**

#### Generate Private Key and CSR
```bash
# Create directory for certificates
mkdir -p ~/ssl-certs
cd ~/ssl-certs

# Generate private key
openssl genrsa -out studio.key 2048

# Generate certificate signing request (CSR)
openssl req -new -key studio.key -out studio.csr
```

#### CSR Information
```
Country Name (2 letter code): US
State or Province Name: California
Locality Name: San Francisco
Organization Name: Your Company Inc
Organizational Unit: IT Department
Common Name: studio.example.com
Email Address: admin@example.com
```

### **Step 2: Submit CSR to CA**

#### Choose Certificate Provider
- **DigiCert** - Enterprise certificates
- **GlobalSign** - Business certificates
- **Comodo** - Affordable certificates
- **GoDaddy** - Popular provider

#### Submit CSR
1. **Copy CSR content**
   ```bash
   cat studio.csr
   ```

2. **Submit to CA website**
   - Paste CSR content
   - Choose certificate type
   - Complete domain validation
   - Complete organization validation (if required)

### **Step 3: Install Certificate**

#### Install Certificate Files
```bash
# Create certificate directory
sudo mkdir -p /etc/ssl/studio

# Copy certificate files
sudo cp studio.key /etc/ssl/studio/
sudo cp your_certificate.crt /etc/ssl/studio/
sudo cp intermediate.crt /etc/ssl/studio/

# Set proper permissions
sudo chmod 600 /etc/ssl/studio/studio.key
sudo chmod 644 /etc/ssl/studio/*.crt
```

#### Create Certificate Chain
```bash
# Create full chain file
cat your_certificate.crt intermediate.crt > /etc/ssl/studio/fullchain.pem
```

#### Update Nginx Configuration
```nginx
# Update SSL certificate paths
ssl_certificate /etc/ssl/studio/fullchain.pem;
ssl_certificate_key /etc/ssl/studio/studio.key;
```

## 🔧 Self-Signed Certificate (Development)

### **Generate Self-Signed Certificate**
```bash
# Create certificate directory
mkdir -p ~/ssl-dev
cd ~/ssl-dev

# Generate private key
openssl genrsa -out studio-dev.key 2048

# Generate self-signed certificate
openssl req -new -x509 -key studio-dev.key -out studio-dev.crt -days 365 \
  -subj "/C=US/ST=California/L=San Francisco/O=Dev/CN=localhost"
```

### **Configure for Development**
```nginx
# Development Nginx configuration
server {
    listen 443 ssl;
    server_name localhost;
    
    ssl_certificate /path/to/studio-dev.crt;
    ssl_certificate_key /path/to/studio-dev.key;
    
    # Development settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔄 Certificate Management

### **Automatic Renewal (Let's Encrypt)**

#### Setup Cron Job
```bash
# Edit crontab
sudo crontab -e

# Add renewal job (runs twice daily)
0 0,12 * * * /usr/bin/certbot renew --quiet --deploy-hook "systemctl reload nginx"
```

#### Test Renewal
```bash
# Test renewal process
sudo certbot renew --dry-run

# Check renewal status
sudo certbot certificates
```

#### Docker Renewal
```bash
# Create renewal script
cat > renew-cert.sh << 'EOF'
#!/bin/bash
docker run --rm \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -p 80:80 \
  certbot/certbot renew --quiet

# Reload Nginx
docker-compose exec nginx nginx -s reload
EOF

chmod +x renew-cert.sh

# Add to crontab
0 0,12 * * * /path/to/renew-cert.sh
```

### **Certificate Monitoring**

#### Monitor Certificate Expiry
```bash
#!/bin/bash
# check-cert-expiry.sh

DOMAIN="studio.example.com"
DAYS_WARNING=30

# Get certificate expiry date
EXPIRY_DATE=$(openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | \
  openssl x509 -noout -enddate | cut -d= -f2)

# Convert to timestamp
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))

# Check if certificate is expiring soon
if [ $DAYS_UNTIL_EXPIRY -le $DAYS_WARNING ]; then
  echo "WARNING: Certificate for $DOMAIN expires in $DAYS_UNTIL_EXPIRY days"
  # Send alert (email, Slack, etc.)
  # send_alert "Certificate expiring soon" "$DOMAIN expires in $DAYS_UNTIL_EXPIRY days"
else
  echo "Certificate for $DOMAIN is valid for $DAYS_UNTIL_EXPIRY more days"
fi
```

#### Certificate Health Check
```python
# cert_health_check.py
import ssl
import socket
import datetime
from urllib.parse import urlparse

def check_certificate_health(url):
    """Check SSL certificate health"""
    parsed = urlparse(url)
    hostname = parsed.hostname
    port = parsed.port or 443
    
    try:
        # Create SSL context
        context = ssl.create_default_context()
        
        # Connect to server
        with socket.create_connection((hostname, port)) as sock:
            with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                cert = ssock.getpeercert()
                
                # Check certificate validity
                expiry_date = datetime.datetime.strptime(cert['notAfter'], '%b %d %H:%M:%S %Y %Z')
                days_until_expiry = (expiry_date - datetime.datetime.now()).days
                
                # Check certificate chain
                issuer = cert['issuer']
                subject = cert['subject']
                
                return {
                    'valid': True,
                    'expiry_date': expiry_date.isoformat(),
                    'days_until_expiry': days_until_expiry,
                    'issuer': issuer,
                    'subject': subject,
                    'version': cert['version'],
                    'serial_number': cert['serialNumber']
                }
    
    except Exception as e:
        return {
            'valid': False,
            'error': str(e)
        }

# Usage
result = check_certificate_health('https://studio.example.com')
print(json.dumps(result, indent=2))
```

## 🔍 SSL/TLS Testing

### **SSL Configuration Test**

#### Test SSL Configuration
```bash
# Test SSL configuration
sudo nginx -t

# Test SSL connection
openssl s_client -connect studio.example.com:443 -servername studio.example.com

# Check certificate chain
openssl s_client -connect studio.example.com:443 -showcerts
```

#### Online SSL Testers
- **SSL Labs** - https://www.ssllabs.com/ssltest/
- **Qualys SSL Test** - Comprehensive SSL analysis
- **SSL Checker** - https://www.sslchecker.com/

### **Security Headers Test**

#### Test Security Headers
```bash
# Test security headers
curl -I https://studio.example.com

# Check specific headers
curl -I https://studio.example.com | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options)"
```

#### Security Headers Test Script
```python
# security_headers_test.py
import requests
import json

def test_security_headers(url):
    """Test security headers"""
    try:
        response = requests.head(url, allow_redirects=True)
        headers = response.headers
        
        # Required security headers
        required_headers = {
            'Strict-Transport-Security': 'HSTS header',
            'X-Frame-Options': 'Clickjacking protection',
            'X-Content-Type-Options': 'MIME type sniffing protection',
            'X-XSS-Protection': 'XSS protection',
            'Referrer-Policy': 'Referrer policy'
        }
        
        results = {
            'url': url,
            'status_code': response.status_code,
            'headers_found': {},
            'headers_missing': {},
            'recommendations': []
        }
        
        for header, description in required_headers.items():
            if header in headers:
                results['headers_found'][header] = {
                    'value': headers[header],
                    'description': description
                }
            else:
                results['headers_missing'][header] = description
                results['recommendations'].append(f"Add {header} header")
        
        # Check HSTS max-age
        if 'Strict-Transport-Security' in headers:
            hsts = headers['Strict-Transport-Security']
            if 'max-age=' in hsts:
                max_age = int(hsts.split('max-age=')[1].split(';')[0])
                if max_age < 31536000:  # Less than 1 year
                    results['recommendations'].append("Increase HSTS max-age to at least 1 year")
        
        return results
    
    except Exception as e:
        return {
            'url': url,
            'error': str(e)
        }

# Usage
result = test_security_headers('https://studio.example.com')
print(json.dumps(result, indent=2))
```

## 🚨 Troubleshooting

### **Common SSL Issues**

#### Certificate Not Trusted
```bash
# Check certificate chain
openssl s_client -connect studio.example.com:443 -showcerts

# Verify certificate
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /etc/letsencrypt/live/studio.example.com/fullchain.pem
```

#### Mixed Content Warning
```bash
# Check for mixed content
curl -I https://studio.example.com | grep -i "content-security-policy"

# Find HTTP resources
grep -r "http://" /var/www/studio/
```

#### Certificate Expired
```bash
# Check certificate expiry
openssl x509 -in /etc/letsencrypt/live/studio.example.com/cert.pem -noout -dates

# Renew certificate
sudo certbot renew
```

#### SSL Handshake Failed
```bash
# Check SSL protocols
openssl s_client -connect studio.example.com:443 -tls1_2

# Check cipher suites
openssl ciphers -v | grep ECDHE
```

### **Debug Commands**

#### Certificate Information
```bash
# Display certificate details
openssl x509 -in certificate.crt -text -noout

# Check certificate subject
openssl x509 -in certificate.crt -noout -subject

# Check certificate issuer
openssl x509 -in certificate.crt -noout -issuer
```

#### SSL Connection Test
```bash
# Test SSL connection with specific protocol
openssl s_client -connect studio.example.com:443 -tls1_2

# Test with specific cipher
openssl s_client -connect studio.example.com:443 -cipher ECDHE-RSA-AES256-GCM-SHA384

# Test certificate chain
openssl s_client -connect studio.example.com:443 -verify_return_error
```

## 📚 Best Practices

### **Security Best Practices**
- Use **strong cipher suites**
- Implement **HSTS** with long max-age
- Enable **OCSP stapling**
- Use **TLS 1.2+** only
- Regularly **update certificates**
- Monitor **certificate expiry**

### **Performance Optimization**
- Enable **HTTP/2**
- Use **session caching**
- Implement **certificate pinning** (mobile apps)
- Optimize **certificate chain**
- Use **CDN with SSL offloading**

### **Compliance Requirements**
- **PCI DSS** - Strong encryption required
- **HIPAA** - Data protection mandatory
- **GDPR** - Data transmission security
- **SOC 2** - Security controls validation

---

!!! tip "Certificate Management"
    Set up automated monitoring and renewal to prevent certificate expiration issues.

!!! warning "Security Headers"
    Always implement security headers with SSL/TLS to ensure comprehensive protection.

!!! note "Testing"
    Regularly test your SSL configuration using online tools to ensure optimal security and performance.
