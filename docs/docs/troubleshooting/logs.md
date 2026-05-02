# Log Analysis and Management

This guide covers comprehensive log management, analysis techniques, and troubleshooting strategies using logs for the Studio Platform.

## 📊 Logging Architecture

### **Log Categories**
- **Application Logs** - Application events, errors, and performance data
- **Security Logs** - Authentication, authorization, and security events
- **System Logs** - Infrastructure and system-level events
- **Audit Logs** - Compliance and audit trail information
- **Performance Logs** - Response times, resource usage, and bottlenecks

### **Log Levels**
```python
# Python logging levels
DEBUG = 10      # Detailed information for debugging
INFO = 20       # General information about system events
WARNING = 30    # Warning about potential issues
ERROR = 40      # Error events that may affect functionality
CRITICAL = 50   # Critical errors that may cause system failure
```

## 🔧 Log Configuration

### **Django Logging Setup**
```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
        'json': {
            'format': '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "module": "%(module)s", "message": "%(message)s", "request_id": "%(request_id)s"}',
            'style': '{',
        },
    },
    'filters': {
        'request_id': {
            '()': 'log_request_id.RequestIdFilter',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/app/logs/studio.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 5,
            'formatter': 'verbose',
            'filters': ['request_id'],
        },
        'error_file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/app/logs/studio_error.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 10,
            'formatter': 'verbose',
            'filters': ['request_id'],
        },
        'security_file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/app/logs/security.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 20,
            'formatter': 'json',
            'filters': ['request_id'],
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
        'syslog': {
            'level': 'INFO',
            'class': 'logging.handlers.SysLogHandler',
            'address': ('localhost', 514),
            'facility': 'local0',
            'formatter': 'json',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
        'studio': {
            'handlers': ['file', 'error_file', 'console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'security': {
            'handlers': ['security_file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
        'celery': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
}
```

### **Request ID Middleware**
```python
# middleware.py
import uuid
import logging

class RequestIdMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        request_id = str(uuid.uuid4())
        request.request_id = request_id
        
        # Add request ID to all log records
        old_factory = logging.getLogRecordFactory()
        
        def record_factory(*args, **kwargs):
            record = old_factory(*args, **kwargs)
            record.request_id = getattr(request, 'request_id', None)
            return record
        
        logging.setLogRecordFactory(record_factory)
        
        response = self.get_response(request)
        
        # Add request ID to response headers
        response['X-Request-ID'] = request_id
        
        # Restore old factory
        logging.setLogRecordFactory(old_factory)
        
        return response
```

## 🔍 Log Analysis Techniques

### **Real-time Log Monitoring**
```python
# log_monitor.py
import re
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta

class LogMonitor:
    def __init__(self, log_file='/app/logs/studio.log'):
        self.log_file = log_file
        self.patterns = {
            'error': re.compile(r'ERROR'),
            'critical': re.compile(r'CRITICAL'),
            'slow_request': re.compile(r'response_time.*>(\d+)ms'),
            'database_error': re.compile(r'database.*error'),
            'authentication_failure': re.compile(r'login.*failed'),
            'api_error': re.compile(r'API.*error'),
        }
        self.alerts = deque(maxlen=1000)
        self.stats = defaultdict(int)
    
    def monitor_logs(self, interval=60):
        """Monitor logs in real-time"""
        last_position = 0
        
        while True:
            try:
                with open(self.log_file, 'r') as f:
                    f.seek(last_position)
                    new_lines = f.readlines()
                    last_position = f.tell()
                
                for line in new_lines:
                    self.analyze_line(line.strip())
                
                self.check_alerts()
                time.sleep(interval)
                
            except Exception as e:
                print(f"Error monitoring logs: {e}")
                time.sleep(interval)
    
    def analyze_line(self, line):
        """Analyze individual log line"""
        timestamp = self.extract_timestamp(line)
        
        for pattern_name, pattern in self.patterns.items():
            if pattern.search(line):
                self.stats[pattern_name] += 1
                
                alert = {
                    'timestamp': timestamp,
                    'type': pattern_name,
                    'message': line,
                    'severity': self.get_severity(pattern_name)
                }
                
                self.alerts.append(alert)
                
                # Immediate alert for critical issues
                if alert['severity'] == 'critical':
                    self.send_immediate_alert(alert)
    
    def extract_timestamp(self, line):
        """Extract timestamp from log line"""
        try:
            # Assuming format: 2024-01-01 12:00:00
            timestamp_str = line.split()[0] + ' ' + line.split()[1]
            return datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
        except:
            return datetime.now()
    
    def get_severity(self, pattern_name):
        severity_map = {
            'error': 'warning',
            'critical': 'critical',
            'slow_request': 'info',
            'database_error': 'warning',
            'authentication_failure': 'warning',
            'api_error': 'warning'
        }
        return severity_map.get(pattern_name, 'info')
    
    def check_alerts(self):
        """Check for alert conditions"""
        recent_alerts = [
            alert for alert in self.alerts 
            if datetime.now() - alert['timestamp'] < timedelta(minutes=5)
        ]
        
        # Check for error rate spike
        error_count = len([a for a in recent_alerts if a['type'] in ['error', 'critical']])
        if error_count > 10:
            self.send_alert('High error rate detected', 'warning')
        
        # Check for authentication failures
        auth_failures = len([a for a in recent_alerts if a['type'] == 'authentication_failure'])
        if auth_failures > 5:
            self.send_alert('Multiple authentication failures detected', 'warning')
    
    def send_immediate_alert(self, alert):
        """Send immediate alert for critical issues"""
        message = f"CRITICAL: {alert['message']}"
        self.send_alert(message, 'critical')
    
    def send_alert(self, message, severity):
        """Send alert to monitoring system"""
        print(f"ALERT [{severity.upper()}]: {message}")
        # Integration with alerting system (Slack, email, etc.)
        # self.alerting_system.send_alert(message, severity)
```

