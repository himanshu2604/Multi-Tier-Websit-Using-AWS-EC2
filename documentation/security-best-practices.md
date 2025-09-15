# 🔒 Security Best Practices Guide

## Overview

This document outlines comprehensive security best practices for the Multi-Tier Website architecture on AWS, covering network security, data protection, access control, and compliance requirements.

## Table of Contents
1. [Security Framework](#security-framework)
2. [Network Security](#network-security)
3. [Identity and Access Management](#identity-and-access-management)
4. [Data Protection](#data-protection)
5. [Application Security](#application-security)
6. [Infrastructure Security](#infrastructure-security)
7. [Monitoring and Compliance](#monitoring-and-compliance)
8. [Incident Response](#incident-response)

---

## Security Framework

### AWS Well-Architected Security Pillar

Our security implementation follows the AWS Well-Architected Security Pillar:

#### Security Design Principles
- **Apply security at all layers**: Defense in depth
- **Enable traceability**: Comprehensive logging and monitoring
- **Implement strong identity foundation**: Centralized identity management
- **Apply principle of least privilege**: Minimal required access
- **Secure system design**: Security by design, not as an afterthought
- **Automate security best practices**: Reduce human error through automation

#### Security Domains
```
🛡️ Identity and Access Management (IAM)
🛡️ Detective Controls (CloudTrail, Config, GuardDuty)
🛡️ Infrastructure Protection (VPC, Security Groups, NACLs)
🛡️ Data Protection (Encryption at rest and in transit)
🛡️ Incident Response (Automated response and recovery)
```

---

## Network Security

### VPC Security Architecture

#### Network Segmentation
```
Internet Facing:
├── Public Subnets (Load Balancer only)
│   ├── us-east-1a: 10.0.1.0/24
│   └── us-east-1b: 10.0.2.0/24
│
Private Application Tier:
├── Private Subnets (Web Servers)
│   ├── us-east-1a: 10.0.10.0/24
│   └── us-east-1b: 10.0.20.0/24
│
Private Data Tier:
└── Private Subnets (Database)
    ├── us-east-1a: 10.0.30.0/24
    └── us-east-1b: 10.0.40.0/24
```

#### Security Groups Configuration

**Load Balancer Security Group (alb-sg)**
```bash
# Create ALB security group
aws ec2 create-security-group \
  --group-name abc-company-alb-sg \
  --description "Security group for Application Load Balancer" \
  --vpc-id vpc-12345678

# Allow HTTP and HTTPS from internet
aws ec2 authorize-security-group-ingress \
  --group-id sg-alb12345 \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-alb12345 \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# Allow outbound to web tier only
aws ec2 authorize-security-group-egress \
  --group-id sg-alb12345 \
  --protocol tcp --port 80 \
  --source-group sg-web12345
```

**Web Tier Security Group (web-sg)**
```bash
# Create web tier security group
aws ec2 create-security-group \
  --group-name abc-company-web-sg \
  --description "Security group for web tier EC2 instances" \
  --vpc-id vpc-12345678

# Allow HTTP from ALB only
aws ec2 authorize-security-group-ingress \
  --group-id sg-web12345 \
  --protocol tcp --port 80 \
  --source-group sg-alb12345

# Allow SSH from bastion host/admin IP only
aws ec2 authorize-security-group-ingress \
  --group-id sg-web12345 \
  --protocol tcp --port 22 \
  --cidr 203.0.113.100/32

# Allow outbound for updates and database access
aws ec2 authorize-security-group-egress \
  --group-id sg-web12345 \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress \
  --group-id sg-web12345 \
  --protocol tcp --port 3306 \
  --source-group sg-db12345
```

**Database Security Group (db-sg)**
```bash
# Create database security group
aws ec2 create-security-group \
  --group-name abc-company-db-sg \
  --description "Security group for RDS database" \
  --vpc-id vpc-12345678

# Allow MySQL from web tier only
aws ec2 authorize-security-group-ingress \
  --group-id sg-db12345 \
  --protocol tcp --port 3306 \
  --source-group sg-web12345

# No outbound rules (default deny)
aws ec2 revoke-security-group-egress \
  --group-id sg-db12345 \
  --protocol -1 --cidr 0.0.0.0/0
```

### Network Access Control Lists (NACLs)

#### Additional Network Layer Security
```bash
# Create custom NACL for database tier
aws ec2 create-network-acl --vpc-id vpc-12345678

# Allow inbound MySQL from web tier subnets only
aws ec2 create-network-acl-entry \
  --network-acl-id acl-db12345 \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=3306,To=3306 \
  --cidr-block 10.0.10.0/23 \
  --rule-action allow

# Allow outbound responses
aws ec2 create-network-acl-entry \
  --network-acl-id acl-db12345 \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=1024,To=65535 \
  --cidr-block 10.0.10.0/23 \
  --rule-action allow \
  --egress
```

---

## Identity and Access Management

### IAM Roles and Policies

#### EC2 Instance Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### EC2 Instance Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:CreateLogStream"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:Connect"
      ],
      "Resource": "arn:aws:rds-db:us-east-1:123456789012:dbuser:abc-company-db/intel"
    }
  ]
}
```

#### Auto Scaling Service Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeSnapshots",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeAvailabilityZones",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
```

### Multi-Factor Authentication (MFA)

#### Enable MFA for AWS Console Access
```bash
# Create virtual MFA device
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name admin-mfa \
  --outfile QRCode.png \
  --bootstrap-method QRCodePNG

# Enable MFA for IAM user
aws iam enable-mfa-device \
  --user-name admin-user \
  --serial-number arn:aws:iam::123456789012:mfa/admin-mfa \
  --authentication-code1 123456 \
  --authentication-code2 789012
```

---

## Data Protection

### Encryption at Rest

#### RDS Encryption
```bash
# Enable encryption for RDS instance
aws rds create-db-instance \
  --db-instance-identifier abc-company-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username intel \
  --master-user-password intel123 \
  --allocated-storage 20 \
  --storage-encrypted \
  --kms-key-id alias/aws/rds
```

#### EBS Volume Encryption
```bash
# Create encrypted EBS volume for EC2 instances
aws ec2 create-volume \
  --size 8 \
  --encrypted \
  --volume-type gp3 \
  --availability-zone us-east-1a \
  --kms-key-id alias/aws/ebs
```

#### S3 Bucket Encryption (for static assets)
```bash
# Create S3 bucket with encryption
aws s3 mb s3://abc-company-assets

# Enable default encryption
aws s3api put-bucket-encryption \
  --bucket abc-company-assets \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

### Encryption in Transit

#### SSL/TLS Certificate Management
```bash
# Request SSL certificate from ACM
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names www.example.com \
  --validation-method DNS

# Add HTTPS listener to ALB
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/50dc6c495c0c9188 \
  --protocol HTTPS \
  --port 443 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/abc-company-web-tg/73e2d6bc24d8a067 \
  --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

#### Force HTTPS Redirection
```bash
# Create HTTP to HTTPS redirect rule
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/50dc6c495c0c9188 \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

### Database Connection Encryption

#### MySQL SSL Configuration
```sql
-- Enable SSL for database connections
ALTER USER 'intel'@'%' REQUIRE SSL;
FLUSH PRIVILEGES;

-- Verify SSL configuration
SHOW VARIABLES LIKE 'have_ssl';
SELECT * FROM performance_schema.session_status WHERE VARIABLE_NAME = 'Ssl_cipher';
```

---

## Application Security

### Input Validation and Sanitization

#### PHP Security Best Practices
```php
<?php
// Input validation and sanitization
function validateInput($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// Email validation
function validateEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL);
}

// SQL injection prevention with prepared statements
function insertData($pdo, $firstname, $email) {
    try {
        // Validate inputs
        if (!validateEmail($email)) {
            throw new Exception("Invalid email format");
        }
        
        if (strlen($firstname) > 50) {
            throw new Exception("First name too long");
        }
        
        // Use prepared statements
        $stmt = $pdo->prepare("INSERT INTO data (firstname, email) VALUES (?, ?)");
        $stmt->execute([
            validateInput($firstname),
            validateInput($email)
        ]);
        
        return $stmt->rowCount();
    } catch (Exception $e) {
        error_log("Database insert error: " . $e->getMessage());
        return false;
    }
}

// Secure session management
session_start([
    'cookie_lifetime' => 3600,
    'cookie_secure' => true,    // HTTPS only
    'cookie_httponly' => true,  // No JavaScript access
    'cookie_samesite' => 'Strict'
]);

// CSRF protection
function generateCSRFToken() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function validateCSRFToken($token) {
    return isset($_SESSION['csrf_token']) && 
           hash_equals($_SESSION['csrf_token'], $token);
}
?>
```

#### Security Headers Configuration
```apache
# Add to /etc/httpd/conf/httpd.conf

# Security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
Header always set Referrer-Policy "strict-origin-when-cross-origin"

# Remove server signature
ServerTokens Prod
ServerSignature Off

# Disable unnecessary HTTP methods
<Location "/">
    <LimitExcept GET POST HEAD>
        Require all denied
    </LimitExcept>
</Location>
```

### Web Application Firewall (WAF)

#### AWS WAF Configuration
```bash
# Create WAF Web ACL
aws wafv2 create-web-acl \
  --name abc-company-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --description "WAF for ABC Company website" \
  --rules '[
    {
      "Name": "AWSManagedRulesCommonRuleSet",
      "Priority": 1,
      "OverrideAction": {"None": {}},
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "CommonRuleSetMetric"
      }
    },
    {
      "Name": "AWSManagedRulesKnownBadInputsRuleSet",
      "Priority": 2,
      "OverrideAction": {"None": {}},
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesKnownBadInputsRuleSet"
        }
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "KnownBadInputsMetric"
      }
    }
  ]'

