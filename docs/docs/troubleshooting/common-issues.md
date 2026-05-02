# Common Issues and Solutions

This document covers the most frequently encountered issues with the Studio Platform and their step-by-step solutions.

## 🚨 Quick Fixes

### **System Not Responding**
```bash
# 1. Check if services are running
docker-compose ps

# 2. Restart services if needed
docker-compose restart

# 3. Check system resources
docker stats

# 4. Clear system cache
docker-compose exec backend python manage.py clear_cache
```

### **Cannot Access Web Interface**
```bash
# 1. Check if web server is running
curl -I http://localhost:8000

# 2. Check port availability
netstat -tulpn | grep :8000

# 3. Check firewall settings
sudo ufw status

# 4. Restart web service
docker-compose restart frontend
```

### **Database Connection Issues**
```bash
# 1. Test database connectivity
docker-compose exec db psql -U studio_user -d studio_db -c "SELECT 1;"

# 2. Check database logs
docker-compose logs db

# 3. Restart database service
docker-compose restart db

# 4. Check database configuration
docker-compose exec db cat /var/lib/postgresql/data/postgresql.conf
```

## 🔐 Authentication Issues

### **Login Failures**

#### Problem: Users cannot log in
**Symptoms:**
- Invalid credentials error
- Login page redirects to itself
- Authentication loop

**Solutions:**

1. **Check User Credentials**
   ```sql
   -- Verify user exists in database
   SELECT username, email, is_active, last_login 
   FROM auth_user 
   WHERE username = 'problem_user';
   ```

2. **Reset User Password**
   ```bash
   # Reset password via command line
   docker-compose exec backend python manage.py changepassword username
   ```

3. **Check Authentication Configuration**
   ```yaml
   # Check authentication settings in docker-compose.yml
   environment:
     - AUTHENTICATION_BACKEND=django.contrib.auth.backends.ModelBackend
     - LOGIN_URL=/login/
     - LOGIN_REDIRECT_URL=/dashboard/
   ```

4. **Clear Session Data**
   ```bash
   # Clear all sessions
   docker-compose exec backend python manage.py clearsessions
   ```

### **Token Expiration Issues**

#### Problem: API tokens expire frequently
**Symptoms:**
- 401 Unauthorized errors
- Frequent re-authentication required
- Session timeout errors

**Solutions:**

1. **Adjust Token Expiration**
   ```python
   # settings.py
   SIMPLE_JWT = {
       'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
       'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
       'ROTATE_REFRESH_TOKENS': True,
   }
   ```

2. **Implement Token Refresh**
   ```javascript
   // Frontend token refresh logic
   async function refreshToken() {
       try {
           const response = await fetch('/api/token/refresh/', {
               method: 'POST',
               headers: {
                   'Content-Type': 'application/json',
               },
               body: JSON.stringify({
                   refresh: localStorage.getItem('refreshToken')
               })
           });
           
           const data = await response.json();
           localStorage.setItem('accessToken', data.access);
       } catch (error) {
           console.error('Token refresh failed:', error);
           // Redirect to login
           window.location.href = '/login/';
       }
   }
   ```

### **Permission Issues**

#### Problem: Users cannot access certain features
**Symptoms:**
- Access denied errors
- Missing menu items
- 403 Forbidden errors

**Solutions:**

1. **Check User Permissions**
   ```sql
   -- Check user groups and permissions
   SELECT 
       u.username,
       g.name as group_name,
       p.name as permission_name
   FROM auth_user u
   LEFT JOIN auth_user_groups ug ON u.id = ug.user_id
   LEFT JOIN auth_group g ON ug.group_id = g.id
   LEFT JOIN auth_group_permissions gp ON g.id = gp.group_id
   LEFT JOIN auth_permission p ON gp.permission_id = p.id
   WHERE u.username = 'problem_user';
   ```

2. **Assign Required Permissions**
   ```bash
   # Add user to group
   docker-compose exec backend python manage.py add_user_to_group username group_name
   
   # Assign specific permission
   docker-compose exec backend python manage.py add_permission username permission_codename
   ```

## 📁 File and Upload Issues

### **File Upload Failures**

#### Problem: Cannot upload files
**Symptoms:**
- Upload progress bar hangs
- File size limit errors
- Unsupported file type errors

**Solutions:**

1. **Check File Size Limits**
   ```python
   # settings.py
   FILE_UPLOAD_MAX_MEMORY_SIZE = 52428800  # 50MB
   DATA_UPLOAD_MAX_MEMORY_SIZE = 52428800  # 50MB
   MEDIA_ROOT = '/app/media/'
   ```

