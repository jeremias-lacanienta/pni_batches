#!/bin/bash

# 99-cleanup-migration.sh
# Cleanup script for removing DynamoDB tables and resources
# Usage: ./99-cleanup-migration.sh [dev|prod] [--confirm]

set -e

# Disable AWS CLI pager
export AWS_PAGER=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with colors
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Parse arguments
ENVIRONMENT=""
CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        --confirm)
            CONFIRM=true
            shift
            ;;
        *)
            error "Unknown argument: $1"
            echo "Usage: $0 [dev|prod] [--confirm]"
            exit 1
            ;;
    esac
done

# Set default environment if not provided
if [[ -z "$ENVIRONMENT" ]]; then
    ENVIRONMENT="dev"
fi

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    error "Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

# Set configuration based on environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
    export TABLE_PREFIX="pni"  # Same table names, different regions
    export AWS_DEFAULT_REGION="us-east-1"
    export DB_NAME="genaicoe_postgresql"
else
    export TABLE_PREFIX="pni"  # Same table names, different regions
    export AWS_DEFAULT_REGION="eu-west-1"
    export DB_NAME="prod"
fi

log "🧹 Cleanup Migration for $ENVIRONMENT environment"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Table Prefix: $TABLE_PREFIX"
echo "AWS Region: $AWS_DEFAULT_REGION"
echo "=============================================="
echo

# Warning message
warning "⚠️  THIS WILL DELETE ALL MIGRATION DATA ⚠️"
echo
echo "The following actions will be performed:"
echo "• Delete DynamoDB tables: ${TABLE_PREFIX}-lessons, ${TABLE_PREFIX}-passages, ${TABLE_PREFIX}-topics, ${TABLE_PREFIX}-cache-metadata"
echo "• Remove migration metadata"
echo "• Clean up temporary files"
echo

if [[ "$CONFIRM" != true ]]; then
    echo "Type 'DELETE' to confirm cleanup (or Ctrl+C to cancel):"
    read -r confirmation
    
    if [[ "$confirmation" != "DELETE" ]]; then
        log "Cleanup cancelled"
        exit 0
    fi
fi

echo
log "🗂️  Checking existing tables..."

# Define tables to delete
TABLES=("${TABLE_PREFIX}-lessons" "${TABLE_PREFIX}-passages" "${TABLE_PREFIX}-topics" "${TABLE_PREFIX}-cache-metadata")
EXISTING_TABLES=()

for table in "${TABLES[@]}"; do
    if aws dynamodb describe-table --table-name "$table" > /dev/null 2>&1; then
        EXISTING_TABLES+=("$table")
        warning "Found table: $table"
    else
        log "Table not found: $table (skipping)"
    fi
done

if [[ ${#EXISTING_TABLES[@]} -eq 0 ]]; then
    warning "No tables found to delete"
else
    echo
    log "🗑️  Deleting DynamoDB tables..."
    
    for table in "${EXISTING_TABLES[@]}"; do
        log "Deleting table: $table"
        aws dynamodb delete-table --table-name "$table"
        success "Delete request sent for: $table"
    done
    
    echo
    log "⏳ Waiting for tables to be deleted..."
    
    for table in "${EXISTING_TABLES[@]}"; do
        log "Waiting for $table to be deleted..."
        
        # Wait for table to be deleted (with timeout)
        TIMEOUT=300  # 5 minutes
        ELAPSED=0
        
        while [[ $ELAPSED -lt $TIMEOUT ]]; do
            if ! aws dynamodb describe-table --table-name "$table" > /dev/null 2>&1; then
                success "Table deleted: $table"
                break
            fi
            
            sleep 10
            ELAPSED=$((ELAPSED + 10))
            echo -n "."
        done
        
        if [[ $ELAPSED -ge $TIMEOUT ]]; then
            error "Timeout waiting for $table to be deleted"
        fi
    done
fi

echo
log "🧹 Cleaning up local files..."

# Clean up temporary files
TEMP_FILES=(
    "migration-*.log"
    "*.tmp"
    ".migration_lock"
    "dynamodb-*.json"
)

for pattern in "${TEMP_FILES[@]}"; do
    if ls $pattern 1> /dev/null 2>&1; then
        rm -f $pattern
        success "Removed: $pattern"
    fi
done

# Clean up Python cache
if [[ -d "__pycache__" ]]; then
    rm -rf __pycache__
    success "Removed Python cache"
fi

if [[ -d ".pytest_cache" ]]; then
    rm -rf .pytest_cache
    success "Removed pytest cache"
fi

# Optional: Clean up virtual environment
echo
read -p "Do you want to remove the Python virtual environment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -d ".venv" ]]; then
        rm -rf .venv
        success "Removed virtual environment"
    else
        warning "Virtual environment not found"
    fi
fi

# Optional: Remove old migration scripts
echo
log "🗂️  Old migration scripts found:"
OLD_SCRIPTS=(
    "postgres-to-dynamodb.py"
    "postgres-to-dynamodbv2.py"
    "run-migration.sh"
    "create-dynamodb-user.sh"
)

FOUND_OLD_SCRIPTS=()
for script in "${OLD_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        FOUND_OLD_SCRIPTS+=("$script")
        warning "Found old script: $script"
    fi
done

if [[ ${#FOUND_OLD_SCRIPTS[@]} -gt 0 ]]; then
    echo
    read -p "Do you want to remove old migration scripts? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for script in "${FOUND_OLD_SCRIPTS[@]}"; do
            rm -f "$script"
            success "Removed: $script"
        done
    fi
fi

echo
log "📊 Verification..."

# Verify tables are deleted
REMAINING_TABLES=()
for table in "${EXISTING_TABLES[@]}"; do
    if aws dynamodb describe-table --table-name "$table" > /dev/null 2>&1; then
        REMAINING_TABLES+=("$table")
    fi
done

if [[ ${#REMAINING_TABLES[@]} -eq 0 ]]; then
    success "All tables successfully deleted"
else
    warning "Some tables still exist (may be in DELETING state):"
    for table in "${REMAINING_TABLES[@]}"; do
        echo "  - $table"
    done
fi

# Check for any remaining resources
log "🔍 Checking for remaining resources..."
ALL_TABLES=$(aws dynamodb list-tables --query "TableNames[?starts_with(@, '${TABLE_PREFIX}-')]" --output text)

if [[ -n "$ALL_TABLES" ]]; then
    warning "Remaining tables with prefix ${TABLE_PREFIX}-:"
    echo "$ALL_TABLES"
else
    success "No remaining tables with prefix ${TABLE_PREFIX}-"
fi

echo
log "📋 Cleanup Summary"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Tables Deleted: ${#EXISTING_TABLES[@]}"
echo "Region: $AWS_DEFAULT_REGION"
echo "Table Prefix: $TABLE_PREFIX"
echo "=============================================="

success "Cleanup completed!"

echo
warning "Note: IAM users and policies were not deleted automatically."
warning "If you want to remove IAM resources, please do so manually:"
echo "  - User: pni-dynamodb-${ENVIRONMENT}-user"
echo "  - Policy: PNI-DynamoDB-${ENVIRONMENT}-Policy"