# Associate WAF with ALB
aws wafv2 associate-web-acl \
  --web-acl-arn arn:aws:wafv2:us-east-1:123456789012:regional/webacl/abc-company-waf/12345678 \
  --resource-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/abc-company-alb/50dc6c495c0c9188
```

---

## Infrastructure Security

### EC2 Security Hardening

#### System Security Configuration
```bash
#!/bin/bash
# EC2 Security Hardening Script

# Update system packages
yum update -y

# Remove unnecessary packages
yum remove -y telnet rsh rlogin

# Configure SSH security
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
echo "AllowUsers ec2-user" >> /etc/ssh/sshd_config
systemctl restart sshd

# Configure firewall
yum install -y iptables-services
systemctl enable iptables
systemctl start iptables

# Basic iptables rules
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# Allow HTTP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Save rules
service iptables save

# Install and configure fail2ban
yum install -y epel-release
yum install -y fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
logpath = /var/log/secure
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Set up log monitoring
yum install -y awslogs
systemctl enable awslogsd
systemctl start awslogsd
```

#### File System Security
```bash
# Set proper permissions
chmod 600 /etc/shadow
chmod 644 /etc/passwd
chmod 644 /etc/group

# Secure Apache directories
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Remove world-writable files
find / -type f -perm -002 -exec chmod o-w {} \; 2>/dev/null

