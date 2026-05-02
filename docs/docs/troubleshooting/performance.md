# Performance Optimization

This guide covers performance tuning, monitoring, and optimization strategies for the Studio Platform to ensure optimal performance and user experience.

## 📊 Performance Metrics

### **Key Performance Indicators (KPIs)**
- **Response Time** - < 2 seconds for 95% of requests
- **Throughput** - > 1000 requests per minute
- **CPU Usage** - < 80% average utilization
- **Memory Usage** - < 85% of allocated memory
- **Database Response** - < 100ms for 95% of queries
- **Page Load Time** - < 3 seconds for all pages

### **Monitoring Tools**
```bash
# System monitoring
docker stats
htop
iotop
netstat -i

# Application monitoring
curl http://localhost:8000/api/metrics
docker-compose logs -f --tail=100

# Database monitoring
docker-compose exec db psql -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;"
```

## 🚀 Frontend Performance

### **Browser Optimization**

#### Asset Minification and Compression
```javascript
// webpack.config.js
module.exports = {
  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          compress: {
            drop_console: true,
          },
        },
      }),
    ],
  },
  plugins: [
    new CompressionPlugin({
      algorithm: 'gzip',
      test: /\.(js|css|html|svg)$/,
      threshold: 8192,
      minRatio: 0.8,
    }),
  ],
};
```

#### Lazy Loading Implementation
```javascript
// React lazy loading example
import React, { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./components/Dashboard'));
const Reports = lazy(() => import('./components/Reports'));

function App() {
  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <Route path="/dashboard" component={Dashboard} />
        <Route path="/reports" component={Reports} />
      </Suspense>
    </div>
  );
}
```

#### Code Splitting
```javascript
// Dynamic imports for code splitting
const loadModule = async (moduleName) => {
  const module = await import(`./modules/${moduleName}`);
  return module.default;
};

// Usage
const ComplianceModule = await loadModule('compliance');
```

### **Caching Strategies**

#### Browser Caching
```nginx
# nginx.conf
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
  add_header Vary Accept-Encoding;
}

location ~* \.(html)$ {
  expires 1h;
  add_header Cache-Control "public, must-revalidate";
}
```

#### Service Worker Implementation
```javascript
// service-worker.js
const CACHE_NAME = 'studio-v1';
const urlsToCache = [
  '/',
  '/static/js/main.js',
  '/static/css/main.css',
  '/api/health'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        return response || fetch(event.request);
      })
  );
});
```

## ⚡ Backend Performance

### **Database Optimization**

#### Query Optimization
```sql
-- Add appropriate indexes
CREATE INDEX CONCURRENTLY idx_evidence_created_at ON evidence_evidence(created_at DESC);
CREATE INDEX CONCURRENTLY idx_compliance_framework_status ON compliance_compliance(framework_id, status);
CREATE INDEX CONCURRENTLY idx_user_last_login ON auth_user(last_login DESC);

-- Use EXPLAIN ANALYZE to analyze slow queries
EXPLAIN ANALYZE 
SELECT e.*, c.framework_id 
FROM evidence_evidence e 
JOIN compliance_compliance c ON e.compliance_id = c.id 
WHERE e.created_at > '2024-01-01' 
ORDER BY e.created_at DESC 
LIMIT 50;
```

#### Connection Pooling
```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'studio_db',
        'USER': 'studio_user',
        'PASSWORD': 'password',
        'HOST': 'db',
        'PORT': '5432',
        'OPTIONS': {
            'MAX_CONNS': 20,
            'MIN_CONNS': 5,
            'CONN_MAX_AGE': 600,
        }
    }
}
```

#### Database Query Optimization
```python
# Use select_related and prefetch_related
def get_evidence_with_frameworks():
    return Evidence.objects.select_related('compliance').prefetch_related('tags')

# Use only() and defer() for specific fields
def get_evidence_list():
    return Evidence.objects.only('id', 'title', 'created_at', 'status')

# Use bulk operations for large datasets
def bulk_create_evidence(evidence_data):
    return Evidence.objects.bulk_create(evidence_data, batch_size=1000)
```

### **Application Caching**

#### Redis Configuration
```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 5,
            'SOCKET_TIMEOUT': 5,
            'RETRY_ON_TIMEOUT': True,
        }
    }
}

# Cache expensive operations
@cache_page(300)  # 5 minutes
def compliance_dashboard(request):
    # Expensive dashboard logic
    pass

@cache_page(60 * 60 * 24)  # 24 hours
def static_data_view(request):
    # Static data that changes rarely
    pass
```

#### Custom Cache Decorators
```python
from django.core.cache import cache
import hashlib

def cache_result(timeout=300):
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Create cache key from function name and arguments
            key = f"{func.__name__}_{hashlib.md5(str(args + tuple(kwargs.items())).encode()).hexdigest()}"
            
            # Try to get from cache
            result = cache.get(key)
            if result is None:
                result = func(*args, **kwargs)
                cache.set(key, result, timeout)
            
            return result
        return wrapper
    return decorator

@cache_result(timeout=600)
def get_compliance_score(framework_id):
    # Expensive calculation
    pass
```

