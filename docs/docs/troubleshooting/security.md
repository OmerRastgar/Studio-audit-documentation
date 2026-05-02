# Security Troubleshooting

This guide covers security-related issues, incident response, and security best practices for troubleshooting and resolving security problems in the Studio Platform.

## 🚨 Security Incident Response

### **Immediate Response Steps**
1. **Isolate the System** - Disconnect affected systems from the network
2. **Preserve Evidence** - Don't modify or delete any logs or data
3. **Assess Impact** - Determine scope and severity of the incident
4. **Notify Stakeholders** - Alert security team and management
5. **Document Everything** - Record all actions and findings

### **Security Incident Checklist**
```bash
# 1. Check for unauthorized access
docker-compose exec backend python manage.py check_security

# 2. Review recent authentication logs
docker-compose logs backend | grep -i "login\|auth\|failed"

# 3. Check for suspicious activity
docker-compose exec backend python manage.py audit_recent_activity

# 4. Verify system integrity
docker-compose exec backend python manage.py integrity_check

# 5. Generate security report
docker-compose exec backend python manage.py security_report
```

## 🔐 Authentication Issues

### **Failed Login Attempts**

#### Problem: Brute force attack detected
**Symptoms:**
- Multiple failed login attempts
- Locked user accounts
- Unusual login patterns

**Solutions:**

1. **Enable Rate Limiting**
   ```python
   # settings.py
   REST_FRAMEWORK = {
       'DEFAULT_THROTTLE_CLASSES': [
           'rest_framework.throttling.AnonRateThrottle',
           'rest_framework.throttling.UserRateThrottle'
       ],
       'DEFAULT_THROTTLE_RATES': {
           'anon': '5/hour',
           'user': '1000/hour'
       }
   }
   
   # Custom rate limiting for login
   LOGIN_RATE_LIMIT = '5/15m'  # 5 attempts per 15 minutes
   ```

2. **Implement Account Lockout**
   ```python
   # authentication.py
   from django.core.cache import cache
   from django.contrib.auth import authenticate
   
   def authenticate_with_lockout(request, username, password):
       cache_key = f"login_attempts_{username}"
       attempts = cache.get(cache_key, 0)
       
       if attempts >= 5:
           return None, "Account temporarily locked"
       
       user = authenticate(request, username=username, password=password)
       
       if user is None:
           cache.set(cache_key, attempts + 1, 900)  # 15 minutes
           return None, f"Invalid credentials. {4 - attempts} attempts remaining"
       
       cache.delete(cache_key)
       return user, "Login successful"
   ```

3. **Monitor Suspicious Activity**
   ```python
   # middleware.py
   class SecurityMiddleware:
       def __init__(self, get_response):
           self.get_response = get_response
       
       def __call__(self, request):
           # Log failed authentication attempts
           if request.path == '/api/login/' and request.method == 'POST':
               self.log_login_attempt(request)
           
           return self.get_response(request)
       
       def log_login_attempt(self, request):
           ip_address = self.get_client_ip(request)
           username = request.POST.get('username', '')
           
           # Log to security monitoring
           SecurityLog.objects.create(
               event_type='login_attempt',
               ip_address=ip_address,
               username=username,
               user_agent=request.META.get('HTTP_USER_AGENT', ''),
               timestamp=timezone.now()
           )
   ```

### **Session Hijacking**

#### Problem: Session security compromised
**Symptoms:**
- Users logged in from unexpected locations
- Session tokens being used by unauthorized users
- Account activity from unknown IPs

**Solutions:**

1. **Implement Secure Session Management**
   ```python
   # settings.py
   SESSION_COOKIE_SECURE = True
   SESSION_COOKIE_HTTPONLY = True
   SESSION_COOKIE_SAMESITE = 'Strict'
   SESSION_COOKIE_AGE = 3600  # 1 hour
   SESSION_SAVE_EVERY_REQUEST = True
   
   # Enable CSRF protection
   CSRF_COOKIE_SECURE = True
   CSRF_COOKIE_HTTPONLY = True
   ```

