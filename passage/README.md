# Passage Migration Lambda (Modified for Data Comparison)

**CURRENT STATUS: DynamoDB operations are commented out for data validation**

This Lambda function exports passage data from PostgreSQL to JSON format for comparison purposes. The DynamoDB write operations have been temporarily commented out to allow data validation before actual migration.

## Overview

The function currently:
- Reads passage data from PostgreSQL (with questions and lesson context)
- ~~Creates DynamoDB tables if they don't exist~~ **COMMENTED OUT**
- ~~Migrates data to DynamoDB~~ **COMMENTED OUT** 
- **NEW**: Exports data to JSON format and uploads to S3 for comparison
- Runs automatically every 10 minutes (when enabled)

## Current Output

Instead of writing to DynamoDB, the function now:
- Exports all passage data as JSON
- Uploads to S3 as `passage-migration-{environment}.json`
- Provides detailed comparison data including metadata structure

## JSON Output Structure

```json
{
  "metadata": {
    "environment": "dev|prod",
    "region": "us-east-1|eu-west-1", 
    "export_timestamp": "ISO timestamp",
    "total_passages": number,
    "total_topics": number,
    "passages_by_level": {
      "beginner": number,
      "intermediate": number, 
      "advanced": number
    }
  },
  "passages": [/* all passage objects with questions */],
  "topics": [/* topic objects */],
  "cache_metadata": {/* DynamoDB metadata structure */}
}
```

## Tables That Would Be Created (Currently Commented Out)

- `pni-passages` - Individual passages with their questions
- `pni-topics` - Available topics  
- `pni-cache-metadata` - Cache metadata and timestamps

## Comparison Files

- **Dev**: `s3://pi-app-data/passage-migration-dev.json`
- **Prod**: `s3://pi-app-data/passage-migration-prod.json`

## Restoring DynamoDB Operations

To restore DynamoDB functionality after validation:

1. Uncomment the DynamoDB functions in `passage-migration.py`:
   - `create_dynamodb_tables()`
   - `batch_write_passages()`
   - `batch_write_topics()` 
   - `write_cache_metadata()`

2. Uncomment the DynamoDB operations in `migrate_passages()` function

3. Redeploy the Lambda functions

## Environment Detection

The function automatically detects the environment based on the AWS region:
- `us-east-1` → Development environment (`genaicoe_postgresql` database)
- `eu-west-1` → Production environment (`prod` database)

## Deployment

### Deploy to Development (us-east-1)
```bash
./deploy-dev.sh
```

### Deploy to Production (eu-west-1)
```bash
./deploy-prod.sh
```

## Schedule Management

The EventBridge schedules are initially created in DISABLED state. Use the management script to control them:

### Enable automatic migration
```bash
./manage-schedule.sh enable dev    # Enable dev schedule
./manage-schedule.sh enable prod   # Enable prod schedule
```

### Disable automatic migration
```bash
./manage-schedule.sh disable dev   # Disable dev schedule
./manage-schedule.sh disable prod  # Disable prod schedule
```

### Check schedule status
```bash
./manage-schedule.sh status dev    # Check dev schedule status
./manage-schedule.sh status prod   # Check prod schedule status
```

## Manual Testing

You can test the Lambda function locally:

```bash
python3 passage-migration.py dev   # Test with dev environment
python3 passage-migration.py prod  # Test with prod environment
```

## Dependencies

- `pg8000` - Pure Python PostgreSQL driver
- `boto3` - AWS SDK for Python
- Built-in AWS Lambda Python 3.9 runtime

## Database Schema

The function expects the following PostgreSQL schema:
- `practise_improve_pilot.lessons`
- `practise_improve_pilot.passages` 
- `practise_improve_pilot.questions`

## DynamoDB Structure

### pni-passages table
- Partition key: `lesson_id` (Number)
- Sort key: `passage_id` (String)
- GSI: `proficiency-index` on `proficiency` field

### pni-topics table
- Partition key: `topic` (String)

### pni-cache-metadata table
- Partition key: `cache_type` (String)

## Environment Variables

Set in the Lambda function:
- `PG_HOST` - PostgreSQL host
- `PG_USER` - PostgreSQL username  
- `PG_PASSWORD` - PostgreSQL password
- `PG_PORT` - PostgreSQL port (default: 5432)

## IAM Permissions

The Lambda function uses the existing `lambda-prompt-migration-role` which should have:
- DynamoDB read/write permissions
- CloudWatch Logs permissions
- VPC access (if database is in VPC)
