# Deployment Architecture

This document covers the comprehensive deployment architecture of the Studio Platform, including infrastructure design, deployment strategies, and operational considerations.

## 🏗️ Architecture Overview

### **High-Level Architecture**
```mermaid
graph TB
    subgraph "External Layer"
        A[Users] --> B[Load Balancer]
        B --> C[CDN]
    end
    
    subgraph "Application Layer"
        C --> D[Web Servers]
        D --> E[Application Servers]
        E --> F[API Gateway]
    end
    
    subgraph "Service Layer"
        F --> G[Core Services]
        G --> H[Background Workers]
        G --> I[Cache Layer]
    end
    
    subgraph "Data Layer"
        G --> J[Primary Database]
        G --> K[Replica Database]
        G --> L[Object Storage]
        G --> M[Search Engine]
    end
    
    subgraph "Monitoring Layer"
        N[Monitoring Stack]
        O[Logging Stack]
        P[Alerting System]
    end
    
    D --> N
    E --> O
    G --> P
```

### **Component Breakdown**

#### **Infrastructure Components**
- **Load Balancer** - Traffic distribution and SSL termination
- **Web Servers** - Static content serving and reverse proxy
- **Application Servers** - Core application logic
- **API Gateway** - API management and routing
- **Background Workers** - Asynchronous task processing
- **Cache Layer** - Performance optimization
- **Database** - Primary and replica databases
- **Object Storage** - File and media storage
- **Search Engine** - Full-text search capabilities

#### **Supporting Services**
- **Monitoring** - System and application monitoring
- **Logging** - Centralized log management
- **Alerting** - Automated alerting and notification
- **Security** - Firewall, WAF, and security scanning
- **Backup** - Automated backup and recovery

## 🌐 Network Architecture

### **Network Segmentation**
```mermaid
graph LR
    subgraph "DMZ"
        A[Load Balancer]
        B[Web Servers]
        C[WAF]
    end
    
    subgraph "Application Tier"
        D[Application Servers]
        E[API Gateway]
        F[Cache Layer]
    end
    
    subgraph "Data Tier"
        G[Database Servers]
        H[Object Storage]
        I[Search Engine]
    end
    
    subgraph "Management"
        J[Monitoring]
        K[Logging]
        L[Backup]
    end
    
    A --> D
    D --> G
    J --> D
    K --> D
    L --> G
```

### **Security Zones**

#### **DMZ (Demilitarized Zone)**
- **Load Balancer** - Public-facing traffic management
- **Web Servers** - Static content and reverse proxy
- **Web Application Firewall (WAF)** - Application layer security
- **CDN Edge Points** - Content caching and DDoS protection

#### **Application Zone**
- **Application Servers** - Core business logic
- **API Gateway** - API management and security
- **Cache Layer** - Redis/Memcached clusters
- **Background Workers** - Celery/RQ workers

#### **Data Zone**
- **Primary Database** - PostgreSQL master
- **Replica Database** - PostgreSQL replicas
- **Object Storage** - S3-compatible storage
- **Search Engine** - Elasticsearch cluster

#### **Management Zone**
- **Monitoring Stack** - Prometheus, Grafana
- **Logging Stack** - ELK (Elasticsearch, Logstash, Kibana)
- **Backup Systems** - Automated backup solutions
- **Security Tools** - Vulnerability scanning, intrusion detection

## 🚀 Deployment Strategies

### **Blue-Green Deployment**
```mermaid
graph TB
    subgraph "Production"
        A[Load Balancer]
        B[Blue Environment]
        C[Green Environment]
    end
    
    subgraph "New Version"
        D[Deploy to Green]
        E[Health Checks]
        F[Switch Traffic]
        G[Retire Blue]
    end
    
    A --> B
    A --> C
    
    D --> E
    E --> F
    F --> G
```

#### **Blue-Green Process**
1. **Deploy** new version to inactive environment (Green)
2. **Test** deployment with health checks
3. **Switch** traffic from Blue to Green
4. **Monitor** for issues
5. **Rollback** to Blue if issues detected
6. **Retire** Blue environment

