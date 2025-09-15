#!/bin/bash

# ABC Company Deployment Validation Script
# This script validates the multi-tier infrastructure deployment

# Variables (update with your actual values)
ALB_DNS_NAME="your-alb-dns-name.region.elb.amazonaws.com"
RDS_ENDPOINT="your-rds-endpoint.region.rds.amazonaws.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}ABC Company Deployment Validation${NC}"
echo "=================================="
echo ""

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}Testing: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
    fi
    echo ""
}

# Test 1: Load Balancer HTTP Response
run_test "Load Balancer HTTP connectivity" \
    "curl -s --max-time 10 -o /dev/null -w '%{http_code}' http://$ALB_DNS_NAME | grep -q '^2'"

# Test 2: Health Check Endpoint
run_test "Health check endpoint" \
    "curl -s --max-time 10 http://$ALB_DNS_NAME/health.php | grep -q 'healthy'"

# Test 3: PHP Info Page
run_test "PHP info page" \
    "curl -s --max-time 10 http://$ALB_DNS_NAME/info.php | grep -q 'PHP Version'"

# Test 4: RDS Connectivity (if mysql is available)
if command -v mysql &> /dev/null; then
    run_test "RDS database connectivity" \
        "mysql -h $RDS_ENDPOINT -u intel -pintel123 -e 'SELECT 1;' 2>/dev/null"
else
    echo -e "${YELLOW}Skipping RDS test - MySQL client not available${NC}"
    echo ""
fi

# Test 5: Load Balancer HTTPS (if configured)
run_test "Load Balancer HTTPS connectivity" \
    "curl -s --max-time 10 -k -o /dev/null -w '%{http_code}' https://$ALB_DNS_NAME | grep -q '^2'"

# Summary
echo "=================================="
echo -e "${BLUE}Test Results Summary${NC}"
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 All tests passed! Deployment is successful.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the configuration.${NC}"
    echo ""
    echo "Common issues:"
    echo "- Update ALB_DNS_NAME and RDS_ENDPOINT in this script"
    echo "- Ensure security groups allow traffic"
    echo "- Check if instances are healthy in target groups"
    echo "- Verify RDS is accessible from web tier"
    exit 1
fi