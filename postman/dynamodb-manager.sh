#!/bin/bash
# DynamoDB management tool
# ...existing code or placeholder...
#!/bin/bash

# ===========================================
# DynamoDB Manager Tool for PNI Learning Platform
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"eu-west-1"}
USER_PROGRESS_TABLE="user-progress"
LESSONS_TABLE="pni-lessons"
PASSAGES_TABLE="pni-passages"
DEFAULT_USER_ID="default-user"

# Helper functions
print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured and ready"
}

# User Progress Management
delete_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_header "Deleting User Progress for: $user_id"
    
    # Get all progress items for the user
    local items=$(aws dynamodb query \
        --table-name "$USER_PROGRESS_TABLE" \
        --key-condition-expression "userId = :userId" \
        --expression-attribute-values '{":userId":{"S":"'$user_id'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq -r '.Items[]')
    
    if [ -z "$items" ]; then
        print_warning "No progress found for user: $user_id"
        return
    fi
    
    # Delete all items
    echo "$items" | jq -r '{userId: .userId.S, progressKey: .progressKey.S}' | while read -r item; do
        local userId=$(echo "$item" | jq -r '.userId')
        local progressKey=$(echo "$item" | jq -r '.progressKey')
        
        aws dynamodb delete-item \
            --table-name "$USER_PROGRESS_TABLE" \
            --key '{"userId":{"S":"'$userId'"},"progressKey":{"S":"'$progressKey'"}}' \
            --region "$AWS_REGION" 2>/dev/null
        
        print_success "Deleted progress: $progressKey"
    done
    
    print_success "All progress deleted for user: $user_id"
}

list_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_header "User Progress for: $user_id"
    
    aws dynamodb query \
        --table-name "$USER_PROGRESS_TABLE" \
        --key-condition-expression "userId = :userId" \
        --expression-attribute-values '{":userId":{"S":"'$user_id'"}}' \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to retrieve user progress"
}

list_all_users() {
    print_header "All Users in Database"
    
    aws dynamodb scan \
        --table-name "$USER_PROGRESS_TABLE" \
        --projection-expression "userId" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | \
        jq -r '.Items[].userId.S' | sort | uniq || print_error "Failed to retrieve users"
}

# Lesson Management
list_lessons() {
    print_header "All Lessons"
    
    aws dynamodb scan \
        --table-name "$LESSONS_TABLE" \
        --projection-expression "lesson_id, title, #level, difficulty_level" \
        --expression-attribute-names '{"#level": "level"}' \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to retrieve lessons"
}

get_lesson_details() {
    local lesson_id=$1
    local level=$2
    
    if [ -z "$lesson_id" ] || [ -z "$level" ]; then
        print_error "Usage: get_lesson_details <lesson_id> <level>"
        return 1
    fi
    
    print_header "Lesson Details: ID=$lesson_id, Level=$level"
    
    aws dynamodb get-item \
        --table-name "$LESSONS_TABLE" \
        --key '{"lesson_id":{"N":"'$lesson_id'"},"level":{"S":"'$level'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.' || print_error "Failed to retrieve lesson details"
}

# Passage Management
list_passages() {
    local lesson_id=$1
    
    print_header "Passages for Lesson: $lesson_id"
    
    if [ -z "$lesson_id" ]; then
        # List all passages
        aws dynamodb scan \
            --table-name "$PASSAGES_TABLE" \
            --projection-expression "lesson_id, passage_id, title, question_count" \
            --region "$AWS_REGION" \
            --output table 2>/dev/null || print_error "Failed to retrieve passages"
    else
        # List passages for specific lesson
        aws dynamodb query \
            --table-name "$PASSAGES_TABLE" \
            --key-condition-expression "lesson_id = :lesson_id" \
            --expression-attribute-values '{":lesson_id":{"N":"'$lesson_id'"}}' \
            --projection-expression "lesson_id, passage_id, title, question_count" \
            --region "$AWS_REGION" \
            --output table 2>/dev/null || print_error "Failed to retrieve passages for lesson $lesson_id"
    fi
}

