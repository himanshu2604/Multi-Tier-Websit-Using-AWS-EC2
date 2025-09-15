# 📊 Performance Monitoring & Optimization Guide

## Overview

This guide covers comprehensive performance monitoring, metrics collection, and optimization strategies for the Multi-Tier Website architecture on AWS.

## Table of Contents
1. [Key Performance Indicators](#key-performance-indicators)
2. [CloudWatch Metrics Setup](#cloudwatch-metrics-setup)
3. [Performance Benchmarks](#performance-benchmarks)
4. [Monitoring Dashboards](#monitoring-dashboards)
5. [Alerting Configuration](#alerting-configuration)
6. [Optimization Strategies](#optimization-strategies)
7. [Load Testing](#load-testing)

---

## Key Performance Indicators

### Application Performance Metrics
- **Response Time**: <200ms (target), <500ms (acceptable)
- **Throughput**: 100+ requests/second
- **Error Rate**: <0.1%
- **Availability**: 99.9% uptime
- **Concurrent Users**: 500+ simultaneous users

### Infrastructure Metrics
- **CPU Utilization**: <70% average, <90% peak
- **Memory Usage**: <80% of available RAM
- **Network I/O**: <80% of instance bandwidth
- **Disk I/O**: <1000 IOPS sustained
- **Auto Scaling Response**: <5 minutes to scale out

### Database Performance Metrics
- **Connection Time**: <50ms
- **Query Response**: <20ms for simple queries
- **Database CPU**: <60% average
- **Database Connections**: <80% of max connections
- **Read/Write Latency**: <10ms

---

## CloudWatch Metrics Setup

### EC2 Instance Metrics

#### Standard Metrics (Automatic)
```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average,Maximum

# Network In/Out
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkIn \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Sum
```

#### Custom Metrics (Manual Setup)
```bash
# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# CloudWatch Agent Configuration (JSON)
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "ABC-Company/WebTier",
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 300
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 300,
                "resources": ["*"]
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_listen"],
                "metrics_collection_interval": 300
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/apache/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/apache/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
```

### Load Balancer Metrics

```bash
# Request Count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=app/abc-company-alb/50dc6c495c0c9188 \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Sum

# Target Response Time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/abc-company-alb/50dc6c495c0c9188 \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average

# HTTP Error Codes
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/abc-company-alb/50dc6c495c0c9188 \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Sum
```

### RDS Database Metrics

```bash
# Database CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=abc-company-db \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average

# Database Connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=abc-company-db \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average

# Read/Write Latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name ReadLatency \
  --dimensions Name=DBInstanceIdentifier,Value=abc-company-db \
  --start-time 2025-09-15T10:00:00Z \
  --end-time 2025-09-15T11:00:00Z \
  --period 300 --statistics Average
```

---

## Performance Benchmarks

### Baseline Performance Tests

#### Response Time Benchmark
```bash
# Simple load test
ab -n 1000 -c 10 http://abc-company-alb-1234567890.us-east-1.elb.amazonaws.com/

# Expected Results:
# Requests per second: 50-100 RPS
# Time per request: 100-200ms
# Transfer rate: 500KB/sec

# Database interaction test
ab -n 500 -c 5 -p post_data.txt -T 'application/x-www-form-urlencoded' \
  http://abc-company-alb-1234567890.us-east-1.elb.amazonaws.com/

# post_data.txt content:
# firstname=TestUser&email=test@example.com&submit=Add Record
```

#### Sustained Load Test
```bash
# 10-minute sustained test
ab -n 6000 -c 50 -t 600 http://abc-company-alb-1234567890.us-east-1.elb.amazonaws.com/

# Monitor during test:
watch -n 5 "aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>"
```

#### Auto Scaling Trigger Test
```bash
# Generate CPU load to trigger scaling
stress --cpu 2 --timeout 300s  # Run on EC2 instances

# Monitor scaling activity
watch -n 10 "aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name abc-company-asg --max-items 3"
```

### Performance Thresholds

| Metric | Good | Warning | Critical | Action |
|--------|------|---------|----------|--------|
| **Response Time** | <200ms | 200-500ms | >500ms | Scale out |
| **Error Rate** | <0.1% | 0.1-1% | >1% | Investigate |
| **CPU Usage** | <50% | 50-70% | >70% | Scale out |
| **Memory Usage** | <60% | 60-80% | >80% | Optimize |
| **DB Connections** | <50% | 50-80% | >80% | Connection pooling |
| **DB CPU** | <40% | 40-60% | >60% | Optimize queries |

---

## Monitoring Dashboards

### CloudWatch Dashboard Configuration

```json
{
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/abc-company-alb/50dc6c495c0c9188" ],
                    [ ".", "TargetResponseTime", ".", "." ],
                    [ ".", "HTTPCode_Target_2XX_Count", ".", "." ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Load Balancer Performance"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "abc-company-asg" ],
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "abc-company-asg" ],
                    [ ".", "GroupInServiceInstances", ".", "." ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Auto Scaling Metrics"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "abc-company-db" ],
                    [ ".", "DatabaseConnections", ".", "." ],
                    [ ".", "ReadLatency", ".", "." ],
                    [ ".", "WriteLatency", ".", "." ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Database Performance"
            }
        }
    ]
}
```

### Custom Application Metrics

```bash
# Create custom metric for application errors
aws cloudwatch put-metric-data \
  --namespace "ABC-Company/Application" \
  --metric-data MetricName=ApplicationErrors,Value=1,Unit=Count

# Create custom metric for response time
aws cloudwatch put-metric-data \
  --namespace "ABC-Company/Application" \
  --metric-data MetricName=ResponseTime,Value=150,Unit=Milliseconds

# Create custom metric for database query time
aws cloudwatch put-metric-data \
  --namespace "ABC-Company/Database" \
  --metric-data MetricName=QueryTime,Value=25,Unit=Milliseconds
```

---

## Alerting Configuration

### CloudWatch Alarms

#### High CPU Utilization
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "ABC-Company-High-CPU" \
  --alarm-description "Alarm when CPU exceeds 70%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=AutoScalingGroupName,Value=abc-company-asg \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:abc-company-alerts
```

#### High Error Rate
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "ABC-Company-High-Error-Rate" \
  --alarm-description "Alarm when error rate exceeds 1%" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=LoadBalancer,Value=app/abc-company-alb/50dc6c495c0c9188 \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:abc-company-alerts
```

#### Database Connection Threshold
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "ABC-Company-High-DB-Connections" \
  --alarm-description "Alarm when database connections exceed 80" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=abc-company-db \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:abc-company-alerts
```

### SNS Topic for Notifications

```bash
# Create SNS topic
aws sns create-topic --name abc-company-alerts

# Subscribe email to topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:abc-company-alerts \
  --protocol email \
  --notification-endpoint admin@company.com
```

---

## Optimization Strategies

### Application Layer Optimization

#### PHP Performance Tuning
```bash
# Enable OPcache
echo "zend_extension=opcache.so
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1" >> /etc/php.ini

# Optimize PHP settings
echo "memory_limit = 256M
max_execution_time = 60
max_input_vars = 3000
post_max_size = 64M
upload_max_filesize = 64M" >> /etc/php.ini
```

#### Apache Performance Tuning
```bash
# Configure Apache for better performance
cat >> /etc/httpd/conf/httpd.conf << 'EOF'
# Performance optimizations
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 15

# Enable compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>

# Cache static content
<FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
</FilesMatch>
EOF
```

### Database Optimization

#### MySQL Performance Tuning
```sql
-- Optimize database configuration
SET GLOBAL innodb_buffer_pool_size = 134217728;  -- 128MB
SET GLOBAL query_cache_size = 33554432;          -- 32MB
SET GLOBAL query_cache_type = ON;
SET GLOBAL tmp_table_size = 16777216;            -- 16MB
SET GLOBAL max_heap_table_size = 16777216;       -- 16MB

-- Add indexes for better performance
CREATE INDEX idx_data_email ON data(email);
CREATE INDEX idx_data_created_at ON data(created_at);
CREATE INDEX idx_data_composite ON data(email, created_at);

-- Regular maintenance
ANALYZE TABLE data;
OPTIMIZE TABLE data;
```

#### Connection Pool Optimization
```php
<?php
// Implement connection pooling
class DatabasePool {
    private static $instances = [];
    private static $maxConnections = 10;
    
    public static function getConnection() {
        if (count(self::$instances) < self::$maxConnections) {
            $pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_PERSISTENT => true,
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
            ]);
            self::$instances[] = $pdo;
            return $pdo;
        }
        return array_shift(self::$instances);
    }
}
?>
```

### Infrastructure Optimization

#### Auto Scaling Policy Tuning
```bash
# Optimize scaling policies for better responsiveness
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name abc-company-asg \
  --policy-name cpu-scale-out \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 60.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleOutCooldown": 180,
    "ScaleInCooldown": 300
  }'
```

#### Load Balancer Optimization
```bash
# Enable connection draining
aws elbv2 modify-target-group-attributes \
  --target-group-arn <TARGET_GROUP_ARN> \
  --attributes Key=deregistration_delay.timeout_seconds,Value=30

# Configure health check optimization
aws elbv2 modify-target-group \
  --target-group-arn <TARGET_GROUP_ARN> \
  --health-check-interval-seconds 15 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --health-check-timeout-seconds 10
```

---

## Load Testing

### Comprehensive Load Testing Strategy

#### Progressive Load Test
```bash
#!/bin/bash
# Progressive load testing script

ALB_URL="http://abc-company-alb-1234567890.us-east-1.elb.amazonaws.com"

echo "Starting progressive load test..."

# Light load (warm up)
echo "Phase 1: Light load (10 concurrent users)"
ab -n 1000 -c 10 -g light_load.plot $ALB_URL/

sleep 60

# Medium load
echo "Phase 2: Medium load (50 concurrent users)"
ab -n 5000 -c 50 -g medium_load.plot $ALB_URL/

sleep 120

# Heavy load
echo "Phase 3: Heavy load (100 concurrent users)"
ab -n 10000 -c 100 -g heavy_load.plot $ALB_URL/

# Monitor auto scaling during test
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name abc-company-asg --max-items 10
```

#### Database Load Test
```bash
#!/bin/bash
# Database write load test

ALB_URL="http://abc-company-alb-1234567890.us-east-1.elb.amazonaws.com"

# Create POST data file
echo "firstname=LoadTest&email=test@loadtest.com&submit=Add Record" > post_data.txt

# Execute database write test
ab -n 1000 -c 20 -p post_data.txt -T 'application/x-www-form-urlencoded' $ALB_URL/

# Monitor database performance during test
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=abc-company-db \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Average
```

### Performance Testing Results Analysis

```bash
#!/bin/bash
# Performance analysis script

echo "=== Performance Test Results Analysis ==="

# Analyze Apache logs
echo "Top 10 slowest requests:"
tail -10000 /var/log/httpd/access_log | \
  awk '{print $(NF-1), $0}' | \
  sort -nr | \
  head -10

# Analyze error patterns
echo "Error analysis:"
grep -E "(50[0-9]|40[0-9])" /var/log/httpd/access_log | \
  awk '{print $9}' | sort | uniq -c | sort -nr

# Database performance analysis
mysql -h <RDS_ENDPOINT> -u intel -p << 'EOF'
SELECT 
    ROUND(AVG(query_time), 2) as avg_query_time,
    ROUND(MAX(query_time), 2) as max_query_time,
    COUNT(*) as total_queries
FROM mysql.slow_log 
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
EOF
```

---

## Performance Monitoring Automation

### Automated Performance Reports

```bash
#!/bin/bash
# Daily performance report script

REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="/tmp/performance_report_$REPORT_DATE.txt"

echo "=== Daily Performance Report - $REPORT_DATE ===" > $REPORT_FILE

# Get ALB metrics
echo "Load Balancer Performance:" >> $REPORT_FILE
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/abc-company-alb/50dc6c495c0c9188 \
  --start-time $(date -u -d 'yesterday' +%Y-%m-%dT00:00:00) \
  --end-time $(date -u -d 'yesterday' +%Y-%m-%dT23:59:59) \
  --period 3600 --statistics Average,Maximum >> $REPORT_FILE

# Get Auto Scaling metrics
echo "Auto Scaling Activity:" >> $REPORT_FILE
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name abc-company-asg \
  --max-items 10 >> $REPORT_FILE

# Email report
aws ses send-email \
  --source admin@company.com \
  --destination ToAddresses=management@company.com \
  --message Subject="{Data='Daily Performance Report - $REPORT_DATE'}",Body="{Text={Data='$(cat $REPORT_FILE)'}}"
```

This comprehensive performance monitoring guide provides the foundation for maintaining optimal performance of your multi-tier website architecture on AWS. Regular monitoring and optimization based on these metrics will ensure consistent, high-quality user experience.