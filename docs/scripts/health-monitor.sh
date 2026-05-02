# Monitoring and Maintenance Procedures
## Studio Platform Documentation

This document outlines the comprehensive monitoring and maintenance procedures for the Studio Platform documentation deployed at `doc.cybergaar.com`.

## 📊 Monitoring Overview

### Monitoring Objectives
- **Availability**: Ensure 99.9% uptime
- **Performance**: Maintain < 3 second page load times
- **Security**: Monitor for security threats and vulnerabilities
- **User Experience**: Track user engagement and satisfaction
- **System Health**: Monitor infrastructure and application health

### Monitoring Stack
- **Health Checks**: Custom health endpoints
- **Log Management**: Centralized logging with rotation
- **Metrics Collection**: Performance and usage metrics
- **Alerting**: Automated notifications for issues
- **Reporting**: Regular performance and usage reports

## 🔍 Health Monitoring

### Health Check Endpoints

#### Primary Health Check
```bash
# Basic health check
curl -f https://doc.cybergaar.com/health

# Expected response
HTTP/1.1 200 OK
Content-Type: text/plain
healthy
```

#### Detailed Health Check
```bash
# Detailed health check with metrics
curl -f https://doc.cybergaar.com/health/detailed

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-03-21T12:00:00Z",
  "version": "1.0.0",
  "uptime": "72h15m30s",
  "checks": {
    "database": "healthy",
    "search": "healthy",
    "ssl": "valid",
    "storage": "healthy"
  }
}
```

### Health Monitoring Script
<tool_call>write_to_file
<arg_key>CodeContent</arg_key>
<arg_value>#!/bin/bash

# Health Monitoring Script for Studio Documentation
# This script performs comprehensive health checks

set -e

# Configuration
HEALTH_URL="https://doc.cybergaar.com/health"
DETAILED_HEALTH_URL="https://doc.cybergaar.com/health/detailed"
LOG_FILE="/opt/studio-docs/logs/health-monitor.log"
ALERT_EMAIL="admin@cybergaar.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO: $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS: $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING: $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR: $1"
}