get_passage_details() {
    local lesson_id=$1
    local passage_id=$2
    
    if [ -z "$lesson_id" ] || [ -z "$passage_id" ]; then
        print_error "Usage: get_passage_details <lesson_id> <passage_id>"
        return 1
    fi
    
    print_header "Passage Details: Lesson=$lesson_id, Passage=$passage_id"
    
    aws dynamodb get-item \
        --table-name "$PASSAGES_TABLE" \
        --key '{"lesson_id":{"N":"'$lesson_id'"},"passage_id":{"S":"'$passage_id'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.' || print_error "Failed to retrieve passage details"
}

# Database Operations
backup_table() {
    local table_name=$1
    local backup_name="${table_name}-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -z "$table_name" ]; then
        print_error "Usage: backup_table <table_name>"
        return 1
    fi
    
    print_header "Creating Backup: $backup_name"
    
    aws dynamodb create-backup \
        --table-name "$table_name" \
        --backup-name "$backup_name" \
        --region "$AWS_REGION" 2>/dev/null && \
        print_success "Backup created: $backup_name" || \
        print_error "Failed to create backup for $table_name"
}

list_backups() {
    print_header "Available Backups"
    
    aws dynamodb list-backups \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to list backups"
}

# Table Statistics
table_stats() {
    local table_name=$1
    
    if [ -z "$table_name" ]; then
        print_error "Usage: table_stats <table_name>"
        return 1
    fi
    
    print_header "Table Statistics: $table_name"
    
    # Get table description
    aws dynamodb describe-table \
        --table-name "$table_name" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | \
        jq '{
            TableName: .Table.TableName,
            ItemCount: .Table.ItemCount,
            TableSizeBytes: .Table.TableSizeBytes,
            Status: .Table.TableStatus,
            CreationDateTime: .Table.CreationDateTime
        }' || print_error "Failed to get table statistics"
    
    # Get item count
    local item_count=$(aws dynamodb scan \
        --table-name "$table_name" \
        --select "COUNT" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.Count')
    
    print_info "Current item count: $item_count"
}

# HTTPie Test Commands
run_httpie_tests() {
    print_header "Running HTTPie API Tests"
    
    local base_url="http://localhost:3000"
    
    # Check if server is running
    if ! curl -s "$base_url" > /dev/null; then
        print_error "Server is not running at $base_url"
        print_info "Please start the server first with: ./scripts/restart-servers.sh"
        return 1
    fi
    
    print_info "Testing User Progress API..."
    
    # Test get user progress
    echo -e "${CYAN}GET User Progress:${NC}"
    http GET "$base_url/api/user-progress" userId=="$DEFAULT_USER_ID" || print_warning "Get user progress failed"
    
    echo -e "${CYAN}GET Lesson Progress:${NC}"
    http GET "$base_url/api/lesson-progress-manager" userId=="$DEFAULT_USER_ID" lessonId==1 level==beginner || print_warning "Get lesson progress failed"
    
    print_success "HTTPie tests completed"
}

# Menu System
show_menu() {
    clear
    print_header "DynamoDB Manager for PNI Learning Platform"
    echo -e "${YELLOW}Current Region: $AWS_REGION${NC}"
    echo -e "${YELLOW}Default User: $DEFAULT_USER_ID${NC}"
    echo ""
    echo -e "${CYAN}USER PROGRESS MANAGEMENT:${NC}"
    echo "1)  List user progress"
    echo "2)  Delete user progress"
    echo "3)  List all users"
    echo ""
    echo -e "${CYAN}LESSON MANAGEMENT:${NC}"
    echo "4)  List all lessons"
    echo "5)  Get lesson details"
    echo ""
    echo -e "${CYAN}PASSAGE MANAGEMENT:${NC}"
    echo "6)  List all passages"
    echo "7)  List passages for lesson"
    echo "8)  Get passage details"
    echo ""
    echo -e "${CYAN}DATABASE OPERATIONS:${NC}"
    echo "9)  Table statistics"
    echo "10) Create table backup"
    echo "11) List backups"
    echo ""
    echo -e "${CYAN}TESTING:${NC}"
    echo "12) Run HTTPie API tests"
    echo ""
    echo -e "${CYAN}OTHER:${NC}"
    echo "13) Change default user ID"
    echo "14) Change AWS region"
    echo ""
    echo "0)  Exit"
    echo ""
    echo -n "Select an option [0-14]: "
}