2. **Check Storage Permissions**
   ```bash
   # Check media directory permissions
   ls -la /app/media/
   
   # Fix permissions if needed
   sudo chown -R www-data:www-data /app/media/
   sudo chmod -R 755 /app/media/
   ```

3. **Check Disk Space**
   ```bash
   # Check available disk space
   df -h
   
   # Clean up old files if needed
   find /app/media/ -type f -mtime +30 -delete
   ```

### **Evidence Collection Issues**

#### Problem: Evidence not appearing in system
**Symptoms:**
- Uploaded files not showing
- Metadata not being processed
- Indexing delays

**Solutions:**

1. **Check Processing Queue**
   ```bash
   # Check Celery workers
   docker-compose exec worker celery -A studio worker status
   
   # Restart worker if needed
   docker-compose restart worker
   ```

2. **Manually Trigger Processing**
   ```bash
   # Trigger evidence processing
   docker-compose exec backend python manage.py process_evidence --evidence-id 123
   ```

3. **Check Indexing Status**
   ```bash
   # Rebuild search index
   docker-compose exec backend python manage.py rebuild_index
   ```

## 🌐 Network and Connectivity Issues

### **API Connection Problems**

#### Problem: API endpoints not responding
**Symptoms:**
- Connection timeout errors
- 502 Bad Gateway errors
- Slow API responses

**Solutions:**

1. **Check API Service Status**
   ```bash
   # Check if API service is running
   docker-compose exec backend curl -I http://localhost:8000/api/health
   
   # Check API logs
   docker-compose logs backend
   ```

2. **Check Load Balancer Configuration**
   ```nginx
   # nginx.conf
   upstream backend {
       server backend:8000;
       keepalive 32;
   }
   
   server {
       listen 80;
       location /api/ {
           proxy_pass http://backend;
           proxy_set_header Host $host;
           proxy_connect_timeout 30s;
           proxy_send_timeout 30s;
           proxy_read_timeout 30s;
       }
   }
   ```

