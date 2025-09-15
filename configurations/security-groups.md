# 🔒 Security Groups Configuration

## Overview
This document outlines the security group configurations for the ABC Company multi-tier website architecture. The security groups implement a layered security approach with proper network segmentation between tiers.

## Architecture Security Design
```
Internet Gateway
    ↓ (Port 80, 443)
ALB Security Group
    ↓ (Port 80 from ALB)
Web Tier Security Group
    ↓ (Port 3306 from Web Tier)
Database Tier Security Group
```

## 1. Application Load Balancer Security Group

**Name**: `alb-security-group`  
**Description**: Security group for Application Load Balancer

### Inbound Rules
| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Allow HTTP traffic from internet |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Allow HTTPS traffic from internet |

### Outbound Rules
| Type | Protocol | Port Range | Destination | Description |
|------|----------|------------|-------------|-------------|
| HTTP | TCP | 80 | web-tier-sg | Forward HTTP to web tier |
| All Traffic | All | All | 0.0.0.0/0 | Default outbound rule |

**AWS CLI Command:**
```bash
# Create ALB Security Group
aws ec2 create-security-group \
    --group-name alb-security-group \
    --description "Security group for Application Load Balancer" \
    --vpc-id vpc-xxxxxxxxx

# Add inbound rules
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

## 2. Web Tier Security Group

**Name**: `web-tier-security-group`  
**Description**: Security group for web servers (EC2 instances)

### Inbound Rules
| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| HTTP | TCP | 80 | alb-security-group | Allow traffic from ALB only |
| SSH | TCP | 22 | Your-IP/32 | SSH access for management |

### Outbound Rules
| Type | Protocol | Port Range | Destination | Description |
|------|----------|------------|-------------|-------------|
| MySQL/Aurora | TCP | 3306 | db-tier-sg | Database access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Package updates |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Package updates |

**AWS CLI Command:**
```bash
# Create Web Tier Security Group
aws ec2 create-security-group \
    --group-name web-tier-security-group \
    --description "Security group for web servers" \
    --vpc-id vpc-xxxxxxxxx

# Add inbound rules
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 80 \
    --source-group sg-alb-security-group-id

aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 22 \
    --cidr YOUR-IP/32
```

## 3. Database Tier Security Group

**Name**: `database-tier-security-group`  
**Description**: Security group for RDS MySQL database

### Inbound Rules
| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| MySQL/Aurora | TCP | 3306 | web-tier-sg | Allow MySQL access from web tier only |

### Outbound Rules
| Type | Protocol | Port Range | Destination | Description |
|------|----------|------------|-------------|-------------|
| All Traffic | All | All | 0.0.0.0/0 | Default outbound (usually not needed for RDS) |

**AWS CLI Command:**
```bash
# Create Database Tier Security Group
aws ec2 create-security-group \
    --group-name database-tier-security-group \
    --description "Security group for RDS MySQL database" \
    --vpc-id vpc-xxxxxxxxx

# Add inbound rule
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 3306 \
    --source-group sg-web-tier-security-group-id
```

## 4. Management Security Group (Optional)

**Name**: `management-security-group`  
**Description**: Security group for administrative access

### Inbound Rules
| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your-IP/32 | SSH access from admin IP |
| RDP | TCP | 3389 | Your-IP/32 | RDP access (if Windows instances) |

## Security Best Practices

### 1. Principle of Least Privilege
- Only allow necessary ports and protocols
- Restrict source/destination to specific security groups where possible
- Avoid using 0.0.0.0/0 except for public-facing services

### 2. Network Segmentation
- Web tier accepts traffic only from ALB
- Database tier accepts traffic only from web tier
- No direct internet access to database tier

### 3. Regular Security Reviews
- Audit security group rules quarterly
- Remove unused rules and security groups
- Monitor CloudTrail for security group changes

### 4. Tagging Strategy
```bash
# Tag security groups for better organization
aws ec2 create-tags \
    --resources sg-xxxxxxxxx \
    --tags Key=Project,Value=ABC-Company-Migration \
           Key=Tier,Value=Web \
           Key=Environment,Value=Production \
           Key=Owner,Value=CloudAdmin
```

## Implementation Checklist

- [ ] Create VPC if not already exists
- [ ] Create ALB security group with internet access
- [ ] Create Web tier security group with ALB access only
- [ ] Create Database tier security group with web tier access only
- [ ] Test connectivity between tiers
- [ ] Verify no direct internet access to database
- [ ] Apply proper tags to all security groups
- [ ] Document security group IDs for reference

## Troubleshooting

### Common Issues
1. **Connection Timeout**: Check if source security group is correctly referenced
2. **Access Denied**: Verify port numbers and protocols match application requirements
3. **Can't Connect to RDS**: Ensure database security group allows MySQL port 3306 from web tier

### Testing Commands
```bash
# Test web server connectivity
curl -I http://your-alb-dns-name

# Test database connectivity from web server
mysql -h your-rds-endpoint -u intel -p intel

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

## Related Documentation
- [AWS Security Groups Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [Multi-Tier Architecture Security](../documentation/architecture-overview.md)
- [Auto Scaling Configuration](auto-scaling-config.md)