# Set umask for security
echo "umask 027" >> /etc/profile
```

### Secrets Management

#### AWS Secrets Manager Integration
```bash
# Store database credentials in Secrets Manager
aws secretsmanager create-secret \
  --name "abc-company/db/credentials" \
  --description "Database credentials for ABC Company" \
  --secret-string '{"username":"intel","password":"intel123"}'

# Update IAM policy to allow access to secrets
aws iam attach-role-policy \
  --role-name EC2-SecretAccess-Role \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
```

#### Application Integration
```php
<?php
// Retrieve database credentials from Secrets Manager
function getDatabaseCredentials() {
    $client = new Aws\SecretsManager\SecretsManagerClient([
        'version' => '2017-10-17',
        'region'  => 'us-east-1'
    ]);
    
    try {
        $result = $client->getSecretValue([
            'SecretId' => 'abc-company/db/credentials'
        ]);
        
        return json_decode($result['SecretString'], true);
    } catch (Exception $e) {
        error_log("Failed to retrieve database credentials: " . $e->getMessage());
        return null;
    }
}

// Use credentials securely
$credentials = getDatabaseCredentials();
if ($credentials) {
    $pdo = new PDO(
        "mysql:host=$servername;dbname=intel",
        $credentials['username'],
        $credentials['password']
    );
}
?>
```

---

## Monitoring and Compliance

### Security Monitoring

#### AWS CloudTrail Configuration
```bash
# Create CloudTrail for audit logging
aws cloudtrail create-trail \
  --name abc-company-cloudtrail \
  --s3-bucket-name abc-company-cloudtrail-logs \
  --include-global-service-events \
  --is-multi-region-trail \
  --enable-log-file-validation

