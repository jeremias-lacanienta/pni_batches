#!/usr/bin/env python3
"""
Simple script to retrieve all approved passages with their questions
Usage: python3 get-approved-passages.py [dev|prod]
"""

import sys
import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import configparser

def get_db_config(environment):
    """Get database configuration based on environment"""
    # Load PostgreSQL credentials from ~/.aws/credentials
    aws_creds_path = os.path.expanduser('~/.aws/credentials')
    profile = os.getenv('PG_AWS_PROFILE', 'postgres-creds')
    config = configparser.ConfigParser()
    config.read(aws_creds_path)

    pg_user = config.get(profile, 'pg_user')
    pg_password = config.get(profile, 'pg_password')
    pg_host = config.get(profile, 'pg_host')
    pg_port = config.get(profile, 'pg_port', fallback='5432')
    
    if environment == 'dev':
        pg_database = 'genaicoe_postgresql'
    elif environment == 'prod':
        pg_database = 'prod'
    else:
        raise ValueError(f"Invalid environment: {environment}. Use 'dev' or 'prod'")
    
    return {
        'host': pg_host,
        'port': pg_port,
        'database': pg_database,
        'user': pg_user,
        'password': pg_password
    }

def get_approved_passages(environment='prod'):
    """Retrieve all approved passages with their lessons and questions"""
    
    db_config = get_db_config(environment)
    
    try:
        # Connect to PostgreSQL
        conn = psycopg2.connect(**db_config, cursor_factory=RealDictCursor)
        cursor = conn.cursor()
        
        print(f"📋 Retrieving approved passages from {environment} environment...")
        print(f"🔗 Database: {db_config['database']}")
        print()
        
        # Get all approved passages with their lessons
        cursor.execute("""
            SELECT 
                l.id as lesson_id,
                l.title as lesson_title,
                l.description as lesson_description,
                l.topic as lesson_topic,
                l.proficiency_level as lesson_proficiency,
                l.estimated_duration as lesson_estimated_duration,
                l.approval_status as lesson_approval_status,
                
                p.id as passage_id,
                p.title as passage_title,
                p.content as passage_content,
                p.sort_order as passage_sort_order,
                p.approval_status as passage_approval_status,
                p.word_count as passage_word_count,
                p.reading_level as passage_reading_level,
                p.source as passage_source,
                p.created_at as passage_created_at
                
            FROM practise_improve_pilot.lessons l
            INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
            WHERE l.approval_status = 'approved' 
                AND p.approval_status = 'approved'
            ORDER BY l.topic, l.id, p.sort_order
        """)
        
        passages = cursor.fetchall()
        print(f"✅ Found {len(passages)} approved passages")
        
        # Get questions for each passage
        for i, passage in enumerate(passages):
            cursor.execute("""
                SELECT 
                    q.id as question_id,
                    q.question_text as question,
                    q.question_type as type,
                    q.options,
                    q.correct_answer_index as correct,
                    q.correct_answer as correct_answer,
                    q.acceptable_answers,
                    q.word_limit,
                    q.placeholder,
                    q.sort_order,
                    q.points,
                    q.approval_status as question_approval_status
                FROM practise_improve_pilot.questions q
                WHERE q.passage_id = %s::text
                    AND q.approval_status = 'approved'
                ORDER BY q.sort_order
            """, (passage['passage_id'],))
            
            questions = cursor.fetchall()
            passage['questions'] = [dict(q) for q in questions]
            passage['question_count'] = len(questions)
            
            # Convert to dict for JSON serialization
            passages[i] = dict(passage)
        
        cursor.close()
        conn.close()
        
        return passages
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def print_summary(passages):
    """Print a summary of the passages"""
    if not passages:
        print("❌ No passages found")
        return
    
    print(f"\n📊 SUMMARY:")
    print(f"   Total passages: {len(passages)}")
    
    # Group by lesson
    lessons = {}
    total_questions = 0
    
    for passage in passages:
        lesson_id = passage['lesson_id']
        if lesson_id not in lessons:
            lessons[lesson_id] = {
                'title': passage['lesson_title'],
                'topic': passage['lesson_topic'],
                'proficiency': passage['lesson_proficiency'],
                'passages': 0,
                'questions': 0
            }
        lessons[lesson_id]['passages'] += 1
        lessons[lesson_id]['questions'] += passage['question_count']
        total_questions += passage['question_count']
    
    print(f"   Total lessons: {len(lessons)}")
    print(f"   Total questions: {total_questions}")
    print()
    
    print("📚 BY LESSON:")
    for lesson_id, lesson_data in lessons.items():
        print(f"   Lesson {lesson_id}: {lesson_data['title']}")
        print(f"      Topic: {lesson_data['topic']}")
        print(f"      Level: {lesson_data['proficiency']}")
        print(f"      Passages: {lesson_data['passages']}")
        print(f"      Questions: {lesson_data['questions']}")
        print()

def main():
    environment = sys.argv[1] if len(sys.argv) > 1 else 'prod'
    
    if environment not in ['dev', 'prod']:
        print("Usage: python3 get-approved-passages.py [dev|prod]")
        sys.exit(1)
    
    passages = get_approved_passages(environment)
    
    if passages:
        print_summary(passages)
        
        # Optionally save to JSON file
        output_file = f"approved-passages-{environment}.json"
        with open(output_file, 'w') as f:
            json.dump(passages, f, indent=2, default=str)
        print(f"💾 Data saved to: {output_file}")
    
if __name__ == "__main__":
    main()
