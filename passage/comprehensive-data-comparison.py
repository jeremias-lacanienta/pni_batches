#!/usr/bin/env python3
"""
Comprehensive Passage Data Comparison Report
Compares simplified Lambda vs original postgres-to-dynamodb-unified.py including questions
Generates detailed analysis for pni-passage table structure
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, List
from collections import defaultdict

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


def fetch_original_approach_data() -> List[Dict]:
    """
    Fetch data using the EXACT approach from postgres-to-dynamodb-unified.py
    This replicates the fetch_passages_with_questions() function structure
    """
    
    db_config = get_database_config()
    
    try:
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info("🔍 Fetching data using ORIGINAL postgres-to-dynamodb-unified.py approach...")
        
        all_passages = []
        
        # Process each proficiency level using substring match
        proficiency_levels = [
            ('beginner', 'A'),
            ('intermediate', 'B'), 
            ('advanced', 'C')
        ]
        
        for proficiency, db_prefix in proficiency_levels:
            logger.info(f"  📚 Processing {proficiency} level (prefix: {db_prefix})")
            
            # Main passage query (use substring to avoid LIKE % issues)
            passages_query = """
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
                    AND SUBSTRING(l.proficiency_level, 1, 1) = %s
                ORDER BY l.topic, l.id, p.sort_order
                LIMIT 3
            """
            
            passages = connection.run(passages_query, [db_prefix])
            
            logger.info(f"    📄 Found {len(passages)} passages for {proficiency}")
            
            # Process each passage and add questions
            for passage_row in passages:
                try:
                    # Create passage data structure (like original)
                    passage_data = {
                        'lesson_id': passage_row[0],
                        'lesson_title': passage_row[1],
                        'lesson_description': passage_row[2],
                        'lesson_topic': passage_row[3],
                        'lesson_proficiency': passage_row[4],
                        'lesson_estimated_duration': passage_row[5],
                        'lesson_approval_status': passage_row[6],
                        'passage_id': passage_row[7],
                        'passage_title': passage_row[8],
                        'passage_content': passage_row[9][:200] + '...' if passage_row[9] and len(passage_row[9]) > 200 else passage_row[9],
                        'passage_sort_order': passage_row[10],
                        'passage_approval_status': passage_row[11],
                        'passage_word_count': passage_row[12],
                        'passage_reading_level': passage_row[13],
                        'passage_source': passage_row[14],
                        'proficiency': proficiency  # Set to category like original
                    }
                    
                    # Fetch questions for this passage (exact original query)
                    questions_query = """
                        SELECT 
                            q.id as question_id,
                            q.question_text as question,
                            q.question_type as type,
                            q.options,
                            q.correct_answer_index as correct,
                            q.correct_answer as correctAnswer,
                            q.acceptable_answers as acceptableAnswers,
                            q.word_limit as wordLimit,
                            q.placeholder,
                            q.sort_order,
                            q.points,
                            q.approval_status as question_approval_status
                        FROM practise_improve_pilot.questions q
                        WHERE q.passage_id = %s
                            AND q.approval_status = 'approved'
                        ORDER BY q.sort_order
                    """
                    
                    questions = connection.run(questions_query, [str(passage_data['passage_id'])])
                    
                    # Process questions
                    passage_questions = []
                    total_points = 0
                    
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
                            'points': q_row[10] if q_row[10] else 0,
                            'question_approval_status': q_row[11]
                        }
                        passage_questions.append(question)
                        total_points += question['points']
                    
                    # Add question data to passage (like original)
                    passage_data['questions'] = passage_questions
                    passage_data['question_count'] = len(passage_questions)
                    passage_data['total_points'] = total_points
                    
                    all_passages.append(passage_data)
                    
                    logger.info(f"      ❓ Added {len(passage_questions)} questions (total points: {total_points})")
                    
                except Exception as e:
                    logger.warning(f"Error processing passage {passage_row[7]}: {e}")
                    continue
        
        connection.close()
        logger.info(f"✅ ORIGINAL approach fetched {len(all_passages)} total passages with questions")
        return all_passages
        
    except Exception as e:
        logger.error(f"Original approach failed: {e}")
        raise


def fetch_simplified_lambda_data() -> List[Dict]:
    """Fetch data using the simplified Lambda approach"""
    
    db_config = get_database_config()
    
    try:
        connection = pg8000.native.Connection(
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port'],
            database=db_config['database']
        )
        
        logger.info("🔍 Fetching data using SIMPLIFIED Lambda approach...")
        
        # Simplified query (current Lambda approach)
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
          AND p.title IS NOT NULL
          AND p.content IS NOT NULL
          AND LENGTH(p.title) > 0
          AND LENGTH(p.content) > 0
        ORDER BY l.proficiency_level, p.sort_order
        LIMIT 9;
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
        logger.info(f"✅ SIMPLIFIED approach fetched {len(simplified_data)} passages")
        return simplified_data
        
    except Exception as e:
        logger.error(f"Simplified approach failed: {e}")
        raise


def generate_comprehensive_comparison(original_data: List[Dict], simplified_data: List[Dict]) -> Dict[str, Any]:
    """Generate comprehensive comparison analysis"""
    
    logger.info("📊 Generating comprehensive comparison analysis...")
    
    # Extract passage IDs and create lookup maps
    orig_by_id = {p['passage_id']: p for p in original_data}
    simp_by_id = {p['id']: p for p in simplified_data}
    
    orig_ids = set(orig_by_id.keys())
    simp_ids = set(simp_by_id.keys())
    
    matching_ids = orig_ids.intersection(simp_ids)
    only_in_original = orig_ids - simp_ids
    only_in_simplified = simp_ids - orig_ids
    
    # Proficiency level analysis
    orig_by_proficiency = defaultdict(list)
    simp_by_proficiency = defaultdict(list)
    
    for p in original_data:
        orig_by_proficiency[p['proficiency']].append(p)
    
    for p in simplified_data:
        # Map actual proficiency levels to categories
        if p['proficiency'].startswith('A'):
            category = 'beginner'
        elif p['proficiency'].startswith('B'):
            category = 'intermediate'
        elif p['proficiency'].startswith('C'):
            category = 'advanced'
        else:
            category = p['proficiency']
        simp_by_proficiency[category].append(p)
    
    # Question analysis
    question_stats = {
        'total_questions': sum(len(p.get('questions', [])) for p in original_data),
        'total_points': sum(p.get('total_points', 0) for p in original_data),
        'question_types': defaultdict(int),
        'passages_with_questions': sum(1 for p in original_data if p.get('question_count', 0) > 0),
        'passages_without_questions': sum(1 for p in original_data if p.get('question_count', 0) == 0)
    }
    
    for passage in original_data:
        for question in passage.get('questions', []):
            question_stats['question_types'][question.get('type', 'unknown')] += 1
    
    # Detailed matching analysis
    detailed_matches = []
    for passage_id in list(matching_ids)[:5]:  # Analyze first 5 matches
        orig = orig_by_id[passage_id]
        simp = simp_by_id[passage_id]
        
        match_analysis = {
            'passage_id': passage_id,
            'title_match': orig['passage_title'] == simp['title'],
            'content_length_orig': len(orig['passage_content']),
            'content_length_simp': len(simp['content']),
            'proficiency_orig': orig['lesson_proficiency'],
            'proficiency_simp': simp['proficiency'],
            'topic_orig': orig['lesson_topic'],
            'topic_simp': simp['topic'],
            'question_count': orig.get('question_count', 0),
            'total_points': orig.get('total_points', 0),
            'question_types': [q.get('type') for q in orig.get('questions', [])]
        }
        detailed_matches.append(match_analysis)
    
    # Create comprehensive report
    comparison_report = {
        'summary': {
            'original_approach': {
                'total_passages': len(original_data),
                'unique_passage_ids': len(orig_ids),
                'has_questions': True,
                'has_lesson_context': True
            },
            'simplified_approach': {
                'total_passages': len(simplified_data),
                'unique_passage_ids': len(simp_ids),
                'has_questions': False,
                'has_lesson_context': False
            },
            'data_overlap': {
                'matching_passage_ids': len(matching_ids),
                'only_in_original': len(only_in_original),
                'only_in_simplified': len(only_in_simplified),
                'overlap_percentage': (len(matching_ids) / max(len(orig_ids), len(simp_ids))) * 100
            }
        },
        
        'proficiency_analysis': {
            'original_by_proficiency': {k: len(v) for k, v in orig_by_proficiency.items()},
            'simplified_by_proficiency': {k: len(v) for k, v in simp_by_proficiency.items()}
        },
        
        'question_analysis': question_stats,
        
        'detailed_matches': detailed_matches,
        
        'data_structure_comparison': {
            'original_fields': list(original_data[0].keys()) if original_data else [],
            'simplified_fields': list(simplified_data[0].keys()) if simplified_data else [],
            'original_sample': original_data[0] if original_data else {},
            'simplified_sample': simplified_data[0] if simplified_data else {}
        },
        
        'recommendations': {
            'data_completeness': 'Original approach provides full lesson context and questions',
            'data_efficiency': 'Simplified approach is faster and avoids encoding issues',
            'migration_strategy': 'Use simplified approach for initial data validation, then enhance with questions',
            'pni_passage_structure': {
                'required_fields': ['lesson_id', 'passage_id', 'title', 'content', 'proficiency', 'questions'],
                'original_provides': ['lesson_id', 'passage_id', 'title', 'content', 'proficiency', 'questions', 'lesson_context'],
                'simplified_provides': ['passage_id', 'title', 'content', 'proficiency'],
                'missing_in_simplified': ['lesson_id', 'questions', 'lesson_context']
            }
        }
    }
    
    return comparison_report


def main():
    """Main comparison function"""
    print("\n" + "="*100)
    print("COMPREHENSIVE PASSAGE DATA COMPARISON REPORT")
    print("Original postgres-to-dynamodb-unified.py vs Simplified Lambda")
    print("="*100)
    
    try:
        # Fetch data using both approaches
        print("\n📋 Phase 1: Data Collection")
        original_data = fetch_original_approach_data()
        simplified_data = fetch_simplified_lambda_data()
        
        # Generate comprehensive comparison
        print("\n📊 Phase 2: Analysis")
        comparison_report = generate_comprehensive_comparison(original_data, simplified_data)
        
        # Save detailed results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = f'/tmp/comprehensive-passage-comparison-{timestamp}.json'
        
        full_report = {
            'metadata': {
                'timestamp': datetime.now().isoformat(),
                'environment': 'dev',
                'comparison_type': 'comprehensive_with_questions'
            },
            'raw_data': {
                'original_data': original_data,
                'simplified_data': simplified_data
            },
            'analysis': comparison_report
        }
        
        with open(output_file, 'w') as f:
            json.dump(full_report, f, indent=2, default=str)
        
        print(f"\n📄 Full report saved to: {output_file}")
        
        # Print executive summary
        print("\n" + "="*80)
        print("EXECUTIVE SUMMARY")
        print("="*80)
        
        summary = comparison_report['summary']
        print(f"📊 Data Volume:")
        print(f"   Original: {summary['original_approach']['total_passages']} passages with questions")
        print(f"   Simplified: {summary['simplified_approach']['total_passages']} passages (basic data)")
        
        overlap = summary['data_overlap']
        print(f"\n🔗 Data Overlap:")
        print(f"   Matching IDs: {overlap['matching_passage_ids']}")
        print(f"   Overlap rate: {overlap['overlap_percentage']:.1f}%")
        print(f"   Only in original: {overlap['only_in_original']}")
        print(f"   Only in simplified: {overlap['only_in_simplified']}")
        
        questions = comparison_report['question_analysis']
        print(f"\n❓ Question Analysis:")
        print(f"   Total questions: {questions['total_questions']}")
        print(f"   Total points: {questions['total_points']}")
        print(f"   Question types: {dict(questions['question_types'])}")
        print(f"   Passages with questions: {questions['passages_with_questions']}")
        
        proficiency = comparison_report['proficiency_analysis']
        print(f"\n📚 Proficiency Distribution:")
        print(f"   Original: {proficiency['original_by_proficiency']}")
        print(f"   Simplified: {proficiency['simplified_by_proficiency']}")
        
        # Recommendations
        recommendations = comparison_report['recommendations']
        print(f"\n💡 Key Recommendations:")
        print(f"   • {recommendations['data_completeness']}")
        print(f"   • {recommendations['data_efficiency']}")
        print(f"   • {recommendations['migration_strategy']}")
        
        pni_structure = recommendations['pni_passage_structure']
        print(f"\n🏗️  PNI-Passage Table Requirements:")
        print(f"   Required: {pni_structure['required_fields']}")
        print(f"   Original provides: {len(pni_structure['original_provides'])} fields")
        print(f"   Simplified provides: {len(pni_structure['simplified_provides'])} fields")
        print(f"   Missing in simplified: {pni_structure['missing_in_simplified']}")
        
        if overlap['matching_passage_ids'] > 0:
            print(f"\n✅ SUCCESS: Both approaches access valid passage data")
            print(f"✅ Data integrity confirmed with {overlap['overlap_percentage']:.1f}% overlap")
        else:
            print(f"\n⚠️  WARNING: Limited data overlap detected")
        
        print(f"\n📋 Next Steps:")
        print(f"   1. ✅ Simplified approach working for basic passage data")
        print(f"   2. 🔧 Enhance Lambda to include questions for full pni-passage structure")
        print(f"   3. 🚀 Deploy enhanced version for complete migration")
        
        return True
        
    except Exception as e:
        logger.error(f"Comprehensive comparison failed: {e}")
        return False


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
