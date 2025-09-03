# Prompt Group Migration Lambda

This directory contains the Lambda function for migrating prompt groups from PostgreSQL to S3 in YAML format.

## Files

- `prompt-group-migration.py` - Main Lambda function (converted from `99-prompt-group-migration.py`)
- `deploy-lambda.sh` - Main deployment script for both environments
- `deploy-dev.sh` - Quick deploy to dev (us-east-1)
- `deploy-prod.sh` - Quick deploy to prod (eu-west-1)

## Environment Variables

The Lambda function requires the following environment variables:

- `PG_HOST` - PostgreSQL host
- `PG_USER` - PostgreSQL username
- `PG_PASSWORD` - PostgreSQL password
- `PG_PORT` - PostgreSQL port (default: 5432)
- `S3_BUCKET` - S3 bucket name (default: pi-app-data)

## Deployment

### Deploy to Both Environments
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