2. **IP-Based Session Validation**
   ```python
   # middleware.py
   class SessionSecurityMiddleware:
       def __init__(self, get_response):
           self.get_response = get_response
       
       def __call__(self, request):
           if request.user.is_authenticated:
               session_ip = request.session.get('login_ip')
               current_ip = self.get_client_ip(request)
               
               if session_ip and session_ip != current_ip:
                   # Log out user and notify
                   auth.logout(request)
                   self.notify_suspicious_activity(request, session_ip, current_ip)
           
           return self.get_response(request)
       
       def get_client_ip(self, request):
           x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
           if x_forwarded_for:
               return x_forwarded_for.split(',')[0]
           return request.META.get('REMOTE_ADDR')
   ```

3. **Multi-Factor Authentication**
   ```python
   # mfa.py
   import pyotp
   import qrcode
   from io import BytesIO
   import base64
   
   class MFAService:
       @staticmethod
       def generate_secret(user):
           return pyotp.random_base32()
       
       @staticmethod
       def generate_qr_code(user, secret):
           totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
               name=user.email,
               issuer_name="Studio Platform"
           )
           
           qr = qrcode.QRCode(version=1, box_size=10, border=5)
           qr.add_data(totp_uri)
           qr.make(fit=True)
           
           img = qr.make_image(fill_color="black", back_color="white")
           buffer = BytesIO()
           img.save(buffer, format='PNG')
           
           return base64.b64encode(buffer.getvalue()).decode()
       
       @staticmethod
       def verify_token(secret, token):
           totp = pyotp.TOTP(secret)
           return totp.verify(token, valid_window=1)
   ```

## 🛡️ Data Protection Issues

### **Data Leakage**

#### Problem: Sensitive data exposed
**Symptoms:**
- Sensitive information in logs
- Data accessible without authentication
- Information in error messages

**Solutions:**

1. **Implement Data Masking**
   ```python
   # utils.py
   import re
   
   def mask_sensitive_data(data):
       """Mask sensitive information in logs and responses"""
       if isinstance(data, str):
           # Mask email addresses
           data = re.sub(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', r'\1***@\2', data)
           
           # Mask phone numbers
           data = re.sub(r'(\d{3})\d{3}(\d{4})', r'\1***\2', data)
           
           # Mask credit card numbers
           data = re.sub(r'(\d{4})\d{8,12}(\d{4})', r'\1************\2', data)
           
           # Mask API keys
           data = re.sub(r'(api[_-]?key[_-]?[=:]?)[\w-]{20,}', r'\1***MASKED***', data, flags=re.IGNORECASE)
       
       return data
   
   # Usage in logging
   import logging
   
   class SecureFormatter(logging.Formatter):
       def format(self, record):
           message = super().format(record)
           return mask_sensitive_data(message)
   ```

2. **Secure Error Handling**
   ```python
   # views.py
   from django.http import JsonResponse
   import logging
   
   logger = logging.getLogger(__name__)
   
   def handle_api_error(request, error):
       """Handle API errors without exposing sensitive information"""
       
       # Log full error details
       logger.error(f"API Error: {str(error)}", exc_info=True, extra={
           'request': request,
           'user': request.user.id if request.user.is_authenticated else None
       })
       
       # Return generic error to client
       return JsonResponse({
           'error': 'An internal error occurred',
           'error_code': 'INTERNAL_ERROR',
           'timestamp': timezone.now().isoformat()
       }, status=500)
   ```