# Read user input
read_input() {
    local choice
    read choice
    case $choice in
        1)
            echo ""
            echo -n "Enter user ID (press Enter for default: $DEFAULT_USER_ID): "
            read user_id
            list_user_progress "${user_id:-$DEFAULT_USER_ID}"
            ;;
        2)
            echo ""
            echo -n "Enter user ID to delete progress (press Enter for default: $DEFAULT_USER_ID): "
            read user_id
            echo -e "${RED}WARNING: This will delete ALL progress for user: ${user_id:-$DEFAULT_USER_ID}${NC}"
            echo -n "Are you sure? (yes/no): "
            read confirm
            if [ "$confirm" = "yes" ]; then
                delete_user_progress "${user_id:-$DEFAULT_USER_ID}"
            else
                print_info "Operation cancelled"
            fi
            ;;
        3)
            list_all_users
            ;;
        4)
            list_lessons
            ;;
        5)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            echo -n "Enter level: "
            read level
            get_lesson_details "$lesson_id" "$level"
            ;;
        6)
            list_passages
            ;;
        7)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            list_passages "$lesson_id"
            ;;
        8)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            echo -n "Enter passage ID: "
            read passage_id
            get_passage_details "$lesson_id" "$passage_id"
            ;;
        9)
            echo ""
            echo "Available tables:"
            echo "  1) $USER_PROGRESS_TABLE"
            echo "  2) $LESSONS_TABLE"
            echo "  3) $PASSAGES_TABLE"
            echo -n "Select table (1-3) or enter custom name: "
            read table_choice
            case $table_choice in
                1) table_stats "$USER_PROGRESS_TABLE" ;;
                2) table_stats "$LESSONS_TABLE" ;;
                3) table_stats "$PASSAGES_TABLE" ;;
                *) table_stats "$table_choice" ;;
            esac
            ;;
        10)
            echo ""
            echo "Available tables:"
            echo "  1) $USER_PROGRESS_TABLE"
            echo "  2) $LESSONS_TABLE"
            echo "  3) $PASSAGES_TABLE"
            echo -n "Select table (1-3) or enter custom name: "
            read table_choice
            case $table_choice in
                1) backup_table "$USER_PROGRESS_TABLE" ;;
                2) backup_table "$LESSONS_TABLE" ;;
                3) backup_table "$PASSAGES_TABLE" ;;
                *) backup_table "$table_choice" ;;
            esac
            ;;
        11)
            list_backups
            ;;
        12)
            run_httpie_tests
            ;;
        13)
            echo ""
            echo -n "Enter new default user ID: "
            read new_user_id
            if [ -n "$new_user_id" ]; then
                DEFAULT_USER_ID="$new_user_id"
                print_success "Default user ID changed to: $DEFAULT_USER_ID"
            fi
            ;;
        14)
            echo ""
            echo -n "Enter new AWS region: "
            read new_region
            if [ -n "$new_region" ]; then
                AWS_REGION="$new_region"
                print_success "AWS region changed to: $AWS_REGION"
            fi
            ;;
        0)
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check prerequisites
    check_aws_cli
    
    # Main loop
    while true; do
        show_menu
        read_input
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/bin/bash