### **Log Analysis Scripts**
```bash
#!/bin/bash
# log_analysis.sh

# Function to count error types by hour
count_errors_by_hour() {
    local log_file=$1
    local date=$2
    
    echo "Error count for $date:"
    grep "$date" "$log_file" | grep -E "(ERROR|CRITICAL)" | \
    awk '{print $2}' | cut -d: -f1 | sort | uniq -c | sort -nr
}

# Function to find slow requests
find_slow_requests() {
    local log_file=$1
    local threshold=$2
    
    echo "Requests slower than ${threshold}ms:"
    grep "response_time.*>$threshold" "$log_file" | \
    awk '{print $7, $8}' | sort | uniq -c | sort -nr | head -10
}

# Function to analyze authentication patterns
analyze_auth_patterns() {
    local log_file=$1
    
    echo "Authentication Analysis:"
    echo "Failed logins:"
    grep "login.*failed" "$log_file" | awk '{print $1, $2}' | sort | uniq -c | sort -nr | head -10
    
    echo "Successful logins:"
    grep "login.*success" "$log_file" | awk '{print $1, $2}' | sort | uniq -c | sort -nr | head -10
}

# Function to check for database errors
check_database_errors() {
    local log_file=$1
    
    echo "Database Errors:"
    grep -i "database.*error" "$log_file" | tail -20
}

# Usage examples
if [ "$1" == "errors" ]; then
    count_errors_by_hour "/app/logs/studio.log" "$(date +%Y-%m-%d)"
elif [ "$1" == "slow" ]; then
    find_slow_requests "/app/logs/studio.log" "${2:-1000}"
elif [ "$1" == "auth" ]; then
    analyze_auth_patterns "/app/logs/studio.log"
elif [ "$1" == "db" ]; then
    check_database_errors "/app/logs/studio.log"
else
    echo "Usage: $0 {errors|slow|auth|db} [threshold]"
fi
```

