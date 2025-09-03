#!/bin/bash
# Prompt Group Migration Lambda Deployment Script
# Deploys to dev (us-east-1) and prod (eu-west-1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_NAME="prompt-group-migration"
LAMBDA_ZIP="prompt-group-migration.zip"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DEPLOY]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[DEPLOY]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[DEPLOY]${NC} ⚠️  $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Function to create deployment package
create_deployment_package() {
    log "Creating deployment package..."
    
    # Create temporary directory for Lambda package
    TEMP_DIR=$(mktemp -d)
    
    # Copy the Lambda function
    cp "$SCRIPT_DIR/prompt-group-migration.py" "$TEMP_DIR/lambda_function.py"
    
    # Create requirements.txt for Lambda layers or inline dependencies
    cat > "$TEMP_DIR/requirements.txt" << EOF
psycopg2-binary==2.9.10
PyYAML==6.0.2
boto3==1.34.162
EOF
    
    # Install dependencies in the package directory
    log "Installing dependencies..."
    pip install -r "$TEMP_DIR/requirements.txt" -t "$TEMP_DIR" --quiet
    
    # Create ZIP file
    cd "$TEMP_DIR"
    zip -r "$SCRIPT_DIR/$LAMBDA_ZIP" . --quiet
    cd "$SCRIPT_DIR"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    log_success "Deployment package created: $LAMBDA_ZIP"
}

# Function to create EventBridge rule
create_eventbridge_rule() {
    local environment=$1
    local region=$2
    local function_name="${FUNCTION_NAME}-${environment}"
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Creating EventBridge rule for $function_name..."
    
    # Create EventBridge rule for 10-minute schedule
    aws events put-rule \
        --name "$rule_name" \
        --schedule-expression "rate(10 minutes)" \
        --description "Trigger prompt migration every 10 minutes for $environment" \
        --state ENABLED \
        --region "$region" \
        --output table
    
    # Get the Lambda function ARN
    local function_arn=$(aws lambda get-function \
        --function-name "$function_name" \
        --region "$region" \
        --query 'Configuration.FunctionArn' \
        --output text)
    
    # Add Lambda target to the rule
    aws events put-targets \
        --rule "$rule_name" \
        --targets "Id=1,Arn=$function_arn,Input={\"environment\":\"$environment\"}" \
        --region "$region" \
        --output table
    
    # Add permission for EventBridge to invoke Lambda
    aws lambda add-permission \
        --function-name "$function_name" \
        --statement-id "eventbridge-invoke-$environment" \
        --action "lambda:InvokeFunction" \
        --principal "events.amazonaws.com" \
        --source-arn "arn:aws:events:$region:$(aws sts get-caller-identity --query Account --output text):rule/$rule_name" \
        --region "$region" \
        --output table || log_warning "Permission may already exist"
    
    log_success "EventBridge rule $rule_name created and configured"
}

# Function to deploy Lambda
deploy_lambda() {
    local environment=$1
    local region=$2
    local function_name="${FUNCTION_NAME}-${environment}"
    
    log "Deploying $function_name to $region..."
    
    # Check if function exists
    if aws lambda get-function --function-name "$function_name" --region "$region" &> /dev/null; then
        # Update existing function
        log "Updating existing function..."
        aws lambda update-function-code \
            --function-name "$function_name" \
            --zip-file "fileb://$LAMBDA_ZIP" \
            --region "$region" \
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
            
            # Create and attach EventBridge policy
            cat > eventbridge-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:PutRule",
        "events:PutTargets",
        "events:EnableRule",
        "events:DisableRule",
        "events:DescribeRule"
      ],
      "Resource": "*"
    }
  ]
}
EOF
            
            aws iam put-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-name "EventBridgeAccessPolicy" \
                --policy-document file://eventbridge-policy.json
            
            ROLE_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME"
            
            # Wait for role to be available
            log "Waiting for IAM role to be ready..."
            sleep 10
            
            # Cleanup policy files
            rm -f trust-policy.json s3-policy.json eventbridge-policy.json
        fi
        
        # Create Lambda function
        aws lambda create-function \
            --function-name "$function_name" \
            --runtime "python3.9" \
            --role "$ROLE_ARN" \
            --handler "lambda_function.lambda_handler" \
            --zip-file "fileb://$LAMBDA_ZIP" \
            --timeout 300 \
            --memory-size 512 \
            --region "$region" \
            --environment "Variables={
                S3_BUCKET=pi-app-data,
                PG_HOST=\${PG_HOST},
                PG_USER=\${PG_USER},
                PG_PASSWORD=\${PG_PASSWORD},
                PG_PORT=5432
            }" \
            --output table
    fi
    
    log_success "Deployed $function_name to $region"
    
    # Create EventBridge schedule
    create_eventbridge_rule "$environment" "$region"
}

