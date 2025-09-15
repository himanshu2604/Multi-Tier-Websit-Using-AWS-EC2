# 🔧 Multi-Tier Website Troubleshooting Guide

## Quick Reference

### Common Issues
1. [Website Not Loading](#website-not-loading)
2. [Database Connection Issues](#database-connection-issues)
3. [Auto Scaling Not Working](#auto-scaling-not-working)
4. [Load Balancer Issues](#load-balancer-issues)
5. [High Response Times](#high-response-times)
6. [SSL/Security Issues](#ssl-security-issues)

---

## Website Not Loading

### Symptom
- Browser shows "This site can't be reached" or timeout errors
- 502/503/504 HTTP errors

### Diagnostic Steps
```bash
# Check Load Balancer status
aws elbv2 describe-load-balancers --names abc-company-alb

# Check Target Group health
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>

# Check Security Group rules
aws ec2 describe-security-groups --group-names abc-company-web-sg
```

### Common Causes & Solutions

#### Load Balancer Security Group
**Problem**: ALB security group doesn't allow HTTP/HTTPS traffic
```bash
# Fix: Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id <ALB_SG_ID> \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id <ALB_SG_ID> \
  --protocol tcp --port 443 --cidr 0.0.0.0/0
```

#### Target Group Health Issues
**Problem**: No healthy targets in target group
```bash
# Check instance health
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID>

# Check application logs
sudo tail -f /var/log/httpd/error_log
sudo systemctl status httpd
```

**Solutions**:
- Restart Apache: `sudo systemctl restart httpd`
- Check user data script execution: `sudo tail -f /var/log/cloud-init-output.log`
- Verify application code: `ls -la /var/www/html/`

#### Subnet Configuration
**Problem**: Instances in wrong subnets
- **Fix**: Ensure Auto Scaling Group uses private subnets
- **Fix**: Ensure Load Balancer uses public subnets

---

## Database Connection Issues

### Symptom
- "Connection failed" error messages
- PHP PDO exceptions
- Database timeout errors

### Diagnostic Steps
```bash
# Test database connectivity from EC2 instance
mysql -h <RDS_ENDPOINT> -u intel -p

# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier abc-company-db

# Check security group rules for RDS
aws ec2 describe-security-groups --group-names abc-company-db-sg
```

### Common Causes & Solutions

#### Security Group Configuration
**Problem**: Database security group doesn't allow connections from web tier
```bash
# Fix: Allow MySQL traffic from web tier
aws ec2 authorize-security-group-ingress \
  --group-id <DB_SG_ID> \
  --protocol tcp --port 3306 \
  --source-group <WEB_SG_ID>
```

#### RDS Subnet Group Issues
**Problem**: RDS in wrong subnet group
- **Check**: RDS must be in private subnets
- **Fix**: Modify RDS subnet group if necessary

#### Database Endpoint Configuration
**Problem**: Wrong RDS endpoint in application code
```bash
# Get correct RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier abc-company-db \
  --query 'DBInstances[0].Endpoint.Address' --output text

# Update application configuration
sudo sed -i 's/OLD_ENDPOINT/NEW_ENDPOINT/g' /var/www/html/index.php
sudo systemctl restart httpd
```

#### Database Credentials
**Problem**: Incorrect database credentials
```sql
-- Verify database user exists
SELECT User, Host FROM mysql.user WHERE User = 'intel';

-- Reset password if needed
ALTER USER 'intel'@'%' IDENTIFIED BY 'intel123';
FLUSH PRIVILEGES;
```

---

## Auto Scaling Not Working

### Symptom
- No new instances launching during high load
- Instances not terminating during low load
- Scaling events not triggered

### Diagnostic Steps
```bash
# Check Auto Scaling Group status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names abc-company-asg

# Check scaling policies
aws autoscaling describe-policies --auto-scaling-group-name abc-company-asg

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names <ALARM_NAME>

# Check scaling activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name abc-company-asg
```

### Common Causes & Solutions

#### CloudWatch Alarms Not Triggering
**Problem**: CPU metrics not being collected
```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=abc-company-asg \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average
```

**Solutions**:
- Ensure CloudWatch agent is installed
- Verify IAM role permissions for CloudWatch
- Check alarm thresholds are appropriate

#### Launch Template Issues
**Problem**: Launch template configuration errors
```bash
# Verify launch template
aws ec2 describe-launch-templates --launch-template-names abc-company-web-template

# Check latest version
aws ec2 describe-launch-template-versions --launch-template-name abc-company-web-template
```

**Solutions**:
- Update launch template with correct configuration
- Ensure security group exists and is accessible
- Verify user data script syntax

#### Insufficient Capacity
**Problem**: AWS capacity constraints
- **Check**: Try different instance types or AZs
- **Monitor**: AWS Service Health Dashboard
- **Solution**: Use multiple instance types in ASG

---

## Load Balancer Issues

### Symptom
- Uneven traffic distribution
- Sticky sessions not working
- Health checks failing

### Diagnostic Steps
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>

# Check load balancer attributes
aws elbv2 describe-load-balancer-attributes --load-balancer-arn <ALB_ARN>

# Monitor target group metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=TargetGroup,Value=<TARGET_GROUP_FULL_NAME> \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average
```

### Common Causes & Solutions

#### Health Check Configuration
**Problem**: Health checks too aggressive or misconfigured
```bash
# Modify health check settings
aws elbv2 modify-target-group \
  --target-group-arn <TARGET_GROUP_ARN> \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 5 \
  --health-check-timeout-seconds 10
```

#### Application Not Ready
**Problem**: Application starts before dependencies are ready
- **Solution**: Add dependency checks in user data
- **Solution**: Increase health check grace period in ASG

#### Cross-Zone Load Balancing
**Problem**: Uneven distribution across AZs
```bash
# Enable cross-zone load balancing
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn <ALB_ARN> \
  --attributes Key=load_balancing.cross_zone.enabled,Value=true
```

---

## High Response Times

### Symptom
- Slow page loading (>5 seconds)
- Database query timeouts
- High CPU utilization

### Diagnostic Steps
```bash
# Check application performance
ab -n 100 -c 10 http://<ALB_DNS_NAME>/

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average,Maximum

# Check database performance
aws rds describe-db-instances --db-instance-identifier abc-company-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### Common Causes & Solutions

#### Database Performance Issues
**Problem**: Slow database queries
```sql
-- Check for slow queries
SHOW PROCESSLIST;

-- Optimize table
OPTIMIZE TABLE data;

-- Add indexes if needed
CREATE INDEX idx_email ON data(email);
CREATE INDEX idx_created_at ON data(created_at);
```

**Solutions**:
- Enable RDS Performance Insights
- Consider database connection pooling
- Optimize database parameters

#### Insufficient Instance Resources
**Problem**: t2.micro instances overwhelmed
- **Solution**: Upgrade to larger instance type
- **Solution**: Ensure proper auto-scaling triggers
- **Solution**: Optimize application code

#### Network Latency
**Problem**: Cross-AZ database calls
- **Solution**: Use RDS Proxy for connection pooling
- **Solution**: Implement application-level caching
- **Solution**: Optimize database queries

---

## SSL/Security Issues

### Symptom
- Mixed content warnings
- Certificate errors
- Security group access denied

### Diagnostic Steps
```bash
# Test SSL certificate
openssl s_client -connect <ALB_DNS_NAME>:443 -servername <ALB_DNS_NAME>

# Check security group rules
aws ec2 describe-security-groups --group-ids <SECURITY_GROUP_ID>

# Verify HTTPS listener
aws elbv2 describe-listeners --load-balancer-arn <ALB_ARN>
```

### Common Causes & Solutions

#### SSL Certificate Issues
**Problem**: Self-signed or expired certificates
```bash
# Request ACM certificate
aws acm request-certificate \
  --domain-name example.com \
  --validation-method DNS

# Add HTTPS listener to ALB
aws elbv2 create-listener \
  --load-balancer-arn <ALB_ARN> \
  --protocol HTTPS --port 443 \
  --default-actions Type=forward,TargetGroupArn=<TARGET_GROUP_ARN> \
  --certificates CertificateArn=<ACM_CERT_ARN>
```

#### Security Group Misconfigurations
**Problem**: Overly restrictive or permissive rules
- **Fix**: Review and minimize security group rules
- **Fix**: Use principle of least privilege
- **Fix**: Implement security group references instead of CIDR blocks

---

## Performance Optimization Tips

### Application Level
```php
// Enable PHP OPcache
; Add to php.ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=4000

// Database connection optimization
$pdo = new PDO($dsn, $user, $pass, [
    PDO::ATTR_PERSISTENT => true,
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8"
]);
```

### Infrastructure Level
```bash
# Enable gzip compression in Apache
echo "LoadModule deflate_module modules/mod_deflate.so" >> /etc/httpd/conf.modules.d/00-base.conf
echo "<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \\.(?:gif|jpe?g|png)$ no-gzip dont-vary
</Location>" >> /etc/httpd/conf/httpd.conf
```

### Database Optimization
```sql
-- Optimize MySQL configuration
SET GLOBAL innodb_buffer_pool_size = 128M;
SET GLOBAL query_cache_size = 32M;
SET GLOBAL query_cache_type = ON;

-- Regular maintenance
ANALYZE TABLE data;
OPTIMIZE TABLE data;
```

## Monitoring Commands

### Real-time Monitoring
```bash
# Monitor Auto Scaling events
watch -n 10 "aws autoscaling describe-scaling-activities --auto-scaling-group-name abc-company-asg --max-items 5"

# Monitor target health
watch -n 5 "aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>"

# Monitor CloudWatch logs
aws logs tail /aws/ec2/user-data --follow

# Monitor application logs
sudo tail -f /var/log/httpd/access_log
sudo tail -f /var/log/httpd/error_log
```

### Performance Monitoring
```bash
# CPU and Memory usage
top -p $(pgrep httpd | tr '\n' ',' | sed 's/,$//')

# Database connections
mysql -h <RDS_ENDPOINT> -u intel -p -e "SHOW STATUS LIKE 'Threads_connected';"

# Network statistics
netstat -an | grep :80 | wc -l
```

## Emergency Contacts

### AWS Support
- **Business Support**: Available via AWS Console
- **Enterprise Support**: 24/7 phone support

### Internal Team
- **DevOps Team**: devops@company.com
- **Database Team**: dba@company.com
- **Security Team**: security@company.com
- **On-call Engineer**: +1-XXX-XXX-XXXX

### Escalation Procedures
1. **Level 1**: Application team investigates (30 min)
2. **Level 2**: DevOps team engaged (60 min)
3. **Level 3**: AWS Support case opened (immediate)
4. **Level 4**: Management notification (critical issues)

---

**Last Updated**: September 15, 2025
**Version**: 1.0
**Maintained by**: DevOps Team