### **Python Log Analysis**
```python
# log_analyzer.py
import re
import json
from datetime import datetime, timedelta
from collections import Counter, defaultdict
import pandas as pd
import matplotlib.pyplot as plt

class LogAnalyzer:
    def __init__(self, log_file):
        self.log_file = log_file
        self.logs = []
        self.parse_logs()
    
    def parse_logs(self):
        """Parse log file into structured data"""
        with open(self.log_file, 'r') as f:
            for line in f:
                try:
                    log_entry = self.parse_log_line(line.strip())
                    if log_entry:
                        self.logs.append(log_entry)
                except Exception as e:
                    print(f"Error parsing line: {e}")
    
    def parse_log_line(self, line):
        """Parse individual log line"""
        # Assuming format: LEVEL timestamp module message
        parts = line.split(' ', 3)
        if len(parts) < 4:
            return None
        
        return {
            'level': parts[0],
            'timestamp': parts[1] + ' ' + parts[2],
            'module': parts[3].split()[0] if parts[3] else '',
            'message': ' '.join(parts[3].split()[1:]) if len(parts[3].split()) > 1 else '',
            'raw': line
        }
    
    def get_error_trends(self, days=7):
        """Analyze error trends over time"""
        cutoff_date = datetime.now() - timedelta(days=days)
        recent_logs = [log for log in self.logs 
                      if datetime.strptime(log['timestamp'], '%Y-%m-%d %H:%M:%S') > cutoff_date]
        
        errors = [log for log in recent_logs if log['level'] in ['ERROR', 'CRITICAL']]
        
        # Group by hour
        hourly_errors = defaultdict(int)
        for error in errors:
            hour = datetime.strptime(error['timestamp'], '%Y-%m-%d %H:%M:%S').replace(minute=0, second=0)
            hourly_errors[hour] += 1
        
        return dict(hourly_errors)
    
    def get_top_errors(self, limit=10):
        """Get most common error messages"""
        errors = [log for log in self.logs if log['level'] in ['ERROR', 'CRITICAL']]
        error_messages = [log['message'] for log in errors]
        
        return Counter(error_messages).most_common(limit)
    
    def get_slow_requests(self, threshold=1000):
        """Find slow requests from logs"""
        slow_requests = []
        
        for log in self.logs:
            if 'response_time' in log['message']:
                # Extract response time
                match = re.search(r'response_time.*?(\d+)ms', log['message'])
                if match and int(match.group(1)) > threshold:
                    slow_requests.append({
                        'timestamp': log['timestamp'],
                        'response_time': int(match.group(1)),
                        'message': log['message']
                    })
        
        return sorted(slow_requests, key=lambda x: x['response_time'], reverse=True)
    
    def get_authentication_patterns(self):
        """Analyze authentication patterns"""
        auth_logs = [log for log in self.logs if 'login' in log['message'].lower()]
        
        successful_logins = []
        failed_logins = []
        
        for log in auth_logs:
            if 'success' in log['message'].lower():
                successful_logins.append(log)
            elif 'failed' in log['message'].lower():
                failed_logins.append(log)
        
        return {
            'successful': len(successful_logins),
            'failed': len(failed_logins),
            'success_rate': len(successful_logins) / (len(successful_logins) + len(failed_logins)) * 100 if (len(successful_logins) + len(failed_logins)) > 0 else 0,
            'recent_failures': [log for log in failed_logins if datetime.strptime(log['timestamp'], '%Y-%m-%d %H:%M:%S') > datetime.now() - timedelta(hours=24)]
        }
    
    def generate_report(self):
        """Generate comprehensive log analysis report"""
        report = {
            'analysis_date': datetime.now().isoformat(),
            'total_logs': len(self.logs),
            'error_trends': self.get_error_trends(),
            'top_errors': self.get_top_errors(),
            'slow_requests': self.get_slow_requests(),
            'authentication_patterns': self.get_authentication_patterns()
        }
        
        return report
    
    def export_to_csv(self, filename):
        """Export logs to CSV for analysis"""
        df = pd.DataFrame(self.logs)
        df.to_csv(filename, index=False)
    
    def plot_error_trends(self):
        """Plot error trends over time"""
        trends = self.get_error_trends()
        
        if not trends:
            print("No error data to plot")
            return
        
        dates = list(trends.keys())
        counts = list(trends.values())
        
        plt.figure(figsize=(12, 6))
        plt.plot(dates, counts, marker='o')
        plt.title('Error Trends Over Time')
        plt.xlabel('Time')
        plt.ylabel('Error Count')
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()
```

## 🚨 Log-Based Troubleshooting

### **Common Log Patterns and Solutions**

