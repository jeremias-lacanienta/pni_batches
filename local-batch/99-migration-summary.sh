#!/bin/bash

# 99-migration-summary.sh
# Generates a comprehensive summary of the migration status
# Usage: ./99-migration-summary.sh [dev|prod]

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

# Environment parameter
ENVIRONMENT=${1:-dev}

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

log "📊 Migration Summary for $ENVIRONMENT environment"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Table Prefix: $TABLE_PREFIX"
echo "AWS Region: $AWS_DEFAULT_REGION"
echo "Database: $DB_NAME"
echo "=============================================="
echo

# Check AWS CLI
log "🔍 Checking AWS CLI connectivity..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
    success "AWS CLI connected - Account: $ACCOUNT_ID"
    echo "   User: $USER_ARN"
else
    error "AWS CLI not configured or no access"
fi
echo

# Check DynamoDB Tables
log "🗂️  Checking DynamoDB tables..."
TABLES=("${TABLE_PREFIX}-lessons" "${TABLE_PREFIX}-passages" "${TABLE_PREFIX}-topics" "${TABLE_PREFIX}-cache-metadata")

for table in "${TABLES[@]}"; do
    if aws dynamodb describe-table --table-name "$table" > /dev/null 2>&1; then
        # Get item count
        ITEM_COUNT=$(aws dynamodb scan --table-name "$table" --select "COUNT" --query 'Count' --output text 2>/dev/null || echo "0")
        success "Table: $table (Items: $ITEM_COUNT)"
        
        # Get table status
        TABLE_STATUS=$(aws dynamodb describe-table --table-name "$table" --query 'Table.TableStatus' --output text)
        echo "   Status: $TABLE_STATUS"
        
        # Get billing mode
        BILLING_MODE=$(aws dynamodb describe-table --table-name "$table" --query 'Table.BillingModeSummary.BillingMode' --output text)
        echo "   Billing: $BILLING_MODE"
    else
        error "Table not found: $table"
    fi
done
echo

# Check PostgreSQL connectivity (if credentials available)
log "🐘 Checking PostgreSQL connectivity..."
AWS_CREDS_FILE="$HOME/.aws/credentials"
if [[ -f "$AWS_CREDS_FILE" ]]; then
    if grep -q "\[postgres-creds\]" "$AWS_CREDS_FILE"; then
        # Extract PostgreSQL credentials
        PG_HOST=$(awk -F'=' '/^\[postgres-creds\]/,/^\[/{if(/^pg_host/) print $2}' "$AWS_CREDS_FILE" | tr -d ' ')
        PG_USER=$(awk -F'=' '/^\[postgres-creds\]/,/^\[/{if(/^pg_user/) print $2}' "$AWS_CREDS_FILE" | tr -d ' ')
        PG_PASSWORD=$(awk -F'=' '/^\[postgres-creds\]/,/^\[/{if(/^pg_password/) print $2}' "$AWS_CREDS_FILE" | tr -d ' ')
        PG_PORT=$(awk -F'=' '/^\[postgres-creds\]/,/^\[/{if(/^pg_port/) print $2}' "$AWS_CREDS_FILE" | tr -d ' ')
        PG_PORT=${PG_PORT:-5432}
        
        if command -v psql > /dev/null 2>&1; then
            if PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
                success "PostgreSQL connected to $DB_NAME"
                
                # Get table counts
                LESSONS_COUNT=$(PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM lessons;" 2>/dev/null | tr -d ' ' || echo "0")
                QUESTIONS_COUNT=$(PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM questions;" 2>/dev/null | tr -d ' ' || echo "0")
                PASSAGES_COUNT=$(PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM passages;" 2>/dev/null | tr -d ' ' || echo "0")
                
                echo "   Source Data:"
                echo "     Lessons: $LESSONS_COUNT"
                echo "     Questions: $QUESTIONS_COUNT"
                echo "     Passages: $PASSAGES_COUNT"
            else
                warning "PostgreSQL connection failed to $DB_NAME"
            fi
        else
            warning "psql not available - cannot test PostgreSQL connection"
        fi
    else
        warning "PostgreSQL credentials not found in ~/.aws/credentials"
    fi
else
    warning "AWS credentials file not found"
fi
echo

# Check Python environment
log "🐍 Checking Python environment..."
if [[ -d ".venv" ]]; then
    success "Virtual environment exists"
    if [[ -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
        echo "   Python: $(python --version)"
        
        # Check required packages
        REQUIRED_PACKAGES=("boto3" "psycopg2-binary" "tabulate")
        for package in "${REQUIRED_PACKAGES[@]}"; do
            if pip show "$package" > /dev/null 2>&1; then
                VERSION=$(pip show "$package" | grep Version | cut -d' ' -f2)
                success "   $package: $VERSION"
            else
                error "   $package: Not installed"
            fi
        done
        deactivate
    else
        error "Virtual environment corrupted"
    fi
else
    warning "Virtual environment not found"
fi
echo

# Migration scripts status
log "📜 Checking migration scripts..."
SCRIPTS=("00-run-migration.sh" "01-setup-environment.sh" "02-validate-prerequisites.sh" "03-create-aws-resources.sh" "04-run-migration.sh" "05-verify-migration.sh" "postgres-to-dynamodb-unified.py")

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            success "$script (executable)"
        else
            warning "$script (not executable)"
        fi
    else
        error "$script (missing)"
    fi
done
echo

# Get last migration metadata
log "🕒 Last migration information..."
if aws dynamodb get-item --table-name "${TABLE_PREFIX}-cache-metadata" --key '{"cache_key":{"S":"migration_'$ENVIRONMENT'"}}' > /dev/null 2>&1; then
    LAST_MIGRATION=$(aws dynamodb get-item --table-name "${TABLE_PREFIX}-cache-metadata" --key '{"cache_key":{"S":"migration_'$ENVIRONMENT'"}}' --query 'Item.created_at.S' --output text 2>/dev/null || echo "Unknown")
    success "Last migration: $LAST_MIGRATION"
else
    warning "No migration metadata found"
fi
echo

# Summary
log "📋 Summary"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_DEFAULT_REGION"
echo "Database: $DB_NAME"
echo "Table Prefix: $TABLE_PREFIX"
echo "=============================================="

success "Migration summary completed!"