# Function to remove EventBridge rule
remove_eventbridge_rule() {
    local environment=$1
    local region=$2
    local function_name="${FUNCTION_NAME}-${environment}"
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Removing EventBridge rule for $function_name..."
    
    # Remove targets first
    aws events remove-targets \
        --rule "$rule_name" \
        --ids "1" \
        --region "$region" \
        2>/dev/null || log_warning "No targets to remove"
    
    # Delete the rule
    aws events delete-rule \
        --name "$rule_name" \
        --region "$region" \
        2>/dev/null || log_warning "Rule may not exist"
    
    # Remove Lambda permission
    aws lambda remove-permission \
        --function-name "$function_name" \
        --statement-id "eventbridge-invoke-$environment" \
        --region "$region" \
        2>/dev/null || log_warning "Permission may not exist"
    
    log_success "EventBridge rule $rule_name removed"
}

# Function to test Lambda
test_lambda() {
    local environment=$1
    local region=$2
    local function_name="${FUNCTION_NAME}-${environment}"
    
    log "Testing $function_name in $region..."
    
    # Create test payload
    cat > test-payload.json << EOF
{
  "environment": "$environment"
}
EOF
    
    # Invoke function
    aws lambda invoke \
        --function-name "$function_name" \
        --payload file://test-payload.json \
        --region "$region" \
        response.json
    
    # Show response
    log "Response:"
    cat response.json | jq .
    
    # Cleanup
    rm -f test-payload.json response.json
}

# Main execution
main() {
    local action=${1:-"deploy"}
    
    case $action in
        "deploy")
            log "Starting Lambda deployment with EventBridge schedule..."
            create_deployment_package
            
            # Deploy to dev (us-east-1)
            log "Deploying to DEV environment (us-east-1)..."
            deploy_lambda "dev" "us-east-1"
            
            # Deploy to prod (eu-west-1)
            log "Deploying to PROD environment (eu-west-1)..."
            deploy_lambda "prod" "eu-west-1"
            
            # Cleanup
            rm -f "$LAMBDA_ZIP"
            
            log_success "All deployments completed with EventBridge schedules!"
            log "Both Lambda functions will now run automatically every 10 minutes"
            ;;
        "deploy-single")
            local environment=${2:-"dev"}
            local region=${3:-"us-east-1"}
            
            log "Starting single Lambda deployment for $environment with EventBridge schedule..."
            create_deployment_package
            
            deploy_lambda "$environment" "$region"
            
            # Cleanup
            rm -f "$LAMBDA_ZIP"
            
            log_success "Deployment completed for $environment with EventBridge schedule!"
            log "Lambda function will now run automatically every 10 minutes"
            ;;
        "cleanup")
            local environment=${2:-"all"}
            
            if [ "$environment" = "all" ]; then
                log "Cleaning up all EventBridge schedules..."
                remove_eventbridge_rule "dev" "us-east-1"
                remove_eventbridge_rule "prod" "eu-west-1"
            else
                local region="us-east-1"
                if [ "$environment" = "prod" ]; then
                    region="eu-west-1"
                fi
                remove_eventbridge_rule "$environment" "$region"
            fi
            
            log_success "EventBridge cleanup completed"
            ;;
        "test")
            environment=${2:-"dev"}
            region="us-east-1"
            if [ "$environment" = "prod" ]; then
                region="eu-west-1"
            fi
            test_lambda "$environment" "$region"
            ;;
        *)
            log_error "Usage: $0 [deploy|deploy-single|cleanup|test] [environment] [region]"
            echo ""
            echo "Commands:"
            echo "  deploy              - Deploy to both dev and prod with EventBridge schedules"
            echo "  deploy-single ENV   - Deploy to specific environment with EventBridge schedule"
            echo "  cleanup [ENV|all]   - Remove EventBridge schedules (default: all)"
            echo "  test ENV            - Test Lambda function"
            echo ""
            echo "Examples:"
            echo "  $0 deploy                    # Deploy both with schedules"
            echo "  $0 deploy-single dev         # Deploy dev only with schedule"
            echo "  $0 cleanup prod             # Remove prod schedule only"
            echo "  $0 test dev                 # Test dev function"
            exit 1
            ;;
    esac
}

main "$@"
