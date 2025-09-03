#!/usr/bin/env python3
"""
Simple Prompt Group Migration Utility
Single SQL query to export category, title, content grouped by category
"""

import sys
import os
import configparser
from datetime import datetime
import argparse

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("❌ psycopg2 is required but not installed.")
    print("Please install it with: pip install psycopg2-binary")
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

def export_prompts(environment):
    """Single SQL query to fetch and export prompts"""
    
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
                categories[category] = []
            categories[category].append((title, content))
        
        # Write to text file
        filename = f"config.{environment}.txt"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"# Prompt Configuration - {environment.upper()}\n")
            f.write(f"# Export timestamp: {datetime.now().isoformat()}\n")
            f.write(f"# Total categories: {len(categories)}\n")
            f.write(f"# Total prompts: {len(results)}\n\n")
            
            for category in sorted(categories.keys()):
                f.write(f"[{category}]\n")
                for title, content in categories[category]:
                    # Clean title for config key
                    key = title.replace(' ', '_').replace('-', '_').lower()
                    # Escape newlines in content
                    clean_content = content.replace('\n', '\\n').replace('\r', '')
                    f.write(f"{key} = {clean_content}\n")
                f.write("\n")
        
        print(f"✅ Exported {len(results)} prompts to {filename}")
        print(f"📂 Categories: {sorted(categories.keys())}")
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        sys.exit(1)
    finally:
        if 'connection' in locals():
            connection.close()

def main():
    parser = argparse.ArgumentParser(description='Export prompts using single SQL query')
    parser.add_argument('environment', choices=['dev', 'prod'], help='Environment (dev or prod)')
    args = parser.parse_args()
    
    export_prompts(args.environment)

if __name__ == "__main__":
    main()