# ===========================================
# DynamoDB Manager Tool for PNI Learning Platform
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"eu-west-1"}
USER_PROGRESS_TABLE="user-progress"
LESSONS_TABLE="pni-lessons"
PASSAGES_TABLE="pni-passages"
DEFAULT_USER_ID="default-user"

# Helper functions
print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured and ready"
}

# User Progress Management
delete_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_header "Deleting User Progress for: $user_id"
    
    # Get all progress items for the user
    local items=$(aws dynamodb query \
        --table-name "$USER_PROGRESS_TABLE" \
        --key-condition-expression "userId = :userId" \
        --expression-attribute-values '{":userId":{"S":"'$user_id'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq -r '.Items[]')
    
    if [ -z "$items" ]; then
        print_warning "No progress found for user: $user_id"
        return
    fi
    
    # Delete all items
    echo "$items" | jq -r '{userId: .userId.S, progressKey: .progressKey.S}' | while read -r item; do
        local userId=$(echo "$item" | jq -r '.userId')
        local progressKey=$(echo "$item" | jq -r '.progressKey')
        
        aws dynamodb delete-item \
            --table-name "$USER_PROGRESS_TABLE" \
            --key '{"userId":{"S":"'$userId'"},"progressKey":{"S":"'$progressKey'"}}' \
            --region "$AWS_REGION" 2>/dev/null
        
        print_success "Deleted progress: $progressKey"
    done
    
    print_success "All progress deleted for user: $user_id"
}

list_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_header "User Progress for: $user_id"
    
    aws dynamodb query \
        --table-name "$USER_PROGRESS_TABLE" \
        --key-condition-expression "userId = :userId" \
        --expression-attribute-values '{":userId":{"S":"'$user_id'"}}' \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to retrieve user progress"
}

list_all_users() {
    print_header "All Users in Database"
    
    aws dynamodb scan \
        --table-name "$USER_PROGRESS_TABLE" \
        --projection-expression "userId" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | \
        jq -r '.Items[].userId.S' | sort | uniq || print_error "Failed to retrieve users"
}

# Lesson Management
list_lessons() {
    print_header "All Lessons"
    
    aws dynamodb scan \
        --table-name "$LESSONS_TABLE" \
        --projection-expression "lesson_id, title, #level, difficulty_level" \
        --expression-attribute-names '{"#level": "level"}' \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to retrieve lessons"
}

get_lesson_details() {
    local lesson_id=$1
    local level=$2
    
    if [ -z "$lesson_id" ] || [ -z "$level" ]; then
        print_error "Usage: get_lesson_details <lesson_id> <level>"
        return 1
    fi
    
    print_header "Lesson Details: ID=$lesson_id, Level=$level"
    
    aws dynamodb get-item \
        --table-name "$LESSONS_TABLE" \
        --key '{"lesson_id":{"N":"'$lesson_id'"},"level":{"S":"'$level'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.' || print_error "Failed to retrieve lesson details"
}

# Passage Management
list_passages() {
    local lesson_id=$1
    
    print_header "Passages for Lesson: $lesson_id"
    
    if [ -z "$lesson_id" ]; then
        # List all passages
        aws dynamodb scan \
            --table-name "$PASSAGES_TABLE" \
            --projection-expression "lesson_id, passage_id, title, question_count" \
            --region "$AWS_REGION" \
            --output table 2>/dev/null || print_error "Failed to retrieve passages"
    else
        # List passages for specific lesson
        aws dynamodb query \
            --table-name "$PASSAGES_TABLE" \
            --key-condition-expression "lesson_id = :lesson_id" \
            --expression-attribute-values '{":lesson_id":{"N":"'$lesson_id'"}}' \
            --projection-expression "lesson_id, passage_id, title, question_count" \
            --region "$AWS_REGION" \
            --output table 2>/dev/null || print_error "Failed to retrieve passages for lesson $lesson_id"
    fi
}

