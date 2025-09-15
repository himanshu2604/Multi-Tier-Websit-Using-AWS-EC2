# 🌐 Load Balancer Configuration

## Overview
This document outlines the Application Load Balancer (ALB) configuration for the ABC Company multi-tier website. The ALB provides high availability, traffic distribution, and health monitoring with 30-second health checks across multiple availability zones.

## Load Balancer Architecture
```
Internet Gateway
    ↓
Application Load Balancer (Multi-AZ)
    ↓
Target Group (Health Checks every 30s)
    ↓
Auto Scaling Group Instances
    ↓ (Port 80)
Web Application (PHP/Apache)
```

## 1. Application Load Balancer Configuration

### Basic ALB Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | abc-company-alb | Application Load Balancer name |
| **Scheme** | Internet-facing | Public load balancer |
| **IP Address Type** | IPv4 | Standard IPv4 addressing |
| **VPC** | abc-company-vpc | Virtual Private Cloud |
| **Availability Zones** | us-east-1a, us-east-1b | Multi-AZ deployment |
| **Security Groups** | alb-security-group | ALB security group |

### ALB Creation JSON
```json
{
    "Name": "abc-company-alb",
    "Subnets": [
        "subnet-12345678",
        "subnet-87654321"
    ],
    "SecurityGroups": [
        "sg-alb-security-group-id"
    ],
    "Scheme": "internet-facing",
    "Tags": [
        {
            "Key": "Name",
            "Value": "ABC-Company-ALB"
        },
        {
            "Key": "Project", 
            "Value": "ABC-Company-Migration"
        },
        {
            "Key": "Environment",
            "Value": "Production"
        }
    ],
    "Type": "application",
    "IpAddressType": "ipv4"
}
```

**AWS CLI Command:**
```bash
# Create Application Load Balancer
aws elbv2 create-load-balancer \
    --name abc-company-alb \
    --subnets subnet-12345678 subnet-87654321 \
    --security-groups sg-alb-security-group-id \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --tags Key=Name,Value=ABC-Company-ALB Key=Project,Value=ABC-Company-Migration
```

## 2. Target Group Configuration

### Target Group Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | abc-company-target-group | Target group name |
| **Protocol** | HTTP | Target protocol |
| **Port** | 80 | Target port |
| **VPC** | abc-company-vpc | Virtual Private Cloud |
| **Health Check Protocol** | HTTP | Health check protocol |
| **Health Check Path** | /index.php | Health check endpoint |
| **Health Check Interval** | 30 seconds | Health check frequency |
| **Health Check Timeout** | 5 seconds | Health check timeout |
| **Healthy Threshold** | 2 | Consecutive successful checks |
| **Unhealthy Threshold** | 3 | Consecutive failed checks |

### Target Group JSON Configuration
```json
{
    "Name": "abc-company-target-group",
    "Protocol": "HTTP",
    "Port": 80,
    "VpcId": "vpc-12345678",
    "ProtocolVersion": "HTTP1",
    "HealthCheckProtocol": "HTTP",
    "HealthCheckPath": "/index.php",
    "HealthCheckIntervalSeconds": 30,
    "HealthCheckTimeoutSeconds": 5,
    "HealthyThresholdCount": 2,
    "UnhealthyThresholdCount": 3,
    "TargetType": "instance",
    "Matcher": {
        "HttpCode": "200"
    },
    "Tags": [
        {
            "Key": "Name",
            "Value": "ABC-Company-TargetGroup"
        },
        {
            "Key": "Project",
            "Value": "ABC-Company-Migration"
        }
    ]
}
```

**AWS CLI Command:**
```bash
# Create Target Group
aws elbv2 create-target-group \
    --name abc-company-target-group \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-12345678 \
    --health-check-protocol HTTP \
    --health-check-path /index.php \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --matcher HttpCode=200 \
    --tags Key=Name,Value=ABC-Company-TargetGroup
```

## 3. Listener Configuration

### HTTP Listener
```json
{
    "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/1234567890123456",
    "Protocol": "HTTP",
    "Port": 80,
    "DefaultActions": [
        {
            "Type": "forward",
            "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456"
        }
    ]
}
```

### HTTPS Listener (Optional - with SSL Certificate)
```json
{
    "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/1234567890123456",
    "Protocol": "HTTPS",
    "Port": 443,
    "Certificates": [
        {
            "CertificateArn": "arn:aws:acm:us-east-1:123456789012:certificate/certificate-id"
        }
    ],
    "DefaultActions": [
        {
            "Type": "forward",
            "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456"
        }
    ]
}
```

**AWS CLI Commands:**
```bash
# Create HTTP Listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/1234567890123456 \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456

# Create HTTPS Listener (if SSL certificate available)
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/1234567890123456 \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/certificate-id \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456
```

## 4. Health Check Configuration

### Health Check Parameters
```bash
# Modify Target Group Health Checks
aws elbv2 modify-target-group \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456 \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --health-check-path "/index.php" \
    --matcher HttpCode=200
```

