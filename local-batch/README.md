# PNI PostgreSQL to DynamoDB Migration System

This directory contains a unified migration system for transferring data from PostgreSQL to DynamoDB with support for both development and production environments.

## 🚀 Quick Start

### Basic Usage
```bash
# Run incremental migration for development environment (default)
./00-run-migration.sh dev

# Run clean migration for development environment (recreates tables)
./00-run-migration.sh dev --clean

# Run incremental migration for production environment
./00-run-migration.sh prod

# Run clean migration for production environment (recreates tables)
./00-run-migration.sh prod --clean
```

### Migration Modes

#### Incremental Migration (Default)
- **Cost Optimized**: Only writes changed or new data
- **Behavior**: 
  - Row exists + same content → **SKIPPED** (no DynamoDB cost)
  - Row exists + different content → **UPDATED** (write cost)
  - Row does not exist → **CREATED** (write cost)
- **Comparison**: Content hash excluding timestamps
- **Use Case**: Regular updates, cost-sensitive environments

#### Clean Migration (--clean flag)
- **Complete Refresh**: Recreates all tables and writes all data
- **Behavior**: All data written fresh (full write costs)
- **Use Case**: Schema changes, data corruption recovery, fresh deployments

## 📁 Script Structure

### Main Process Scripts (Sequential)
- **`00-run-migration.sh`** - Main coordinator script that runs the entire migration pipeline
- **`01-setup-environment.sh`** - Sets up Python virtual environment and dependencies
- **`02-validate-prerequisites.sh`** - Validates AWS credentials and PostgreSQL connectivity
- **`03-create-aws-resources.sh`** - Creates DynamoDB tables with environment-specific prefixes
- **`04-run-migration.sh`** - Executes the actual data migration
- **`05-verify-migration.sh`** - Verifies migration success and data integrity

### Migration Script
- **`postgres-to-dynamodb-unified.py`** - Unified Python script that handles the actual data migration

### Utility Scripts (99- prefix)
- **`99-migration-summary.sh`** - Generates comprehensive migration status report
- **`99-create-iam-user.sh`** - Creates IAM user with DynamoDB permissions (one-time setup)
- **`99-cleanup-migration.sh`** - Cleanup script for removing tables and resources

## 🌍 Environment Configuration

### Development Environment (`dev`)
- **Database**: `genaicoe_postgresql`
- **Region**: `us-east-1`
- **Tables**: `pni-lessons`, `pni-passages`, `pni-topics`, `pni-cache-metadata`

### Production Environment (`prod`)
- **Database**: `prod`
- **Region**: `eu-west-1`
- **Tables**: `pni-lessons`, `pni-passages`, `pni-topics`, `pni-cache-metadata`

**Note**: Same table names across environments, deployed in different AWS regions.

## ⚙️ Prerequisites

### 1. AWS Credentials
Configure AWS CLI with appropriate permissions:
```bash
aws configure
```

### 2. PostgreSQL Credentials
Add PostgreSQL credentials to `~/.aws/credentials`:
```ini
[postgres-creds]
pg_host = your-postgres-host
pg_user = your-username
pg_password = your-password
pg_port = 5432
```

### 3. Python Dependencies
The migration system will automatically install:
- `boto3` (AWS SDK)
- `psycopg2-binary` (PostgreSQL adapter)
- `tabulate` (Table formatting)

## 📊 Usage Examples

### Run Complete Migration
```bash
# Development environment - incremental migration (default)
./00-run-migration.sh dev

# Development environment - clean migration (recreate tables)
./00-run-migration.sh dev --clean

# Production environment - incremental migration (default)
./00-run-migration.sh prod

# Production environment - clean migration (recreate tables)
./00-run-migration.sh prod --clean
```

### Check Migration Status
```bash
# Get comprehensive status report
./99-migration-summary.sh dev
./99-migration-summary.sh prod
```

### Setup IAM User (One-time)
```bash
# Create IAM user for development
./99-create-iam-user.sh dev

# Create IAM user for production
./99-create-iam-user.sh prod
```

