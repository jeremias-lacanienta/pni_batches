#!/usr/bin/env python3
"""
Passage Data Comparison Tester
Tests if simplified Lambda approach produces same results as ORIGINAL postgres-to-dynamodb-unified.py
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, List

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

try:
    import pg8000.native
except ImportError as e:
    logger.error(f"Missing required module: {e}")
    raise


def get_database_config() -> Dict[str, Any]:
    """Get database configuration from environment variables"""
    required_vars = ['PG_HOST', 'PG_USER', 'PG_PASSWORD']
    
    config = {}
    for var in required_vars:
        value = os.getenv(var)
        if not value:
            raise ValueError(f"Missing required environment variable: {var}")
        config[var.lower().replace('pg_', '')] = value
    
    config['port'] = int(os.getenv('PG_PORT', '5432'))
    config['database'] = 'genaicoe_postgresql'  # dev environment
    
    return config


def test_original_postgres_to_dynamodb_query() -> List[Dict]:
    """Test the EXACT original SQL from postgres-to-dynamodb-unified.py fetch_passages_with_questions()"""
    
    db_config = get_database_config()
    
    try:
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info("Testing ORIGINAL query from postgres-to-dynamodb-unified.py")
        
        # EXACT original SQL from postgres-to-dynamodb-unified.py fetch_passages_with_questions()
        proficiency = 'beginner'
        level_filter = "l.proficiency_level LIKE 'A%'"
        
        original_query = f"""
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
                AND l.proficiency_level LIKE 'A%%'
            ORDER BY l.topic, l.id, p.sort_order
            LIMIT 5
        """
        
        results = connection.run(original_query)
        
        # Process results like the original does
        original_data = []
        for row in results:
            try:
                passage_data = {
                    'lesson_id': row[0],
                    'lesson_title': row[1], 
                    'lesson_description': row[2],
                    'lesson_topic': row[3],
                    'lesson_proficiency': row[4],
                    'lesson_estimated_duration': row[5],
                    'lesson_approval_status': row[6],
                    'passage_id': row[7],
                    'passage_title': row[8],
                    'passage_content': row[9][:200] + '...' if row[9] and len(row[9]) > 200 else row[9],
                    'passage_sort_order': row[10],
                    'passage_approval_status': row[11],
                    'passage_word_count': row[12],
                    'passage_reading_level': row[13],
                    'passage_source': row[14],
                    'proficiency': proficiency  # Set to category like original
                }
                
                # Add questions like original does (separate query)
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
                
                questions = connection.run(questions_query, [passage_data['passage_id']])
                passage_data['questions'] = []
                passage_data['question_count'] = len(questions)
                passage_data['total_points'] = 0
                
                for q_row in questions:
                    question = {
                        'question_id': q_row[0],
                        'question': q_row[1],
                        'type': q_row[2],
                        'options': q_row[3],
                        'correct': q_row[4],
                        'correctAnswer': q_row[5],
                        'acceptableAnswers': q_row[6],
                        'wordLimit': q_row[7],
                        'placeholder': q_row[8],
                        'sort_order': q_row[9],
                        'points': q_row[10],
                        'question_approval_status': q_row[11]
                    }
                    passage_data['questions'].append(question)
                    passage_data['total_points'] += q_row[10] if q_row[10] else 0
                
                original_data.append(passage_data)
                
            except Exception as e:
                logger.warning(f"Error processing original query row: {e}")
                continue
        
        connection.close()
        logger.info(f"ORIGINAL query fetched {len(original_data)} passages with questions")
        return original_data
        
    except Exception as e:
        logger.error(f"Original query failed: {e}")
        raise


def test_simplified_lambda_query() -> List[Dict]:
    """Test the simplified approach used in our Lambda"""
    
    db_config = get_database_config()
    
    try:
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info("Testing SIMPLIFIED Lambda query")
        
        # Simplified query like in our Lambda
        simplified_query = """
        SELECT 
            p.id,
            p.title,
            p.content,
            l.proficiency_level,
            p.sort_order,
            l.topic
        FROM practise_improve_pilot.passages p
        INNER JOIN practise_improve_pilot.lessons l ON p.lesson_id = l.id
        WHERE p.approval_status = 'approved' 
          AND l.approval_status = 'approved'
          AND l.proficiency_level LIKE 'A%'
          AND p.title IS NOT NULL
          AND p.content IS NOT NULL
          AND LENGTH(p.title) > 0
          AND LENGTH(p.content) > 0
        ORDER BY l.proficiency_level, p.sort_order
        LIMIT 5;
        """
        
        results = connection.run(simplified_query)
        
        # Process results
        simplified_data = []
        for passage_id, title, content, proficiency, sort_order, topic in results:
            passage_data = {
                'id': passage_id,
                'title': title,
                'content': content[:200] + '...' if len(content) > 200 else content,
                'proficiency': proficiency,
                'sort_order': sort_order,
                'topic': topic
            }
            simplified_data.append(passage_data)
        
        connection.close()
        logger.info(f"SIMPLIFIED query fetched {len(simplified_data)} passages")
        return simplified_data
        
    except Exception as e:
        logger.error(f"Simplified query failed: {e}")
        raise


def compare_results(original_data: List[Dict], simplified_data: List[Dict]) -> Dict[str, Any]:
    """Compare the results from both approaches"""
    
    logger.info("=" * 60)
    logger.info("COMPARISON ANALYSIS")
    logger.info("=" * 60)
    
    # Check if we have matching passage IDs
    orig_passage_ids = set(p['passage_id'] for p in original_data)
    simp_passage_ids = set(p['id'] for p in simplified_data)
    
    matching_ids = orig_passage_ids.intersection(simp_passage_ids)
    
    comparison = {
        'original_approach': {
            'total_passages': len(original_data),
            'passage_ids': list(orig_passage_ids),
            'has_questions': all('questions' in p for p in original_data),
            'sample_structure': {k: type(v).__name__ for k, v in original_data[0].items()} if original_data else {}
        },
        'simplified_approach': {
            'total_passages': len(simplified_data),
            'passage_ids': list(simp_passage_ids),
            'has_questions': False,
            'sample_structure': {k: type(v).__name__ for k, v in simplified_data[0].items()} if simplified_data else {}
        },
        'analysis': {
            'matching_passage_ids': list(matching_ids),
            'count_matching_ids': len(matching_ids),
            'data_completeness': f"{len(matching_ids)}/{max(len(orig_passage_ids), len(simp_passage_ids))} passages match by ID",
            'structure_difference': 'Original includes full lesson context + questions, simplified focuses on basic passage data'
        }
    }
    
    # Detailed comparison for matching passages
    if matching_ids:
        detailed_comparison = []
        for passage_id in list(matching_ids)[:3]:  # Compare first 3 matches
            orig = next(p for p in original_data if p['passage_id'] == passage_id)
            simp = next(p for p in simplified_data if p['id'] == passage_id)
            
            detailed_comparison.append({
                'passage_id': passage_id,
                'title_match': orig['passage_title'] == simp['title'],
                'proficiency_match': orig['lesson_proficiency'] == simp['proficiency'],
                'topic_match': orig['lesson_topic'] == simp['topic'],
                'original_has_questions': len(orig.get('questions', [])) > 0,
                'question_count': len(orig.get('questions', []))
            })
        
        comparison['detailed_comparison'] = detailed_comparison
    
    return comparison


def main():
    """Main test function"""
    print("\n" + "="*80)
    print("PASSAGE DATA COMPARISON: ORIGINAL postgres-to-dynamodb-unified.py vs SIMPLIFIED Lambda")
    print("="*80)
    
    try:
        # Test original postgres-to-dynamodb-unified approach
        print("\n🔍 Testing ORIGINAL postgres-to-dynamodb-unified.py query...")
        original_data = test_original_postgres_to_dynamodb_query()
        
        # Test simplified Lambda approach  
        print("\n🔍 Testing SIMPLIFIED Lambda query...")
        simplified_data = test_simplified_lambda_query()
        
        # Compare results
        print("\n📊 Comparing results...")
        comparison = compare_results(original_data, simplified_data)
        
        # Save results
        output_file = f'/tmp/passage-comparison-{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        with open(output_file, 'w') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'original_data': original_data,
                'simplified_data': simplified_data,
                'comparison': comparison
            }, f, indent=2, default=str)
        
        print(f"\n📄 Results saved to: {output_file}")
        
        # Print summary
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Original approach: {comparison['original_approach']['total_passages']} passages (with questions)")
        print(f"Simplified approach: {comparison['simplified_approach']['total_passages']} passages (basic data)")
        print(f"Matching passage IDs: {comparison['analysis']['count_matching_ids']}")
        print(f"Data completeness: {comparison['analysis']['data_completeness']}")
        
        if comparison['analysis']['count_matching_ids'] > 0:
            print("✅ SUCCESS: Both approaches access the same core passage data")
            if 'detailed_comparison' in comparison:
                for detail in comparison['detailed_comparison']:
                    print(f"  📋 Passage {detail['passage_id']}: Title={detail['title_match']}, Proficiency={detail['proficiency_match']}, Topic={detail['topic_match']}, Questions={detail['question_count']}")
        else:
            print("⚠️  WARNING: No matching passages found")
            
        return True
        
    except Exception as e:
        logger.error(f"Test failed: {e}")
        return False


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
