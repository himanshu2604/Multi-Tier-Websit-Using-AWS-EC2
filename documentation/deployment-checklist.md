# ✅ Multi-Tier Website Deployment Checklist

## Pre-Deployment Checklist

### Account & Access Requirements
- [ ] AWS Account with appropriate permissions
- [ ] IAM user with required policies:
  - [ ] `AmazonEC2FullAccess`
  - [ ] `AmazonRDSFullAccess`
  - [ ] `ElasticLoadBalancingFullAccess`
  - [ ] `AutoScalingFullAccess`
  - [ ] `CloudWatchFullAccess`
- [ ] SSH Key Pair created and downloaded
- [ ] AWS CLI configured with credentials
- [ ] Admin IP address identified for SSH access

### Network Planning
- [ ] VPC CIDR range defined (e.g., 10.0.0.0/16)
- [ ] Availability zones selected (minimum 2)
- [ ] Subnet CIDR ranges planned:
  - [ ] Public subnets for Load Balancer
  - [ ] Private subnets for Web Tier
  - [ ] Private subnets for Database Tier
- [ ] Internet Gateway requirements confirmed
- [ ] NAT Gateway requirements assessed (if needed)

### Database Planning
- [ ] Database credentials defined:
  - [ ] Username: intel
  - [ ] Password: intel123 (or secure alternative)
- [ ] RDS instance specifications confirmed:
  - [ ] Engine: MySQL 8.0.35
  - [ ] Instance class: db.t3.micro
  - [ ] Storage: 20GB minimum
  - [ ] Multi-AZ: Enabled
- [ ] Database schema requirements documented

## Phase 1: Infrastructure Setup

### VPC and Networking
- [ ] VPC created with correct CIDR block
- [ ] Internet Gateway attached to VPC
- [ ] Public subnets created in multiple AZs
- [ ] Private subnets created for web tier
- [ ] Private subnets created for database tier
- [ ] Route tables configured correctly
- [ ] Network ACLs reviewed and configured

### Security Groups Creation
- [ ] Load Balancer Security Group created
  - [ ] Inbound: HTTP (80) from 0.0.0.0/0
  - [ ] Inbound: HTTPS (443) from 0.0.0.0/0
  - [ ] Outbound: HTTP (80) to Web Tier SG
- [ ] Web Tier Security Group created
  - [ ] Inbound: HTTP (80) from ALB SG
  - [ ] Inbound: SSH (22) from Admin IP
  - [ ] Outbound: All traffic (for updates and DB access)
- [ ] Database Security Group created
  - [ ] Inbound: MySQL (3306) from Web Tier SG
  - [ ] Outbound: None (default deny)

### Database Tier Setup
- [ ] Database Subnet Group created
  - [ ] Includes subnets from multiple AZs
  - [ ] Subnets are in private tier
- [ ] RDS MySQL instance launched
  - [ ] Correct instance identifier
  - [ ] Proper security group assigned
  - [ ] Multi-AZ deployment enabled
  - [ ] Backup retention configured (7 days)
- [ ] Database status confirmed as "Available"
- [ ] Database endpoint recorded

## Phase 2: Database Configuration

### Schema Creation
- [ ] Database connection established from bastion/EC2
- [ ] Database "intel" created
- [ ] Table "data" created with correct schema:
  - [ ] id (INT, AUTO_INCREMENT, PRIMARY KEY)
  - [ ] firstname (VARCHAR 50, NOT NULL)
  - [ ] email (VARCHAR 100, NOT NULL)
  - [ ] created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- [ ] Sample data inserted for testing
- [ ] Database connectivity verified

## Phase 3: Application Tier Setup

### Launch Template Creation
- [ ] Launch template created with:
  - [ ] Name: abc-company-web-template
  - [ ] AMI: Amazon Linux 2 (latest)
  - [ ] Instance type: t2.micro
  - [ ] Key pair assigned
  - [ ] Security group assigned (web tier)
  - [ ] User data script configured
- [ ] User data script includes:
  - [ ] Apache installation and configuration
  - [ ] PHP installation
  - [ ] Application code deployment
  - [ ] RDS endpoint substitution
  - [ ] Service startup commands

### Load Balancer Setup
- [ ] Target Group created:
  - [ ] Name: abc-company-web-tg
  - [ ] Protocol: HTTP, Port: 80
  - [ ] Health check path: /
  - [ ] Health check settings optimized
- [ ] Application Load Balancer created:
  - [ ] Name: abc-company-alb
  - [ ] Internet-facing scheme
  - [ ] Multiple AZ deployment
  - [ ] Correct security group
  - [ ] Target group associated
- [ ] ALB DNS name recorded

### Auto Scaling Group Configuration
- [ ] Auto Scaling Group created:
  - [ ] Name: abc-company-asg
  - [ ] Launch template associated
  - [ ] Subnets selected (private web tier)
  - [ ] Target group attached
  - [ ] Health check type: ELB
- [ ] Group size configured:
  - [ ] Minimum: 2 instances
  - [ ] Desired: 2 instances
  - [ ] Maximum: 6 instances
- [ ] Scaling policies configured:
  - [ ] Target tracking policy
  - [ ] CPU utilization metric
  - [ ] Target value: 70%
  - [ ] Cooldown periods set

