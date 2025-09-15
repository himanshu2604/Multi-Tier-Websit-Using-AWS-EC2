# 🚀 Multi-Tier Website Implementation Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Phase 1: Database Tier Setup](#phase-1-database-tier-setup)
3. [Phase 2: Application Tier Setup](#phase-2-application-tier-setup)
4. [Phase 3: Load Balancer Configuration](#phase-3-load-balancer-configuration)
5. [Phase 4: Auto Scaling Configuration](#phase-4-auto-scaling-configuration)
6. [Phase 5: Testing & Validation](#phase-5-testing--validation)
7. [Post-Deployment Tasks](#post-deployment-tasks)

## Prerequisites

### AWS Account Requirements
- AWS Account with appropriate permissions
- IAM user with the following policies:
  - `AmazonEC2FullAccess`
  - `AmazonRDSFullAccess`
  - `ElasticLoadBalancingFullAccess`
  - `AutoScalingFullAccess`
  - `CloudWatchFullAccess`

### Local Environment Setup
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI
aws configure
# Enter your Access Key ID, Secret Access Key, Region, and Output format
```

### Required Information
- VPC ID and Subnet IDs (or create new ones)
- SSH Key Pair name
- Database credentials (username: intel, password: intel123)
- Your IP address for SSH access

## Phase 1: Database Tier Setup

### Step 1.1: Create Database Subnet Group

1. Navigate to **RDS Console** → **Subnet Groups**
2. Click **Create DB Subnet Group**
3. Configure:
   ```
   Name: abc-company-db-subnet-group
   Description: Subnet group for ABC Company database
   VPC: Select your VPC
   Availability Zones: Select at least 2 AZs
   Subnets: Select private subnets in each AZ
   ```

### Step 1.2: Create Security Group for Database

1. Navigate to **EC2 Console** → **Security Groups**
2. Create new security group:
   ```
   Name: abc-company-db-sg
   Description: Security group for RDS database
   VPC: Select your VPC
   
   Inbound Rules:
   - Type: MySQL/Aurora (3306)
   - Source: Custom (Web tier security group - to be created)
   ```

### Step 1.3: Create RDS MySQL Instance

1. Navigate to **RDS Console** → **Databases**
2. Click **Create Database**
3. Configure:

   **Engine Options:**
   ```
   Engine type: MySQL
   Version: MySQL 8.0.35
   ```

   **Templates:**
   ```
   Select: Free tier
   ```

   **Settings:**
   ```
   DB instance identifier: abc-company-db
   Master username: intel
   Master password: intel123
   ```

   **DB Instance Class:**
   ```
   Instance type: db.t3.micro
   ```

   **Storage:**
   ```
   Storage type: General Purpose SSD (gp2)
   Allocated storage: 20 GiB
   Enable storage autoscaling: Yes
   ```

   **Connectivity:**
   ```
   VPC: Select your VPC
   DB subnet group: abc-company-db-subnet-group
   Public access: No
   VPC security groups: abc-company-db-sg
   ```

4. Click **Create Database**
5. Wait for status to become "Available" (5-10 minutes)

### Step 1.4: Setup Database Schema

1. Connect to RDS from a bastion host or EC2 instance in the same VPC:
   ```bash
   mysql -h <RDS_ENDPOINT> -u intel -p
   ```

2. Create database and table:
   ```sql
   CREATE DATABASE intel;
   USE intel;
   
   CREATE TABLE data (
       id INT AUTO_INCREMENT PRIMARY KEY,
       firstname VARCHAR(50) NOT NULL,
       email VARCHAR(100) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   -- Insert sample data
   INSERT INTO data (firstname, email) VALUES 
   ('John', 'john@example.com'),
   ('Jane', 'jane@example.com'),
   ('Bob', 'bob@example.com');
   ```

## Phase 2: Application Tier Setup

### Step 2.1: Create Security Group for Web Tier

1. Navigate to **EC2 Console** → **Security Groups**
2. Create new security group:
   ```
   Name: abc-company-web-sg
   Description: Security group for web tier
   VPC: Select your VPC
   
   Inbound Rules:
   - Type: HTTP (80), Source: 0.0.0.0/0
   - Type: HTTPS (443), Source: 0.0.0.0/0
   - Type: SSH (22), Source: Your IP address
   ```

3. Update database security group:
   - Edit **abc-company-db-sg**
   - Add inbound rule: MySQL/Aurora (3306) from **abc-company-web-sg**

### Step 2.2: Create Launch Template

1. Navigate to **EC2 Console** → **Launch Templates**
2. Click **Create Launch Template**
3. Configure:

   **Template Name:**
   ```
   Name: abc-company-web-template
   Description: Launch template for ABC Company web servers
   ```

   **Application and OS Images:**
   ```
   AMI: Amazon Linux 2 AMI (HVM), SSD Volume Type
   ```

   **Instance Type:**
   ```
   Instance type: t2.micro
   ```

   **Key Pair:**
   ```
   Key pair name: Select your existing key pair
   ```

   **Network Settings:**
   ```
   Security groups: abc-company-web-sg
   ```

   **Advanced Details - User Data:**
   ```bash
   #!/bin/bash
   yum update -y
   yum install -y httpd php php-mysql
   systemctl start httpd
   systemctl enable httpd
   
   # Download application files
   cd /var/www/html
   
   # Create index.php
   cat > index.php << 'EOF'
   <?php
   $servername = "YOUR_RDS_ENDPOINT";
   $username = "intel";
   $password = "intel123";
   $dbname = "intel";
   
   try {
       $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
       $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
       
       echo "<h1>ABC Company - Multi-Tier Website</h1>";
       echo "<h2>Connected to Database Successfully!</h2>";
       echo "<p>Server: " . $_SERVER['SERVER_ADDR'] . "</p>";
       echo "<p>Instance ID: " . file_get_contents('http://169.254.169.254/latest/meta-data/instance-id') . "</p>";
       
       // Display data from database
       $stmt = $pdo->query("SELECT * FROM data ORDER BY created_at DESC");
       echo "<h3>Database Records:</h3>";
       echo "<table border='1' style='border-collapse: collapse;'>";
       echo "<tr><th>ID</th><th>First Name</th><th>Email</th><th>Created At</th></tr>";
       
       while ($row = $stmt->fetch()) {
           echo "<tr>";
           echo "<td>" . $row['id'] . "</td>";
           echo "<td>" . $row['firstname'] . "</td>";
           echo "<td>" . $row['email'] . "</td>";
           echo "<td>" . $row['created_at'] . "</td>";
           echo "</tr>";
       }
       echo "</table>";
       
   } catch(PDOException $e) {
       echo "<h1>Connection failed: " . $e->getMessage() . "</h1>";
   }
   ?>
   
   <hr>
   <form method="post" action="">
       <h3>Add New Record:</h3>
       <input type="text" name="firstname" placeholder="First Name" required>
       <input type="email" name="email" placeholder="Email" required>
       <input type="submit" name="submit" value="Add Record">
   </form>
   
   <?php
   if (isset($_POST['submit'])) {
       try {
           $stmt = $pdo->prepare("INSERT INTO data (firstname, email) VALUES (?, ?)");
           $stmt->execute([$_POST['firstname'], $_POST['email']]);
           echo "<p>Record added successfully! <a href=''>Refresh</a></p>";
       } catch(PDOException $e) {
           echo "<p>Error: " . $e->getMessage() . "</p>";
       }
   }
   ?>
   EOF
   
   # Replace RDS endpoint in the file
   RDS_ENDPOINT=$(aws rds describe-db-instances --region us-east-1 --db-instance-identifier abc-company-db --query 'DBInstances[0].Endpoint.Address' --output text)
   sed -i "s/YOUR_RDS_ENDPOINT/$RDS_ENDPOINT/g" /var/www/html/index.php
   
   systemctl restart httpd
   ```

4. Click **Create Launch Template**

## Phase 3: Load Balancer Configuration

### Step 3.1: Create Target Group

1. Navigate to **EC2 Console** → **Target Groups**
2. Click **Create Target Group**
3. Configure:
   ```
   Target type: Instances
   Target group name: abc-company-web-tg
   Protocol: HTTP
   Port: 80
   VPC: Select your VPC
   
   Health checks:
   - Health check path: /
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   - Timeout: 5 seconds
   - Interval: 30 seconds
   ```

### Step 3.2: Create Application Load Balancer

1. Navigate to **EC2 Console** → **Load Balancers**
2. Click **Create Load Balancer** → **Application Load Balancer**
3. Configure:

   **Basic Configuration:**
   ```
   Name: abc-company-alb
   Scheme: Internet-facing
   IP address type: IPv4
   ```

   **Network Mapping:**
   ```
   VPC: Select your VPC
   Mappings: Select at least 2 public subnets in different AZs
   ```

   **Security Groups:**
   ```
   Select: abc-company-web-sg
   ```

   **Listeners:**
   ```
   Protocol: HTTP
   Port: 80
   Default action: Forward to abc-company-web-tg
   ```

4. Click **Create Load Balancer**

## Phase 4: Auto Scaling Configuration

### Step 4.1: Create Auto Scaling Group

1. Navigate to **EC2 Console** → **Auto Scaling Groups**
2. Click **Create Auto Scaling Group**
3. Configure:

   **Step 1 - Choose launch template:**
   ```
   Name: abc-company-asg
   Launch template: abc-company-web-template
   Version: Latest
   ```

   **Step 2 - Configure settings:**
   ```
   VPC: Select your VPC
   Subnets: Select private subnets in multiple AZs
   ```

   **Step 3 - Configure advanced options:**
   ```
   Load balancing: Attach to an existing load balancer
   Target groups: abc-company-web-tg
   Health checks: ELB
   Health check grace period: 300 seconds
   ```

   **Step 4 - Configure group size:**
   ```
   Desired capacity: 2
   Minimum capacity: 2
   Maximum capacity: 6
   ```

   **Step 5 - Add scaling policies:**
   ```
   Scaling policy: Target tracking scaling policy
   Scaling policy name: cpu-scaling-policy
   Metric type: Average CPU Utilization
   Target value: 70
   ```

4. Click **Create Auto Scaling Group**

### Step 4.2: Configure CloudWatch Alarms

Auto Scaling Group will automatically create CloudWatch alarms, but you can customize them:

1. Navigate to **CloudWatch Console** → **Alarms**
2. Review and modify the auto-created alarms if needed

## Phase 5: Testing & Validation

### Step 5.1: Test Load Balancer

1. Get ALB DNS name from EC2 Console → Load Balancers
2. Open browser and navigate to: `http://YOUR_ALB_DNS_NAME`
3. Verify:
   - Website loads successfully
   - Database connection works
   - Different instance IDs appear on refresh

### Step 5.2: Test Auto Scaling

Generate load to test scaling:
```bash
# Install stress testing tool on a separate EC2 instance
sudo yum install -y httpd-tools

# Generate load
ab -n 10000 -c 100 http://YOUR_ALB_DNS_NAME/
```

Monitor scaling in EC2 Console → Auto Scaling Groups.

### Step 5.3: Test Database Functionality

1. Add records through the web interface
2. Verify records are stored in RDS
3. Test from multiple instances

### Step 5.4: Test High Availability

1. Terminate one EC2 instance manually
2. Verify ALB redirects traffic to healthy instances
3. Verify Auto Scaling launches replacement instance

## Post-Deployment Tasks

### Monitor Resources
- Set up CloudWatch dashboards
- Configure billing alerts
- Review security group rules

### Optimization
- Review performance metrics
- Adjust scaling policies if needed
- Optimize database queries

### Backup Strategy
- Enable RDS automated backups
- Create manual snapshots
- Document recovery procedures

### Security Hardening
- Review and tighten security groups
- Enable SSL/TLS certificates
- Implement WAF if needed

## Troubleshooting Common Issues

### Website Not Loading
1. Check security group rules
2. Verify target group health
3. Check EC2 instance user data logs

### Database Connection Issues
1. Verify RDS endpoint in code
2. Check security group rules for RDS
3. Ensure instances are in correct subnets

### Auto Scaling Not Working
1. Check CloudWatch metrics
2. Verify scaling policies
3. Review Auto Scaling Group configuration

---

**Next Steps:** Refer to the [Architecture Overview](architecture-overview.md) for detailed technical information about the system design.