#!/usr/bin/env python3
"""
Passage Migration Lambda Function (Modified for Data Comparison)
Exports passage data from PostgreSQL to JSON format for comparison
DynamoDB operations are commented out for validation purposes
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, List
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    import pg8000.native
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


def upload_json_to_s3(data: Dict[str, Any], environment: str) -> bool:
    """Upload the data as JSON to S3 for comparison"""
    bucket_name = os.getenv('S3_BUCKET', 'pi-app-data')
    s3_key = f"passage-migration-{environment}.json"
    
    try:
        s3_client = boto3.client('s3')
        
        logger.info(f"Uploading comparison data to s3://{bucket_name}/{s3_key}")
        
        # Convert data to JSON string with proper formatting
        json_content = json.dumps(data, indent=2, default=str, ensure_ascii=False)
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=json_content.encode('utf-8'),
            ACL='public-read',
            ContentType='application/json',
            Metadata={
                'uploaded-by': 'passage-migration-lambda',
                'environment': environment,
                'upload-timestamp': datetime.now().isoformat(),
                'purpose': 'data-comparison'
            }
        )
        
        logger.info(f"Successfully uploaded comparison data to s3://{bucket_name}/{s3_key}")
        return True
        
    except Exception as e:
        logger.error(f"S3 upload failed: {e}")
        return False


def get_dynamodb_config(environment: str) -> Dict[str, str]:
    """Get DynamoDB table names and region based on environment"""
    region = 'us-east-1' if environment == 'dev' else 'eu-west-1'
    
    return {
        'region': region,
        'passages_table': 'pni-passages',
        'topics_table': 'pni-topics',
        'cache_metadata_table': 'pni-cache-metadata'
    }


# COMMENTED OUT FOR COMPARISON - DYNAMODB TABLE CREATION
# def create_dynamodb_tables(dynamodb, config: Dict[str, str]) -> bool:
#     """Create DynamoDB tables if they don't exist"""
#     
#     def create_passages_table():
#         """Create passages table with lesson_id as partition key and passage_id as sort key"""
#         try:
#             table = dynamodb.create_table(
#                 TableName=config['passages_table'],
#                 KeySchema=[
#                     {'AttributeName': 'lesson_id', 'KeyType': 'HASH'},  # Partition key
#                     {'AttributeName': 'passage_id', 'KeyType': 'RANGE'}  # Sort key
#                 ],
#                 AttributeDefinitions=[
#                     {'AttributeName': 'lesson_id', 'AttributeType': 'N'},
#                     {'AttributeName': 'passage_id', 'AttributeType': 'S'},  # String for UUIDs
#                     {'AttributeName': 'proficiency', 'AttributeType': 'S'}
#                 ],
#                 GlobalSecondaryIndexes=[
#                     {
#                         'IndexName': 'proficiency-index',
#                         'KeySchema': [
#                             {'AttributeName': 'proficiency', 'KeyType': 'HASH'}
#                         ],
#                         'Projection': {'ProjectionType': 'ALL'}
#                     }
#                 ],
#                 BillingMode='PAY_PER_REQUEST'
#             )
#             
#             logger.info(f"Creating table {config['passages_table']}...")
#             table.wait_until_exists()
#             logger.info(f"Table {config['passages_table']} created successfully")
#             return True
#             
#         except ClientError as e:
#             if e.response['Error']['Code'] == 'ResourceInUseException':
#                 logger.info(f"Table {config['passages_table']} already exists")
#                 return True
#             else:
#                 logger.error(f"Error creating table {config['passages_table']}: {e}")
#                 return False
# 
#     def create_topics_table():
#         """Create topics table"""
#         try:
#             table = dynamodb.create_table(
#                 TableName=config['topics_table'],
#                 KeySchema=[
#                     {'AttributeName': 'topic', 'KeyType': 'HASH'}  # Partition key
#                 ],
#                 AttributeDefinitions=[
#                     {'AttributeName': 'topic', 'AttributeType': 'S'}
#                 ],
#                 BillingMode='PAY_PER_REQUEST'
#             )
#             
#             logger.info(f"Creating table {config['topics_table']}...")
#             table.wait_until_exists()
#             logger.info(f"Table {config['topics_table']} created successfully")
#             return True
#             
#         except ClientError as e:
#             if e.response['Error']['Code'] == 'ResourceInUseException':
#                 logger.info(f"Table {config['topics_table']} already exists")
#                 return True
#             else:
#                 logger.error(f"Error creating table {config['topics_table']}: {e}")
#                 return False
# 
#     def create_cache_metadata_table():
#         """Create cache metadata table"""
#         try:
#             table = dynamodb.create_table(
#                 TableName=config['cache_metadata_table'],
#                 KeySchema=[
#                     {'AttributeName': 'cache_type', 'KeyType': 'HASH'}  # Partition key
#                 ],
#                 AttributeDefinitions=[
#                     {'AttributeName': 'cache_type', 'AttributeType': 'S'}
#                 ],
#                 BillingMode='PAY_PER_REQUEST'
#             )
#             
#             logger.info(f"Creating table {config['cache_metadata_table']}...")
#             table.wait_until_exists()
#             logger.info(f"Table {config['cache_metadata_table']} created successfully")
#             return True
#             
#         except ClientError as e:
#             if e.response['Error']['Code'] == 'ResourceInUseException':
#                 logger.info(f"Table {config['cache_metadata_table']} already exists")
#                 return True
#             else:
#                 logger.error(f"Error creating table {config['cache_metadata_table']}: {e}")
#                 return False
# 
#     # Create all tables
#     return (create_passages_table() and 
#             create_topics_table() and 
#             create_cache_metadata_table())


def fetch_passages_complete(environment: str) -> List[Dict]:
    """Fetch passages with complete data using single query with JSON aggregation"""
    
    # Get database config and connect
    db_config = get_database_config(environment)
    
    try:
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info(f"🔍 Fetching COMPLETE passage data with single query from {environment}")
        
        # Single query to get ALL passage data including questions
        # Match original logic: ALL proficiency levels + filter for passages with questions
        complete_query = """
        SELECT 
            -- Lesson information
            l.id as lesson_id,
            l.title as lesson_title,
            l.summary as lesson_description,
            l.topic as lesson_topic,
            l.proficiency_level as lesson_proficiency,
            l.estimated_duration as lesson_estimated_duration,
            l.approval_status as lesson_approval_status,
            
            -- Passage information
            p.id as passage_id,
            p.title as passage_title,
            p.content as passage_content,
            p.sort_order as passage_sort_order,
            p.approval_status as passage_approval_status,
            p.word_count as passage_word_count,
            p.reading_level as passage_reading_level,
            p.source as passage_source,
            
            -- Aggregated questions for this passage
            JSON_AGG(
                JSON_BUILD_OBJECT(
                    'question_id', q.id,
                    'question', q.question_text,
                    'type', q.question_type,
                    'options', q.options,
                    'correct', q.correct_answer_index,
                    'correctAnswer', q.correct_answer,
                    'acceptableAnswers', q.acceptable_answers,
                    'wordLimit', q.word_limit,
                    'placeholder', q.placeholder,
                    'sort_order', q.sort_order,
                    'points', COALESCE(q.points, 0),
                    'question_approval_status', q.approval_status
                ) ORDER BY q.sort_order
            ) as questions
            
        FROM practise_improve_pilot.lessons l
        INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
        INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text 
        WHERE l.approval_status = 'approved' 
            AND p.approval_status = 'approved'
            AND q.approval_status = 'approved'
            AND p.title IS NOT NULL
            AND p.content IS NOT NULL
            AND (
                l.proficiency_level LIKE 'A%' OR 
                l.proficiency_level LIKE 'B%' OR 
                l.proficiency_level LIKE 'C%'
            )
        GROUP BY 
            l.id, l.title, l.summary, l.topic, l.proficiency_level, 
            l.estimated_duration, l.approval_status,
            p.id, p.title, p.content, p.sort_order, p.approval_status,
            p.word_count, p.reading_level, p.source
        ORDER BY 
            l.proficiency_level, l.topic, l.id, p.sort_order
        LIMIT 50;
        """
        
        logger.info("  📊 Executing single query for complete passage data...")
        results = connection.run(complete_query)
        
        # Process results
        all_passages = []
        
        for row in results:
            try:
                # Extract all fields
                lesson_id, lesson_title, lesson_description, lesson_topic, lesson_proficiency, \
                lesson_estimated_duration, lesson_approval_status, \
                passage_id, passage_title, passage_content, passage_sort_order, \
                passage_approval_status, passage_word_count, passage_reading_level, \
                passage_source, questions_json = row
                
                # Map proficiency to category
                if lesson_proficiency.startswith('A'):
                    proficiency = 'beginner'
                elif lesson_proficiency.startswith('B'):
                    proficiency = 'intermediate'
                elif lesson_proficiency.startswith('C'):
                    proficiency = 'advanced'
                else:
                    proficiency = lesson_proficiency
                
                # Parse questions JSON
                questions = questions_json if questions_json else []
                
                # Calculate totals
                question_count = len(questions)
                total_points = sum(q.get('points', 0) for q in questions) if questions else 0
                
                # Create complete passage data structure
                passage_data = {
                    'lesson_id': lesson_id,
                    'lesson_title': lesson_title,
                    'lesson_description': lesson_description,
                    'lesson_topic': lesson_topic,
                    'lesson_proficiency': lesson_proficiency,
                    'lesson_estimated_duration': lesson_estimated_duration,
                    'lesson_approval_status': lesson_approval_status,
                    'passage_id': passage_id,
                    'passage_title': passage_title,
                    'passage_content': passage_content,  # Full content
                    'passage_sort_order': passage_sort_order,
                    'passage_approval_status': passage_approval_status,
                    'passage_word_count': passage_word_count,
                    'passage_reading_level': passage_reading_level,
                    'passage_source': passage_source,
                    'proficiency': proficiency,  # Category
                    'questions': questions,
                    'question_count': question_count,
                    'total_points': total_points
                }
                
                all_passages.append(passage_data)
                
                logger.info(f"    ✅ '{passage_title[:30]}...' ({proficiency}) - {question_count} questions ({total_points} points)")
                
            except Exception as e:
                logger.warning(f"Error processing passage row: {e}")
                continue
        
        connection.close()
        logger.info(f"✅ Single query fetched {len(all_passages)} passages with complete data")
        return all_passages
        
    except Exception as e:
        logger.error(f"Complete single query fetch failed: {e}")
        raise
        
        # Convert to list of dicts and add questions
        result_passages = []
        for passage_row in passages:
            try:
                passage = dict(zip([
                    'lesson_id', 'lesson_title', 'lesson_description', 'lesson_topic',
                    'lesson_proficiency', 'lesson_estimated_duration', 'lesson_approval_status',
                    'passage_id', 'passage_title', 'passage_content', 'passage_sort_order',
                    'passage_approval_status', 'passage_word_count', 'passage_reading_level',
                    'passage_source'
                ], passage_row))
                
                passage['proficiency'] = proficiency  # Set to category
                
                # Clean up any potential encoding issues
                for key, value in passage.items():
                    if isinstance(value, str):
                        try:
                            # Ensure the string is properly encoded
                            passage[key] = value.encode('utf-8', errors='replace').decode('utf-8')
                        except (UnicodeDecodeError, UnicodeEncodeError):
                            # Replace problematic characters
                            passage[key] = str(value).encode('ascii', errors='replace').decode('ascii')
                    elif isinstance(value, bytes):
                        # Convert bytes to string with error handling
                        try:
                            passage[key] = value.decode('utf-8', errors='replace')
                        except:
                            passage[key] = str(value)
                
                # Get questions for this passage
                try:
                    questions_query = """
                        SELECT 
                            q.id as question_id,
                            q.question_text as question,
                            q.question_type as type,
                            q.options,
                            q.correct_answer_index as correct,
                            q.correct_answer as "correctAnswer",
                            q.acceptable_answers as "acceptableAnswers",
                            q.word_limit as "wordLimit",
                            q.placeholder,
                            q.sort_order,
                            q.points,
                            q.approval_status as question_approval_status
                        FROM practise_improve_pilot.questions q
                        WHERE q.passage_id = %s::text
                            AND q.approval_status = 'approved'
                        ORDER BY q.sort_order
                    """
                    
                    questions = connection.run(questions_query, (str(passage['passage_id']),))
                    
                    passage['questions'] = []
                    for q_row in questions:
                        try:
                            question = dict(zip([
                                'question_id', 'question', 'type', 'options', 'correct',
                                'correctAnswer', 'acceptableAnswers', 'wordLimit', 'placeholder',
                                'sort_order', 'points', 'question_approval_status'
                            ], q_row))
                            
                            # Clean up encoding issues in questions too
                            for key, value in question.items():
                                if isinstance(value, str):
                                    try:
                                        question[key] = value.encode('utf-8', errors='replace').decode('utf-8')
                                    except (UnicodeDecodeError, UnicodeEncodeError):
                                        question[key] = str(value).encode('ascii', errors='replace').decode('ascii')
                                elif isinstance(value, bytes):
                                    try:
                                        question[key] = value.decode('utf-8', errors='replace')
                                    except:
                                        question[key] = str(value)
                            
                            passage['questions'].append(question)
                        except Exception as qe:
                            logger.warning(f"Error processing question in passage {passage['passage_id']}: {qe}")
                            continue
                    
                    passage['question_count'] = len(passage['questions'])
                    passage['total_points'] = sum(q.get('points', 0) or 0 for q in passage['questions'])
                    
                except Exception as qe:
                    logger.warning(f"Error fetching questions for passage {passage['passage_id']}: {qe}")
                    passage['questions'] = []
                    passage['question_count'] = 0
                    passage['total_points'] = 0
                
                # Only include passages with questions
                if passage['question_count'] > 0:
                    result_passages.append(passage)
                    
            except Exception as pe:
                logger.warning(f"Error processing passage: {pe}")
                continue
        
        return result_passages
        
    except Exception as e:
        logger.error(f"Error fetching {proficiency} passages: {e}")
        raise


def fetch_topics(connection) -> List[str]:
    """Fetch all distinct topics"""
    try:
        query = """
            SELECT DISTINCT topic 
            FROM practise_improve_pilot.lessons 
            WHERE approval_status = 'approved' 
                AND topic IS NOT NULL 
                AND topic != '' 
            ORDER BY topic
        """
        
        results = connection.run(query)
        topics = []
        
        for row in results:
            if row[0] and str(row[0]).strip():
                topic = row[0]
                # Handle encoding issues
                if isinstance(topic, str):
                    try:
                        topic = topic.encode('utf-8', errors='replace').decode('utf-8')
                    except (UnicodeDecodeError, UnicodeEncodeError):
                        topic = str(topic).encode('ascii', errors='replace').decode('ascii')
                elif isinstance(topic, bytes):
                    try:
                        topic = topic.decode('utf-8', errors='replace')
                    except:
                        topic = str(topic)
                
                topics.append(topic.strip())
        
        return topics
        
    except Exception as e:
        logger.error(f"Error fetching topics: {e}")
        raise


# DYNAMODB WRITE FUNCTIONS - OPTIMIZED FOR COST EFFICIENCY
def batch_write_passages(passages: List[Dict], table_name: str, dynamodb):
    """Write passages to DynamoDB in batches - optimized for cost efficiency"""
    table = dynamodb.Table(table_name)
    
    logger.info(f"Writing {len(passages)} passages to {table_name}...")
    
    # DynamoDB batch write limit is 25 items
    batch_size = 25
    successful_writes = 0
    
    for i in range(0, len(passages), batch_size):
        batch = passages[i:i + batch_size]
        
        try:
            with table.batch_writer() as batch_writer:
                for passage in batch:
                    # Clean up the passage data and ensure proper types
                    clean_passage = {}
                    for k, v in passage.items():
                        if v is not None:
                            # Ensure numeric fields are numbers
                            if k in ['lesson_id', 'passage_word_count', 'question_count', 'total_points']:
                                clean_passage[k] = int(v) if v != '' else 0
                            # passage_id should remain as string (UUID)
                            elif k == 'passage_id':
                                clean_passage[k] = str(v)
                            # Ensure string fields are strings
                            elif k in ['proficiency', 'lesson_title', 'passage_title']:
                                clean_passage[k] = str(v)
                            # Convert empty strings to None (skip them)
                            elif v == '':
                                continue
                            else:
                                clean_passage[k] = v
                    
                    batch_writer.put_item(Item=clean_passage)
                    successful_writes += 1
                    
            logger.info(f"Batch {i//batch_size + 1}: Wrote {len(batch)} passages")
            
        except Exception as e:
            logger.error(f"Error writing batch {i//batch_size + 1}: {e}")
            raise
    
    logger.info(f"Successfully wrote {successful_writes} passages to {table_name}")


def batch_write_topics(topics: List[str], table_name: str, dynamodb):
    """Write topics to DynamoDB - optimized for cost efficiency"""
    table = dynamodb.Table(table_name)
    
    # Filter out empty or None topics
    valid_topics = [topic for topic in topics if topic and topic.strip()]
    
    if not valid_topics:
        logger.info("No valid topics to write to DynamoDB")
        return
    
    with table.batch_writer() as batch_writer:
        for topic in valid_topics:
            batch_writer.put_item(Item={'topic': topic.strip()})
    
    logger.info(f"Written {len(valid_topics)} topics to DynamoDB")


def write_cache_metadata(table_name: str, config: Dict[str, str], dynamodb):
    """Write cache metadata - optimized for cost efficiency"""
    table = dynamodb.Table(table_name)
    
    metadata = {
        'cache_type': 'lesson_cache',
        'lastUpdated': int(datetime.now().timestamp() * 1000),
        'source': 'passage-migration-lambda',
        'migrationTimestamp': int(datetime.now().timestamp() * 1000),
        'tables': {
            'passages': config['passages_table'],
            'topics': config['topics_table']
        },
        'structure': {
            'passages': 'passage-focused (individual passages with questions)'
        }
    }
    
    table.put_item(Item=metadata)
    logger.info("Cache metadata written to DynamoDB")