#### **Configuration**
```yaml
# docker-compose.blue-green.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - blue-app
      - green-app
    networks:
      - frontend
  
  blue-app:
    image: studio-platform:${BLUE_VERSION}
    environment:
      - ENV=production
      - COLOR=blue
    networks:
      - frontend
      - backend
    deploy:
      replicas: 3
  
  green-app:
    image: studio-platform:${GREEN_VERSION}
    environment:
      - ENV=production
      - COLOR=green
    networks:
      - frontend
      - backend
    deploy:
      replicas: 0  # Initially inactive

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### **Canary Deployment**
```mermaid
graph TB
    subgraph "Traffic Distribution"
        A[100% Traffic]
        B[90% Stable]
        C[10% Canary]
    end
    
    subgraph "Environments"
        D[Stable Version]
        E[Canary Version]
    end
    
    A --> B
    A --> C
    B --> D
    C --> E
```

#### **Canary Process**
1. **Deploy** new version to canary environment
2. **Route** small percentage of traffic (5-10%)
3. **Monitor** key metrics and error rates
4. **Gradually increase** traffic if healthy
5. **Rollback** if issues detected
6. **Complete** migration when 100% traffic routed

#### **Implementation**
```python
# canary_deployment.py
import time
import requests
from kubernetes import client, config

class CanaryDeployment:
    def __init__(self, app_name, new_image, canary_percentage=10):
        self.app_name = app_name
        self.new_image = new_image
        self.canary_percentage = canary_percentage
        self.k8s_client = config.load_kube_config()
        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
    
    def deploy_canary(self):
        """Deploy canary version"""
        # Create canary deployment
        canary_deployment = self.create_deployment_spec(
            name=f"{self.app_name}-canary",
            image=self.new_image,
            replicas=1
        )
        
        self.apps_v1.create_namespaced_deployment(
            namespace="default",
            body=canary_deployment
        )
        
        # Update service to route traffic
        self.update_service_routing()
    
    def update_service_routing(self):
        """Update service to route traffic to canary"""
        service = self.v1.read_namespaced_service(
            name=self.app_name,
            namespace="default"
        )
        
        # Update service selector to include canary
        service.spec.selector['version'] = 'canary'
        
        self.v1.patch_namespaced_service(
            name=self.app_name,
            namespace="default",
            body=service
        )
    
    def monitor_canary(self):
        """Monitor canary deployment health"""
        while True:
            health_status = self.check_health()
            
            if health_status['healthy']:
                if self.canary_percentage < 100:
                    self.increase_canary_traffic()
                else:
                    self.promote_canary()
                    break
            else:
                self.rollback_canary()
                break
            
            time.sleep(60)  # Check every minute
    
    def check_health(self):
        """Check canary deployment health"""
        try:
            response = requests.get(
                f"http://{self.app_name}-canary/health",
                timeout=5
            )
            
            return {
                'healthy': response.status_code == 200,
                'response_time': response.elapsed.total_seconds(),
                'error_rate': self.calculate_error_rate()
            }
        except Exception as e:
            return {
                'healthy': False,
                'error': str(e)
            }
```

### **Rolling Deployment**
```mermaid
graph TB
    subgraph "Rolling Update"
        A[Old Pods]
        B[New Pods]
        C[Load Balancer]
    end
    
    A --> C
    B --> C
    
    subgraph "Update Process"
        D[Scale Down Old]
        E[Scale Up New]
        F[Health Check]
        G[Continue]
    end
    
    D --> E
    E --> F
    F --> G
    G --> D
```

#### **Rolling Update Configuration**
```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: studio-platform
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: studio-platform
  template:
    metadata:
      labels:
        app: studio-platform
        version: v1
    spec:
      containers:
      - name: app
        image: studio-platform:latest
        ports:
        - containerPort: 8000
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
```

## 🐳 Container Orchestration

### **Docker Compose Deployment**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/ssl
      - static_files:/var/www/studio/static
      - media_files:/var/www/studio/media
    depends_on:
      - web
    networks:
      - frontend
    restart: unless-stopped
  
  web:
    build:
      context: .
      dockerfile: Dockerfile.prod
    environment:
      - DJANGO_SETTINGS_MODULE=studio.settings.production
      - DATABASE_URL=postgresql://studio:${DB_PASSWORD}@db:5432/studio_db
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY=${SECRET_KEY}
    volumes:
      - static_files:/app/static
      - media_files:/app/media
    depends_on:
      - db
      - redis
    networks:
      - frontend
      - backend
    restart: unless-stopped
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
  
  worker:
    build:
      context: .
      dockerfile: Dockerfile.prod
    command: celery -A studio worker -l info
    environment:
      - DJANGO_SETTINGS_MODULE=studio.settings.production
      - DATABASE_URL=postgresql://studio:${DB_PASSWORD}@db:5432/studio_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - backend
    restart: unless-stopped
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
  
  scheduler:
    build:
      context: .
      dockerfile: Dockerfile.prod
    command: celery -A studio beat -l info
    environment:
      - DJANGO_SETTINGS_MODULE=studio.settings.production
      - DATABASE_URL=postgresql://studio:${DB_PASSWORD}@db:5432/studio_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    networks:
      - backend
    restart: unless-stopped
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=studio_db
      - POSTGRES_USER=studio
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
  
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
  
  elasticsearch:
    image: elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
      - xpack.security.enabled=false
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G

volumes:
  postgres_data:
  redis_data:
  elasticsearch_data:
  static_files:
  media_files:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

### **Kubernetes Deployment**
```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: studio-platform

