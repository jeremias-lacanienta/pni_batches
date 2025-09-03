#!/bin/bash
# Step 2: Validate Prerequisites
# Checks AWS credentials, PostgreSQL connectivity, and configuration

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
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[VALIDATE]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[VALIDATE]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[VALIDATE]${NC} ⚠️ $1"
}

# Activate virtual environment
source "$VENV_DIR/bin/activate"

log "🔍 Validating prerequisites for migration"

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    EXPECTED_DB="genaicoe_postgresql"
    EXPECTED_REGION="us-east-1"
else
    EXPECTED_DB="prod"
    EXPECTED_REGION="eu-west-1"
fi

log "🎯 Target environment: $ENVIRONMENT"
log "   Database: $EXPECTED_DB"
log "   Region: $EXPECTED_REGION"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found. Please install AWS CLI."
    exit 1
fi
log_success "AWS CLI found: $(aws --version | head -n1)"

# Check AWS credentials
log "🔐 Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    log_success "AWS credentials valid"
    log "   Account: $ACCOUNT_ID"
    log "   Identity: $USER_ARN"
else
    log_error "AWS credentials not configured or invalid"
    log "Please run 'aws configure' or set AWS environment variables"
    exit 1
fi

# Check if we can access DynamoDB in target region
log "🗄️ Checking DynamoDB access in $EXPECTED_REGION..."
export AWS_DEFAULT_REGION="$EXPECTED_REGION"
if aws dynamodb list-tables --region "$EXPECTED_REGION" &> /dev/null; then
    log_success "DynamoDB access confirmed in $EXPECTED_REGION"
else
    log_error "Cannot access DynamoDB in $EXPECTED_REGION"
    log "Please check your AWS permissions and region configuration"
    exit 1
fi

# Check PostgreSQL credentials
log "🐘 Checking PostgreSQL credentials..."
aws_creds_path=~/.aws/credentials
profile=${PG_AWS_PROFILE:-postgres-creds}

if [[ ! -f "$aws_creds_path" ]]; then
    log_error "AWS credentials file not found: $aws_creds_path"
    exit 1
fi

# Test PostgreSQL connection
log "🔌 Testing PostgreSQL connection..."
python3 -c "
import configparser
import psycopg2
import os
import sys

try:
    # Load PostgreSQL credentials
    config = configparser.ConfigParser()
    config.read('$aws_creds_path')
    
    if '$profile' not in config:
        print('❌ Profile [$profile] not found in $aws_creds_path')
        sys.exit(1)
    
    pg_user = config.get('$profile', 'pg_user')
    pg_password = config.get('$profile', 'pg_password')  
    pg_host = config.get('$profile', 'pg_host')
    pg_database = '$EXPECTED_DB'
    pg_port = config.get('$profile', 'pg_port', fallback='5432')
    
    # Test connection
    conn = psycopg2.connect(
        host=pg_host,
        port=pg_port,
        database=pg_database,
        user=pg_user,
        password=pg_password
    )
    
    cursor = conn.cursor()
    cursor.execute('SELECT version();')
    version = cursor.fetchone()[0]
    print(f'✅ PostgreSQL connection successful')
    print(f'   Database: {pg_database}')
    print(f'   Host: {pg_host}:{pg_port}')
    print(f'   Version: {version[:50]}...')
    
    # Check for required tables
    cursor.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('lessons', 'questions')
        ORDER BY table_name;
    \"\"\")
    tables = [row[0] for row in cursor.fetchall()]
    
    required_tables = ['lessons', 'questions']
    missing_tables = [t for t in required_tables if t not in tables]
    
    if missing_tables:
        print(f'❌ Missing required tables: {missing_tables}')
        sys.exit(1)
    else:
        print(f'✅ All required tables found: {tables}')
    
    # Check for optional tables that may not exist
    cursor.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
    \"\"\")
    all_tables = [row[0] for row in cursor.fetchall()]
    
    optional_tables = ['passages', 'topics']
    available_optional = [t for t in optional_tables if t in all_tables]
    missing_optional = [t for t in optional_tables if t not in all_tables]
    
    if available_optional:
        print(f'✅ Optional tables found: {available_optional}')
    if missing_optional:
        print(f'ℹ️  Optional tables not present: {missing_optional}')
        print(f'   Migration will generate derived data from lessons and questions')
    
    # Get data counts
    cursor.execute('SELECT COUNT(*) FROM lessons;')
    lesson_count = cursor.fetchone()[0]
    cursor.execute('SELECT COUNT(*) FROM questions;')
    question_count = cursor.fetchone()[0]
    
    print(f'📊 Data summary:')
    print(f'   - Lessons: {lesson_count}')
    print(f'   - Questions: {question_count}')
    
    conn.close()
    
except Exception as e:
    print(f'❌ PostgreSQL connection failed: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    log_success "PostgreSQL connection and schema validation passed"
else
    log_error "PostgreSQL validation failed"
    exit 1
fi

# Check for Python dependencies
log "📦 Verifying Python dependencies..."
python3 -c "
import boto3, psycopg2, tabulate
print('✅ All Python dependencies available')
"

log_success "All prerequisites validated successfully"

echo ""
log "📊 Validation Summary:"
log "   ✅ AWS CLI configured"
log "   ✅ AWS credentials valid" 
log "   ✅ DynamoDB access confirmed"
log "   ✅ PostgreSQL connection successful"
log "   ✅ Required database tables present"
log "   ✅ Python dependencies installed"

echo ""
log_success "Step 2 completed: Prerequisites validation passed"