### **Async Task Processing**

#### Celery Configuration
```python
# celery.py
from celery import Celery
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'studio.settings')

app = Celery('studio')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# Configure worker settings
app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)
```

#### Async Task Examples
```python
# tasks.py
from celery import shared_task
from django.core.cache import cache

@shared_task(bind=True, max_retries=3)
def process_evidence(self, evidence_id):
    try:
        evidence = Evidence.objects.get(id=evidence_id)
        # Process evidence asynchronously
        result = process_evidence_data(evidence)
        
        # Cache result
        cache.set(f'evidence_{evidence_id}_processed', True, timeout=3600)
        
        return result
    except Exception as exc:
        # Retry on failure
        raise self.retry(exc=exc, countdown=60)

@shared_task
def generate_compliance_report(framework_id, report_type):
    # Generate report asynchronously
    report_data = collect_report_data(framework_id, report_type)
    report_file = create_report_file(report_data)
    
    # Notify user when ready
    notify_user_report_ready(report_file.id)
    
    return report_file.id
```

## 🌐 Network Performance

### **HTTP/2 and HTTP/3**
```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    # HTTP/3 (QUIC) - requires nginx 1.25+
    listen 443 quic;
    
    # Enable HTTP/3
    add_header Alt-Svc 'h3=":443"; ma=86400';
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
}
```

### **Content Delivery Network (CDN)**
```yaml
# docker-compose.yml
services:
  frontend:
    environment:
      - CDN_URL=https://cdn.studio.example.com
      - STATIC_URL=/static/
      - MEDIA_URL=/media/
```

```javascript
// CDN configuration
const CDN_BASE_URL = process.env.CDN_URL || '';

// Use CDN for static assets
function getAssetUrl(path) {
  return `${CDN_BASE_URL}${path}`;
}

// Usage
const logoUrl = getAssetUrl('/static/images/logo.png');
```

### **Load Balancing**
```nginx
# nginx.conf
upstream backend {
    least_conn;
    server backend1:8000 weight=3 max_fails=3 fail_timeout=30s;
    server backend2:8000 weight=3 max_fails=3 fail_timeout=30s;
    server backend3:8000 weight=2 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
```

## 📈 Monitoring and Analytics

### **Application Performance Monitoring (APM)**
```python
# middleware.py
import time
import logging
from django.utils.deprecation import MiddlewareMixin

class PerformanceMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request.start_time = time.time()
    
    def process_response(self, request, response):
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            
            # Log slow requests
            if duration > 2.0:  # Log requests taking > 2 seconds
                logging.warning(
                    f"Slow request: {request.method} {request.path} "
                    f"took {duration:.2f}s"
                )
            
            # Add performance headers
            response['X-Response-Time'] = f"{duration:.3f}s"
        
        return response
```

### **Performance Metrics Collection**
```python
# metrics.py
from prometheus_client import Counter, Histogram, Gauge
import time

# Define metrics
REQUEST_COUNT = Counter('studio_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('studio_request_duration_seconds', 'Request duration')
ACTIVE_USERS = Gauge('studio_active_users', 'Number of active users')
DATABASE_CONNECTIONS = Gauge('studio_database_connections', 'Database connections')

class PerformanceTracker:
    @staticmethod
    def track_request(method, endpoint):
        REQUEST_COUNT.labels(method=method, endpoint=endpoint).inc()
    
    @staticmethod
    def track_duration(func):
        def wrapper(*args, **kwargs):
            start_time = time.time()
            result = func(*args, **kwargs)
            REQUEST_DURATION.observe(time.time() - start_time)
            return result
        return wrapper
```

### **Real-time Monitoring Dashboard**
```javascript
// monitoring.js
class PerformanceMonitor {
    constructor() {
        this.metrics = {};
        this.thresholds = {
            responseTime: 2000,  // 2 seconds
            errorRate: 0.05,      // 5%
            cpuUsage: 0.8        // 80%
        };
    }
    
    async collectMetrics() {
        const response = await fetch('/api/metrics');
        this.metrics = await response.json();
        this.checkThresholds();
    }
    
    checkThresholds() {
        if (this.metrics.responseTime > this.thresholds.responseTime) {
            this.alert('High response time detected');
        }
        
        if (this.metrics.errorRate > this.thresholds.errorRate) {
            this.alert('High error rate detected');
        }
        
        if (this.metrics.cpuUsage > this.thresholds.cpuUsage) {
            this.alert('High CPU usage detected');
        }
    }
    
    alert(message) {
        console.warn(`Performance Alert: ${message}`);
        // Send to monitoring service
        this.sendAlert(message);
    }
    
    sendAlert(message) {
        fetch('/api/alerts', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message, timestamp: Date.now() })
        });
    }
}

// Initialize monitoring
const monitor = new PerformanceMonitor();
setInterval(() => monitor.collectMetrics(), 30000);  // Every 30 seconds
```

