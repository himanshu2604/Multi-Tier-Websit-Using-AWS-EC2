# ⚖️ Auto Scaling Configuration

## Overview
This document outlines the Auto Scaling Group (ASG) configuration for the ABC Company multi-tier website. The configuration ensures high availability with automatic scaling from 2-6 instances based on CPU utilization, providing cost optimization and performance reliability.

## Auto Scaling Architecture
```
CloudWatch Metrics (CPU Utilization)
    ↓
Auto Scaling Policies (Scale Out/In)
    ↓
Auto Scaling Group (2-6 Instances)
    ↓
Launch Template (t2.micro)
    ↓
Target Group Registration
```

## 1. Launch Template Configuration

### Basic Configuration
```json
{
    "LaunchTemplateName": "abc-company-web-template",
    "LaunchTemplateData": {
        "ImageId": "ami-0abcdef1234567890",
        "InstanceType": "t2.micro",
        "KeyName": "abc-company-keypair",
        "SecurityGroupIds": ["sg-web-tier-security-group-id"],
        "IamInstanceProfile": {
            "Name": "EC2-CloudWatch-Role"
        },
        "UserData": "base64-encoded-user-data",
        "TagSpecifications": [
            {
                "ResourceType": "instance",
                "Tags": [
                    {"Key": "Name", "Value": "ABC-Company-WebServer"},
                    {"Key": "Project", "Value": "ABC-Company-Migration"},
                    {"Key": "Environment", "Value": "Production"},
                    {"Key": "Tier", "Value": "Web"}
                ]
            }
        ]
    }
}
```

### User Data Script
```bash
#!/bin/bash
yum update -y
yum install -y httpd php php-mysql mysql

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Download website files
cd /var/www/html
wget https://raw.githubusercontent.com/your-repo/website-files/index.php
chown apache:apache /var/www/html/*
```

**AWS CLI Command:**
```bash
# Create Launch Template
aws ec2 create-launch-template \
    --launch-template-name abc-company-web-template \
    --launch-template-data file://launch-template-data.json
```

## 2. Auto Scaling Group Configuration

### ASG Parameters
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | abc-company-asg | Auto Scaling Group name |
| **Min Size** | 2 | Minimum instances for high availability |
| **Desired Capacity** | 2 | Initial number of instances |
| **Max Size** | 6 | Maximum instances for cost control |
| **VPC Zones** | us-east-1a, us-east-1b | Multi-AZ deployment |
| **Health Check Type** | ELB | Use load balancer health checks |
| **Health Check Grace Period** | 300 seconds | Time before health checks start |

### ASG Configuration JSON
```json
{
    "AutoScalingGroupName": "abc-company-asg",
    "LaunchTemplate": {
        "LaunchTemplateName": "abc-company-web-template",
        "Version": "$Latest"
    },
    "MinSize": 2,
    "MaxSize": 6,
    "DesiredCapacity": 2,
    "VPCZoneIdentifier": "subnet-12345678,subnet-87654321",
    "TargetGroupARNs": ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-tg/1234567890123456"],
    "HealthCheckType": "ELB",
    "HealthCheckGracePeriod": 300,
    "DefaultCooldown": 300,
    "Tags": [
        {
            "Key": "Name",
            "Value": "ABC-Company-ASG",
            "PropagateAtLaunch": true
        },
        {
            "Key": "Project",
            "Value": "ABC-Company-Migration",
            "PropagateAtLaunch": true
        }
    ]
}
```

**AWS CLI Command:**
```bash
# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
    --cli-input-json file://asg-config.json
```

## 3. Scaling Policies

### Scale Out Policy (High CPU)
```json
{
    "PolicyName": "scale-out-policy",
    "AutoScalingGroupName": "abc-company-asg",
    "PolicyType": "TargetTrackingScaling",
    "TargetTrackingConfiguration": {
        "TargetValue": 70.0,
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "ScaleOutCooldown": 300,
        "ScaleInCooldown": 300
    }
}
```

### Step Scaling Policy (Advanced)
```json
{
    "PolicyName": "step-scale-out-policy",
    "AutoScalingGroupName": "abc-company-asg",
    "PolicyType": "StepScaling",
    "AdjustmentType": "ChangeInCapacity",
    "StepAdjustments": [
        {
            "MetricIntervalLowerBound": 0,
            "MetricIntervalUpperBound": 20,
            "ScalingAdjustment": 1
        },
        {
            "MetricIntervalLowerBound": 20,
            "ScalingAdjustment": 2
        }
    ],
    "Cooldown": 300
}
```

**AWS CLI Commands:**
```bash
# Create Target Tracking Scaling Policy
aws autoscaling put-scaling-policy \
    --cli-input-json file://scale-out-policy.json

# Create Step Scaling Policy (optional)
aws autoscaling put-scaling-policy \
    --cli-input-json file://step-scale-policy.json
```

## 4. CloudWatch Alarms

### High CPU Alarm
```bash
# Create CloudWatch Alarm for High CPU
aws cloudwatch put-metric-alarm \
    --alarm-name "ABC-Company-HighCPU" \
    --alarm-description "Alarm when CPU exceeds 70%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=AutoScalingGroupName,Value=abc-company-asg \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:policy-id \
    --unit Percent
```

### Low CPU Alarm
```bash
# Create CloudWatch Alarm for Low CPU
aws cloudwatch put-metric-alarm \
    --alarm-name "ABC-Company-LowCPU" \
    --alarm-description "Alarm when CPU is below 25%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 25 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=AutoScalingGroupName,Value=abc-company-asg \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:us-east-1:123456789012:scalingPolicy:policy-id \
    --unit Percent
```