3. **Data Encryption at Rest**
   ```python
   # encryption.py
   from cryptography.fernet import Fernet
   import base64
   import os
   
   class DataEncryption:
       def __init__(self):
           self.key = os.environ.get('ENCRYPTION_KEY')
           if not self.key:
               self.key = Fernet.generate_key().decode()
           self.cipher = Fernet(self.key.encode())
       
       def encrypt(self, data):
           """Encrypt sensitive data"""
           if isinstance(data, str):
               data = data.encode()
           encrypted = self.cipher.encrypt(data)
           return base64.b64encode(encrypted).decode()
       
       def decrypt(self, encrypted_data):
           """Decrypt sensitive data"""
           if isinstance(encrypted_data, str):
               encrypted_data = base64.b64decode(encrypted_data.encode())
           decrypted = self.cipher.decrypt(encrypted_data)
           return decrypted.decode()
   
   # Usage in models
   from django.db import models
   
   class EncryptedField(models.TextField):
       def __init__(self, *args, **kwargs):
           kwargs['blank'] = True
           super().__init__(*args, **kwargs)
       
       def from_db_value(self, value, expression, connection):
           if value is None:
               return value
           encryption = DataEncryption()
           return encryption.decrypt(value)
       
       def to_python(self, value):
           if value is None:
               return value
           if isinstance(value, str):
               return value
           return str(value)
       
       def get_prep_value(self, value):
           if value is None:
               return value
           encryption = DataEncryption()
           return encryption.encrypt(value)
   ```

### **Unauthorized Data Access**

#### Problem: Users accessing data they shouldn't see
**Symptoms:**
- Data visible to unauthorized users
- API endpoints returning sensitive data
- Permission bypass attempts

**Solutions:**

1. **Implement Row-Level Security**
   ```python
   # permissions.py
   from rest_framework.permissions import BasePermission
   
   class IsOwnerOrReadOnly(BasePermission):
       def has_object_permission(self, request, view, obj):
           if request.method in ['GET', 'HEAD', 'OPTIONS']:
               return True
           return obj.owner == request.user
   
   class ComplianceDataPermission(BasePermission):
       def has_permission(self, request, view):
           if not request.user.is_authenticated:
               return False
           
           # Check if user has access to the requested compliance framework
           framework_id = view.kwargs.get('framework_id')
           if framework_id:
               return request.user.has_perm('compliance.view_framework', framework_id)
           
           return True
   ```

2. **Data Access Auditing**
   ```python
   # models.py
   from django.db import models
   from django.contrib.auth import get_user_model
   
   User = get_user_model()
   
   class DataAccessLog(models.Model):
       user = models.ForeignKey(User, on_delete=models.CASCADE)
       action = models.CharField(max_length=50)  # 'view', 'edit', 'delete'
       resource_type = models.CharField(max_length=50)
       resource_id = models.CharField(max_length=100)
       ip_address = models.GenericIPAddressField()
       user_agent = models.TextField()
       timestamp = models.DateTimeField(auto_now_add=True)
       success = models.BooleanField(default=True)
       
       class Meta:
           indexes = [
               models.Index(fields=['user', 'timestamp']),
               models.Index(fields=['resource_type', 'resource_id']),
           ]
   
   # middleware.py
   class DataAccessMiddleware:
       def __init__(self, get_response):
           self.get_response = get_response
       
       def __call__(self, request):
           response = self.get_response(request)
           
           # Log data access for API endpoints
           if request.path.startswith('/api/') and request.method in ['GET', 'PUT', 'DELETE']:
               self.log_data_access(request, response)
           
           return response
       
       def log_data_access(self, request, response):
           if request.user.is_authenticated and response.status_code < 400:
               DataAccessLog.objects.create(
                   user=request.user,
                   action=self.get_action_from_method(request.method),
                   resource_type=self.get_resource_type(request.path),
                   resource_id=self.get_resource_id(request.path),
                   ip_address=self.get_client_ip(request),
                   user_agent=request.META.get('HTTP_USER_AGENT', ''),
                   success=response.status_code < 400
               )
   ```

## 🔍 Security Monitoring

### **Intrusion Detection**