3. **Check Database Connection Pool**
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
           }
       }
   }
   ```

### **Integration Failures**

#### Problem: Third-party integrations not working
**Symptoms:**
- Integration status shows disconnected
- Data not syncing from external services
- Webhook failures

**Solutions:**

1. **Check API Credentials**
   ```bash
   # Test integration API connectivity
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        https://api.thirdparty.com/endpoint
   
   # Check stored credentials
   docker-compose exec backend python manage.py check_integration --name integration_name
   ```

2. **Verify Webhook Configuration**
   ```bash
   # Test webhook endpoint
   curl -X POST https://studio.example.com/webhooks/integration \
        -H "Content-Type: application/json" \
        -d '{"test": "data"}'
   
   # Check webhook logs
   docker-compose logs | grep webhook
   ```

3. **Reconfigure Integration**
   ```bash
   # Reset integration configuration
   docker-compose exec backend python manage.py reset_integration --name integration_name
   
   # Re-authenticate
   docker-compose exec backend python manage.py authenticate_integration --name integration_name
   ```

## 🐛 Performance Issues

### **Slow Response Times**

#### Problem: System responds slowly
**Symptoms:**
- Page load times > 5 seconds
- API calls timing out
- High CPU usage

**Solutions:**

1. **Check System Resources**
   ```bash
   # Check CPU and memory usage
   docker stats
   
   # Check database performance
   docker-compose exec db psql -U studio_user -d studio_db -c "
   SELECT query, calls, total_time, mean_time 
   FROM pg_stat_statements 
   ORDER BY total_time DESC 
   LIMIT 10;"
   ```

2. **Optimize Database Queries**
   ```sql
   -- Add indexes for slow queries
   CREATE INDEX idx_evidence_created_at ON evidence_evidence(created_at);
   CREATE INDEX idx_compliance_framework ON compliance_compliance(framework_id);
   ```

3. **Enable Caching**
   ```python
   # settings.py
   CACHES = {
       'default': {
           'BACKEND': 'django_redis.cache.RedisCache',
           'LOCATION': 'redis://redis:6379/1',
           'OPTIONS': {
               'CLIENT_CLASS': 'django_redis.client.DefaultClient',
           }
       }
   }
   
   # Cache expensive queries
   @cache_page(300)  # 5 minutes
   def compliance_dashboard(request):
       # Dashboard logic here
       pass
   ```

### **Memory Leaks**

#### Problem: Memory usage increases over time
**Symptoms:**
- Out of memory errors
- Container restarts
- System becomes unresponsive

**Solutions:**

1. **Monitor Memory Usage**
   {% raw %}
   ```bash
   # Monitor memory usage over time
   docker stats --format "table &#123;&#123;.Container&#125;&#125;\t&#123;&#123;.CPUPerc&#125;&#125;\t&#123;&#123;.MemUsage&#125;&#125;\t&#123;&#123;.MemPerc&#125;&#125;"
   
   # Check for memory leaks
   docker-compose exec backend python -m memory_profiler manage.py runserver
   ```
   {% endraw %}

2. **Optimize Code**
   ```python
   # Use generators instead of lists for large datasets
   def get_large_dataset():
       for item in queryset.iterator():
           yield item
   
   # Clear unused objects
   import gc
   gc.collect()
   ```

3. **Adjust Memory Limits**
   ```yaml
   # docker-compose.yml
   services:
     backend:
       deploy:
         resources:
           limits:
             memory: 2G
           reservations:
             memory: 1G
   ```

## 📊 Data Issues

### **Data Corruption**

#### Problem: Database data appears corrupted
**Symptoms:**
- Inconsistent data
- Missing records
- Incorrect calculations

**Solutions:**

1. **Check Database Integrity**
   ```bash
   # Run database consistency check
   docker-compose exec db pg_dump -U studio_user studio_db > backup.sql
   docker-compose exec db psql -U studio_user studio_db -c "SELECT * FROM pg_stat_user_tables;"
   ```

2. **Restore from Backup**
   ```bash
   # Restore from recent backup
   docker-compose exec db psql -U studio_user studio_db < backup.sql
   ```

3. **Run Data Validation**
   ```bash
   # Validate data integrity
   docker-compose exec backend python manage.py validate_data
   ```

### **Sync Issues**

#### Problem: Data not syncing between components
**Symptoms:**
- Different systems show different data
- Updates not reflected everywhere
- Inconsistent reporting

**Solutions:**

1. **Check Sync Status**
   ```bash
   # Check sync queue
   docker-compose exec worker celery -A studio inspect active
   
   # Check last sync time
   docker-compose exec backend python manage.py check_sync_status
   ```

2. **Force Full Sync**
   ```bash
   # Trigger full synchronization
   docker-compose exec backend python manage.py full_sync --integration integration_name
   ```

3. **Verify Sync Configuration**
   ```yaml
   # Check sync settings
   sync_settings:
     interval: 300  # 5 minutes
     batch_size: 100
     retry_attempts: 3
     timeout: 60
   ```

## 🔄 Configuration Issues

### **Environment Variable Problems**

#### Problem: Configuration not being applied
**Symptoms:**
- Default settings being used
- Environment changes not taking effect
- Incorrect behavior

**Solutions:**

1. **Check Environment Variables**
   ```bash
   # List current environment variables
   docker-compose exec backend env | grep STUDIO_
   
   # Check .env file
   cat .env
   ```

2. **Restart Services with New Config**
   ```bash
   # Recreate containers with new environment
   docker-compose down
   docker-compose up -d
   ```

3. **Verify Configuration Loading**
   ```python
   # Check if settings are loaded correctly
   import os
   print(f"DEBUG: {os.getenv('DEBUG', 'Not set')}")
   print(f"DATABASE_URL: {os.getenv('DATABASE_URL', 'Not set')}")
   ```

### **SSL/TLS Issues**

#### Problem: HTTPS not working
**Symptoms:**
- Certificate errors
- Mixed content warnings
- Insecure connection warnings

**Solutions:**

1. **Check Certificate Validity**
   ```bash
   # Check SSL certificate
   openssl x509 -in /path/to/cert.pem -text -noout
   
   # Check certificate expiration
   openssl x509 -in /path/to/cert.pem -noout -dates
   ```

2. **Verify Certificate Chain**
   ```bash
   # Test SSL configuration
   openssl s_client -connect studio.example.com:443 -servername studio.example.com
   ```

3. **Update Certificate**
   ```bash
   # Renew Let's Encrypt certificate
   certbot renew --dry-run
   certbot renew
   ```

## 📞 When to Contact Support

### **Critical Issues**
- Complete system outage
- Data loss or corruption
- Security breaches
- Performance degradation affecting all users

### **Information to Provide**
1. **Error Messages** - Exact error text and screenshots
2. **System Information** - Platform version, browser, OS
3. **Timeline** - When the issue started and any patterns
4. **Recent Changes** - Updates, configuration changes, deployments
5. **Impact** - Number of affected users and business impact

### **Support Channels**
- **Emergency**: +1-555-STUDIO (24/7)
- **Standard**: support@cybergaar.com
- **Portal**: support.cybergaar.com
- **Chat**: Available on website

---

!!! tip "Preventive Maintenance"
    Regular system maintenance and monitoring can prevent many of these common issues. Set up automated alerts for system health metrics.

!!! warning "Before Making Changes"
    Always create a backup before applying fixes to production systems. Test solutions in a staging environment first.

!!! note "Documentation Updates"
    If you encounter an issue not covered here, please document the solution to help others in the future.
