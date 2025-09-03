#!/bin/bash
# Deploy Passage Migration Lambda to PROD environment (eu-west-1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_NAME="passage-migration-prod"
REGION="eu-west-1"
ZIP_FILE="passage-migration-prod.zip"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[PROD-DEPLOY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PROD-DEPLOY]${NC} ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}[PROD-DEPLOY]${NC} ⚠️  $1"
}

log "🚀 Deploying Lambda to PROD environment (eu-west-1)..."

# Create deployment package
log "Creating deployment package..."
TEMP_DIR=$(mktemp -d)

# Copy Lambda function
cp "$SCRIPT_DIR/passage-migration.py" "$TEMP_DIR/lambda_function.py"

log "Installing dependencies..."
pip3 install -r "$SCRIPT_DIR/requirements.txt" -t "$TEMP_DIR" --quiet

# Create ZIP file
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/$ZIP_FILE" . --quiet
cd "$SCRIPT_DIR"

# Clean up temp directory
rm -rf "$TEMP_DIR"

log_success "Deployment package created: $ZIP_FILE"

# Deploy Lambda function
log "Deploying Lambda function..."

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
    log "Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://$ZIP_FILE" \
        --region "$REGION" \
        --output table
else
    log "Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime python3.9 \
        --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-prompt-migration-role" \
        --handler lambda_function.lambda_handler \
        --zip-file "fileb://$ZIP_FILE" \
        --timeout 300 \
        --memory-size 512 \
        --region "$REGION" \
        --environment Variables="{
            PG_HOST=gen-ai-coe-database-instance-1.c5mq68484fye.eu-west-1.rds.amazonaws.com,
            PG_USER=postgres,
            PG_PASSWORD=bd3zw229fxw1,
            PG_PORT=5432
        }" \
        --output table
fi

# Create EventBridge schedule (initially disabled as requested)
log "Creating EventBridge schedule (disabled)..."

# Create rule (disabled)
aws events put-rule \
    --name "passage-migration-schedule-prod" \
    --schedule-expression "rate(10 minutes)" \
    --state "DISABLED" \
    --description "Passage migration every 10 minutes (PROD)" \
    --region "$REGION" \
    --output table

# Add Lambda target
aws events put-targets \
    --rule "passage-migration-schedule-prod" \
    --targets "Id"="1","Arn"="arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:$FUNCTION_NAME" \
    --region "$REGION" \
    --output table

# Add permission for EventBridge to invoke Lambda
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "AllowExecutionFromEventBridge" \
    --action "lambda:InvokeFunction" \
    --principal events.amazonaws.com \
    --source-arn "arn:aws:events:$REGION:$(aws sts get-caller-identity --query Account --output text):rule/passage-migration-schedule-prod" \
    --region "$REGION" >/dev/null 2>&1 || log_warning "Permission may already exist"

# Clean up ZIP file
rm "$ZIP_FILE"

log_success "✅ PROD deployment complete!"
echo "🔗 Function name: $FUNCTION_NAME"
echo "🌎 Region: $REGION"
echo "📅 Schedule: Every 10 minutes (DISABLED)"
echo "📋 DynamoDB Tables: pni-passages, pni-topics, pni-cache-metadata"