#### Database Connection Errors
```python
# Troubleshoot database issues from logs
def troubleshoot_database_logs(log_file):
    """Analyze database-related log entries"""
    
    with open(log_file, 'r') as f:
        logs = f.readlines()
    
    db_errors = []
    connection_issues = []
    slow_queries = []
    
    for log in logs:
        if 'database' in log.lower() and 'error' in log.lower():
            db_errors.append(log.strip())
        elif 'connection' in log.lower() and 'failed' in log.lower():
            connection_issues.append(log.strip())
        elif 'slow query' in log.lower() or 'query time' in log.lower():
            slow_queries.append(log.strip())
    
    print(f"Database Errors Found: {len(db_errors)}")
    for error in db_errors[-5:]:  # Show last 5 errors
        print(f"  - {error}")
    
    print(f"\nConnection Issues: {len(connection_issues)}")
    for issue in connection_issues[-3:]:  # Show last 3 issues
        print(f"  - {issue}")
    
    print(f"\nSlow Queries: {len(slow_queries)}")
    for query in slow_queries[-3:]:  # Show last 3 slow queries
        print(f"  - {query}")
    
    # Provide recommendations
    if len(db_errors) > 10:
        print("\nRecommendation: Check database configuration and connectivity")
    
    if len(connection_issues) > 5:
        print("\nRecommendation: Review connection pool settings and database availability")
    
    if len(slow_queries) > 10:
        print("\nRecommendation: Optimize slow queries and add appropriate indexes")
```

#### Authentication Issues
```python
# Troubleshoot authentication from logs
def troubleshoot_auth_logs(log_file):
    """Analyze authentication-related log entries"""
    
    with open(log_file, 'r') as f:
        logs = f.readlines()
    
    failed_logins = []
    successful_logins = []
    suspicious_activity = []
    
    for log in logs:
        if 'login' in log.lower():
            if 'failed' in log.lower() or 'error' in log.lower():
                failed_logins.append(log.strip())
            elif 'success' in log.lower():
                successful_logins.append(log.strip())
        
        # Check for suspicious patterns
        if 'login' in log.lower() and ('multiple' in log.lower() or 'rapid' in log.lower()):
            suspicious_activity.append(log.strip())
    
    print(f"Failed Logins: {len(failed_logins)}")
    if failed_logins:
        print("Recent failed logins:")
        for login in failed_logins[-5:]:
            print(f"  - {login}")
    
    print(f"\nSuccessful Logins: {len(successful_logins)}")
    
    print(f"\nSuspicious Activity: {len(suspicious_activity)}")
    for activity in suspicious_activity:
        print(f"  - {activity}")
    
    # Check for brute force patterns
    ip_failures = defaultdict(int)
    for login in failed_logins:
        # Extract IP address (simplified)
        ip_match = re.search(r'(\d+\.\d+\.\d+\.\d+)', login)
        if ip_match:
            ip_failures[ip_match.group(1)] += 1
    
    suspicious_ips = {ip: count for ip, count in ip_failures.items() if count > 5}
    
    if suspicious_ips:
        print(f"\nSuspicious IPs (multiple failed attempts):")
        for ip, count in suspicious_ips.items():
            print(f"  - {ip}: {count} failed attempts")
```

#### Performance Issues
```python
# Troubleshoot performance from logs
def troubleshoot_performance_logs(log_file):
    """Analyze performance-related log entries"""
    
    with open(log_file, 'r') as f:
        logs = f.readlines()
    
    slow_requests = []
    memory_issues = []
    cpu_issues = []
    
    for log in logs:
        if 'response_time' in log.lower():
            # Extract response time
            match = re.search(r'response_time.*?(\d+)ms', log.lower())
            if match:
                response_time = int(match.group(1))
                if response_time > 2000:  # > 2 seconds
                    slow_requests.append({
                        'line': log.strip(),
                        'response_time': response_time
                    })
        
        elif 'memory' in log.lower() and ('error' in log.lower() or 'warning' in log.lower()):
            memory_issues.append(log.strip())
        
        elif 'cpu' in log.lower() and ('high' in log.lower() or 'error' in log.lower()):
            cpu_issues.append(log.strip())
    
    print(f"Slow Requests (>2s): {len(slow_requests)}")
    if slow_requests:
        print("Slowest requests:")
        sorted_requests = sorted(slow_requests, key=lambda x: x['response_time'], reverse=True)
        for req in sorted_requests[:5]:
            print(f"  - {req['response_time']}ms: {req['line']}")
    
    print(f"\nMemory Issues: {len(memory_issues)}")
    for issue in memory_issues[-3:]:
        print(f"  - {issue}")
    
    print(f"\nCPU Issues: {len(cpu_issues)}")
    for issue in cpu_issues[-3:]:
        print(f"  - {issue}")
```

## 📊 Log Management Best Practices