# Start logging
aws cloudtrail start-logging \
  --name abc-company-cloudtrail
```

#### AWS Config for Compliance
```bash
# Enable AWS Config
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::123456789012:role/config-role \
  --recording-group allSupported=true,includeGlobalResourceTypes=true

# Create compliance rules
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "encrypted-volumes",
    "Description": "Checks whether EBS volumes are encrypted",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "ENCRYPTED_VOLUMES"
    },
    "Scope": {
      "ComplianceResourceTypes": [
        "AWS::EC2::Volume"
      ]
    }
  }'
```

#### AWS GuardDuty for Threat Detection
```bash
# Enable GuardDuty
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES

# Create custom threat intelligence set
aws guardduty create-threat-intel-set \
  --detector-id 12abc34d567e8fa901bc2d34e56789f0 \
  --name "CustomThreatIntel" \
  --format TXT \
  --location s3://abc-company-threat-intel/threats.txt \
  --activate
```

### VPC Flow Logs
```bash
# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-12345678 \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs \
  --deliver-logs-permission-arn arn:aws:iam::123456789012:role/flowlogsRole
```

### Security Scanning and Assessment

#### AWS Inspector for Vulnerability Assessment
```bash
# Create assessment target
aws inspector create-assessment-target \
  --assessment-target-name "ABC-Company-Web-Tier" \
  --resource-group-arn arn:aws:inspector:us-east-1:123456789012:resourcegroup/0-AB1CDEFG

# Create and run assessment template
aws inspector create-assessment-template \
  --assessment-target-arn arn:aws:inspector:us-east-1:123456789012:target/0-AB1CDEFG \
  --assessment-template-name "Security-Assessment" \
  --duration-in-seconds 3600 \
  --rules-package-arns arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7

aws inspector start-assessment-run \
  --assessment-template-arn arn:aws:inspector:us-east-1:123456789012:target/0-AB1CDEFG
```

---

## Incident Response

### Security Incident Response Plan

#### Phase 1: Preparation
```bash
#!/bin/bash
# Incident Response Preparation Script

# Create isolated investigation environment
aws ec2 create-vpc --cidr-block 10.99.0.0/16
aws ec2 create-subnet --vpc-id vpc-isolation123 --cidr-block 10.99.1.0/24

# Create forensic analysis AMI
aws ec2 create-image \
  --instance-id i-compromised123 \
  --name "forensic-analysis-$(date +%Y%m%d%H%M)" \
  --no-reboot
```

#### Phase 2: Identification and Isolation
```bash
#!/bin/bash
# Incident Isolation Script

INSTANCE_ID=$1

# Isolate compromised instance
aws ec2 modify-instance-attribute \
  --instance-id $INSTANCE_ID \
  --groups sg-isolation123

# Create forensic snapshot
aws ec2 create-snapshot \
  --volume-id $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text) \
  --description "Forensic snapshot for incident response"

# Enable detailed monitoring
aws ec2 monitor-instances --instance-ids $INSTANCE_ID

# Collect logs
aws logs create-export-task \
  --log-group-name /aws/ec2/apache/access \
  --from $(date -d '1 hour ago' +%s)000 \
  --to $(date +%s)000 \
  --destination abc-company-incident-logs \
  --destination-prefix "incident-$(date +%Y%m%d)"
```

#### Phase 3: Containment and Eradication
```bash
#!/bin/bash
# Containment Script

# Rotate access keys immediately
aws iam update-access-key \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --status Inactive \
  --user-name compromised-user

