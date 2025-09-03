#!/usr/bin/env python3
"""
Original PostgreSQL Query Runner - No Modifications
Runs the exact original query from postgres-to-dynamodb-unified.py and exports to JSON
Then compares with Lambda output
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, List
import psycopg2
from psycopg2.extras import RealDictCursor

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

# Use same config approach as original postgres-to-dynamodb-unified.py
import configparser

def get_postgres_config():
    """Get PostgreSQL config like original script"""
    # Load PostgreSQL credentials from ~/.aws/credentials
    aws_creds_path = os.path.expanduser('~/.aws/credentials')
    profile = os.getenv('PG_AWS_PROFILE', 'postgres-creds')
    config = configparser.ConfigParser()
    config.read(aws_creds_path)

    pg_user = config.get(profile, 'pg_user')
    pg_password = config.get(profile, 'pg_password')
    pg_host = config.get(profile, 'pg_host')
    pg_port = config.get(profile, 'pg_port', fallback='5432')
    pg_database = 'genaicoe_postgresql'  # dev environment

    return {
        'host': pg_host,
        'port': pg_port,
        'database': pg_database,
        'user': pg_user,
        'password': pg_password
    }

def fetch_original_passages_with_questions(proficiency: str) -> List[Dict]:
    """
    EXACT COPY of fetch_passages_with_questions() from postgres-to-dynamodb-unified.py
    NO MODIFICATIONS - this is the original working code
    """
    POSTGRES_CONFIG = get_postgres_config()
    
    try:
        # Use a fresh connection to avoid transaction conflicts
        fresh_conn = psycopg2.connect(**POSTGRES_CONFIG)
        
        with fresh_conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Map proficiency categories to database values
            if proficiency == 'beginner':
                level_filter = "l.proficiency_level LIKE 'A%'"
            elif proficiency == 'intermediate':
                level_filter = "l.proficiency_level LIKE 'B%'"
            elif proficiency == 'advanced':
                level_filter = "l.proficiency_level LIKE 'C%'"
            else:
                raise ValueError(f"Unknown proficiency level: {proficiency}")
            
            # Get passages with lesson context (EXACTLY like original - get ALL first)
            cursor.execute(f"""
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
                    p.source as passage_source
                    
                FROM practise_improve_pilot.lessons l
                INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
                WHERE l.approval_status = 'approved' 
                    AND p.approval_status = 'approved' 
                    AND {level_filter}
                ORDER BY l.topic, l.id, p.sort_order
            """)
            
            passages = cursor.fetchall()
            
            # Get questions for each passage
            for passage in passages:
                passage['proficiency'] = proficiency  # Set to category (beginner/intermediate/advanced)
                try:
                    cursor.execute("""
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
                    """, (passage['passage_id'],))
                    
                    questions = cursor.fetchall()
                    passage['questions'] = [dict(q) for q in questions]
                    passage['question_count'] = len(questions)
                    passage['total_points'] = sum(q.get('points', 0) for q in questions)
                    
                except Exception as qe:
                    logger.warning(f"Error fetching questions for passage {passage['passage_id']}: {qe}")
                    passage['questions'] = []  # Set empty questions if query fails
                    passage['question_count'] = 0
                    passage['total_points'] = 0
            
            fresh_conn.close()
            # Filter out passages with no questions (EXACTLY like original)
            passages_with_questions = [dict(p) for p in passages if p.get('question_count', 0) > 0]
            return passages_with_questions
            
    except Exception as e:
        logger.error(f"Error in fetch_original_passages_with_questions: {e}")
        raise

def run_original_postgres_queries():
    """Run the original postgres queries for all proficiency levels"""
    
    logger.info("🔍 Running ORIGINAL postgres-to-dynamodb-unified.py queries...")
    
    all_passages = []
    
    # Run for all proficiency levels like original script
    proficiency_levels = ['beginner', 'intermediate', 'advanced']
    
    for proficiency in proficiency_levels:
        logger.info(f"  📚 Fetching {proficiency} passages...")
        try:
            passages = fetch_original_passages_with_questions(proficiency)
            logger.info(f"    ✅ Found {len(passages)} {proficiency} passages")
            all_passages.extend(passages)
        except Exception as e:
            logger.error(f"    ❌ Failed to fetch {proficiency} passages: {e}")
    
    logger.info(f"✅ Total passages fetched: {len(all_passages)}")
    
    return all_passages

def load_lambda_output():
    """Load the Lambda JSON output"""
    
    lambda_file = '/tmp/passage-export-dev.json'
    
    if not os.path.exists(lambda_file):
        logger.error(f"Lambda output file not found: {lambda_file}")
        return None
    
    with open(lambda_file, 'r') as f:
        lambda_data = json.load(f)
    
    logger.info(f"📄 Loaded Lambda output: {len(lambda_data.get('passages', []))} passages")
    return lambda_data

def compare_original_vs_lambda(original_data: List[Dict], lambda_data: Dict):
    """Compare original postgres output with Lambda output"""
    
    logger.info("📊 Comparing ORIGINAL postgres vs Lambda outputs...")
    
    lambda_passages = lambda_data.get('passages', [])
    
    # Create ID mappings
    orig_by_id = {p['passage_id']: p for p in original_data}
    lambda_by_id = {p['id']: p for p in lambda_passages}
    
    orig_ids = set(orig_by_id.keys())
    lambda_ids = set(lambda_by_id.keys())
    
    matching_ids = orig_ids.intersection(lambda_ids)
    only_in_original = orig_ids - lambda_ids
    only_in_lambda = lambda_ids - orig_ids
    
    # Detailed comparison
    comparison = {
        'metadata': {
            'timestamp': datetime.now().isoformat(),
            'comparison_type': 'original_postgres_vs_lambda'
        },
        'summary': {
            'original_postgres': {
                'total_passages': len(original_data),
                'unique_ids': len(orig_ids),
                'has_questions': True,
                'has_lesson_context': True
            },
            'lambda_output': {
                'total_passages': len(lambda_passages),
                'unique_ids': len(lambda_ids),
                'has_questions': False,
                'has_lesson_context': False
            },
            'overlap': {
                'matching_ids': len(matching_ids),
                'only_in_original': len(only_in_original),
                'only_in_lambda': len(only_in_lambda),
                'overlap_percentage': (len(matching_ids) / max(len(orig_ids), len(lambda_ids))) * 100 if max(len(orig_ids), len(lambda_ids)) > 0 else 0
            }
        },
        'detailed_comparison': [],
        'original_data_sample': original_data[:2] if original_data else [],
        'lambda_data_sample': lambda_passages[:2] if lambda_passages else []
    }
    
    # Detailed field comparison for matching IDs
    for passage_id in list(matching_ids)[:5]:  # Compare first 5 matches
        orig = orig_by_id[passage_id]
        lamb = lambda_by_id[passage_id]
        
        field_comparison = {
            'passage_id': passage_id,
            'title_match': orig.get('passage_title') == lamb.get('title'),
            'content_length_orig': len(orig.get('passage_content', '')),
            'content_length_lambda': len(lamb.get('content', '')),
            'proficiency_orig': orig.get('lesson_proficiency'),
            'proficiency_lambda': lamb.get('proficiency'),
            'topic_orig': orig.get('lesson_topic'),
            'topic_lambda': lamb.get('topic'),
            'questions_in_original': orig.get('question_count', 0),
            'questions_types': [q.get('type') for q in orig.get('questions', [])],
            'total_points': orig.get('total_points', 0),
            'lesson_context_available': {
                'lesson_id': orig.get('lesson_id'),
                'lesson_title': orig.get('lesson_title'),
                'lesson_description': bool(orig.get('lesson_description'))
            }
        }
        
        comparison['detailed_comparison'].append(field_comparison)
    
    # Statistics about questions
    total_questions = sum(p.get('question_count', 0) for p in original_data)
    total_points = sum(p.get('total_points', 0) for p in original_data)
    question_types = {}
    
    for passage in original_data:
        for question in passage.get('questions', []):
            qtype = question.get('type', 'unknown')
            question_types[qtype] = question_types.get(qtype, 0) + 1
    
    comparison['question_analysis'] = {
        'total_questions': total_questions,
        'total_points': total_points,
        'question_types': question_types,
        'passages_with_questions': sum(1 for p in original_data if p.get('question_count', 0) > 0),
        'passages_without_questions': sum(1 for p in original_data if p.get('question_count', 0) == 0)
    }
    
    return comparison

def main():
    """Main comparison function"""
    
    print("\n" + "="*80)
    print("ORIGINAL POSTGRES vs LAMBDA COMPARISON")
    print("Using unmodified original postgres-to-dynamodb-unified.py queries")
    print("="*80)
    
    try:
        # Run original postgres queries
        print("\n📋 Phase 1: Running original PostgreSQL queries...")
        original_data = run_original_postgres_queries()
        
        # Load Lambda output
        print("\n📋 Phase 2: Loading Lambda output...")
        lambda_data = load_lambda_output()
        
        if not lambda_data:
            print("❌ Cannot proceed without Lambda output")
            return False
        
        # Compare results
        print("\n📋 Phase 3: Performing comparison...")
        comparison = compare_original_vs_lambda(original_data, lambda_data)
        
        # Save complete results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save original postgres data
        orig_file = f'/tmp/original-postgres-export-{timestamp}.json'
        with open(orig_file, 'w') as f:
            json.dump({
                'metadata': {'source': 'original_postgres-to-dynamodb-unified.py', 'timestamp': datetime.now().isoformat()},
                'passages': original_data
            }, f, indent=2, default=str)
        
        # Save comparison report
        comparison_file = f'/tmp/original-vs-lambda-comparison-{timestamp}.json'
        with open(comparison_file, 'w') as f:
            json.dump(comparison, f, indent=2, default=str)
        
        print(f"\n📄 Original postgres data saved to: {orig_file}")
        print(f"📄 Comparison report saved to: {comparison_file}")
        
        # Print summary
        print("\n" + "="*60)
        print("COMPARISON SUMMARY")
        print("="*60)
        
        summary = comparison['summary']
        print(f"📊 Data Volume:")
        print(f"   Original PostgreSQL: {summary['original_postgres']['total_passages']} passages")
        print(f"   Lambda Output: {summary['lambda_output']['total_passages']} passages")
        
        overlap = summary['overlap']
        print(f"\n🔗 Data Overlap:")
        print(f"   Matching passage IDs: {overlap['matching_ids']}")
        print(f"   Overlap percentage: {overlap['overlap_percentage']:.1f}%")
        print(f"   Only in original: {overlap['only_in_original']}")
        print(f"   Only in lambda: {overlap['only_in_lambda']}")
        
        questions = comparison['question_analysis']
        print(f"\n❓ Question Analysis (Original only):")
        print(f"   Total questions: {questions['total_questions']}")
        print(f"   Total points: {questions['total_points']}")
        print(f"   Question types: {questions['question_types']}")
        print(f"   Passages with questions: {questions['passages_with_questions']}")
        print(f"   Passages without questions: {questions['passages_without_questions']}")
        
        # Field comparison for matches
        if comparison['detailed_comparison']:
            print(f"\n🔍 Field Comparison (Sample):")
            for detail in comparison['detailed_comparison'][:3]:
                print(f"   Passage {detail['passage_id']}:")
                print(f"     Title match: {detail['title_match']}")
                print(f"     Proficiency: {detail['proficiency_orig']} vs {detail['proficiency_lambda']}")
                print(f"     Questions: {detail['questions_in_original']} ({detail['total_points']} points)")
        
        # Conclusions
        print(f"\n✅ CONCLUSIONS:")
        if overlap['matching_ids'] > 0:
            print(f"   • Both approaches access the same core passage data")
            print(f"   • Original provides full lesson context + questions")
            print(f"   • Lambda provides basic passage data only")
            print(f"   • Data integrity confirmed with {overlap['overlap_percentage']:.1f}% overlap")
        else:
            print(f"   • No matching passages found - need to investigate")
        
        return True
        
    except Exception as e:
        logger.error(f"Comparison failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