#### Problem: Detecting security breaches
**Symptoms:**
- Unusual system behavior
- Suspicious network traffic
- Anomalous user activity

**Solutions:**

1. **Implement Security Monitoring**
   ```python
   # monitoring.py
   import logging
   from django.core.cache import cache
   from datetime import datetime, timedelta
   
   class SecurityMonitor:
       def __init__(self):
           self.logger = logging.getLogger('security')
       
       def detect_anomalies(self, request):
           anomalies = []
           
           # Check for unusual IP addresses
           if self.is_suspicious_ip(request):
               anomalies.append('suspicious_ip')
           
           # Check for rapid requests
           if self.is_rapid_requests(request):
               anomalies.append('rapid_requests')
           
           # Check for unusual user agent
           if self.is_unusual_user_agent(request):
               anomalies.append('unusual_user_agent')
           
           if anomalies:
               self.log_security_event(request, anomalies)
               return True
           
           return False
       
       def is_suspicious_ip(self, request):
           ip = self.get_client_ip(request)
           cache_key = f"ip_activity_{ip}"
           activity = cache.get(cache_key, {'count': 0, 'first_seen': datetime.now()})
           
           activity['count'] += 1
           cache.set(cache_key, activity, 3600)  # 1 hour
           
           # Flag if more than 1000 requests per hour
           return activity['count'] > 1000
       
       def is_rapid_requests(self, request):
           user_id = request.user.id if request.user.is_authenticated else None
           cache_key = f"rapid_requests_{user_id or self.get_client_ip(request)}"
           
           recent_requests = cache.get(cache_key, [])
           now = datetime.now()
           
           # Clean old requests (older than 1 minute)
           recent_requests = [req_time for req_time in recent_requests if now - req_time < timedelta(minutes=1)]
           
           recent_requests.append(now)
           cache.set(cache_key, recent_requests, 60)
           
           # Flag if more than 60 requests per minute
           return len(recent_requests) > 60
       
       def log_security_event(self, request, anomalies):
           self.logger.warning(
               f"Security anomalies detected: {', '.join(anomalies)}",
               extra={
                   'ip_address': self.get_client_ip(request),
                   'user': request.user.id if request.user.is_authenticated else None,
                   'path': request.path,
                   'method': request.method,
                   'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                   'anomalies': anomalies
               }
           )
   ```

2. **Automated Threat Response**
   ```python
   # threat_response.py
   class ThreatResponseSystem:
       def __init__(self):
           self.blocked_ips = set()
           self.suspicious_users = set()
       
       def handle_threat(self, threat_type, details):
           if threat_type == 'brute_force':
               self.block_ip(details['ip_address'])
           elif threat_type == 'suspicious_activity':
               self.flag_user(details['user_id'])
           elif threat_type == 'data_breach_attempt':
               self.trigger_emergency_response(details)
       
       def block_ip(self, ip_address):
           """Block IP address at firewall level"""
           self.blocked_ips.add(ip_address)
           
           # Add to firewall rules
           os.system(f"iptables -A INPUT -s {ip_address} -j DROP")
           
           # Log the blocking action
           logging.warning(f"IP address {ip_address} blocked due to suspicious activity")
       
       def flag_user(self, user_id):
           """Flag user account for review"""
           self.suspicious_users.add(user_id)
           
           # Require additional authentication
           User.objects.filter(id=user_id).update(
               requires_mfa=True,
               is_active=False  # Temporarily disable
           )
           
           # Notify security team
           self.notify_security_team(f"User {user_id} flagged for suspicious activity")
       
       def trigger_emergency_response(self, details):
           """Trigger emergency security response"""
           # Block all access temporarily
           os.system("iptables -A INPUT -j DROP")
           
           # Notify all administrators
           self.notify_all_admins("EMERGENCY: Potential data breach detected")
           
           # Start incident response procedures
           self.start_incident_response()
   ```

## 🔧 Security Configuration Issues

### **SSL/TLS Problems**

