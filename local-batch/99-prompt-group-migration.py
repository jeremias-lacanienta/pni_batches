#!/usr/bin/env python3
"""
Simple Prompt Group Migration Utility
Single SQL query to export category, title, content grouped by category as YAML
"""

import sys
import os
import configparser
from datetime import datetime
import argparse

try:
    import psycopg2
    import psycopg2.extras
    import yaml
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError
except ImportError as e:
    missing_module = str(e).split("'")[1] if "'" in str(e) else str(e)
    if missing_module == "psycopg2":
        print("❌ psycopg2 is required but not installed.")
        print("Please install it with: pip install psycopg2-binary")
    elif missing_module == "yaml":
        print("❌ PyYAML is required but not installed.")
        print("Please install it with: pip install PyYAML")
    elif missing_module == "boto3":
        print("❌ boto3 is required but not installed.")
        print("Please install it with: pip install boto3")
    else:
        print(f"❌ Required module '{missing_module}' is not installed.")
    sys.exit(1)

def get_database_config(environment):
    """Get database configuration from AWS credentials file"""
    aws_creds_path = os.path.expanduser('~/.aws/credentials')
    profile = os.getenv('PG_AWS_PROFILE', 'postgres-creds')
    
    if not os.path.exists(aws_creds_path):
        print(f"❌ AWS credentials file not found at {aws_creds_path}")
        sys.exit(1)
    
    config = configparser.ConfigParser()
    config.read(aws_creds_path)
    
    if profile not in config:
        print(f"❌ Profile '{profile}' not found in {aws_creds_path}")
        sys.exit(1)
    
    try:
        pg_user = config.get(profile, 'pg_user')
        pg_password = config.get(profile, 'pg_password')
        pg_host = config.get(profile, 'pg_host')
        pg_port = config.get(profile, 'pg_port', fallback='5432')
    except configparser.NoOptionError as e:
        print(f"❌ Missing PostgreSQL credential: {e}")
        sys.exit(1)
    
    # Set database name based on environment
    pg_database = 'genaicoe_postgresql' if environment == 'dev' else 'prod'
    
    return {
        'host': pg_host,
        'database': pg_database,
        'user': pg_user,
        'password': pg_password,
        'port': int(pg_port)
    }

def upload_to_s3(filename, environment):
    """Upload the generated YAML file to S3 with proper permissions"""
    bucket_name = 'pi-app-data'
    s3_key = f"prompts.{environment}.yaml"  # Put directly in root, no folder
    
    try:
        # Initialize S3 client
        s3_client = boto3.client('s3')
        
        # Upload file with specific ACL
        print(f"📤 Uploading {filename} to s3://{bucket_name}/{s3_key}...")
        
        s3_client.upload_file(
            filename, 
            bucket_name, 
            s3_key,
            ExtraArgs={
                'ACL': 'public-read',  # Read for everyone
                'Metadata': {
                    'uploaded-by': 'prompt-migration-script',
                    'environment': environment,
                    'upload-timestamp': datetime.now().isoformat()
                }
            }
        )
        
        print(f"✅ Successfully uploaded to s3://{bucket_name}/{s3_key}")
        print(f"🔗 URL: https://{bucket_name}.s3.amazonaws.com/{s3_key}")
        
        return True
        
    except NoCredentialsError:
        print("❌ AWS credentials not found. Please configure AWS CLI or set environment variables.")
        return False
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchBucket':
            print(f"❌ Bucket '{bucket_name}' does not exist.")
        elif error_code == 'AccessDenied':
            print(f"❌ Access denied to bucket '{bucket_name}'. Check your permissions.")
        else:
            print(f"❌ AWS error: {e}")
        return False
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        return False

def export_prompts(environment, skip_upload=False):
    """Single SQL query to fetch and export prompts as YAML"""
    
    # Get database config and connect
    db_config = get_database_config(environment)
    
    try:
        connection = psycopg2.connect(**db_config)
        cursor = connection.cursor()
        
        # Single SQL query - only category, title, content
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
        
        print(f"🔍 Fetching prompts from {environment} environment...")
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Group by category
        categories = {}
        for category, title, content in results:
            if category not in categories:
                categories[category] = {}
            # Use title as key and content as value
            categories[category][title] = content
        
        # Write to YAML file
        filename = f"prompts.{environment}.yaml"
        
        # Prepare YAML structure with metadata first, then categories
        yaml_data = {
            'metadata': {
                'environment': environment.upper(),
                'export_timestamp': datetime.now().isoformat(),
                'total_categories': len(categories),
                'total_prompts': len(results)
            }
        }
        # Add categories in sorted order after metadata
        for category in sorted(categories.keys()):
            yaml_data[category] = categories[category]
        
        with open(filename, 'w', encoding='utf-8') as f:
            yaml.dump(yaml_data, f, default_flow_style=False, allow_unicode=True, 
                     sort_keys=False, width=100, indent=2)
        
        print(f"✅ Exported {len(results)} prompts to {filename}")
        print(f"📂 Categories: {sorted(categories.keys())}")
        
        # Upload to S3 unless skipped
        if not skip_upload:
            upload_success = upload_to_s3(filename, environment)
            if not upload_success:
                print("⚠️  Local file created successfully, but S3 upload failed.")
        else:
            print("⏭️  S3 upload skipped.")
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        sys.exit(1)
    finally:
        if 'connection' in locals():
            connection.close()

def main():
    parser = argparse.ArgumentParser(description='Export prompts as YAML using single SQL query')
    parser.add_argument('environment', choices=['dev', 'prod'], help='Environment (dev or prod)')
    parser.add_argument('--skip-upload', action='store_true', help='Skip S3 upload, only create local file')
    args = parser.parse_args()
    
    export_prompts(args.environment, args.skip_upload)

if __name__ == "__main__":
    main()
