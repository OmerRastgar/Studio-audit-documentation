#!/bin/bash

# SSL Certificate Management Script for Studio Documentation
# Supports both development (self-signed) and production (Let's Encrypt) certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="doc.cybergaar.com"
SSL_DIR="./ssl"
CERTBOT_DIR="/var/www/certbot"
EMAIL="admin@cybergaar.com"  # Change this to your actual email

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create SSL directory
create_ssl_dir() {
    log_info "Creating SSL directory..."
    mkdir -p "$SSL_DIR"
    mkdir -p "$CERTBOT_DIR"
}

# Generate self-signed certificate (development)
generate_self_signed() {
    log_info "Generating self-signed SSL certificate for development..."
    
    if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
        log_warning "SSL certificates already exist. Skipping generation."
        return 0
    fi
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/key.pem" \
        -out "$SSL_DIR/cert.pem" \
        -subj "/C=US/ST=State/L=City/O=Cybergaar/OU=Studio/CN=$DOMAIN"
    
    # Generate DH parameters for better security
    openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
    
    log_success "Self-signed SSL certificate generated"
    log_warning "This certificate is for development only. Browsers will show security warnings."
}

# Setup Let's Encrypt certificate (production)
setup_lets_encrypt() {
    log_info "Setting up Let's Encrypt certificate for production..."
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        log_info "Installing certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Obtain certificate
    log_info "Obtaining SSL certificate from Let's Encrypt..."
    certbot certonly --standalone \
        --domain "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        --force-renewal
    
    # Copy certificates to SSL directory
    cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem "$SSL_DIR/cert.pem"
    cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem "$SSL_DIR/key.pem"
    
    # Generate DH parameters
    openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
    
    log_success "Let's Encrypt certificate obtained and installed"
}

# Setup auto-renewal
setup_auto_renewal() {
    log_info "Setting up automatic certificate renewal..."
    
    # Create renewal script
    cat > /usr/local/bin/renew-ssl.sh << 'EOF'
#!/bin/bash

# SSL Certificate Renewal Script
DOMAIN="doc.cybergaar.com"
SSL_DIR="/path/to/your/docs/ssl"  # Update this path

# Renew certificate
certbot renew --quiet

# Copy renewed certificates
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem "$SSL_DIR/cert.pem"
    cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem "$SSL_DIR/key.pem"
    
    # Restart nginx
    docker-compose -f /path/to/your/docs/docker-compose.docs.yml restart docs-nginx
    
    echo "SSL certificate renewed and services restarted"
fi
EOF
    
    chmod +x /usr/local/bin/renew-ssl.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/renew-ssl.sh >> /var/log/ssl-renewal.log 2>&1") | crontab -
    
    log_success "Auto-renewal setup completed"
}

# Verify certificates
verify_certificates() {
    log_info "Verifying SSL certificates..."
    
    if [ ! -f "$SSL_DIR/cert.pem" ] || [ ! -f "$SSL_DIR/key.pem" ]; then
        log_error "SSL certificates not found"
        return 1
    fi
    
    # Check certificate validity
    if openssl x509 -in "$SSL_DIR/cert.pem" -noout -checkend 86400; then
        log_success "SSL certificate is valid"
    else
        log_warning "SSL certificate expires within 24 hours or is invalid"
        return 1
    fi
    
    # Show certificate details
    log_info "Certificate details:"
    openssl x509 -in "$SSL_DIR/cert.pem" -noout -dates -subject
}

# Show certificate status
show_status() {
    log_info "SSL Certificate Status:"
    echo ""
    
    if [ -f "$SSL_DIR/cert.pem" ]; then
        echo "✅ Certificate file exists"
        echo "📅 Valid from: $(openssl x509 -in "$SSL_DIR/cert.pem" -noout -startdate | cut -d= -f2)"
        echo "📅 Valid until: $(openssl x509 -in "$SSL_DIR/cert.pem" -noout -enddate | cut -d= -f2)"
        echo "🔐 Issuer: $(openssl x509 -in "$SSL_DIR/cert.pem" -noout -issuer | cut -d= -f6-)"
    else
        echo "❌ No certificate found"
    fi
    
    echo ""
    echo "📁 SSL Directory: $SSL_DIR"
    echo "🌐 Domain: $DOMAIN"
}

# Cleanup certificates
cleanup() {
    log_info "Cleaning up SSL certificates..."
    rm -f "$SSL_DIR"/*.pem
    log_success "SSL certificates cleaned up"
}

# Main execution
main() {
    case "${1:-}" in
        "dev"|"development")
            create_ssl_dir
            generate_self_signed
            verify_certificates
            ;;
        "prod"|"production")
            create_ssl_dir
            setup_lets_encrypt
            setup_auto_renewal
            verify_certificates
            ;;
        "renew")
            setup_lets_encrypt
            verify_certificates
            ;;
        "verify")
            verify_certificates
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "SSL Certificate Management Script"
            echo ""
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  dev, development  - Generate self-signed certificate (development)"
            echo "  prod, production - Setup Let's Encrypt certificate (production)"
            echo "  renew            - Renew Let's Encrypt certificate"
            echo "  verify           - Verify certificate validity"
            echo "  status           - Show certificate status"
            echo "  cleanup          - Remove all certificates"
            echo "  help             - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 dev           # Setup for development"
            echo "  $0 prod          # Setup for production"
            echo "  $0 status        # Check certificate status"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