---
# kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: studio-config
  namespace: studio-platform
data:
  DJANGO_SETTINGS_MODULE: "studio.settings.production"
  REDIS_URL: "redis://redis-service:6379/0"
  ELASTICSEARCH_URL: "http://elasticsearch-service:9200"

---
# kubernetes/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: studio-secrets
  namespace: studio-platform
type: Opaque
data:
  SECRET_KEY: <base64-encoded-secret>
  DB_PASSWORD: <base64-encoded-db-password>

---
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: studio-web
  namespace: studio-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: studio-web
  template:
    metadata:
      labels:
        app: studio-web
    spec:
      containers:
      - name: web
        image: studio-platform:latest
        ports:
        - containerPort: 8000
        envFrom:
        - configMapRef:
            name: studio-config
        - secretRef:
            name: studio-secrets
        env:
        - name: DATABASE_URL
          value: "postgresql://studio:$(DB_PASSWORD)@postgres-service:5432/studio_db"
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"

---
# kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: studio-web-service
  namespace: studio-platform
spec:
  selector:
    app: studio-web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: ClusterIP

---
# kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: studio-ingress
  namespace: studio-platform
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - studio.example.com
    secretName: studio-tls
  rules:
  - host: studio.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: studio-web-service
            port:
              number: 80
```

## 📊 Monitoring and Observability

### **Monitoring Stack**
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - monitoring
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    networks:
      - monitoring
  
  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring
  
  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

networks:
  monitoring:
    driver: bridge
```

### **Logging Stack**
```yaml
# docker-compose.logging.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - logging
  
  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logs:/var/log/studio
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch
    networks:
      - logging
  
  kibana:
    image: docker.elastic.co/kibana/kibana:8.8.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - logging
  
  filebeat:
    image: docker.elastic.co/beats/filebeat:8.8.0
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - ./logs:/var/log/studio
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - logstash
    networks:
      - logging

volumes:
  elasticsearch_data:

networks:
  logging:
    driver: bridge
```

## 🔒 Security Architecture

### **Security Layers**
```mermaid
graph TB
    subgraph "Network Security"
        A[Firewall]
        B[WAF]
        C[DDoS Protection]
    end
    
    subgraph "Application Security"
        D[Authentication]
        E[Authorization]
        F[Input Validation]
    end
    
    subgraph "Data Security"
        G[Encryption at Rest]
        H[Encryption in Transit]
        I[Access Control]
    end
    
    subgraph "Infrastructure Security"
        J[Container Security]
        K[Secret Management]
        L[Vulnerability Scanning]
    end
    
    A --> D
    D --> G
    G --> J
```

### **Security Configuration**

#### **Network Security**
```yaml
# docker-compose.security.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/security-nginx.conf:/etc/nginx/nginx.conf
      - ./modsecurity:/etc/nginx/modsecurity
    networks:
      - frontend
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
  
  web:
    build:
      context: .
      dockerfile: Dockerfile.prod
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/log
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=studio_db
      - POSTGRES_USER=studio
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

#### **Application Security**
```python
# security_middleware.py
from django.http import HttpResponse
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class SecurityHeadersMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        response = self.get_response(request)
        
        # Add security headers
        response['X-Frame-Options'] = 'DENY'
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
        
        # CSP header
        response['Content-Security-Policy'] = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self'; "
            "connect-src 'self'; "
            "frame-ancestors 'none';"
        )
        
        return response

class RateLimitMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        client_ip = self.get_client_ip(request)
        
        # Check rate limit
        if self.is_rate_limited(client_ip):
            logger.warning(f"Rate limit exceeded for IP: {client_ip}")
            return HttpResponse("Rate limit exceeded", status=429)
        
        return self.get_response(request)
    
    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0]
        return request.META.get('REMOTE_ADDR')
    
    def is_rate_limited(self, ip):
        # Implement rate limiting logic
        # This is a simplified example
        from django.core.cache import cache
        cache_key = f"rate_limit_{ip}"
        requests = cache.get(cache_key, 0)
        
        if requests > 100:  # 100 requests per minute
            return True
        
        cache.set(cache_key, requests + 1, 60)
        return False