## 5. Scaling Metrics and Thresholds

### Performance Targets
| Metric | Scale Out Threshold | Scale In Threshold | Evaluation Period |
|--------|-------------------|--------------------|-------------------|
| **CPU Utilization** | > 70% | < 25% | 5 minutes |
| **Network In** | > 10 MB/min | < 2 MB/min | 5 minutes |
| **Request Count** | > 1000/min | < 200/min | 5 minutes |
| **Response Time** | > 500ms | < 100ms | 5 minutes |

### Scaling Timeline
```
High Traffic Event:
T+0:     CPU reaches 75%
T+2min:  CloudWatch alarm triggers
T+3min:  Scale out policy executes
T+5min:  New instance launches
T+8min:  Instance passes health checks
T+10min: Instance receives traffic

Low Traffic Period:
T+0:     CPU below 20% for 10 minutes
T+10min: CloudWatch alarm triggers
T+12min: Scale in policy executes
T+15min: Instance terminates gracefully
```

## 6. Instance Management

### Health Checks
```bash
# Configure health check settings
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name abc-company-asg \
    --health-check-type ELB \
    --health-check-grace-period 300
```

### Instance Refresh
```json
{
    "AutoScalingGroupName": "abc-company-asg",
    "Preferences": {
        "MinHealthyPercentage": 50,
        "InstanceWarmup": 300
    }
}
```

```bash
# Start instance refresh
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name abc-company-asg \
    --cli-input-json file://instance-refresh.json
```

## 7. Monitoring and Notifications

### SNS Topic for Notifications
```bash
# Create SNS topic
aws sns create-topic --name abc-company-scaling-notifications

# Subscribe email to topic
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789012:abc-company-scaling-notifications \
    --protocol email \
    --notification-endpoint admin@abccompany.com
```

### Auto Scaling Notifications
```bash
# Configure ASG notifications
aws autoscaling put-notification-configuration \
    --auto-scaling-group-name abc-company-asg \
    --topic-arn arn:aws:sns:us-east-1:123456789012:abc-company-scaling-notifications \
    --notification-types "autoscaling:EC2_INSTANCE_LAUNCH" \
                         "autoscaling:EC2_INSTANCE_TERMINATE" \
                         "autoscaling:EC2_INSTANCE_LAUNCH_ERROR" \
                         "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
```

## 8. Cost Optimization

### Scheduled Scaling (Optional)
```json
{
    "ScheduledActionName": "scale-down-evening",
    "AutoScalingGroupName": "abc-company-asg",
    "Recurrence": "0 22 * * *",
    "MinSize": 1,
    "MaxSize": 4,
    "DesiredCapacity": 1
}
```

```bash
# Create scheduled action
aws autoscaling put-scheduled-update-group-action \
    --cli-input-json file://scheduled-scaling.json
```

### Spot Instance Integration (Advanced)
```json
{
    "LaunchTemplateData": {
        "InstanceMarketOptions": {
            "MarketType": "spot",
            "SpotOptions": {
                "MaxPrice": "0.05",
                "SpotInstanceType": "one-time"
            }
        }
    }
}
```

## 9. Testing and Validation

### Load Testing Commands
```bash
# Install Apache Bench for testing
sudo yum install -y httpd-tools

# Generate load to test scaling
ab -n 10000 -c 100 http://your-alb-dns-name/

# Monitor scaling activity
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name abc-company-asg \
    --max-items 10
```

### Monitoring Commands
```bash
# Check ASG status
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names abc-company-asg

# View current instances
aws autoscaling describe-auto-scaling-instances

# Check scaling policies
aws autoscaling describe-policies \
    --auto-scaling-group-name abc-company-asg

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value=abc-company-asg \
    --statistics Average \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-02T00:00:00Z \
    --period 3600
```

## 10. Implementation Checklist

### Prerequisites
- [ ] VPC with public and private subnets in multiple AZs
- [ ] Security groups configured
- [ ] IAM roles for EC2 instances
- [ ] Key pair for SSH access
- [ ] AMI with required software stack

### Deployment Steps
- [ ] Create Launch Template with user data script
- [ ] Create Auto Scaling Group with proper configuration
- [ ] Set up Target Tracking scaling policies
- [ ] Configure CloudWatch alarms
- [ ] Create SNS topic for notifications
- [ ] Test scaling behavior under load
- [ ] Verify health checks and instance replacement
- [ ] Document scaling events and performance

### Post-Deployment
- [ ] Monitor scaling activities for first week
- [ ] Fine-tune scaling thresholds based on actual usage
- [ ] Set up scheduled scaling if applicable
- [ ] Configure cost alerts for unexpected scaling
- [ ] Create runbooks for scaling troubleshooting

## Troubleshooting

### Common Issues
1. **Instances not scaling**: Check CloudWatch alarms and scaling policies
2. **New instances failing health checks**: Verify user data script and security groups
3. **Slow scaling response**: Adjust CloudWatch evaluation periods
4. **Cost overruns**: Review scaling thresholds and maximum instance limits

### Debug Commands
```bash
# Check ASG activities
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name abc-company-asg

# Verify launch template
aws ec2 describe-launch-template-versions \
    --launch-template-name abc-company-web-template

# Check instance health
aws elbv2 describe-target-health \
    --target-group-arn your-target-group-arn
```

## Related Documentation
- [Security Groups Configuration](security-groups.md)
- [Load Balancer Configuration](load-balancer-config.md)
- [AWS Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html)