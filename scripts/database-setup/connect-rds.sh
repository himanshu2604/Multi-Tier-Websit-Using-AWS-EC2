#!/bin/bash

# ABC Company RDS Connection Script
# This script helps connect to RDS MySQL instance and run setup

# Variables (update these with your actual values)
RDS_ENDPOINT="your-rds-endpoint.region.rds.amazonaws.com"
DB_USERNAME="intel"
DB_PASSWORD="intel123"
DB_NAME="intel"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}ABC Company RDS Connection Script${NC}"
echo "=================================="

# Check if mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}MySQL client is not installed. Installing...${NC}"
    if command -v yum &> /dev/null; then
        yum install -y mysql
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y mysql-client
    else
        echo -e "${RED}Please install MySQL client manually${NC}"
        exit 1
    fi
fi

# Function to test connection
test_connection() {
    echo -e "${YELLOW}Testing connection to RDS...${NC}"
    mysql -h $RDS_ENDPOINT -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Connection successful!${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed!${NC}"
        return 1
    fi
}

# Function to run schema setup
setup_schema() {
    echo -e "${YELLOW}Running database schema setup...${NC}"
    mysql -h $RDS_ENDPOINT -u $DB_USERNAME -p$DB_PASSWORD < schema.sql
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Schema setup completed successfully!${NC}"
    else
        echo -e "${RED}✗ Schema setup failed!${NC}"
        exit 1
    fi
}

# Function to show connection details
show_connection_info() {
    echo -e "${YELLOW}Connection Details:${NC}"
    echo "RDS Endpoint: $RDS_ENDPOINT"
    echo "Username: $DB_USERNAME"
    echo "Database: $DB_NAME"
    echo ""
}

# Main execution
case "${1:-help}" in
    "test")
        show_connection_info
        test_connection
        ;;
    "setup")
        show_connection_info
        if test_connection; then
            setup_schema
        fi
        ;;
    "connect")
        show_connection_info
        echo -e "${YELLOW}Connecting to RDS MySQL...${NC}"
        mysql -h $RDS_ENDPOINT -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME
        ;;
    "help"|*)
        echo "Usage: $0 {test|setup|connect}"
        echo ""
        echo "Commands:"
        echo "  test    - Test connection to RDS"
        echo "  setup   - Run database schema setup"
        echo "  connect - Connect to RDS MySQL shell"
        echo ""
        echo "Before running, update the variables in this script:"
        echo "  - RDS_ENDPOINT"
        echo "  - DB_USERNAME" 
        echo "  - DB_PASSWORD"
        echo "  - DB_NAME"
        ;;
esac