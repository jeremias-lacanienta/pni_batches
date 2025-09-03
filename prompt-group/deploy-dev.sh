#!/bin/bash
# Deploy Lambda function to DEV environment (us-east-1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_NAME="prompt-group-migration-dev"
LAMBDA_ZIP="prompt-group-migration-dev.zip"
REGION="us-east-1"
ENVIRONMENT="dev"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[DEV-DEPLOY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DEV-DEPLOY]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[DEV-DEPLOY]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[DEV-DEPLOY]${NC} ⚠️  $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

log "🚀 Deploying Lambda to DEV environment ($REGION)..."

# Create deployment package
log "Creating deployment package..."
TEMP_DIR=$(mktemp -d)

# Copy the Lambda function
cp "$SCRIPT_DIR/prompt-group-migration.py" "$TEMP_DIR/lambda_function.py"

# Create requirements.txt with pg8000 (pure Python PostgreSQL driver)
cat > "$TEMP_DIR/requirements.txt" << EOF
pg8000
PyYAML==6.0.2
EOF

# Install dependencies (pg8000 is pure Python, no platform issues)
log "Installing dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install -r "$TEMP_DIR/requirements.txt" -t "$TEMP_DIR" --quiet
elif command -v python3 &> /dev/null; then
    python3 -m pip install -r "$TEMP_DIR/requirements.txt" -t "$TEMP_DIR" --quiet
else
    log_error "Neither pip3 nor python3 found. Please install Python 3 and pip."
    exit 1
fi

# Download pre-compiled psycopg2 for Lambda
log "Downloading pre-compiled psycopg2 for Lambda..."
curl -L -o "$TEMP_DIR/psycopg2.zip" "https://github.com/jkehler/awslambda-psycopg2/raw/master/psycopg2-3.9.zip"
cd "$TEMP_DIR" && unzip -q psycopg2.zip && rm psycopg2.zip
cd "$SCRIPT_DIR"

# Create ZIP file
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/$LAMBDA_ZIP" . --quiet
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

log_success "Deployment package created: $LAMBDA_ZIP"

# Deploy Lambda function
log "Deploying Lambda function..."

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &> /dev/null; then
    # Update existing function
    log "Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://$LAMBDA_ZIP" \
        --region "$REGION" \
        --output table
else
    # Create new function
    log "Creating new function..."
    
    # Create execution role if it doesn't exist
    ROLE_NAME="lambda-prompt-migration-role"
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    
    if [ -z "$ROLE_ARN" ]; then
        log "Creating IAM role..."
        
        # Create trust policy
        cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
        
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://trust-policy.json
        
        # Attach basic execution policy
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        
        # Create and attach S3 policy
        cat > s3-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::pi-app-data/*"
    }
  ]
}
EOF
        
        aws iam put-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-name "S3AccessPolicy" \
            --policy-document file://s3-policy.json
        
        ROLE_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME"
        
        # Wait for role to be available
        log "Waiting for IAM role to be ready..."
        sleep 10
        
        # Cleanup policy files
        rm -f trust-policy.json s3-policy.json
    fi
    
    # Create environment variables JSON
    cat > env-vars.json << EOF
{
  "Variables": {
    "S3_BUCKET": "pi-app-data",
    "PG_HOST": "\${PG_HOST}",
    "PG_USER": "\${PG_USER}",
    "PG_PASSWORD": "\${PG_PASSWORD}",
    "PG_PORT": "5432"
  }
}
EOF
    
    # Create Lambda function
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime "python3.9" \
        --role "$ROLE_ARN" \
        --handler "lambda_function.lambda_handler" \
        --zip-file "fileb://$LAMBDA_ZIP" \
        --timeout 300 \
        --memory-size 512 \
        --region "$REGION" \
        --environment file://env-vars.json \
        --output table
    
    # Cleanup
    rm -f env-vars.json
fi

# Create EventBridge schedule
log "Creating EventBridge schedule..."
RULE_NAME="prompt-group-migration-schedule-dev"

aws events put-rule \
    --name "$RULE_NAME" \
    --schedule-expression "rate(10 minutes)" \
    --description "Trigger prompt migration every 10 minutes for dev" \
    --state ENABLED \
    --region "$REGION" \
    --output table

# Get the Lambda function ARN
FUNCTION_ARN=$(aws lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --query 'Configuration.FunctionArn' \
    --output text)

# Add Lambda target to the rule (no payload needed, uses region detection)
aws events put-targets \
    --rule "$RULE_NAME" \
    --targets '[{"Id":"1","Arn":"'$FUNCTION_ARN'"}]' \
    --region "$REGION" \
    --output table

# Add permission for EventBridge to invoke Lambda
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "eventbridge-invoke-dev" \
    --action "lambda:InvokeFunction" \
    --principal "events.amazonaws.com" \
    --source-arn "arn:aws:events:$REGION:$(aws sts get-caller-identity --query Account --output text):rule/$RULE_NAME" \
    --region "$REGION" \
    --output table 2>/dev/null || log_warning "Permission may already exist"

# Cleanup
rm -f "$LAMBDA_ZIP"

log_success "✅ DEV deployment complete!"
echo "🔗 Function name: $FUNCTION_NAME"
echo "🌎 Region: $REGION"
echo "📅 Schedule: Every 10 minutes"
echo "📂 S3 Output: s3://pi-app-data/lambda-prompts.dev.yaml"
