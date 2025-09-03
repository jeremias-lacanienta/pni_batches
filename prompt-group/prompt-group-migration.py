#!/usr/bin/env python3
"""
Prompt Group Migration Lambda Function
Exports prompts from PostgreSQL to S3 as YAML format
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    import psycopg2
    import psycopg2.extras
    import yaml
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError
except ImportError as e:
    logger.error(f"Missing required module: {e}")
    raise


def get_database_config(environment: str) -> Dict[str, Any]:
    """Get database configuration from environment variables"""
    required_vars = ['PG_HOST', 'PG_USER', 'PG_PASSWORD']
    
    config = {}
    for var in required_vars:
        value = os.getenv(var)
        if not value:
            raise ValueError(f"Missing required environment variable: {var}")
        config[var.lower().replace('pg_', '')] = value
    
    config['port'] = int(os.getenv('PG_PORT', '5432'))
    config['database'] = 'genaicoe_postgresql' if environment == 'dev' else 'prod'
    
    return config


def upload_to_s3(yaml_content: str, environment: str) -> bool:
    """Upload the generated YAML content to S3"""
    bucket_name = os.getenv('S3_BUCKET', 'pi-app-data')
    s3_key = f"prompts.{environment}.yaml"
    
    try:
        s3_client = boto3.client('s3')
        
        logger.info(f"Uploading to s3://{bucket_name}/{s3_key}")
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=yaml_content.encode('utf-8'),
            ACL='public-read',
            ContentType='application/x-yaml',
            Metadata={
                'uploaded-by': 'prompt-migration-lambda',
                'environment': environment,
                'upload-timestamp': datetime.now().isoformat()
            }
        )
        
        logger.info(f"Successfully uploaded to s3://{bucket_name}/{s3_key}")
        return True
        
    except Exception as e:
        logger.error(f"S3 upload failed: {e}")
        return False


def export_prompts(environment: str) -> Dict[str, Any]:
    """Export prompts from PostgreSQL and upload to S3"""
    
    # Get database config and connect
    db_config = get_database_config(environment)
    
    try:
        connection = psycopg2.connect(**db_config)
        cursor = connection.cursor()
        
        # SQL query to fetch prompts
        query = """
        SELECT 
            pg.category,
            pg.title,
            p.content
        FROM practise_improve_pilot.prompt_groups pg
        INNER JOIN practise_improve_pilot.prompts p ON pg.id = p.group_id
        WHERE pg.is_active = true 
          AND p.is_active = true
        ORDER BY pg.category, pg.title;
        """
        
        logger.info(f"Fetching prompts from {environment} environment")
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Group by category
        categories = {}
        for category, title, content in results:
            if category not in categories:
                categories[category] = {}
            categories[category][title] = content
        
        # Prepare YAML structure
        yaml_data = {
            'metadata': {
                'environment': environment.upper(),
                'export_timestamp': datetime.now().isoformat(),
                'total_categories': len(categories),
                'total_prompts': len(results)
            }
        }
        
        # Add categories in sorted order
        for category in sorted(categories.keys()):
            yaml_data[category] = categories[category]
        
        # Convert to YAML string
        yaml_content = yaml.dump(
            yaml_data, 
            default_flow_style=False, 
            allow_unicode=True,
            sort_keys=False, 
            width=100, 
            indent=2
        )
        
        # Upload to S3
        upload_success = upload_to_s3(yaml_content, environment)
        
        return {
            'success': True,
            'environment': environment,
            'total_prompts': len(results),
            'total_categories': len(categories),
            'categories': sorted(categories.keys()),
            's3_upload': upload_success
        }
        
    except Exception as e:
        logger.error(f"Database error: {e}")
        raise
    finally:
        if 'connection' in locals():
            connection.close()


def lambda_handler(event, context):
    """Lambda entry point"""
    try:
        # Get environment from event or default to 'dev'
        environment = event.get('environment', 'dev')
        
        if environment not in ['dev', 'prod']:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': f"Invalid environment: {environment}. Must be 'dev' or 'prod'"
                })
            }
        
        logger.info(f"Starting prompt migration for {environment} environment")
        
        result = export_prompts(environment)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Prompt migration completed successfully',
                'result': result
            })
        }
        
    except Exception as e:
        logger.error(f"Lambda execution failed: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f"Migration failed: {str(e)}"
            })
        }


# For local testing
def main():
    """Local execution entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Export prompts as YAML')
    parser.add_argument('environment', choices=['dev', 'prod'], help='Environment (dev or prod)')
    args = parser.parse_args()
    
    # Simulate Lambda event
    event = {'environment': args.environment}
    context = None
    
    response = lambda_handler(event, context)
    print(json.dumps(response, indent=2))


if __name__ == "__main__":
    main()