get_passage_details() {
    local lesson_id=$1
    local passage_id=$2
    
    if [ -z "$lesson_id" ] || [ -z "$passage_id" ]; then
        print_error "Usage: get_passage_details <lesson_id> <passage_id>"
        return 1
    fi
    
    print_header "Passage Details: Lesson=$lesson_id, Passage=$passage_id"
    
    aws dynamodb get-item \
        --table-name "$PASSAGES_TABLE" \
        --key '{"lesson_id":{"N":"'$lesson_id'"},"passage_id":{"S":"'$passage_id'"}}' \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.' || print_error "Failed to retrieve passage details"
}

# Database Operations
backup_table() {
    local table_name=$1
    local backup_name="${table_name}-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -z "$table_name" ]; then
        print_error "Usage: backup_table <table_name>"
        return 1
    fi
    
    print_header "Creating Backup: $backup_name"
    
    aws dynamodb create-backup \
        --table-name "$table_name" \
        --backup-name "$backup_name" \
        --region "$AWS_REGION" 2>/dev/null && \
        print_success "Backup created: $backup_name" || \
        print_error "Failed to create backup for $table_name"
}

list_backups() {
    print_header "Available Backups"
    
    aws dynamodb list-backups \
        --region "$AWS_REGION" \
        --output table 2>/dev/null || print_error "Failed to list backups"
}

# Table Statistics
table_stats() {
    local table_name=$1
    
    if [ -z "$table_name" ]; then
        print_error "Usage: table_stats <table_name>"
        return 1
    fi
    
    print_header "Table Statistics: $table_name"
    
    # Get table description
    aws dynamodb describe-table \
        --table-name "$table_name" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | \
        jq '{
            TableName: .Table.TableName,
            ItemCount: .Table.ItemCount,
            TableSizeBytes: .Table.TableSizeBytes,
            Status: .Table.TableStatus,
            CreationDateTime: .Table.CreationDateTime
        }' || print_error "Failed to get table statistics"
    
    # Get item count
    local item_count=$(aws dynamodb scan \
        --table-name "$table_name" \
        --select "COUNT" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null | jq '.Count')
    
    print_info "Current item count: $item_count"
}

# HTTPie Test Commands
run_httpie_tests() {
    print_header "Running HTTPie API Tests"
    
    local base_url="http://localhost:3000"
    
    # Check if server is running
    if ! curl -s "$base_url" > /dev/null; then
        print_error "Server is not running at $base_url"
        print_info "Please start the server first with: ./scripts/restart-servers.sh"
        return 1
    fi
    
    print_info "Testing User Progress API..."
    
    # Test get user progress
    echo -e "${CYAN}GET User Progress:${NC}"
    http GET "$base_url/api/user-progress" userId=="$DEFAULT_USER_ID" || print_warning "Get user progress failed"
    
    echo -e "${CYAN}GET Lesson Progress:${NC}"
    http GET "$base_url/api/lesson-progress-manager" userId=="$DEFAULT_USER_ID" lessonId==1 level==beginner || print_warning "Get lesson progress failed"
    
    print_success "HTTPie tests completed"
}

# Menu System
show_menu() {
    clear
    print_header "DynamoDB Manager for PNI Learning Platform"
    echo -e "${YELLOW}Current Region: $AWS_REGION${NC}"
    echo -e "${YELLOW}Default User: $DEFAULT_USER_ID${NC}"
    echo ""
    echo -e "${CYAN}USER PROGRESS MANAGEMENT:${NC}"
    echo "1)  List user progress"
    echo "2)  Delete user progress"
    echo "3)  List all users"
    echo ""
    echo -e "${CYAN}LESSON MANAGEMENT:${NC}"
    echo "4)  List all lessons"
    echo "5)  Get lesson details"
    echo ""
    echo -e "${CYAN}PASSAGE MANAGEMENT:${NC}"
    echo "6)  List all passages"
    echo "7)  List passages for lesson"
    echo "8)  Get passage details"
    echo ""
    echo -e "${CYAN}DATABASE OPERATIONS:${NC}"
    echo "9)  Table statistics"
    echo "10) Create table backup"
    echo "11) List backups"
    echo ""
    echo -e "${CYAN}TESTING:${NC}"
    echo "12) Run HTTPie API tests"
    echo ""
    echo -e "${CYAN}OTHER:${NC}"
    echo "13) Change default user ID"
    echo "14) Change AWS region"
    echo ""
    echo "0)  Exit"
    echo ""
    echo -n "Select an option [0-14]: "
}