#### Problem: SSL/TLS configuration issues
**Symptoms:**
- Certificate errors
- Mixed content warnings
- Insecure connection warnings

**Solutions:**

1. **Fix SSL Configuration**
   ```nginx
   # nginx.conf
   server {
       listen 443 ssl http2;
       listen [::]:443 ssl http2;
       
       # SSL configuration
       ssl_certificate /etc/ssl/certs/studio.crt;
       ssl_certificate_key /etc/ssl/private/studio.key;
       
       # Strong SSL configuration
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
       ssl_prefer_server_ciphers off;
       ssl_session_cache shared:SSL:10m;
       ssl_session_timeout 10m;
       
       # HSTS
       add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
       
       # Other security headers
       add_header X-Frame-Options DENY;
       add_header X-Content-Type-Options nosniff;
       add_header X-XSS-Protection "1; mode=block";
       add_header Referrer-Policy "strict-origin-when-cross-origin";
   }
   ```

2. **Automated Certificate Management**
   ```bash
   #!/bin/bash
   # cert-renewal.sh
   
   # Check certificate expiration
   cert_file="/etc/ssl/certs/studio.crt"
   expiration_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
   expiration_timestamp=$(date -d "$expiration_date" +%s)
   current_timestamp=$(date +%s)
   days_until_expiration=$(( (expiration_timestamp - current_timestamp) / 86400 ))
   
   # Renew if expiring within 30 days
   if [ $days_until_expiration -lt 30 ]; then
       echo "Certificate expiring in $days_until_expiration days. Renewing..."
       certbot renew --quiet
       
       # Reload nginx
       docker-compose exec nginx nginx -s reload
       
       echo "Certificate renewed and nginx reloaded."
   else
       echo "Certificate is valid for $days_until_expiration more days."
   fi
   ```

### **Security Headers**

#### Problem: Missing security headers
**Symptoms:**
- Vulnerable to XSS attacks
- Clickjacking vulnerabilities
- Content type sniffing issues

**Solutions:**

1. **Implement Security Headers Middleware**
   ```python
   # middleware.py
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
   ```

## 📊 Security Auditing

### **Regular Security Checks**

#### Problem: Identifying security vulnerabilities
**Symptoms:**
- Unknown security gaps
- Outdated dependencies
- Misconfigured permissions

**Solutions:**

1. **Automated Security Scanning**
   ```python
   # security_audit.py
   import subprocess
   import json
   from datetime import datetime
   
   class SecurityAuditor:
       def __init__(self):
           self.findings = []
       
       def run_vulnerability_scan(self):
           """Run vulnerability scanner on dependencies"""
           try:
               result = subprocess.run(
                   ['safety', 'check', '--json'],
                   capture_output=True,
                   text=True
               )
               
               if result.stdout:
                   vulnerabilities = json.loads(result.stdout)
                   for vuln in vulnerabilities:
                       self.add_finding(
                           'vulnerability',
                           f"Dependency {vuln['package']} has vulnerability: {vuln['advisory']}",
                           severity=vuln.get('vulnerability', 'medium')
                       )
           except Exception as e:
               self.add_finding('error', f"Vulnerability scan failed: {str(e)}")
       
       def check_configuration_security(self):
           """Check for security configuration issues"""
           
           # Check debug mode
           if settings.DEBUG:
               self.add_finding('configuration', 'DEBUG mode is enabled in production', 'high')
           
           # Check secret key
           if settings.SECRET_KEY == 'your-secret-key':
               self.add_finding('configuration', 'Default SECRET_KEY is being used', 'critical')
           
           # Check database settings
           if settings.DATABASES['default']['PASSWORD'] == 'password':
               self.add_finding('configuration', 'Default database password is being used', 'critical')
       
       def check_file_permissions(self):
           """Check file permissions for security"""
           import os
           import stat
           
           sensitive_files = [
               '/app/.env',
               '/app/settings.py',
               '/app/requirements.txt'
           ]
           
           for file_path in sensitive_files:
               if os.path.exists(file_path):
                   file_stat = os.stat(file_path)
                   mode = file_stat.st_mode
                   
                   # Check if file is world-readable
                   if mode & stat.S_IROTH:
                       self.add_finding('permissions', f'File {file_path} is world-readable', 'medium')
       
       def add_finding(self, category, description, severity='medium'):
           self.findings.append({
               'category': category,
               'description': description,
               'severity': severity,
               'timestamp': datetime.now().isoformat()
           })
       
       def generate_report(self):
           """Generate security audit report"""
           return {
               'scan_date': datetime.now().isoformat(),
               'total_findings': len(self.findings),
               'findings_by_severity': {
                   'critical': len([f for f in self.findings if f['severity'] == 'critical']),
                   'high': len([f for f in self.findings if f['severity'] == 'high']),
                   'medium': len([f for f in self.findings if f['severity'] == 'medium']),
                   'low': len([f for f in self.findings if f['severity'] == 'low'])
               },
               'findings': self.findings
           }
   
   # Usage
   auditor = SecurityAuditor()
   auditor.run_vulnerability_scan()
   auditor.check_configuration_security()
   auditor.check_file_permissions()
   report = auditor.generate_report()
   print(json.dumps(report, indent=2))
   ```

