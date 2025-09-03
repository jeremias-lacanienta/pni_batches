#!/bin/bash
# Step 3: Create AWS Resources
# Creates DynamoDB tables (lessons table excluded as requested)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENVIRONMENT=${1:-dev}
VENV_DIR="$SCRIPT_DIR/.venv"

# Disable AWS CLI pager
export AWS_PAGER=""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[RESOURCES]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[RESOURCES]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[RESOURCES]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[RESOURCES]${NC} ⚠️ $1"
}

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    export AWS_DEFAULT_REGION="us-east-1"
    export TABLE_PREFIX="pni"
else
    export AWS_DEFAULT_REGION="eu-west-1"
    export TABLE_PREFIX="pni"
fi

log "🏗️ Creating AWS resources for $ENVIRONMENT environment"
log "   Region: $AWS_DEFAULT_REGION"
log "   Table prefix: $TABLE_PREFIX"

# Define table names (lessons table excluded as requested)
PASSAGES_TABLE="${TABLE_PREFIX}-passages"
TOPICS_TABLE="${TABLE_PREFIX}-topics"
CACHE_METADATA_TABLE="${TABLE_PREFIX}-cache-metadata"

TABLES=("$PASSAGES_TABLE" "$TOPICS_TABLE" "$CACHE_METADATA_TABLE")

# Function to create DynamoDB table
create_table() {
    local table_name=$1
    local key_schema=$2
    local attribute_definitions=$3
    
    log "📊 Creating table: $table_name"
    
    if aws dynamodb describe-table --table-name "$table_name" --region "$AWS_DEFAULT_REGION" &>/dev/null; then
        log_warning "Table $table_name already exists, skipping creation"
        return 0
    fi
    
    aws dynamodb create-table \
        --table-name "$table_name" \
        --key-schema "$key_schema" \
        --attribute-definitions "$attribute_definitions" \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_DEFAULT_REGION" \
        --no-cli-pager \
        --output json > /dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Created table: $table_name"
        
        # Wait for table to be active
        log "⏳ Waiting for table $table_name to become active..."
        aws dynamodb wait table-exists --table-name "$table_name" --region "$AWS_DEFAULT_REGION"
        log_success "Table $table_name is now active"
        return 0
    else
        log_error "Failed to create table: $table_name"
        return 1
    fi
}

# Create passages table  
create_table "$PASSAGES_TABLE" \
    'AttributeName=id,KeyType=HASH' \
    'AttributeName=id,AttributeType=S'

# Create topics table
create_table "$TOPICS_TABLE" \
    'AttributeName=level,KeyType=HASH' \
    'AttributeName=level,AttributeType=S'

# Create cache metadata table
create_table "$CACHE_METADATA_TABLE" \
    'AttributeName=cache_key,KeyType=HASH' \
    'AttributeName=cache_key,AttributeType=S'

echo ""
log "📋 Verifying all tables are created and active..."

for table in "${TABLES[@]}"; do
    if aws dynamodb describe-table --table-name "$table" --region "$AWS_DEFAULT_REGION" &>/dev/null; then
        status=$(aws dynamodb describe-table --table-name "$table" --region "$AWS_DEFAULT_REGION" --query 'Table.TableStatus' --output text)
        if [[ "$status" == "ACTIVE" ]]; then
            log_success "Table verified: $table (status: $status)"
        else
            log_warning "Table $table status: $status"
        fi
    else
        log_error "Table not found: $table"
        exit 1
    fi
done

echo ""
log_success "All DynamoDB tables created and verified successfully"

echo ""
log "📊 Resource Creation Summary:"
log "   🌍 Environment: $ENVIRONMENT"
log "   📍 Region: $AWS_DEFAULT_REGION"
log "   📊 Tables created: ${#TABLES[@]} (lessons table excluded as requested)"
for table in "${TABLES[@]}"; do
    log "     ✅ $table"
done
echo ""

log_success "Step 3 completed: AWS resources created"