### Health Check Endpoint (index.php)
Create a simple health check endpoint in your web application:

```php path=null start=null
<?php
// Health check endpoint - /var/www/html/health.php
header('Content-Type: application/json');

$health_status = array(
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'server' => $_SERVER['SERVER_NAME'],
    'php_version' => phpversion()
);

// Optional: Check database connectivity
try {
    $db_host = 'your-rds-endpoint.region.rds.amazonaws.com';
    $db_name = 'intel';
    $db_user = 'intel';
    $db_pass = 'intel123';
    
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $health_status['database'] = 'connected';
} catch (PDOException $e) {
    $health_status['database'] = 'disconnected';
    $health_status['status'] = 'unhealthy';
    http_response_code(503);
}

echo json_encode($health_status);
?>
```

Update health check path to use the dedicated endpoint:
```bash
aws elbv2 modify-target-group \
    --target-group-arn your-target-group-arn \
    --health-check-path "/health.php"
```

## 5. Target Registration

### Auto Scaling Group Integration
The Auto Scaling Group automatically registers and deregisters instances with the target group.

```bash
# Verify target group is associated with ASG
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names abc-company-asg \
    --query 'AutoScalingGroups[0].TargetGroupARNs'

# Manually register instances (if needed)
aws elbv2 register-targets \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456 \
    --targets Id=i-1234567890abcdef0 Id=i-0987654321fedcba0
```

### Check Target Health
```bash
# Describe target health
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-target-group/1234567890123456

# Sample output interpretation:
# - healthy: Target is receiving traffic
# - initial: Target is registering
# - unhealthy: Target failed health checks
# - unused: Target is not registered
# - draining: Target is deregistering
```

## 6. Load Balancer Attributes

### Performance Tuning
```bash
# Configure load balancer attributes
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn your-alb-arn \
    --attributes \
        Key=idle_timeout.timeout_seconds,Value=60 \
        Key=routing.http2.enabled,Value=true \
        Key=access_logs.s3.enabled,Value=true \
        Key=access_logs.s3.bucket,Value=abc-company-alb-logs \
        Key=deletion_protection.enabled,Value=false
```

### Sticky Sessions (if needed)
```bash
# Enable session stickiness
aws elbv2 modify-target-group-attributes \
    --target-group-arn your-target-group-arn \
    --attributes \
        Key=stickiness.enabled,Value=true \
        Key=stickiness.type,Value=lb_cookie \
        Key=stickiness.lb_cookie.duration_seconds,Value=86400
```

## 7. SSL/TLS Configuration

### Request SSL Certificate
```bash
# Request SSL certificate from ACM
aws acm request-certificate \
    --domain-name abccompany.com \
    --subject-alternative-names *.abccompany.com \
    --validation-method DNS \
    --tags Key=Name,Value=ABC-Company-SSL

# List certificates
aws acm list-certificates
```

### SSL Security Policy
```bash
# Update listener with SSL security policy
aws elbv2 modify-listener \
    --listener-arn your-https-listener-arn \
    --ssl-policy ELBSecurityPolicy-TLS-1-2-2017-01
```

## 8. Monitoring and Logging

### CloudWatch Metrics
Key metrics to monitor:
- **ActiveConnectionCount**: Number of active connections
- **NewConnectionCount**: Rate of new connections
- **TargetResponseTime**: Response time from targets
- **HTTPCode_Target_2XX_Count**: Successful responses
- **HTTPCode_Target_4XX_Count**: Client errors
- **HTTPCode_Target_5XX_Count**: Server errors
- **UnHealthyHostCount**: Number of unhealthy targets
- **HealthyHostCount**: Number of healthy targets

```bash
# Create CloudWatch dashboard
aws cloudwatch put-dashboard \
    --dashboard-name "ABC-Company-ALB-Dashboard" \
    --dashboard-body file://alb-dashboard.json
```

### Access Logs
```bash
# Enable access logs
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn your-alb-arn \
    --attributes Key=access_logs.s3.enabled,Value=true \
                Key=access_logs.s3.bucket,Value=abc-company-alb-logs \
                Key=access_logs.s3.prefix,Value=access-logs

# Create S3 bucket for access logs
aws s3 mb s3://abc-company-alb-logs
```

## 9. Listener Rules and Routing

### Path-Based Routing (Advanced)
```json
{
    "ListenerArn": "your-listener-arn",
    "Conditions": [
        {
            "Field": "path-pattern",
            "Values": ["/api/*"]
        }
    ],
    "Priority": 100,
    "Actions": [
        {
            "Type": "forward",
            "TargetGroupArn": "your-api-target-group-arn"
        }
    ]
}
```

```bash
# Create listener rule
aws elbv2 create-rule \
    --listener-arn your-listener-arn \
    --conditions Field=path-pattern,Values='/api/*' \
    --priority 100 \
    --actions Type=forward,TargetGroupArn=your-api-target-group-arn
```

### Host-Based Routing
```bash
# Create rule for subdomain routing
aws elbv2 create-rule \
    --listener-arn your-listener-arn \
    --conditions Field=host-header,Values='api.abccompany.com' \
    --priority 101 \
    --actions Type=forward,TargetGroupArn=your-api-target-group-arn
```