# Read user input
read_input() {
    local choice
    read choice
    case $choice in
        1)
            echo ""
            echo -n "Enter user ID (press Enter for default: $DEFAULT_USER_ID): "
            read user_id
            list_user_progress "${user_id:-$DEFAULT_USER_ID}"
            ;;
        2)
            echo ""
            echo -n "Enter user ID to delete progress (press Enter for default: $DEFAULT_USER_ID): "
            read user_id
            echo -e "${RED}WARNING: This will delete ALL progress for user: ${user_id:-$DEFAULT_USER_ID}${NC}"
            echo -n "Are you sure? (yes/no): "
            read confirm
            if [ "$confirm" = "yes" ]; then
                delete_user_progress "${user_id:-$DEFAULT_USER_ID}"
            else
                print_info "Operation cancelled"
            fi
            ;;
        3)
            list_all_users
            ;;
        4)
            list_lessons
            ;;
        5)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            echo -n "Enter level: "
            read level
            get_lesson_details "$lesson_id" "$level"
            ;;
        6)
            list_passages
            ;;
        7)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            list_passages "$lesson_id"
            ;;
        8)
            echo ""
            echo -n "Enter lesson ID: "
            read lesson_id
            echo -n "Enter passage ID: "
            read passage_id
            get_passage_details "$lesson_id" "$passage_id"
            ;;
        9)
            echo ""
            echo "Available tables:"
            echo "  1) $USER_PROGRESS_TABLE"
            echo "  2) $LESSONS_TABLE"
            echo "  3) $PASSAGES_TABLE"
            echo -n "Select table (1-3) or enter custom name: "
            read table_choice
            case $table_choice in
                1) table_stats "$USER_PROGRESS_TABLE" ;;
                2) table_stats "$LESSONS_TABLE" ;;
                3) table_stats "$PASSAGES_TABLE" ;;
                *) table_stats "$table_choice" ;;
            esac
            ;;
        10)
            echo ""
            echo "Available tables:"
            echo "  1) $USER_PROGRESS_TABLE"
            echo "  2) $LESSONS_TABLE"
            echo "  3) $PASSAGES_TABLE"
            echo -n "Select table (1-3) or enter custom name: "
            read table_choice
            case $table_choice in
                1) backup_table "$USER_PROGRESS_TABLE" ;;
                2) backup_table "$LESSONS_TABLE" ;;
                3) backup_table "$PASSAGES_TABLE" ;;
                *) backup_table "$table_choice" ;;
            esac
            ;;
        11)
            list_backups
            ;;
        12)
            run_httpie_tests
            ;;
        13)
            echo ""
            echo -n "Enter new default user ID: "
            read new_user_id
            if [ -n "$new_user_id" ]; then
                DEFAULT_USER_ID="$new_user_id"
                print_success "Default user ID changed to: $DEFAULT_USER_ID"
            fi
            ;;
        14)
            echo ""
            echo -n "Enter new AWS region: "
            read new_region
            if [ -n "$new_region" ]; then
                AWS_REGION="$new_region"
                print_success "AWS region changed to: $AWS_REGION"
            fi
            ;;
        0)
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check prerequisites
    check_aws_cli
    
    # Main loop
    while true; do
        show_menu
        read_input
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
