#!/bin/bash

# ABC Company Web Server Setup Script
# This script configures Apache, PHP, and MySQL client on Amazon Linux 2

# Update system packages
yum update -y

# Install Apache, PHP, and MySQL client
yum install -y httpd php php-mysql mysql

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Set correct permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create a simple info page
cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

# Download main application files (placeholder)
cd /var/www/html
# wget https://raw.githubusercontent.com/your-repo/website-files/index.php
# Replace with actual download commands for your website files

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "ABC-Company/WebServer",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/httpd/access_log",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/httpd/error_log",
                        "log_stream_name": "{instance_id}"
                    }
                ]
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

# Create health check endpoint
cat > /var/www/html/health.php << 'EOF'
<?php
header('Content-Type: application/json');

$health_status = array(
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'server' => gethostname(),
    'php_version' => phpversion(),
    'instance_id' => file_get_contents('http://169.254.169.254/latest/meta-data/instance-id')
);

// Check if Apache is running
$apache_status = exec('systemctl is-active httpd');
$health_status['apache'] = $apache_status;

if ($apache_status !== 'active') {
    $health_status['status'] = 'unhealthy';
    http_response_code(503);
}

echo json_encode($health_status, JSON_PRETTY_PRINT);
?>
EOF

# Log completion
echo "$(date): Web server setup completed successfully" >> /var/log/user-data.log