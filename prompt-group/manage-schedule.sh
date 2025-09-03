#!/bin/bash
# EventBridge Schedule Management for Prompt Group Migration
# Manages 10-minute schedules for Lambda functions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_NAME="prompt-group-migration"

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

# Function to enable schedule
enable_schedule() {
    local environment=$1
    local region=$2
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Enabling EventBridge schedule for $environment..."
    
    aws events enable-rule \
        --name "$rule_name" \
        --region "$region"
    
    log_success "Schedule enabled for $environment"
}

# Function to disable schedule
disable_schedule() {
    local environment=$1
    local region=$2
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Disabling EventBridge schedule for $environment..."
    
    aws events disable-rule \
        --name "$rule_name" \
        --region "$region"
    
    log_success "Schedule disabled for $environment"
}

# Function to show schedule status
show_status() {
    local environment=$1
    local region=$2
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Checking schedule status for $environment..."
    
    local status=$(aws events describe-rule \
        --name "$rule_name" \
        --region "$region" \
        --query 'State' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$status" = "NOT_FOUND" ]; then
        echo "❌ Schedule not found for $environment"
    else
        echo "📅 Schedule for $environment: $status"
        
        # Show last execution
        local function_name="${FUNCTION_NAME}-${environment}"
        local last_run=$(aws logs describe-log-groups \
            --log-group-name-prefix "/aws/lambda/$function_name" \
            --region "$region" \
            --query 'logGroups[0].lastEventTime' \
            --output text 2>/dev/null || echo "0")
        
        if [ "$last_run" != "0" ] && [ "$last_run" != "None" ]; then
            local last_run_date=$(date -d "@$((last_run/1000))" 2>/dev/null || echo "Unknown")
            echo "🕐 Last execution: $last_run_date"
        fi
    fi
}

# Function to update schedule frequency
update_schedule() {
    local environment=$1
    local region=$2
    local frequency=${3:-"10 minutes"}
    local rule_name="${FUNCTION_NAME}-schedule-${environment}"
    
    log "Updating schedule frequency for $environment to every $frequency..."
    
    aws events put-rule \
        --name "$rule_name" \
        --schedule-expression "rate($frequency)" \
        --description "Trigger prompt migration every $frequency for $environment" \
        --state ENABLED \
        --region "$region"
    
    log_success "Schedule updated to run every $frequency"
}

# Main function
main() {
    local action=${1:-"status"}
    local environment=${2:-"all"}
    
    case $action in
        "enable")
            if [ "$environment" = "all" ]; then
                enable_schedule "dev" "us-east-1"
                enable_schedule "prod" "eu-west-1"
            else
                local region="us-east-1"
                if [ "$environment" = "prod" ]; then
                    region="eu-west-1"
                fi
                enable_schedule "$environment" "$region"
            fi
            ;;
        "disable")
            if [ "$environment" = "all" ]; then
                disable_schedule "dev" "us-east-1"
                disable_schedule "prod" "eu-west-1"
            else
                local region="us-east-1"
                if [ "$environment" = "prod" ]; then
                    region="eu-west-1"
                fi
                disable_schedule "$environment" "$region"
            fi
            ;;
        "status")
            if [ "$environment" = "all" ]; then
                show_status "dev" "us-east-1"
                echo ""
                show_status "prod" "eu-west-1"
            else
                local region="us-east-1"
                if [ "$environment" = "prod" ]; then
                    region="eu-west-1"
                fi
                show_status "$environment" "$region"
            fi
            ;;
        "update")
            local frequency=${3:-"10 minutes"}
            if [ "$environment" = "all" ]; then
                update_schedule "dev" "us-east-1" "$frequency"
                update_schedule "prod" "eu-west-1" "$frequency"
            else
                local region="us-east-1"
                if [ "$environment" = "prod" ]; then
                    region="eu-west-1"
                fi
                update_schedule "$environment" "$region" "$frequency"
            fi
            ;;
        *)
            log_error "Usage: $0 [enable|disable|status|update] [dev|prod|all] [frequency]"
            echo ""
            echo "Commands:"
            echo "  enable [ENV]           - Enable EventBridge schedule"
            echo "  disable [ENV]          - Disable EventBridge schedule"
            echo "  status [ENV]           - Show schedule status"
            echo "  update [ENV] [FREQ]    - Update schedule frequency"
            echo ""
            echo "Examples:"
            echo "  $0 status              # Show all schedules"
            echo "  $0 enable dev          # Enable dev schedule"
            echo "  $0 disable prod        # Disable prod schedule"
            echo "  $0 update all '5 minutes'  # Update to run every 5 minutes"
            echo ""
            echo "Frequency examples: '1 minute', '5 minutes', '1 hour', '1 day'"
            exit 1
            ;;
    esac
}

main "$@"