## Phase 4: Testing & Validation

### Basic Functionality Tests
- [ ] Website accessible via ALB DNS name
- [ ] Database connection successful
- [ ] Sample records display correctly
- [ ] Form submission works
- [ ] New records saved to database
- [ ] Instance ID displayed (for load balancing verification)

### Load Balancer Tests
- [ ] Multiple page refreshes show different instance IDs
- [ ] Health checks passing for all instances
- [ ] Target group shows healthy targets
- [ ] Load distribution appears balanced

### Auto Scaling Tests
- [ ] Initial instance count matches desired (2)
- [ ] All instances healthy in target group
- [ ] CloudWatch metrics collecting data
- [ ] Scaling alarms configured and active

### High Availability Tests
- [ ] Terminate one instance manually
- [ ] Verify traffic continues to flow
- [ ] Confirm ASG launches replacement
- [ ] New instance becomes healthy
- [ ] Service remains available throughout

### Database Tests
- [ ] Database connectivity from all web instances
- [ ] CRUD operations functioning
- [ ] Connection pooling working
- [ ] No database connection errors in logs

## Phase 5: Performance & Security Validation

### Performance Validation
- [ ] Response time < 500ms for simple requests
- [ ] Database queries < 100ms
- [ ] No memory leaks or resource issues
- [ ] Error rate < 1%

### Security Validation
- [ ] Database not accessible from internet
- [ ] SSH access limited to admin IP
- [ ] Security groups follow least privilege
- [ ] No unnecessary ports open
- [ ] RDS in private subnets only

### Monitoring Setup
- [ ] CloudWatch alarms configured
- [ ] Auto Scaling notifications set up
- [ ] Database monitoring enabled
- [ ] Application logs accessible

## Phase 6: Load Testing

### Load Test Preparation
- [ ] Load testing tool installed (Apache Bench)
- [ ] Test parameters defined:
  - [ ] Concurrent users: 100
  - [ ] Total requests: 10,000
  - [ ] Test duration: 10 minutes
- [ ] Monitoring dashboards ready

### Load Test Execution
- [ ] Load test executed successfully
- [ ] Auto scaling triggered at expected threshold
- [ ] New instances launched and became healthy
- [ ] Performance remained acceptable under load
- [ ] No errors during scaling events

### Load Test Validation
- [ ] All requests completed successfully
- [ ] Response times within acceptable limits
- [ ] Auto scaling worked as expected
- [ ] Scale-in occurred after load reduction
- [ ] System returned to desired capacity

## Phase 7: Documentation & Cleanup

### Documentation
- [ ] Architecture diagram updated
- [ ] Deployment steps documented
- [ ] Configuration parameters recorded
- [ ] Troubleshooting guide created
- [ ] Access credentials securely stored

### Final Validation
- [ ] All components functioning correctly
- [ ] Cost optimization reviewed
- [ ] Security best practices confirmed
- [ ] Performance benchmarks established
- [ ] Backup and recovery tested

### Production Readiness
- [ ] Monitoring alerts configured
- [ ] Backup schedule validated
- [ ] Security hardening completed
- [ ] SSL certificate ready (if applicable)
- [ ] DNS configuration planned

## Post-Deployment Checklist

### Operational Readiness
- [ ] Runbook created for common operations
- [ ] Incident response procedures documented
- [ ] Contact information for support teams
- [ ] Escalation procedures defined
- [ ] Change management process documented

### Cost Management
- [ ] Billing alerts configured
- [ ] Resource tagging implemented
- [ ] Cost optimization recommendations noted
- [ ] Reserved Instance opportunities identified
- [ ] Monthly cost review scheduled

### Security Hardening
- [ ] Security group rules minimized
- [ ] Unused ports closed
- [ ] Log retention policies set
- [ ] Access patterns monitored
- [ ] Vulnerability assessment scheduled

## Rollback Plan

### Emergency Rollback
- [ ] Rollback decision criteria defined
- [ ] Database backup created before deployment
- [ ] Previous configuration documented
- [ ] Rollback procedures tested
- [ ] Communication plan for rollback

### Rollback Execution Steps
1. [ ] Stop accepting new traffic
2. [ ] Complete in-flight transactions
3. [ ] Scale down new infrastructure
4. [ ] Restore previous configuration
5. [ ] Verify system functionality
6. [ ] Resume normal operations

## Sign-off Requirements

### Technical Validation
- [ ] Solution Architect approval
- [ ] Security team approval
- [ ] Database Administrator approval
- [ ] Network team approval

### Business Validation
- [ ] Business stakeholder approval
- [ ] Performance criteria met
- [ ] Cost targets achieved
- [ ] Timeline objectives met

### Final Go-Live Approval
- [ ] All checklist items completed
- [ ] Stakeholder sign-offs received
- [ ] Support teams notified
- [ ] Monitoring systems active
- [ ] Ready for production traffic

---

**Deployment Team:**
- **Lead**: _________________
- **Date**: _________________
- **Environment**: Production/Staging/Dev
- **Version**: _________________

**Final Status:** ✅ **APPROVED** / ❌ **REJECTED**

**Notes:**
_________________________________
_________________________________
_________________________________