## 🔧 Performance Tuning

### **Database Tuning**
```sql
-- PostgreSQL configuration optimization
-- postgresql.conf

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Connection settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# Query optimization
random_page_cost = 1.1
effective_io_concurrency = 200
```

### **Application Server Tuning**
```python
# gunicorn.conf.py
bind = "0.0.0.0:8000"
workers = 4
worker_class = "gevent"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = 30
keepalive = 2
preload_app = True
```

### **System Optimization**
```bash
# System tuning for high performance
# /etc/sysctl.conf

# Network optimization
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_tw_buckets = 5000

# File system optimization
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288

# Memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
```

## 📊 Performance Testing

### **Load Testing Script**
```python
# load_test.py
import asyncio
import aiohttp
import time
from concurrent.futures import ThreadPoolExecutor

class LoadTester:
    def __init__(self, base_url, concurrent_users=10, duration=60):
        self.base_url = base_url
        self.concurrent_users = concurrent_users
        self.duration = duration
        self.results = []
    
    async def make_request(self, session, endpoint):
        start_time = time.time()
        try:
            async with session.get(f"{self.base_url}{endpoint}") as response:
                await response.text()
                duration = time.time() - start_time
                self.results.append({
                    'endpoint': endpoint,
                    'status': response.status,
                    'duration': duration,
                    'success': True
                })
        except Exception as e:
            duration = time.time() - start_time
            self.results.append({
                'endpoint': endpoint,
                'status': 0,
                'duration': duration,
                'success': False,
                'error': str(e)
            })
    
    async def run_test(self):
        endpoints = ['/api/health', '/api/compliance', '/api/evidence']
        
        async with aiohttp.ClientSession() as session:
            tasks = []
            for _ in range(self.concurrent_users):
                for endpoint in endpoints:
                    task = asyncio.create_task(self.make_request(session, endpoint))
                    tasks.append(task)
            
            await asyncio.gather(*tasks)
    
    def analyze_results(self):
        total_requests = len(self.results)
        successful_requests = sum(1 for r in self.results if r['success'])
        avg_response_time = sum(r['duration'] for r in self.results) / total_requests
        
        return {
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'success_rate': successful_requests / total_requests,
            'avg_response_time': avg_response_time,
            'max_response_time': max(r['duration'] for r in self.results),
            'min_response_time': min(r['duration'] for r in self.results)
        }

# Usage
tester = LoadTester('http://localhost:8000', concurrent_users=50, duration=60)
await tester.run_test()
results = tester.analyze_results()
print(results)
```

### **Database Performance Test**
```sql
-- Database performance test script
EXPLAIN ANALYZE
SELECT 
    e.id,
    e.title,
    e.created_at,
    c.framework_id,
    c.status
FROM evidence_evidence e
JOIN compliance_compliance c ON e.compliance_id = c.id
WHERE e.created_at > NOW() - INTERVAL '30 days'
ORDER BY e.created_at DESC
LIMIT 100;

-- Test index effectiveness
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

## 🚨 Performance Alerts

### **Alert Configuration**
```yaml
# alerts.yml
performance_alerts:
  high_response_time:
    condition: "response_time > 2000"
    severity: "warning"
    channels: ["email", "slack"]
    cooldown: "5m"
    
  high_error_rate:
    condition: "error_rate > 0.05"
    severity: "critical"
    channels: ["email", "slack", "sms"]
    cooldown: "1m"
    
  high_cpu_usage:
    condition: "cpu_usage > 0.8"
    severity: "warning"
    channels: ["email"]
    cooldown: "10m"
    
  database_slow_queries:
    condition: "avg_query_time > 100"
    severity: "warning"
    channels: ["email"]
    cooldown: "15m"
```

### **Automated Response**
```python
# automated_response.py
class PerformanceAutoResponse:
    def __init__(self):
        self.actions = {
            'high_response_time': self.scale_up,
            'high_cpu_usage': self.restart_service,
            'database_slow_queries': self.restart_database
        }
    
    def handle_alert(self, alert_type, severity):
        if severity == 'critical':
            action = self.actions.get(alert_type)
            if action:
                action()
    
    def scale_up(self):
        # Auto-scale backend services
        os.system('docker-compose up -d --scale backend=2')
    
    def restart_service(self):
        # Restart problematic service
        os.system('docker-compose restart backend')
    
    def restart_database(self):
        # Restart database with optimized settings
        os.system('docker-compose restart db')
```

---

!!! tip "Performance Monitoring"
    Set up continuous performance monitoring with automated alerts to detect issues before they impact users.

!!! warning "Production Changes"
    Always test performance optimizations in a staging environment before applying to production.

!!! note "Regular Maintenance"
    Schedule regular performance reviews and database maintenance to maintain optimal system performance.
