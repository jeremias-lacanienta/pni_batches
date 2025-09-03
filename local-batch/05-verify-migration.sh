#!/bin/bash
# Step 5: Verify Migration
#!/bin/bash
# Step 5: Verify Migration
# Validates that data was migrated successfully to DynamoDB

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENVIRONMENT=${1:-dev}
VENV_DIR="$SCRIPT_DIR/.venv"

# Disable AWS CLI pager
export AWS_PAGER=""

# Colors for output

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENVIRONMENT=${1:-dev}
VENV_DIR="$SCRIPT_DIR/.venv"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[VERIFY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[VERIFY]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[VERIFY]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[VERIFY]${NC} ⚠️ $1"
}

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    export AWS_DEFAULT_REGION="us-east-1"
    export TABLE_PREFIX="pni"  # Same table names, different regions
else
    export AWS_DEFAULT_REGION="eu-west-1"
    export TABLE_PREFIX="pni"  # Same table names, different regions
fi

log "🔍 Verifying migration for $ENVIRONMENT environment"
log "   Region: $AWS_DEFAULT_REGION"
log "   Table prefix: $TABLE_PREFIX"

# Define table names (only tables actually used by the application)
PASSAGES_TABLE="${TABLE_PREFIX}-passages"
TOPICS_TABLE="${TABLE_PREFIX}-topics"
CACHE_METADATA_TABLE="${TABLE_PREFIX}-cache-metadata"

TABLES=("$PASSAGES_TABLE" "$TOPICS_TABLE" "$CACHE_METADATA_TABLE")

echo ""
log "📊 Checking table status and item counts..."

# Function to get table item count
get_item_count() {
    local table_name=$1
    local count=$(aws dynamodb scan --table-name "$table_name" --region "$AWS_DEFAULT_REGION" --select "COUNT" --query "Count" --output text 2>/dev/null || echo "0")
    echo "$count"
}

# Function to get table status
get_table_status() {
    local table_name=$1
    local status=$(aws dynamodb describe-table --table-name "$table_name" --region "$AWS_DEFAULT_REGION" --query "Table.TableStatus" --output text 2>/dev/null || echo "NOT_FOUND")
    echo "$status"
}

TOTAL_ITEMS=0
verification_failed=false

for table in "${TABLES[@]}"; do
    status=$(get_table_status "$table")
    
    if [[ "$status" == "ACTIVE" ]]; then
        count=$(get_item_count "$table")
        TOTAL_ITEMS=$((TOTAL_ITEMS + count))
        
        if [[ "$count" -gt 0 ]]; then
            log_success "📊 $table: $count items"
        else
            log_warning "📊 $table: $count items (table is empty)"
        fi
    else
        log_error "📊 $table: $status"
        verification_failed=true
    fi
done

if [[ "$verification_failed" == true ]]; then
    log_error "Some tables are not in ACTIVE state"
    exit 1
fi

echo ""
log "🔍 Running data integrity checks..."

# Create verification script
python3 << EOF
import boto3
import sys
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb', region_name='$AWS_DEFAULT_REGION')

def verify_table_structure(table_name, expected_keys):
    try:
        table = dynamodb.Table(table_name)
        response = table.scan(Limit=1)
        
        if response['Items']:
            item = response['Items'][0]
            missing_keys = [key for key in expected_keys if key not in item]
            if missing_keys:
                print(f"❌ {table_name}: Missing required keys: {missing_keys}")
                return False
            else:
                print(f"✅ {table_name}: Schema validation passed")
                return True
        else:
            if table_name.endswith('lesson-progress'):
                print(f"⚠️  {table_name}: Empty table (normal for progress)")
                return True
            else:
                print(f"⚠️  {table_name}: No items to verify")
                return True
    except Exception as e:
        print(f"❌ {table_name}: Verification failed: {e}")
        return False

# Verify table structures
verification_results = []

# Passages table  
verification_results.append(verify_table_structure('$PASSAGES_TABLE', ['id', 'passage_content', 'questions']))

# Topics table
verification_results.append(verify_table_structure('$TOPICS_TABLE', ['level', 'topics']))

# Cache metadata table
verification_results.append(verify_table_structure('$CACHE_METADATA_TABLE', ['cache_key', 'created_at']))

# Overall verification result
if all(verification_results):
    print("\n✅ All table structure verifications passed")
    sys.exit(0)
else:
    print("\n❌ Some table structure verifications failed")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    log_success "Data structure validation passed"
else
    log_error "Data structure validation failed"
    exit 1
fi

echo ""
log "📈 Migration Verification Summary:"
log "   ✅ All tables are ACTIVE"
log "   ✅ Data structure validation passed"
log "   📊 Total items migrated: $TOTAL_ITEMS"
log "   🌐 Region: $AWS_DEFAULT_REGION"
log "   🎯 Environment: $ENVIRONMENT"

echo ""
log_success "Step 5 completed: Migration verification successful"

echo ""
log "🎉 Migration pipeline completed successfully!"
echo ""
log "📋 What's been created:"
for table in "${TABLES[@]}"; do
    count=$(get_item_count "$table")
    log "   📊 $table ($count items)"
done

echo ""
log "🚀 Ready to use!"
log "   1. Update your application configuration to use these DynamoDB tables"
log "   2. Run ./99-generate-summary.sh $ENVIRONMENT for detailed report"
log "   3. Monitor DynamoDB metrics in AWS Console"
