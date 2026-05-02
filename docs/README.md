# Studio Platform Documentation

This repository contains the complete MkDocs documentation for the Studio Platform, designed to be deployed at `doc.cybergaar.com`.

## 🚀 Quick Start

### **Development Setup**

```bash
# Clone this repository
git clone https://github.com/OmerRastgar/studio-docs.git
cd studio-docs

# Start documentation server
docker-compose -f docker-compose.docs.yml up -d

# Access documentation
open http://localhost:8000
```

### **Production Deployment**

```bash
# Generate SSL certificates (first time only)
docker-compose -f docker-compose.docs.yml --profile setup up cert-generator

# Deploy with Nginx reverse proxy
docker-compose -f docker-compose.docs.yml --profile production up -d

# Access documentation
open https://doc.cybergaar.com
```

## 📁 Repository Structure

```
studio-docs/
├── docker-compose.docs.yml    # Docker configuration
├── Dockerfile                  # Container definition
├── mkdocs.yml                  # MkDocs configuration
├── requirements.txt            # Python dependencies
├── nginx.conf                  # Nginx configuration (production)
├── deploy-docs.sh             # Deployment script
├── ssl/                       # SSL certificates (generated)
├── docs/                      # Documentation content
│   ├── index.md              # Homepage
│   ├── overview.md           # Platform overview
│   ├── features.md           # Feature documentation
│   ├── quick-start.md        # Quick start guide
│   ├── installation/         # Installation guides
│   ├── user-guide/          # User documentation
│   ├── admin-guide/         # Admin documentation
│   ├── developer-guide/     # Developer documentation
│   ├── architecture/        # Technical architecture
│   ├── integrations/        # Integration guides
│   ├── troubleshooting/     # Troubleshooting guides
│   └── assets/              # Images and static files
└── IMPLEMENTATION_PLAN.md   # Detailed implementation plan
```

## 🐳 Docker Deployment

This documentation is designed to be **completely standalone** and can be deployed on any server with Docker.

### **Prerequisites**
- Docker Engine 20.10+
- Docker Compose 2.0+
- Ports 80 and 443 available (production)
- Domain configured to point to server (production)

### **Development Environment**

```bash
# Start development server
docker-compose -f docker-compose.docs.yml up -d

# View logs
docker-compose -f docker-compose.docs.yml logs -f

# Stop services
docker-compose -f docker-compose.docs.yml down
```

### **Production Environment**

```bash
# 1. Generate SSL certificates
docker-compose -f docker-compose.docs.yml --profile setup up cert-generator

# 2. Deploy with Nginx
docker-compose -f docker-compose.docs.yml --profile production up -d

# 3. Verify deployment
curl -f https://doc.cybergaar.com/health
```

## 🔧 Configuration

### **Environment Variables**

The documentation container supports these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PYTHONUNBUFFERED` | `1` | Python output buffering |
| `MKDOCS_CONFIG` | `mkdocs.yml` | MkDocs configuration file |
| `DOCKER_ENV` | `true` | Enable Docker-specific features |

### **Custom Domain**

To deploy to a custom domain:

1. **Update Nginx Configuration**
   ```bash
   # Edit nginx.conf
   server_name your-domain.com;
   ```

2. **Generate SSL Certificates**
   ```bash
   # Update domain in cert-generator
   -subj '/CN=your-domain.com'
   ```

3. **Deploy**
   ```bash
   docker-compose -f docker-compose.docs.yml --profile production up -d
   ```

## 📝 Content Management

### **Adding New Documentation**

1. **Create Markdown Files**
   ```bash
   # Add new page
   echo "# New Page" > docs/new-page.md
   ```

2. **Update Navigation**
   ```yaml
   # Edit mkdocs.yml
   nav:
     - New Page: new-page.md
   ```

3. **Rebuild Documentation**
   ```bash
   docker-compose -f docker-compose.docs.yml restart docs
   ```

### **Updating Content**

```bash
# Edit documentation files
vim docs/your-page.md

