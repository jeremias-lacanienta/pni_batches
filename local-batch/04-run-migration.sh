#!/bin/bash
# Step 4: Run Migration
# Executes the PostgreSQL to DynamoDB data migration

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
    echo -e "${BLUE}[MIGRATE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[MIGRATE]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[MIGRATE]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[MIGRATE]${NC} ⚠️ $1"
}

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    export DB_NAME="genaicoe_postgresql"
    export AWS_DEFAULT_REGION="us-east-1"
    TABLE_PREFIX="pni"  # Same table names, different regions
    PYTHON_SCRIPT="$SCRIPT_DIR/postgres-to-dynamodb-unified.py"
else
    export DB_NAME="prod"
    export AWS_DEFAULT_REGION="eu-west-1"
    TABLE_PREFIX="pni"  # Same table names, different regions
    PYTHON_SCRIPT="$SCRIPT_DIR/postgres-to-dynamodb-unified.py"
fi

log "🚀 Starting data migration for $ENVIRONMENT environment"
log "   Source DB: $DB_NAME"
log "   Target Region: $AWS_DEFAULT_REGION"
log "   Table Prefix: $TABLE_PREFIX"

# Export environment variables for the Python script
export TABLE_PREFIX
export ENVIRONMENT
export CLEAN_MIGRATION=${CLEAN_MIGRATION:-false}

log "🔍 Migration Mode: $(if [[ "$CLEAN_MIGRATION" == "true" ]]; then echo "CLEAN (tables recreated)"; else echo "INCREMENTAL (check existing data)"; fi)"

# Check if migration script exists
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    log_error "Migration script not found: $PYTHON_SCRIPT"
    exit 1
fi

log "🐍 Using migration script: $(basename "$PYTHON_SCRIPT")"

# Display pre-migration summary
echo ""
log "📋 Migration will create/update:"
log "   📚 ${TABLE_PREFIX}-lessons (lesson-focused: concatenated passages)"
log "   📄 ${TABLE_PREFIX}-passages (passage-focused: individual passages)"
log "   🏷️  ${TABLE_PREFIX}-topics (topic hierarchies)"
log "   📊 ${TABLE_PREFIX}-cache-metadata (migration metadata)"
log "   👤 ${TABLE_PREFIX}-lesson-progress (student progress tracking)"
echo ""

# Confirm migration start
log "⏱️ Migration starting in 3 seconds..."
sleep 3

# Run the migration
log "🔄 Executing migration script..."
start_time=$(date +%s)

if python3 "$PYTHON_SCRIPT"; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    log_success "Migration completed successfully!"
    log "⏱️ Total duration: ${duration} seconds"
else
    log_error "Migration failed!"
    log "📋 Check the error messages above for details"
    exit 1
fi

echo ""
log "📊 Migration Summary:"
log "   ✅ Data successfully migrated from PostgreSQL to DynamoDB"
log "   🎯 Environment: $ENVIRONMENT" 
log "   📈 Source: $DB_NAME"
log "   🌐 Target: $AWS_DEFAULT_REGION"
log "   ⏱️ Duration: ${duration} seconds"

echo ""
log_success "Step 4 completed: Data migration successful"

echo ""
log "🔍 Next: Run verification to confirm data integrity"
