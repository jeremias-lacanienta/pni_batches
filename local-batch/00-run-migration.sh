#!/bin/bash
# Unified PostgreSQL to DynamoDB Migration Coordinator
# Usage: ./00-run-migration.sh [dev|prod] [--clean]
# 
# dev:  Uses DB_NAME=genaicoe_postgresql in us-east-1
# prod: Uses DB_NAME=prod in eu-west-1
# --clean: Recreates tables and performs clean migration

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
ENVIRONMENT=""
CLEAN_MIGRATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        --clean)
            CLEAN_MIGRATION=true
            shift
            ;;
        *)
            echo "Usage: $0 [dev|prod] [--clean]"
            echo "  dev:  Uses DB_NAME=genaicoe_postgresql in us-east-1"
            echo "  prod: Uses DB_NAME=prod in eu-west-1"
            echo "  --clean: Recreates tables and performs clean migration"
            exit 1
            ;;
    esac
done

# Set default environment if not provided
if [[ -z "$ENVIRONMENT" ]]; then
    ENVIRONMENT="dev"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

# Validate environment parameter
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Usage: $0 [dev|prod] [--clean]"
    echo "  dev:  Uses DB_NAME=genaicoe_postgresql in us-east-1"
    echo "  prod: Uses DB_NAME=prod in eu-west-1"
    echo "  --clean: Recreates tables and performs clean migration"
    exit 1
fi

# Show migration mode
if [[ "$CLEAN_MIGRATION" == true ]]; then
    log_warning "🧹 CLEAN MIGRATION MODE - Tables will be recreated"
else
    log "📊 INCREMENTAL MIGRATION MODE - Existing data will be checked"
fi

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    export DB_NAME="genaicoe_postgresql"
    export AWS_DEFAULT_REGION="us-east-1"
    export AWS_REGION="us-east-1"
    log "🔧 Environment: DEVELOPMENT"
    log "   Database: $DB_NAME"
    log "   Region: $AWS_DEFAULT_REGION"
else
    export DB_NAME="prod"
    export AWS_DEFAULT_REGION="eu-west-1" 
    export AWS_REGION="eu-west-1"
    log "🏭 Environment: PRODUCTION"
    log "   Database: $DB_NAME"
    log "   Region: $AWS_DEFAULT_REGION"
fi

# Export clean migration flag for child scripts
export CLEAN_MIGRATION

# Disable AWS CLI pager to prevent interactive prompts
export AWS_PAGER=""

echo ""
log "🚀 Starting PostgreSQL to DynamoDB Migration Pipeline"
log "📁 Working directory: $SCRIPT_DIR"

# If clean migration, run cleanup first
if [[ "$CLEAN_MIGRATION" == true ]]; then
    log_warning "🧹 Running cleanup before migration..."
    if [[ -f "$SCRIPT_DIR/99-cleanup-migration.sh" ]]; then
        bash "$SCRIPT_DIR/99-cleanup-migration.sh" "$ENVIRONMENT" --confirm
        log_success "Cleanup completed"
    else
        log_error "Cleanup script not found"
        exit 1
    fi
fi
echo ""

# Execute migration steps in sequence
STEPS=(
    "01-setup-environment.sh"
    "02-validate-prerequisites.sh"
    "03-create-aws-resources.sh"
    "04-run-migration.sh"
    "05-verify-migration.sh"
)

TOTAL_STEPS=${#STEPS[@]}
CURRENT_STEP=0

for step in "${STEPS[@]}"; do
    CURRENT_STEP=$((CURRENT_STEP + 1))
    
    echo ""
    log "📋 Step $CURRENT_STEP/$TOTAL_STEPS: Executing $step"
    echo ""
    
    if [[ -f "$SCRIPT_DIR/$step" ]]; then
        if bash "$SCRIPT_DIR/$step" "$ENVIRONMENT"; then
            log_success "Step $CURRENT_STEP/$TOTAL_STEPS completed: $step"
        else
            log_error "Step $CURRENT_STEP/$TOTAL_STEPS failed: $step"
            exit 1
        fi
    else
        log_error "Script not found: $SCRIPT_DIR/$step"
        exit 1
    fi
done

echo ""
log_success "🎉 Migration pipeline completed successfully!"
log "🔍 Environment: $ENVIRONMENT"
log "📊 Database: $DB_NAME"
log "🌐 Region: $AWS_DEFAULT_REGION"
if [[ "$CLEAN_MIGRATION" == true ]]; then
    log "🧹 Migration Mode: CLEAN (tables recreated)"
else
    log "📊 Migration Mode: INCREMENTAL (existing data checked)"
fi
echo ""
log "📈 Next steps:"
log "   1. Run: ./99-migration-summary.sh $ENVIRONMENT"
log "   2. Test your application with the migrated data"
log "   3. Monitor DynamoDB metrics in AWS Console"
echo ""