### **Log Rotation and Retention**
```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - ./logs:/app/logs
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
  
  nginx:
    volumes:
      - ./logs/nginx:/var/log/nginx
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### **Centralized Logging with ELK Stack**
```yaml
# docker-compose.elk.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"

  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    volumes:
      - ./logstash/config:/usr/share/logstash/pipeline
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:
```

### **Logstash Configuration**
```ruby
# logstash/pipeline/studio.conf
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][service] == "studio" {
    grok {
      match => { 
        "message" => "%{LOGLEVEL:level} %{TIMESTAMP_ISO8601:timestamp} %{DATA:module} %{GREEDYDATA:message}"
      }
    }
    
    date {
      match => [ "timestamp", "yyyy-MM-dd HH:mm:ss" ]
    }
    
    if [level] == "ERROR" or [level] == "CRITICAL" {
      mutate {
        add_tag => [ "error" ]
      }
    }
    
    if [message] =~ /response_time/ {
      grok {
        match => { 
          "message" => "response_time:%{NUMBER:response_time:int}ms"
        }
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "studio-logs-%{+YYYY.MM.dd}"
  }
}
```

## 🔧 Advanced Log Analysis

### **Machine Learning for Anomaly Detection**
```python
# anomaly_detection.py
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import pandas as pd

class LogAnomalyDetector:
    def __init__(self):
        self.scaler = StandardScaler()
        self.model = IsolationForest(contamination=0.1, random_state=42)
        self.is_trained = False
    
    def extract_features(self, logs):
        """Extract features from logs for anomaly detection"""
        features = []
        
        for log in logs:
            # Time-based features
            timestamp = datetime.strptime(log['timestamp'], '%Y-%m-%d %H:%M:%S')
            hour = timestamp.hour
            day_of_week = timestamp.weekday()
            
            # Log level features
            level_numeric = {'DEBUG': 0, 'INFO': 1, 'WARNING': 2, 'ERROR': 3, 'CRITICAL': 4}
            level_value = level_numeric.get(log['level'], 1)
            
            # Message length
            message_length = len(log['message'])
            
            # Response time if present
            response_time = 0
            if 'response_time' in log['message']:
                match = re.search(r'response_time.*?(\d+)ms', log['message'])
                if match:
                    response_time = int(match.group(1))
            
            features.append([hour, day_of_week, level_value, message_length, response_time])
        
        return np.array(features)
    
    def train(self, logs):
        """Train the anomaly detection model"""
        features = self.extract_features(logs)
        features_scaled = self.scaler.fit_transform(features)
        self.model.fit(features_scaled)
        self.is_trained = True
    
    def detect_anomalies(self, logs):
        """Detect anomalies in logs"""
        if not self.is_trained:
            self.train(logs)
        
        features = self.extract_features(logs)
        features_scaled = self.scaler.transform(features)
        
        predictions = self.model.predict(features_scaled)
        anomalies = []
        
        for i, prediction in enumerate(predictions):
            if prediction == -1:  # Anomaly detected
                anomalies.append({
                    'log': logs[i],
                    'anomaly_score': self.model.decision_function([features_scaled[i]])[0],
                    'features': features[i]
                })
        
        return anomalies
    
    def explain_anomaly(self, anomaly):
        """Explain why a log entry is considered anomalous"""
        log = anomaly['log']
        features = anomaly['features']
        
        explanations = []
        
        # Check time-based anomalies
        hour = int(features[0])
        if hour < 6 or hour > 22:
            explanations.append(f"Unusual hour: {hour}")
        
        # Check level anomalies
        level = log['level']
        if level in ['ERROR', 'CRITICAL']:
            explanations.append(f"High severity level: {level}")
        
        # Check message length anomalies
        message_length = int(features[3])
        if message_length > 1000:
            explanations.append(f"Unusually long message: {message_length} characters")
        
        # Check response time anomalies
        response_time = int(features[4])
        if response_time > 5000:
            explanations.append(f"Very slow response: {response_time}ms")
        
        return explanations
```

---

!!! tip "Log Monitoring"
    Set up real-time log monitoring with automated alerts for critical errors and unusual patterns.

!!! warning "Log Storage"
    Monitor log storage usage and implement proper retention policies to avoid disk space issues.

!!! note "Log Security"
    Ensure logs don't contain sensitive information like passwords, API keys, or personal data.