## 10. High Availability Configuration

### Multi-AZ Deployment
```bash
# Verify ALB spans multiple AZs
aws elbv2 describe-load-balancers \
    --names abc-company-alb \
    --query 'LoadBalancers[0].AvailabilityZones[*].ZoneName'
```

### Cross-Zone Load Balancing
Cross-zone load balancing is enabled by default for Application Load Balancers.

```bash
# Verify cross-zone load balancing status
aws elbv2 describe-load-balancer-attributes \
    --load-balancer-arn your-alb-arn \
    --query 'Attributes[?Key==`load_balancing.cross_zone.enabled`]'
```

## 11. Security Configuration

### WAF Integration (Optional)
```bash
# Associate WAF with ALB
aws wafv2 associate-web-acl \
    --web-acl-arn arn:aws:wafv2:us-east-1:123456789012:global/webacl/abc-company-waf/web-acl-id \
    --resource-arn your-alb-arn
```

### Security Headers
Configure security headers in your application or via ALB listener rules:

```json
{
    "Actions": [
        {
            "Type": "fixed-response",
            "FixedResponseConfig": {
                "StatusCode": "200",
                "ContentType": "text/html",
                "MessageBody": "OK"
            },
            "ResponseHeaders": {
                "X-Frame-Options": "DENY",
                "X-Content-Type-Options": "nosniff",
                "Strict-Transport-Security": "max-age=31536000"
            }
        }
    ]
}
```

## 12. Testing and Validation

### Load Balancer Testing
```bash
# Test load balancer connectivity
curl -I http://your-alb-dns-name
curl -I https://your-alb-dns-name

# Test with different User-Agent strings
curl -H "User-Agent: TestBot/1.0" http://your-alb-dns-name

# Test health check endpoint
curl http://your-alb-dns-name/health.php

# Load testing with Apache Bench
ab -n 1000 -c 50 http://your-alb-dns-name/
```

### Failover Testing
```bash
# Simulate instance failure
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Monitor target health during failover
watch -n 5 'aws elbv2 describe-target-health --target-group-arn your-target-group-arn'

# Test continued availability
curl http://your-alb-dns-name
```

### Health Check Validation
```bash
# Check target group health
aws elbv2 describe-target-health \
    --target-group-arn your-target-group-arn \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
    --output table
```

## 13. Implementation Checklist

### Prerequisites
- [ ] VPC with public subnets in multiple AZs
- [ ] Security groups for ALB configured
- [ ] Auto Scaling Group created
- [ ] SSL certificate requested (if HTTPS needed)
- [ ] Route 53 hosted zone (if custom domain needed)

### Deployment Steps
- [ ] Create Application Load Balancer
- [ ] Create Target Group with health checks
- [ ] Create HTTP listener
- [ ] Create HTTPS listener (if SSL certificate available)
- [ ] Associate target group with Auto Scaling Group
- [ ] Configure health check endpoint in application
- [ ] Test load balancer functionality
- [ ] Enable access logging
- [ ] Set up CloudWatch monitoring

### Post-Deployment
- [ ] Monitor target health for 24 hours
- [ ] Configure DNS records to point to ALB
- [ ] Set up CloudWatch alarms for critical metrics
- [ ] Document ALB DNS name and ARNs
- [ ] Test failover scenarios
- [ ] Create monitoring dashboard

## 14. Troubleshooting

### Common Issues

#### 1. Unhealthy Targets
**Symptoms**: Targets showing as unhealthy in target group
**Solutions**:
- Check security group allows ALB to reach instances on port 80
- Verify health check path returns HTTP 200
- Ensure application is running and listening on correct port
- Check health check timeout and interval settings

#### 2. Connection Timeouts
**Symptoms**: Requests timing out or failing
**Solutions**:
- Verify ALB security group allows traffic on ports 80/443
- Check target security group allows traffic from ALB
- Ensure instances are in correct subnets
- Verify route tables have internet gateway routes

#### 3. SSL Certificate Issues
**Symptoms**: HTTPS not working or certificate warnings
**Solutions**:
- Ensure certificate covers the domain being used
- Check certificate validation status in ACM
- Verify DNS records for domain validation
- Use correct SSL security policy

### Debug Commands
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names abc-company-alb

# Verify target group configuration
aws elbv2 describe-target-groups --names abc-company-target-group

# Check listener configuration
aws elbv2 describe-listeners --load-balancer-arn your-alb-arn

# Monitor ALB access logs
aws logs tail /aws/elasticloadbalancing/application/abc-company-alb --follow

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --dimensions Name=LoadBalancer,Value=app/abc-company-alb/1234567890123456 \
    --statistics Average \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-01T01:00:00Z \
    --period 300
```

## Related Documentation
- [Security Groups Configuration](security-groups.md)
- [Auto Scaling Configuration](auto-scaling-config.md)
- [AWS Application Load Balancer User Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Target Group Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)