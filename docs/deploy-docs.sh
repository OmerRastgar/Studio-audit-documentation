#!/bin/bash

# Studio Documentation Deployment Script
# This script deploys MkDocs documentation to doc.cybergaar.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCS_DIR="./docs"
DOMAIN="doc.cybergaar.com"
DOCKER_COMPOSE_FILE="docker-compose.docs.yml"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    
    # Check if docs directory exists
    if [ ! -d "$DOCS_DIR" ]; then
        log_error "Documentation directory '$DOCS_DIR' not found."
        exit 1
    fi
    
    # Check if mkdocs.yml exists
    if [ ! -f "$DOCS_DIR/mkdocs.yml" ]; then
        log_error "mkdocs.yml not found in '$DOCS_DIR'."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build documentation
build_docs() {
    log_info "Building documentation..."
    
    cd "$DOCS_DIR"
    
    # Install dependencies
    log_info "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Build documentation
    log_info "Building MkDocs site..."
    mkdocs build --clean
    
    cd ..
    
    log_success "Documentation built successfully"
}

# Deploy services
deploy_services() {
    log_info "Deploying documentation services..."
    
    # Stop existing services if running
    log_info "Stopping existing services..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down 2>/dev/null || true
    
    # Start services
    log_info "Starting documentation services..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d --build
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 10
    
    # Check service health
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "healthy"; then
        log_success "Services are healthy"
    else
        log_warning "Services may not be fully healthy yet. Check with: docker-compose -f $DOCKER_COMPOSE_FILE ps"
    fi
}

# Setup SSL certificates
setup_ssl() {
    log_info "Setting up SSL certificates..."
    
    SSL_DIR="$DOCS_DIR/ssl"
    
    # Create SSL directory if it doesn't exist
    mkdir -p "$SSL_DIR"
    
    # Generate self-signed certificate if it doesn't exist
    if [ ! -f "$SSL_DIR/cert.pem" ]; then
        log_info "Generating self-signed SSL certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/key.pem" \
            -out "$SSL_DIR/cert.pem" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
        
        log_success "SSL certificate generated"
    else
        log_info "SSL certificate already exists"
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if documentation is accessible
    if curl -f -s "http://localhost:8000" > /dev/null; then
        log_success "Documentation is accessible at http://localhost:8000"
    else
        log_error "Documentation is not accessible at http://localhost:8000"
        return 1
    fi
    
    # Check health endpoint
    if curl -f -s "http://localhost:8000/health" > /dev/null; then
        log_success "Health check passed"
    else
        log_warning "Health check failed, but documentation may still be accessible"
    fi
}

# Show deployment info
show_deployment_info() {
    log_info "Deployment Information:"
    echo ""
    echo "📚 Documentation URLs:"
    echo "   Local:    http://localhost:8000"
    echo "   Domain:   https://$DOMAIN (once DNS is configured)"
    echo ""
    echo "🔧 Management Commands:"
    echo "   View logs:     docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
    echo "   Stop services: docker-compose -f $DOCKER_COMPOSE_FILE down"
    echo "   Restart:       docker-compose -f $DOCKER_COMPOSE_FILE restart"
    echo ""
    echo "📁 Important Files:"
    echo "   Config:        $DOCS_DIR/mkdocs.yml"
    echo "   Content:       $DOCS_DIR/docs/"
    echo "   SSL Certs:     $DOCS_DIR/ssl/"
    echo ""
    echo "🌐 Next Steps:"
    echo "   1. Configure DNS to point $DOMAIN to your server"
    echo "   2. Set up production SSL certificates (Let's Encrypt recommended)"
    echo "   3. Configure firewall to allow ports 80 and 443"
    echo ""
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    # Add any cleanup tasks here
}

# Main execution
main() {
    log_info "Starting Studio Documentation Deployment..."
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Execute deployment steps
    check_prerequisites
    setup_ssl
    build_docs
    deploy_services
    verify_deployment
    show_deployment_info
    
    log_success "Deployment completed successfully! 🎉"
}

# Handle command line arguments
case "${1:-}" in
    "build")
        build_docs
        ;;
    "deploy")
        deploy_services
        ;;
    "ssl")
        setup_ssl
        ;;
    "verify")
        verify_deployment
        ;;
    "logs")
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f
        ;;
    "stop")
        docker-compose -f "$DOCKER_COMPOSE_FILE" down
        log_info "Documentation services stopped"
        ;;
    "restart")
        docker-compose -f "$DOCKER_COMPOSE_FILE" restart
        log_info "Documentation services restarted"
        ;;
    "help"|"-h"|"--help")
        echo "Studio Documentation Deployment Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  build    - Build documentation only"
        echo "  deploy   - Deploy services only"
        echo "  ssl      - Setup SSL certificates only"
        echo "  verify   - Verify deployment only"
        echo "  logs     - Show service logs"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  help     - Show this help message"
        echo ""
        echo "Default: Full deployment (build + deploy + verify)"
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac
