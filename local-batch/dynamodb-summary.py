#!/usr/bin/env python3
"""
Summarize all DynamoDB tables in the current AWS account/region using the dynamodb_rw_user profile.
"""
import boto3
import os

aws_profile = 'dynamodb_rw_user'
region = 'eu-west-1'

session = boto3.Session(profile_name=aws_profile, region_name=region)
dynamodb_client = session.client('dynamodb', region_name=region)

print(f"Using AWS profile: {aws_profile} in region: {region}\n")

response = dynamodb_client.list_tables()
tables = response.get('TableNames', [])

if not tables:
    print("No DynamoDB tables found.")
    exit(0)

print(f"Found {len(tables)} DynamoDB tables:")
for table_name in tables:
    print(f"- {table_name}")
    desc = dynamodb_client.describe_table(TableName=table_name)['Table']
    print(f"  Status: {desc['TableStatus']}")
    print(f"  Item count: {desc.get('ItemCount', 'N/A')}")
    print(f"  Size (bytes): {desc.get('TableSizeBytes', 'N/A')}")
    print(f"  ARN: {desc['TableArn']}")
    print(f"  Created: {desc['CreationDateTime']}")
    print(f"  Key schema: {desc['KeySchema']}")
    print()
