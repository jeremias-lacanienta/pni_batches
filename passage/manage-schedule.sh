#!/bin/bash
# Manage EventBridge schedules for passage migration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SCHEDULE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SCHEDULE]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[SCHEDULE]${NC} ❌ $1"
}

log_warning() {
    echo -e "${YELLOW}[SCHEDULE]${NC} ⚠️  $1"
}

show_usage() {
    echo "Usage: $0 <command> <environment>"
    echo ""
    echo "Commands:"
    echo "  enable    Enable the EventBridge schedule"
    echo "  disable   Disable the EventBridge schedule"
    echo "  status    Show current schedule status"
    echo ""
    echo "Environments:"
    echo "  dev       Development (us-east-1)"
    echo "  prod      Production (eu-west-1)"
    echo ""
    echo "Examples:"
    echo "  $0 enable dev"
    echo "  $0 disable prod"
    echo "  $0 status dev"
}

if [ $# -ne 2 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
ENVIRONMENT=$2

# Set region and rule name based on environment
if [ "$ENVIRONMENT" = "dev" ]; then
    REGION="us-east-1"
    RULE_NAME="passage-migration-schedule-dev"
elif [ "$ENVIRONMENT" = "prod" ]; then
    REGION="eu-west-1"
    RULE_NAME="passage-migration-schedule-prod"
else
    log_error "Invalid environment: $ENVIRONMENT"
    show_usage
    exit 1
fi

case $COMMAND in
    enable)
        log "Enabling EventBridge schedule for $ENVIRONMENT environment..."
        aws events enable-rule \
            --name "$RULE_NAME" \
            --region "$REGION"
        
        if [ $? -eq 0 ]; then
            log_success "Schedule enabled for $ENVIRONMENT"
        else
            log_error "Failed to enable schedule for $ENVIRONMENT"
            exit 1
        fi
        ;;
    
    disable)
        log "Disabling EventBridge schedule for $ENVIRONMENT environment..."
        aws events disable-rule \
            --name "$RULE_NAME" \
            --region "$REGION"
        
        if [ $? -eq 0 ]; then
            log_success "Schedule disabled for $ENVIRONMENT"
        else
            log_error "Failed to disable schedule for $ENVIRONMENT"
            exit 1
        fi
        ;;
    
    status)
        log "Checking EventBridge schedule status for $ENVIRONMENT environment..."
        STATUS=$(aws events describe-rule \
            --name "$RULE_NAME" \
            --region "$REGION" \
            --query 'State' \
            --output text 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "📋 Schedule Status:"
            echo "   Environment: $ENVIRONMENT"
            echo "   Region: $REGION"
            echo "   Rule: $RULE_NAME"
            echo "   Status: $STATUS"
            echo ""
            
            if [ "$STATUS" = "ENABLED" ]; then
                log_success "Schedule is currently ENABLED"
            else
                log_warning "Schedule is currently DISABLED"
            fi
        else
            log_error "Failed to get schedule status for $ENVIRONMENT (rule may not exist)"
            exit 1
        fi
        ;;
    
    *)
        log_error "Invalid command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