#     logger.info("Cache metadata written to DynamoDB")


def migrate_passages(environment: str) -> Dict[str, Any]:
    """Main migration function - writes to DynamoDB with cost optimization"""
    
    # Get configurations
    dynamo_config = get_dynamodb_config(environment)
    
    try:
        logger.info(f"Starting optimized passage migration for {environment} environment")
        
        # Connect to DynamoDB
        dynamodb = boto3.resource('dynamodb', region_name=dynamo_config['region'])
        
        # Create tables if they don't exist (only creates if missing - no extra cost)
        logger.info("Verifying DynamoDB tables exist...")
        # Note: Table creation is rare and only happens once per environment
        
        # Fetch data from PostgreSQL using optimized single query
        logger.info("Fetching data from PostgreSQL...")
        passages = fetch_passages_complete(environment)
        
        logger.info(f"Fetched {len(passages)} passages with complete data")
        
        # Get database connection for topics (reuse from fetch_passages_complete)
        db_config = get_database_config(environment)
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info("Writing data to DynamoDB...")
        
        # Write passages and topics to DynamoDB (cost-optimized)
        batch_write_passages(passages, dynamo_config['passages_table'], dynamodb)
        
        # Get topics only if passages were successfully written
        topics = fetch_topics(connection)
        batch_write_topics(topics, dynamo_config['topics_table'], dynamodb)
        
        # Close connection
        connection.close()
        
        # Write metadata (single item write)
        write_cache_metadata(dynamo_config['cache_metadata_table'], dynamo_config, dynamodb)
        
        # COMMENTED OUT - S3 output for cost optimization
        # logger.info("Creating JSON output for comparison...")
        # upload_success = upload_json_to_s3(output_data, environment)
        
        return {
            'success': True,
            'environment': environment,
            'region': dynamo_config['region'],
            'total_passages': len(passages),
            'total_topics': len(topics),
            'dynamodb_writes': {
                'passages': len(passages),
                'topics': len(topics),
                'metadata': 1
            },
            'note': 'Data written to DynamoDB tables - S3 output disabled for cost optimization'
        }
        
    except Exception as e:
        logger.error(f"Migration error: {e}")
        raise


def lambda_handler(event, context):
    """Lambda entry point"""
    try:
        # Determine environment from AWS region
        region = context.invoked_function_arn.split(':')[3]  # Extract region from ARN
        environment = 'dev' if region == 'us-east-1' else 'prod'
        
        logger.info(f"Detected region: {region}, using environment: {environment}")
        
        if environment not in ['dev', 'prod']:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': f"Invalid environment: {environment}. Must be 'dev' or 'prod'"
                })
            }
        
        logger.info(f"Starting passage migration for DynamoDB ({environment} environment)")
        
        result = migrate_passages(environment)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Passage migration completed successfully (DynamoDB writes)',
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
    
    parser = argparse.ArgumentParser(description='Migrate passages from PostgreSQL to DynamoDB')
    parser.add_argument('environment', choices=['dev', 'prod'], help='Environment (dev or prod)')
    args = parser.parse_args()
    
    # Simulate Lambda context
    class MockContext:
        def __init__(self, region):
            self.invoked_function_arn = f"arn:aws:lambda:{region}:123456789:function:test"
    
    region = 'us-east-1' if args.environment == 'dev' else 'eu-west-1'
    event = {}
    context = MockContext(region)
    
    response = lambda_handler(event, context)
    print(json.dumps(response, indent=2))


if __name__ == "__main__":
    main()