### Cleanup Resources
```bash
# Clean up development environment
./99-cleanup-migration.sh dev --confirm

# Clean up production environment
./99-cleanup-migration.sh prod --confirm
```

### Run Individual Steps
```bash
# Setup environment only
./01-setup-environment.sh dev

# Validate prerequisites only
./02-validate-prerequisites.sh dev

# Create AWS resources only
./03-create-aws-resources.sh dev

# Run migration only (requires setup first)
./04-run-migration.sh dev

# Verify migration only
./05-verify-migration.sh dev
```

## � Cost Optimization

### DynamoDB Write Cost Management
The migration system is designed to minimize DynamoDB costs:

- **Incremental Migration**: Only writes changed or new items
- **Content Comparison**: Uses MD5 hash of item content (excluding timestamps)
- **Cost Reporting**: Shows actual vs potential costs and savings
- **Typical Savings**: 70-90% reduction in write costs for subsequent migrations

### Write Operation Behavior
```
📊 MIGRATION STATISTICS:
  ✍️  New Items Written: 45
  🔄 Existing Items Updated: 12  
  ⏭️ Unchanged Items Skipped: 143
  💰 Cost Optimization:
    - Potential cost (all writes): $0.2500
    - Actual cost (changed only): $0.0713
    - Savings: $0.1787 (71.5%)
```

## 🗂️ Data Migration Details

The migration transfers the following data:

### Source Tables (PostgreSQL)
- `lessons` - Lesson content and metadata
- `questions` - Questions associated with lessons and passages
- `passages` - Reading passages within lessons

### Target Tables (DynamoDB)
- **Lessons Table**: Lesson-focused view with embedded questions
- **Passages Table**: Passage-focused view with embedded questions
- **Topics Table**: Topic categories and levels
- **Cache Metadata**: Migration tracking and metadata

### Data Transformations
- Questions are embedded within their parent lessons/passages
- JSON fields are parsed and structured appropriately
- Timestamps are converted to ISO format
- Missing values are handled with sensible defaults

## 🔧 Troubleshooting

### Common Issues

1. **AWS Permissions Error**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Create IAM user with proper permissions
   ./99-create-iam-user.sh dev
   ```

2. **PostgreSQL Connection Failed**
   ```bash
   # Verify credentials in ~/.aws/credentials
   # Test connection manually
   psql -h your-host -U your-user -d your-database
   ```

3. **Python Environment Issues**
   ```bash
   # Clean up and recreate environment
   rm -rf .venv
   ./01-setup-environment.sh dev
   ```

4. **DynamoDB Table Already Exists**
   ```bash
   # Clean up existing tables
   ./99-cleanup-migration.sh dev --confirm
   ```

### Logs and Debugging
- All scripts generate timestamped logs with colored output
- Check individual script outputs for detailed error messages
- Use `99-migration-summary.sh` for overall status

## 🧹 Cleanup

To completely remove all migration resources:

```bash
# Remove all DynamoDB tables and local files
./99-cleanup-migration.sh dev --confirm

# Optionally remove IAM user manually
aws iam detach-user-policy --user-name pni-dynamodb-dev-user --policy-arn arn:aws:iam::ACCOUNT:policy/pni-migration/PNI-DynamoDB-Dev-Policy
aws iam delete-user --user-name pni-dynamodb-dev-user
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT:policy/pni-migration/PNI-DynamoDB-Dev-Policy
```

## 📝 Notes

- All scripts include comprehensive error handling and validation
- Environment-specific configuration prevents accidental cross-environment data mixing
- The migration system is idempotent - can be run multiple times safely
- Tables use PAY_PER_REQUEST billing mode to optimize costs
- Migration metadata is stored for tracking and verification purposes

## 🔗 Related Files

- `DATABASE_CRITICAL_ANALYSIS.md` - Database schema analysis
- `database_schema_analysis_*.md` - Detailed schema documentation
- Backup files in `local-batch-backup.zip`