2. **Security Compliance Check**
   ```python
   # compliance_check.py
   class SecurityComplianceChecker:
       def __init__(self):
           self.compliance_standards = {
               'OWASP': self.check_owasp_compliance,
               'SOC2': self.check_soc2_compliance,
               'ISO27001': self.check_iso27001_compliance
           }
       
       def check_owasp_compliance(self):
           """Check OWASP Top 10 compliance"""
           checks = {
               'A01_Broken_Access_Control': self.check_access_control,
               'A02_Cryptographic_Failures': self.check_cryptography,
               'A03_Injection': self.check_injection_protection,
               'A04_Insecure_Design': self.check_secure_design,
               'A05_Security_Misconfiguration': self.check_security_configuration,
               'A06_Vulnerable_Components': self.check_vulnerable_components,
               'A07_Identification_Authentication_Failures': self.check_authentication,
               'A08_Software_Data_Integrity_Failures': self.check_integrity,
               'A09_Security_Logging_Monitoring': self.check_logging_monitoring,
               'A10_Server_Side_Request_Forgery': self.check_ssrf_protection
           }
           
           results = {}
           for check_name, check_func in checks.items():
               results[check_name] = check_func()
           
           return results
       
       def check_access_control(self):
           """Check for proper access control"""
           findings = []
           
           # Check for default admin credentials
           if User.objects.filter(username='admin', is_superuser=True).exists():
               findings.append('Default admin account exists')
           
           # Check for unprotected admin endpoints
           try:
               response = requests.get('http://localhost:8000/admin/', timeout=5)
               if response.status_code == 200:
                   findings.append('Admin interface is accessible without authentication')
           except:
               pass
           
           return findings
       
       def check_cryptography(self):
           """Check for proper cryptographic implementation"""
           findings = []
           
           # Check for weak encryption
           if 'DES' in open('/app/settings.py').read():
               findings.append('Weak encryption algorithm (DES) found in configuration')
           
           # Check for hardcoded secrets
           if 'SECRET_KEY = ' in open('/app/settings.py').read() and 'your-secret-key' in open('/app/settings.py').read():
               findings.append('Hardcoded secret key found')
           
           return findings
   ```

---

!!! tip "Security Monitoring"
    Implement continuous security monitoring with automated alerts for suspicious activities and configuration changes.

!!! warning "Incident Response"
    Have a documented incident response plan and conduct regular drills to ensure team readiness for security incidents.

!!! note "Regular Audits"
    Schedule regular security audits and penetration testing to identify vulnerabilities before they can be exploited.