# Restart to apply changes
docker-compose -f docker-compose.docs.yml restart docs
```

### **Live Development**

For development with live reload:

```bash
# Mount local directory for live editing
docker-compose -f docker-compose.docs.yml up -d docs

# Changes to files will auto-reload
```

## 🔒 Security

### **SSL/TLS Configuration**

- **Development**: Self-signed certificates (auto-generated)
- **Production**: Use Let's Encrypt or custom certificates

### **Security Headers**

The Nginx configuration includes:
- HTTPS enforcement
- Security headers (X-Frame-Options, CSP, etc.)
- Rate limiting
- SSL hardening

### **Access Control**

Consider implementing:
- IP whitelisting
- Basic authentication
- VPN access
- Cloudflare protection

## 📊 Monitoring

### **Health Checks**

```bash
# Documentation health
curl http://localhost:8000/

# Nginx health (production)
curl http://localhost/health
```

### **Logs**

```bash
# View all logs
docker-compose -f docker-compose.docs.yml logs -f

# View specific service logs
docker-compose -f docker-compose.docs.yml logs -f docs
docker-compose -f docker-compose.docs.yml logs -f docs-nginx
```

### **Performance Monitoring**

Monitor:
- Response times
- Memory usage
- Disk space
- Network traffic

## 🚀 Deployment Scripts

### **Automated Deployment**

Use the included deployment script:

```bash
# Make executable
chmod +x deploy-docs.sh

# Run deployment
./deploy-docs.sh

# Available commands
./deploy-docs.sh build    # Build documentation only
./deploy-docs.sh deploy   # Deploy services only
./deploy-docs.sh ssl      # Setup SSL certificates
./deploy-docs.sh verify   # Verify deployment
./deploy-docs.sh logs     # Show logs
./deploy-docs.sh stop     # Stop services
```

### **CI/CD Integration**

Example GitHub Actions workflow:

```yaml
name: Deploy Documentation
on:
  push:
    branches: [main]
    paths: ['docs/**']
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to server
        run: |
          ssh user@server 'cd /path/to/docs && ./deploy-docs.sh'
```

## 🌐 Domain Setup

### **DNS Configuration**

For `doc.cybergaar.com`:

```
Type: A Record
Name: doc
Value: YOUR_SERVER_IP
TTL: 300
```

### **SSL Certificate Options**

1. **Let's Encrypt (Recommended)**
   ```bash
   certbot certonly --standalone -d doc.cybergaar.com
   ```

2. **Cloudflare SSL**
   - Enable Cloudflare proxy
   - Use Full SSL mode

3. **Custom Certificate**
   - Upload your own certificates
   - Update nginx.conf paths

## 🔧 Troubleshooting

### **Common Issues**

| Issue | Solution |
|-------|----------|
| **Port 80/443 in use** | Stop other services or change ports |
| **SSL certificate errors** | Regenerate certificates or check paths |
| **Documentation not loading** | Check logs and restart services |
| **Permission errors** | Fix file permissions and ownership |

### **Debug Commands**

```bash
# Check container status
docker-compose -f docker-compose.docs.yml ps

# Check container logs
docker-compose -f docker-compose.docs.yml logs docs

# Enter container for debugging
docker-compose -f docker-compose.docs.yml exec docs bash

# Check network connectivity
docker network ls
docker network inspect studio_docs_network
```

## 📚 Documentation Resources

- **[MkDocs Documentation](https://www.mkdocs.org/)**
- **[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)**
- **[Docker Documentation](https://docs.docker.com/)**
- **[Nginx Documentation](https://nginx.org/en/docs/)**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📞 Support

For documentation issues:
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Browse this repository for guides
- **Community**: Join our discussions

---

!!! tip "Quick Reminder"
    This documentation is completely standalone and can be deployed on any server with Docker, independent of the main Studio Platform.

!!! note "Production Deployment"
    For production use, ensure proper SSL certificates, firewall configuration, and monitoring are in place.