# Send alert
send_alert() {
    local message="$1"
    local severity="$2"
    
    # Log the alert
    log_message "ALERT [$severity]: $message"
    
    # Send email alert (configure mail command)
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "Studio Docs Alert [$severity]" "$ALERT_EMAIL"
    fi
    
    # Send Slack alert (if webhook configured)
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Check basic health
check_basic_health() {
    log_info "Checking basic health..."
    
    if curl -f -s "$HEALTH_URL" > /dev/null; then
        log_success "Basic health check passed"
        return 0
    else
        log_error "Basic health check failed"
        send_alert "Documentation health check failed - Service may be down" "CRITICAL"
        return 1
    fi
}

# Check detailed health
check_detailed_health() {
    log_info "Checking detailed health..."
    
    local response
    response=$(curl -s "$DETAILED_HEALTH_URL" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Parse JSON response (requires jq)
        if command -v jq &> /dev/null; then
            local status
            status=$(echo "$response" | jq -r '.status')
            
            if [ "$status" = "healthy" ]; then
                log_success "Detailed health check passed"
                
                # Check individual components
                local checks
                checks=$(echo "$response" | jq -r '.checks | to_entries[] | "\(.key): \(.value)"')
                log_info "Component status: $checks"
                
                return 0
            else
                log_error "Detailed health check failed - Status: $status"
                send_alert "Documentation component failure: $response" "WARNING"
                return 1
            fi
        else
            log_warning "jq not available, skipping detailed health parsing"
            return 0
        fi
    else
        log_error "Detailed health check failed - No response"
        return 1
    fi
}

# Check SSL certificate
check_ssl_certificate() {
    log_info "Checking SSL certificate..."
    
    local cert_info
    cert_info=$(openssl s_client -connect doc.cybergaar.com:443 -servername doc.cybergaar.com 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local expiry_date
        expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)
        
        # Convert to timestamp for comparison
        local expiry_timestamp
        expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
        local current_timestamp
        current_timestamp=$(date +%s)
        local days_until_expiry
        days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [ "$days_until_expiry" -lt 30 ]; then
            log_warning "SSL certificate expires in $days_until_expiry days"
            send_alert "SSL certificate expires in $days_until_expiry days" "WARNING"
        else
            log_success "SSL certificate is valid ($days_until_expiry days until expiry)"
        fi
        
        return 0
    else
        log_error "SSL certificate check failed"
        send_alert "SSL certificate validation failed" "CRITICAL"
        return 1
    fi
}

# Check performance
check_performance() {
    log_info "Checking performance..."
    
    local response_time
    response_time=$(curl -o /dev/null -s -w '%{time_total}' "$HEALTH_URL")
    
    # Convert to milliseconds
    local response_ms
    response_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "3000")
    
    if (( $(echo "$response_ms < 3000" | bc -l) )); then
        log_success "Performance check passed (${response_ms}ms)"
        return 0
    else
        log_warning "Performance degraded (${response_ms}ms response time)"
        send_alert "Documentation performance degraded: ${response_ms}ms response time" "WARNING"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."
    
    local usage
    usage=$(df /opt/studio-docs | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 80 ]; then
        log_success "Disk space check passed (${usage}% used)"
        return 0
    elif [ "$usage" -lt 90 ]; then
        log_warning "Disk space running low (${usage}% used)"
        send_alert "Documentation disk space running low: ${usage}% used" "WARNING"
        return 1
    else
        log_error "Disk space critical (${usage}% used)"
        send_alert "Documentation disk space critical: ${usage}% used" "CRITICAL"
        return 1
    fi
}

# Check Docker services
check_docker_services() {
    log_info "Checking Docker services..."
    
    cd /opt/studio-docs/docs
    
    local services
    services=$(docker-compose -f docker-compose.docs.yml ps --services)
    
    local failed_services=""
    for service in $services; do
        local status
        status=$(docker-compose -f docker-compose.docs.yml ps -q "$service" | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
        
        if [ "$status" = "healthy" ] || [ "$status" = "starting" ]; then
            log_success "Service $service is $status"
        else
            log_error "Service $service is $status"
            failed_services="$failed_services $service"
        fi
    done
    
    if [ -n "$failed_services" ]; then
        send_alert "Docker services failed:$failed_services" "CRITICAL"
        return 1
    else
        return 0
    fi
}

# Generate health report
generate_health_report() {
    log_info "Generating health report..."
    
    local report_file="/opt/studio-docs/logs/health-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
Studio Documentation Health Report
==================================
Generated: $(date)
Server: $(hostname)
Uptime: $(uptime -p 2>/dev/null || uptime)

Health Checks:
--------------
$(tail -n 50 "$LOG_FILE" | grep -E "(SUCCESS|ERROR|WARNING)")

System Information:
------------------
Memory Usage: $(free -h | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
Disk Usage: $(df -h /opt/studio-docs | awk 'NR==2{print $5}')
Load Average: $(uptime | awk -F'load average:' '{print $2}')

Docker Services:
----------------
$(cd /opt/studio-docs/docs && docker-compose -f docker-compose.docs.yml ps)

Recent Errors:
-------------
$(tail -n 100 "$LOG_FILE" | grep ERROR || echo "No recent errors")
EOF
    
    log_success "Health report generated: $report_file"
}

# Main monitoring function
run_health_checks() {
    log_info "Starting comprehensive health checks..."
    
    local failed_checks=0
    
    # Run all checks
    check_basic_health || ((failed_checks++))
    check_detailed_health || ((failed_checks++))
    check_ssl_certificate || ((failed_checks++))
    check_performance || ((failed_checks++))
    check_disk_space || ((failed_checks++))
    check_docker_services || ((failed_checks++))
    
    # Generate report
    generate_health_report
    
    if [ "$failed_checks" -eq 0 ]; then
        log_success "All health checks passed"
        return 0
    else
        log_error "$failed_checks health checks failed"
        return 1
    fi
}

# Command line interface
case "${1:-}" in
    "basic")
        check_basic_health
        ;;
    "detailed")
        check_detailed_health
        ;;
    "ssl")
        check_ssl_certificate
        ;;
    "performance")
        check_performance
        ;;
    "disk")
        check_disk_space
        ;;
    "docker")
        check_docker_services
        ;;
    "report")
        generate_health_report
        ;;
    "help"|"-h"|"--help")
        echo "Health Monitoring Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  basic      - Check basic health"
        echo "  detailed   - Check detailed health"
        echo "  ssl        - Check SSL certificate"
        echo "  performance- Check performance"
        echo "  disk       - Check disk space"
        echo "  docker     - Check Docker services"
        echo "  report     - Generate health report"
        echo "  help       - Show this help message"
        echo ""
        echo "Default: Run all health checks"
        ;;
    "")
        run_health_checks
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac
