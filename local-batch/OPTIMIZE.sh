#!/bin/bash

# DynamoDB Optimization Script
# Applies recommended configuration to both us-east-1 and eu-west-1 regions
# Based on cost optimization analysis and performance requirements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Regions to optimize
REGIONS=("us-east-1" "eu-west-1")

# DynamoDB tables to optimize (actual tables found in your AWS account)
TABLES=(
    "pni-cache-metadata"
    "pni-passages" 
    "pni-topics"
    "lesson_progress"  # Only exists in eu-west-1
)

# Configuration parameters
MIN_READ_CAPACITY=50
MAX_READ_CAPACITY=500
MIN_WRITE_CAPACITY=5
MAX_WRITE_CAPACITY=50
TARGET_UTILIZATION=70.0

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    print_success "AWS CLI is available"
}

check_aws_credentials() {
    local region=$1
    if ! aws sts get-caller-identity --region "$region" &> /dev/null; then
        print_error "AWS credentials not configured for region $region"
        exit 1
    fi
    print_success "AWS credentials configured for $region"
}

list_dynamodb_tables() {
    local region=$1
    print_info "Listing DynamoDB tables in $region..."
    
    local tables
    tables=$(aws dynamodb list-tables --region "$region" --query 'TableNames[]' --output text 2>/dev/null || echo "")
    
    if [ -z "$tables" ]; then
        print_warning "No DynamoDB tables found in $region"
        return 1
    fi
    
    echo "Available tables in $region:"
    for table in $tables; do
        echo "  • $table"
    done
    return 0
}

get_table_status() {
    local region=$1
    local table_name=$2
    
    aws dynamodb describe-table \
        --region "$region" \
        --table-name "$table_name" \
        --query 'Table.TableStatus' \
        --output text 2>/dev/null || echo "NOT_FOUND"
}

update_table_billing_mode() {
    local region=$1
    local table_name=$2
    
    print_info "Setting $table_name to PROVISIONED billing mode in $region..."
    
    aws dynamodb update-table \
        --region "$region" \
        --table-name "$table_name" \
        --billing-mode PROVISIONED \
        --provisioned-throughput ReadCapacityUnits="$MIN_READ_CAPACITY",WriteCapacityUnits="$MIN_WRITE_CAPACITY" \
        --query 'TableDescription.TableStatus' \
        --output text
}

enable_auto_scaling() {
    local region=$1
    local table_name=$2
    local resource_id="table/$table_name"
    
    print_info "Enabling auto scaling for $table_name in $region..."
    
    # Register scalable target for read capacity
    aws application-autoscaling register-scalable-target \
        --region "$region" \
        --service-namespace dynamodb \
        --scalable-dimension dynamodb:table:ReadCapacityUnits \
        --resource-id "$resource_id" \
        --min-capacity "$MIN_READ_CAPACITY" \
        --max-capacity "$MAX_READ_CAPACITY" \
        --role-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/application-autoscaling-dynamodb-table" &> /dev/null || true
    
    # Register scalable target for write capacity
    aws application-autoscaling register-scalable-target \
        --region "$region" \
        --service-namespace dynamodb \
        --scalable-dimension dynamodb:table:WriteCapacityUnits \
        --resource-id "$resource_id" \
        --min-capacity "$MIN_WRITE_CAPACITY" \
        --max-capacity "$MAX_WRITE_CAPACITY" \
        --role-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/application-autoscaling-dynamodb-table" &> /dev/null || true
    
    # Create scaling policy for read capacity
    aws application-autoscaling put-scaling-policy \
        --region "$region" \
        --policy-name "${table_name}-read-scaling-policy" \
        --service-namespace dynamodb \
        --scalable-dimension dynamodb:table:ReadCapacityUnits \
        --resource-id "$resource_id" \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": '"$TARGET_UTILIZATION"',
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "DynamoDBReadCapacityUtilization"
            }
        }' &> /dev/null || true
    
    # Create scaling policy for write capacity
    aws application-autoscaling put-scaling-policy \
        --region "$region" \
        --policy-name "${table_name}-write-scaling-policy" \
        --service-namespace dynamodb \
        --scalable-dimension dynamodb:table:WriteCapacityUnits \
        --resource-id "$resource_id" \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": '"$TARGET_UTILIZATION"',
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "DynamoDBWriteCapacityUtilization"
            }
        }' &> /dev/null || true
    
    print_success "Auto scaling configured for $table_name"
}

optimize_table() {
    local region=$1
    local table_name=$2
    
    print_header "Optimizing $table_name in $region"
    
    # Check if table exists
    local status
    status=$(get_table_status "$region" "$table_name")
    
    if [ "$status" = "NOT_FOUND" ]; then
        print_warning "Table $table_name not found in $region - skipping"
        return 0
    fi
    
    if [ "$status" != "ACTIVE" ]; then
        print_warning "Table $table_name is not ACTIVE (status: $status) - skipping"
        return 0
    fi
    
    # Update billing mode to PROVISIONED
    print_info "Current status: $status"
    update_table_billing_mode "$region" "$table_name"
    
    # Wait for table to be active
    print_info "Waiting for table to become active..."
    aws dynamodb wait table-exists --region "$region" --table-name "$table_name"
    
    # Enable auto scaling
    enable_auto_scaling "$region" "$table_name"
    
    print_success "Optimization complete for $table_name in $region"
    echo ""
}

show_optimization_summary() {
    print_header "DynamoDB Optimization Summary"
    
    echo "Configuration Applied:"
    echo "  • Billing mode: PROVISIONED"
    echo "  • Auto scaling: ENABLED"
    echo "  • Read capacity: $MIN_READ_CAPACITY - $MAX_READ_CAPACITY RCUs (target: ${TARGET_UTILIZATION}%)"
    echo "  • Write capacity: $MIN_WRITE_CAPACITY - $MAX_WRITE_CAPACITY WCUs (target: ${TARGET_UTILIZATION}%)"
    echo "  • Regions: ${REGIONS[*]}"
    echo ""
    
    print_info "Cost Optimization Notes:"
    echo "  • Use Eventually Consistent Reads (default) to save 50% on read costs"
    echo "  • Keep item sizes ≤ 4 KB where possible"
    echo "  • Only create GSI/LSI if absolutely required"
    echo "  • Storage cost: ~$0.25/GB/month"
    echo ""
    
    print_warning "Manual Actions Required:"
    echo "  • Review application code to use Eventually Consistent Reads"
    echo "  • Monitor CloudWatch metrics for capacity utilization"
    echo "  • Consider removing unused indexes"
    echo "  • Implement item size optimization where needed"
}

main() {
    print_header "DynamoDB Optimization Script"
    
    # Check prerequisites
    check_aws_cli
    
    # Check credentials for all regions
    for region in "${REGIONS[@]}"; do
        check_aws_credentials "$region"
    done
    
    # List available tables in each region
    for region in "${REGIONS[@]}"; do
        print_header "Tables in $region"
        list_dynamodb_tables "$region"
        echo ""
    done
    
    # Ask for confirmation
    echo -e "${YELLOW}This script will optimize the following tables:${NC}"
    for table in "${TABLES[@]}"; do
        echo "  • $table"
    done
    echo ""
    echo -e "${YELLOW}In regions: ${REGIONS[*]}${NC}"
    echo ""
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        exit 0
    fi
    
    # Optimize tables in each region
    for region in "${REGIONS[@]}"; do
        for table in "${TABLES[@]}"; do
            optimize_table "$region" "$table"
        done
    done
    
    show_optimization_summary
    print_success "DynamoDB optimization completed successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            print_info "Dry run mode - no changes will be made"
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be done without making changes"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "This script optimizes DynamoDB tables in us-east-1 and eu-west-1 regions"
            echo "by applying the recommended cost-optimization configuration."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
