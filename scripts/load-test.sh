#!/bin/bash

# ABC Company Load Testing Script
# Simple load testing to trigger auto scaling

# Variables
ALB_DNS_NAME="your-alb-dns-name.region.elb.amazonaws.com"
REQUESTS=1000
CONCURRENCY=50
DURATION=300  # 5 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}ABC Company Load Testing Script${NC}"
echo "================================"
echo ""

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo -e "${YELLOW}Installing Apache Bench...${NC}"
    if command -v yum &> /dev/null; then
        yum install -y httpd-tools
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y apache2-utils
    else
        echo -e "${RED}Please install Apache Bench (ab) manually${NC}"
        exit 1
    fi
fi

# Function to run load test
run_load_test() {
    local test_name="$1"
    local url="$2"
    local requests="$3"
    local concurrency="$4"
    
    echo -e "${YELLOW}Running $test_name...${NC}"
    echo "URL: $url"
    echo "Requests: $requests"
    echo "Concurrency: $concurrency"
    echo ""
    
    ab -n $requests -c $concurrency -g results.dat "$url"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Load test completed successfully${NC}"
    else
        echo -e "${RED}✗ Load test failed${NC}"
    fi
    echo ""
}

# Function to monitor scaling
monitor_scaling() {
    echo -e "${YELLOW}Monitoring Auto Scaling activity...${NC}"
    echo "Check your AWS Console for:"
    echo "- CloudWatch metrics showing increased CPU utilization"
    echo "- Auto Scaling Group launching new instances"
    echo "- Load Balancer distributing traffic"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    
    while true; do
        echo -n "$(date): Load testing in progress..."
        curl -s -o /dev/null -w " Response: %{http_code} | Time: %{time_total}s\n" "http://$ALB_DNS_NAME/"
        sleep 5
    done
}

# Main execution
case "${1:-help}" in
    "quick")
        run_load_test "Quick Load Test" "http://$ALB_DNS_NAME/" 500 25
        ;;
    "medium")
        run_load_test "Medium Load Test" "http://$ALB_DNS_NAME/" $REQUESTS $CONCURRENCY
        ;;
    "stress")
        run_load_test "Stress Test" "http://$ALB_DNS_NAME/" 2000 100
        ;;
    "monitor")
        monitor_scaling
        ;;
    "help"|*)
        echo "Usage: $0 {quick|medium|stress|monitor}"
        echo ""
        echo "Commands:"
        echo "  quick   - Quick test (500 requests, 25 concurrent)"
        echo "  medium  - Medium test (1000 requests, 50 concurrent)"
        echo "  stress  - Stress test (2000 requests, 100 concurrent)"
        echo "  monitor - Monitor scaling activity"
        echo ""
        echo "Before running, update ALB_DNS_NAME in this script"
        echo ""
        echo "Expected behavior:"
        echo "- CPU utilization should increase on instances"
        echo "- Auto Scaling should launch new instances at 70% CPU"
        echo "- Load should be distributed across healthy instances"
        ;;
esac