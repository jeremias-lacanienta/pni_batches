# Prompt Group Migration Lambda

This directory contains the Lambda function for migrating prompt groups from PostgreSQL to S3 in YAML format.

## Files

- `prompt-group-migration.py` - Main Lambda function (converted from `99-prompt-group-migration.py`)
- `deploy-lambda.sh` - Main deployment script for both environments
- `deploy-dev.sh` - Quick deploy to dev (us-east-1)
- `deploy-prod.sh` - Quick deploy to prod (eu-west-1)
- `manage-schedule.sh` - EventBridge schedule management script

## Environment Variables

The Lambda function requires the following environment variables:

- `PG_HOST` - PostgreSQL host
- `PG_USER` - PostgreSQL username
- `PG_PASSWORD` - PostgreSQL password
- `PG_PORT` - PostgreSQL port (default: 5432)
- `S3_BUCKET` - S3 bucket name (default: pi-app-data)

## Deployment

### Deploy to Both Environments (with EventBridge schedule)
```bash
./deploy-lambda.sh deploy
```

### Deploy to Dev Only (us-east-1)
```bash
./deploy-dev.sh
```

### Deploy to Prod Only (eu-west-1)
```bash
./deploy-prod.sh
```

### Test Lambda Function
```bash
# Test dev environment
./deploy-lambda.sh test dev

# Test prod environment
./deploy-lambda.sh test prod
```

### Clean up EventBridge Schedules
```bash
# Remove all schedules
./deploy-lambda.sh cleanup all

# Remove specific environment schedule
./deploy-lambda.sh cleanup dev
```

## EventBridge Schedule Management

The Lambda functions are automatically scheduled to run every 10 minutes using EventBridge.

### Manage Schedules
```bash
# Check schedule status
./manage-schedule.sh status

# Enable/disable schedules
./manage-schedule.sh enable all
./manage-schedule.sh disable prod

# Update schedule frequency
./manage-schedule.sh update all "5 minutes"
./manage-schedule.sh update dev "1 hour"
```

### Schedule Details
- **Default frequency**: Every 10 minutes
- **Rule names**: 
  - `prompt-group-migration-schedule-dev`
  - `prompt-group-migration-schedule-prod`
- **Trigger payload**: `{"environment": "dev"}` or `{"environment": "prod"}`

## Lambda Function Details

- **Runtime**: Python 3.9
- **Timeout**: 300 seconds (5 minutes)
- **Memory**: 512 MB
- **Handler**: `lambda_function.lambda_handler`

## Function Names

- Dev: `prompt-group-migration-dev` (us-east-1)
- Prod: `prompt-group-migration-prod` (eu-west-1)

## Invocation

The Lambda function accepts an event with the following structure:

```json
{
  "environment": "dev|prod"
}
```

## Output

The function exports prompts to S3 as `prompts.{environment}.yaml` with the following structure:

```yaml
metadata:
  environment: DEV/PROD
  export_timestamp: "2025-09-03T15:30:00"
  total_categories: 5
  total_prompts: 25

category1:
  title1: "content1"
  title2: "content2"

category2:
  title3: "content3"
```

## IAM Permissions

The Lambda function requires:
- Basic Lambda execution permissions
- S3 PutObject permissions on the target bucket
- Network access to PostgreSQL database

**EventBridge requires:**
- `events:PutRule` - Create/update EventBridge rules
- `events:PutTargets` - Add Lambda as target
- `events:EnableRule`/`events:DisableRule` - Manage rule state
- `lambda:AddPermission` - Allow EventBridge to invoke Lambda

## Monitoring

- **CloudWatch Logs**: `/aws/lambda/prompt-group-migration-dev` and `/aws/lambda/prompt-group-migration-prod`
- **EventBridge Rules**: Monitor rule execution in EventBridge console
- **S3 Objects**: Check timestamp metadata on uploaded YAML files
