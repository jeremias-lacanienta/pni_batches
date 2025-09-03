#!/bin/bash

# ===========================================
# Quick Demo Script for PNI Tools
# ===========================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_demo() {
    echo -e "${BLUE}🎯 DEMO: $1${NC}"
    echo -e "${YELLOW}$2${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo ""
}

# Demo the tools
main() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}PNI Learning Platform - Tools Demo${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
    
    print_demo "HTTPie API Testing Tool" "Interactive menu for testing all API endpoints"
    echo "Available commands:"
    echo "  ./postman/httpie-tests.sh                 # Interactive menu"
    echo "  ./postman/httpie-tests.sh run_full_test_suite   # Run all tests"
    echo "  ./postman/httpie-tests.sh test_user_progress    # Test user progress API"
    echo ""
    
    print_demo "DynamoDB Management Tool" "Interactive menu for managing database tables and data"
    echo "Available commands:"
    echo "  ./postman/dynamodb-manager.sh             # Interactive menu"
    echo ""
    
    print_demo "Pure HTTPie Command Files" "Copy-paste ready HTTPie commands"
    echo "Available files:"
    echo "  postman/user-progress-api.httpie.txt           # User progress commands"
    echo "  postman/lesson-progress-manager.httpie.txt     # Lesson progress commands"
    echo ""
    
    print_demo "Quick Test Example" "Testing user progress API"
    echo "# Get user progress"
    echo "http GET http://localhost:3000/api/user-progress userId==default-user"
    echo ""
    echo "# Start a lesson"
    echo "http POST http://localhost:3000/api/lesson-progress-manager \\"
    echo "  action=\"start\" \\"
    echo "  userId=\"default-user\" \\"
    echo "  lessonId:=1 \\"
    echo "  level=\"beginner\""
    echo ""
    
    print_demo "DynamoDB Operations Example" "Managing user data"
    echo "# List all users"
    echo "aws dynamodb scan --table-name user-progress --projection-expression userId --region eu-west-1"
    echo ""
    echo "# Get table statistics"
    echo "aws dynamodb describe-table --table-name user-progress --region eu-west-1"
    echo ""
    
    print_success "Tools are ready to use!"
    
    echo "Next steps:"
    echo "1. Make sure the server is running: ./scripts/restart-servers.sh"
    echo "2. Test the APIs: ./postman/httpie-tests.sh"
    echo "3. Manage the database: ./postman/dynamodb-manager.sh"
    echo "4. Check the documentation: cat postman/README.md"
}

# Run demo
main "$@"
