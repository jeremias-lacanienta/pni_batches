#!/bin/bash

# 99-create-iam-user.sh
# Creates IAM user for DynamoDB access (one-time setup)
# Usage: ./99-create-iam-user.sh [dev|prod]

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
    USER_NAME="pni-dynamodb-dev-user"
    POLICY_NAME="PNI-DynamoDB-Dev-Policy"
    TABLE_PREFIX="pni"  # Same table names, different regions
    AWS_DEFAULT_REGION="us-east-1"
else
    USER_NAME="pni-dynamodb-prod-user"
    POLICY_NAME="PNI-DynamoDB-Prod-Policy"
    TABLE_PREFIX="pni"  # Same table names, different regions
    AWS_DEFAULT_REGION="eu-west-1"
fi

log "🔐 Creating IAM user for $ENVIRONMENT environment"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "User Name: $USER_NAME"
echo "Policy Name: $POLICY_NAME"
echo "Table Prefix: $TABLE_PREFIX"
echo "Region: $AWS_DEFAULT_REGION"
echo "=============================================="
echo

# Check if user already exists
log "🔍 Checking if user already exists..."
if aws iam get-user --user-name "$USER_NAME" > /dev/null 2>&1; then
    warning "User $USER_NAME already exists"
    
    # Ask if user wants to continue
    read -p "Do you want to update the existing user? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Exiting without changes"
        exit 0
    fi
else
    # Create the user
    log "👤 Creating IAM user: $USER_NAME"
    aws iam create-user --user-name "$USER_NAME" --path "/pni-migration/"
    success "User created: $USER_NAME"
fi

# Create policy document
POLICY_DOCUMENT=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:ListTables",
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:${AWS_DEFAULT_REGION}:*:table/${TABLE_PREFIX}-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:ListTables"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Create or update policy
log "📜 Creating/updating IAM policy: $POLICY_NAME"
POLICY_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/pni-migration/$POLICY_NAME"

# Check if policy exists
if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    warning "Policy already exists, creating new version"
    # Create new policy version
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document "$POLICY_DOCUMENT" \
        --set-as-default
    success "Policy updated: $POLICY_NAME"
else
    # Create new policy
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --path "/pni-migration/" \
        --policy-document "$POLICY_DOCUMENT" \
        --description "DynamoDB access policy for PNI migration ($ENVIRONMENT)"
    success "Policy created: $POLICY_NAME"
fi

# Attach policy to user
log "🔗 Attaching policy to user..."
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn "$POLICY_ARN"
success "Policy attached to user"

# Create access key (if not exists)
log "🔑 Creating access key..."
EXISTING_KEYS=$(aws iam list-access-keys --user-name "$USER_NAME" --query 'AccessKeyMetadata[?Status==`Active`].AccessKeyId' --output text)

if [[ -n "$EXISTING_KEYS" ]]; then
    warning "Active access key already exists for user"
    echo "Existing keys: $EXISTING_KEYS"
    
    read -p "Do you want to create a new access key? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Skipping access key creation"
    else
        # Create new access key
        ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USER_NAME")
        ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.AccessKeyId')
        SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.SecretAccessKey')
        
        success "New access key created"
        echo "=============================================="
        echo "🔐 SAVE THESE CREDENTIALS SECURELY:"
        echo "Access Key ID: $ACCESS_KEY_ID"
        echo "Secret Access Key: $SECRET_ACCESS_KEY"
        echo "=============================================="
        
        # Offer to add to AWS credentials file
        echo
        read -p "Do you want to add these credentials to ~/.aws/credentials? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            PROFILE_NAME="pni-dynamodb-$ENVIRONMENT"
            
            # Add to credentials file
            cat >> ~/.aws/credentials << EOF

[$PROFILE_NAME]
aws_access_key_id = $ACCESS_KEY_ID
aws_secret_access_key = $SECRET_ACCESS_KEY
region = $AWS_DEFAULT_REGION
EOF
            success "Credentials added to profile: $PROFILE_NAME"
        fi
    fi
else
    # Create new access key
    ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USER_NAME")
    ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.AccessKeyId')
    SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | jq -r '.AccessKey.SecretAccessKey')
    
    success "Access key created"
    echo "=============================================="
    echo "🔐 SAVE THESE CREDENTIALS SECURELY:"
    echo "Access Key ID: $ACCESS_KEY_ID"
    echo "Secret Access Key: $SECRET_ACCESS_KEY"
    echo "=============================================="
    
    # Offer to add to AWS credentials file
    echo
    read -p "Do you want to add these credentials to ~/.aws/credentials? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        PROFILE_NAME="pni-dynamodb-$ENVIRONMENT"
        
        # Add to credentials file
        cat >> ~/.aws/credentials << EOF

[$PROFILE_NAME]
aws_access_key_id = $ACCESS_KEY_ID
aws_secret_access_key = $SECRET_ACCESS_KEY
region = $AWS_DEFAULT_REGION
EOF
        success "Credentials added to profile: $PROFILE_NAME"
    fi
fi

echo
log "📋 Summary"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "IAM User: $USER_NAME"
echo "Policy: $POLICY_NAME"
echo "Region: $AWS_DEFAULT_REGION"
echo "Tables: ${TABLE_PREFIX}-*"
echo "=============================================="

success "IAM user setup completed!"

# Test the user permissions
echo
log "🧪 Testing user permissions..."
if [[ -n "$ACCESS_KEY_ID" && -n "$SECRET_ACCESS_KEY" ]]; then
    # Test with new credentials
    AWS_ACCESS_KEY_ID="$ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$SECRET_ACCESS_KEY" AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" aws dynamodb list-tables > /dev/null 2>&1 && success "User can access DynamoDB" || warning "User cannot access DynamoDB yet (permissions may need time to propagate)"
else
    warning "Cannot test permissions - no new access key created"
fi