```

## 🔄 CI/CD Pipeline

### **Deployment Pipeline**
```yaml
# .github/workflows/deploy.yml
name: Deploy Studio Platform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: studio-platform

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: |
        pytest --cov=studio --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to production
      run: |
        echo "Deploying to production..."
        # Add deployment commands here
        # kubectl apply -f kubernetes/
        # docker-compose -f docker-compose.prod.yml up -d
```

## 📈 Performance Optimization

### **Scaling Strategies**

#### **Horizontal Scaling**
```yaml
# docker-compose.scale.yml
version: '3.8'

services:
  web:
    build: .
    environment:
      - DJANGO_SETTINGS_MODULE=studio.settings.production
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/scale-nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - web
```

#### **Vertical Scaling**
```python
# autoscaler.py
import psutil
import docker
import time

class AutoScaler:
    def __init__(self):
        self.client = docker.from_env()
        self.cpu_threshold = 80
        self.memory_threshold = 80
        self.check_interval = 60
    
    def monitor_resources(self):
        """Monitor system resources and scale if needed"""
        while True:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory_percent = psutil.virtual_memory().percent
            
            print(f"CPU: {cpu_percent}%, Memory: {memory_percent}%")
            
            if cpu_percent > self.cpu_threshold or memory_percent > self.memory_threshold:
                self.scale_up()
            
            time.sleep(self.check_interval)
    
    def scale_up(self):
        """Scale up application services"""
        try:
            # Get current number of web containers
            containers = self.client.containers.list(
                filters={'label': 'com.docker.compose.service=web'}
            )
            current_replicas = len(containers)
            
            if current_replicas < 10:  # Maximum 10 replicas
                print(f"Scaling up from {current_replicas} to {current_replicas + 1}")
                
                # Scale up using docker-compose
                import subprocess
                subprocess.run([
                    'docker-compose', 'up', '-d', '--scale', f'web={current_replicas + 1}'
                ])
        
        except Exception as e:
            print(f"Error scaling up: {e}")
    
    def scale_down(self):
        """Scale down application services"""
        try:
            containers = self.client.containers.list(
                filters={'label': 'com.docker.compose.service=web'}
            )
            current_replicas = len(containers)
            
            if current_replicas > 2:  # Minimum 2 replicas
                print(f"Scaling down from {current_replicas} to {current_replicas - 1}")
                
                import subprocess
                subprocess.run([
                    'docker-compose', 'up', '-d', '--scale', f'web={current_replicas - 1}'
                ])
        
        except Exception as e:
            print(f"Error scaling down: {e}")

# Usage
if __name__ == "__main__":
    scaler = AutoScaler()
    scaler.monitor_resources()
```

## 🔧 Infrastructure as Code

### **Terraform Configuration**
```hcl
# terraform/main.tf
provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "studio_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "studio-vpc"
    Environment = var.environment
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.studio_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "studio-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.studio_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "studio-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "studio_cluster" {
  name = "studio-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "studio-cluster"
    Environment = var.environment
  }
}

# Load Balancer
resource "aws_lb" "studio_alb" {
  name               = "studio-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Name = "studio-alb"
    Environment = var.environment
  }
}

# RDS Database
resource "aws_db_instance" "studio_db" {
  identifier     = "studio-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_encrypted     = true
  storage_type          = "gp2"
  
  db_name  = "studio_db"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.studio_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "studio-db-final-snapshot"
  
  tags = {
    Name = "studio-db"
    Environment = var.environment
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "studio_redis_subnet" {
  name       = "studio-redis-subnet"
  subnet_ids = aws_subnet.private_subnet[*].id
}

resource "aws_elasticache_cluster" "studio_redis" {
  cluster_id           = "studio-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.studio_redis_subnet.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  
  tags = {
    Name = "studio-redis"
    Environment = var.environment
  }
}
```

---

!!! tip "Deployment Strategy"
    Choose the deployment strategy that best fits your requirements: Blue-Green for zero-downtime, Canary for gradual rollout, or Rolling for simplicity.

!!! warning "Security First"
    Always implement security layers at every level of your deployment architecture, from network to application to data.

!!! note "Monitoring Essential"
    Implement comprehensive monitoring and logging from day one to ensure you can quickly identify and resolve issues.
