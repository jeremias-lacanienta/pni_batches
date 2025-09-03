#!/bin/bash
# Update existing Lambda functions with psycopg2 layer

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[UPDATE-LAYERS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[UPDATE-LAYERS]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[UPDATE-LAYERS]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[UPDATE-LAYERS]${NC} ⚠️  $1"
}

log "🔄 Updating Lambda functions with psycopg2 layers..."

# Update DEV function
log "Updating DEV function (us-east-1)..."
aws lambda update-function-configuration \
    --function-name "prompt-group-migration-dev" \
    --layers "arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py39:1" \
    --region "us-east-1" \
    --output table

log_success "DEV function updated with psycopg2 layer"

# Update PROD function
log "Updating PROD function (eu-west-1)..."
aws lambda update-function-configuration \
    --function-name "prompt-group-migration-prod" \
    --layers "arn:aws:lambda:eu-west-1:898466741470:layer:psycopg2-py39:1" \
    --region "eu-west-1" \
    --output table

log_success "PROD function updated with psycopg2 layer"

log_success "✅ All Lambda functions updated with psycopg2 layers!"
echo ""
echo "📋 Layer Details:"
echo "  • DEV (us-east-1): arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py39:1"
echo "  • PROD (eu-west-1): arn:aws:lambda:eu-west-1:898466741470:layer:psycopg2-py39:1"
echo ""
echo "🔧 This resolves the 'No module named psycopg2._psycopg' error"