# Change database passwords
aws rds modify-db-instance \
  --db-instance-identifier abc-company-db \
  --master-user-password NewSecurePassword123 \
  --apply-immediately

# Revoke active sessions
mysql -h $RDS_ENDPOINT -u admin -p << 'EOF'
KILL QUERY WHERE User = 'intel' AND Host != 'localhost';
EOF

# Update security groups to block suspicious IPs
aws ec2 revoke-security-group-ingress \
  --group-id sg-web12345 \
  --protocol tcp \
  --port 22 \
  --cidr 192.0.2.100/32
```

#### Phase 4: Recovery
```bash
#!/bin/bash
# Recovery Script

# Launch clean instances from golden AMI
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name abc-company-asg \
  --launch-template LaunchTemplateName=abc-company-secure-template,Version='$Latest'

# Force instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name abc-company-asg \
  --preferences InstanceWarmup=300,MinHealthyPercentage=50

# Verify system integrity
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["rpm -Va","find /var/www/html -type f -exec md5sum {} \;"]' \
  --targets "Key=tag:Environment,Values=production"
```

### Automated Security Response

#### Lambda Function for Automated Response
```python
import json
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Parse GuardDuty finding
    detail = event['detail']
    finding_type = detail['type']
    instance_id = detail['service']['resourceRole']
    
    if 'UnauthorizedAPICall' in finding_type:
        # Isolate instance
        response = ec2.modify_instance_attribute(
            InstanceId=instance_id,
            Groups=['sg-isolation123']
        )
        
        # Send notification
        sns = boto3.client('sns')
        sns.publish(
            TopicArn='arn:aws:sns:us-east-1:123456789012:security-alerts',
            Message=f'Security incident detected: {finding_type}. Instance {instance_id} isolated.',
            Subject='Security Alert - Automated Response Triggered'
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Incident response completed')
    }
```

---

## Compliance and Governance

### Security Baselines

#### CIS Benchmark Implementation
```bash
#!/bin/bash
# CIS Benchmark Security Hardening

# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled
echo "install cramfs /bin/true" >> /etc/modprobe.d/cramfs.conf

# 1.1.1.2 Ensure mounting of freevxfs filesystems is disabled
echo "install freevxfs /bin/true" >> /etc/modprobe.d/freevxfs.conf

# 3.1.1 Ensure IP forwarding is disabled
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf

# 3.2.1 Ensure source routed packets are not accepted
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf

# Apply sysctl settings
sysctl -p

# 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured
chmod 600 /etc/ssh/sshd_config

# 5.2.4 Ensure SSH X11 forwarding is disabled
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
```

### Regular Security Assessments

#### Automated Security Scanning
```bash
#!/bin/bash
# Weekly Security Assessment Script

DATE=$(date +%Y%m%d)
REPORT_FILE="security_assessment_$DATE.txt"

echo "=== Weekly Security Assessment - $DATE ===" > $REPORT_FILE

# Check for unused security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?length(IpPermissions)==`0`].GroupId' \
  --output text >> $REPORT_FILE

# Check for overly permissive security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?contains(IpPermissions[].IpRanges[].CidrIp, `0.0.0.0/0`)].[GroupId,GroupName]' \
  --output table >> $REPORT_FILE

# Check for unencrypted volumes
aws ec2 describe-volumes \
  --query 'Volumes[?Encrypted==`false`].[VolumeId,State]' \
  --output table >> $REPORT_FILE

# Check for public snapshots
aws ec2 describe-snapshots \
  --owner-ids self \
  --query 'Snapshots[?Encrypted==`false`].[SnapshotId,Public]' \
  --output table >> $REPORT_FILE

# Send report
aws ses send-email \
  --source security@company.com \
  --destination ToAddresses=admin@company.com \
  --message Subject="{Data='Weekly Security Assessment - $DATE'}",Body="{Text={Data='$(cat $REPORT_FILE)'}}"
```

This comprehensive security guide provides the foundation for maintaining a secure multi-tier website architecture on AWS. Regular review and updates of these security practices ensure protection against evolving threats and compliance with industry standards.