#!/usr/bin/env python3
"""
Question Format and Field Comparison
Compare question structures between original PostgreSQL and Lambda outputs
"""

import json

def load_data(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def analyze_question_structure(data, source_name):
    """Analyze question structure and fields"""
    
    all_questions = []
    for passage in data.get('passages', []):
        for question in passage.get('questions', []):
            all_questions.append(question)
    
    if not all_questions:
        return None
    
    # Get field names from first question
    sample_question = all_questions[0]
    field_names = list(sample_question.keys())
    
    # Analyze question types
    question_types = {}
    for q in all_questions:
        q_type = q.get('type', 'unknown')
        if q_type not in question_types:
            question_types[q_type] = []
        question_types[q_type].append(q)
    
    return {
        'source': source_name,
        'total_questions': len(all_questions),
        'field_names': sorted(field_names),
        'question_types': {k: len(v) for k, v in question_types.items()},
        'sample_questions': {k: v[0] for k, v in question_types.items()},
        'all_questions': all_questions
    }

def compare_questions():
    """Compare question formats between original and Lambda"""
    
    print("🔍 QUESTION FORMAT & FIELD COMPARISON")
    print("=" * 70)
    
    # Load data
    original_data = load_data('/tmp/original-postgres-export-20250903_221057.json')
    lambda_data = load_data('/tmp/lambda-final-output.json')
    
    # Analyze both
    original_analysis = analyze_question_structure(original_data, "Original PostgreSQL")
    lambda_analysis = analyze_question_structure(lambda_data, "Lambda Single Query")
    
    if not original_analysis or not lambda_analysis:
        print("❌ Could not analyze question structures")
        return
    
    print(f"📊 QUESTION COUNTS")
    print(f"  • Original: {original_analysis['total_questions']} questions")
    print(f"  • Lambda:   {lambda_analysis['total_questions']} questions")
    print(f"  • Match:    {'✅' if original_analysis['total_questions'] == lambda_analysis['total_questions'] else '❌'}")
    print()
    
    print(f"📝 FIELD NAMES COMPARISON")
    original_fields = set(original_analysis['field_names'])
    lambda_fields = set(lambda_analysis['field_names'])
    
    print(f"  • Original fields: {len(original_fields)}")
    print(f"  • Lambda fields:   {len(lambda_fields)}")
    print(f"  • Fields match:    {'✅' if original_fields == lambda_fields else '❌'}")
    print()
    
    if original_fields != lambda_fields:
        only_original = original_fields - lambda_fields
        only_lambda = lambda_fields - original_fields
        
        if only_original:
            print(f"  ⚠️  Only in original: {sorted(only_original)}")
        if only_lambda:
            print(f"  ⚠️  Only in lambda: {sorted(only_lambda)}")
        print()
    else:
        print(f"  ✅ All fields present in both:")
        for field in sorted(original_fields):
            print(f"     • {field}")
        print()
    
    print(f"❓ QUESTION TYPE DISTRIBUTION")
    print(f"  Original:")
    for q_type, count in original_analysis['question_types'].items():
        print(f"    • {q_type}: {count}")
    
    print(f"  Lambda:")
    for q_type, count in lambda_analysis['question_types'].items():
        print(f"    • {q_type}: {count}")
    
    print(f"  Types match: {'✅' if original_analysis['question_types'] == lambda_analysis['question_types'] else '❌'}")
    print()
    
    # Detailed field comparison for each question type
    print(f"🔬 DETAILED FIELD VALUE COMPARISON")
    for q_type in original_analysis['question_types'].keys():
        print(f"\n  📋 {q_type.upper()} Questions:")
        
        original_sample = original_analysis['sample_questions'][q_type]
        lambda_sample = lambda_analysis['sample_questions'][q_type]
        
        print(f"    Question ID: {original_sample.get('question_id')} vs {lambda_sample.get('question_id')} {'✅' if original_sample.get('question_id') == lambda_sample.get('question_id') else '❌'}")
        
        for field in sorted(original_fields):
            orig_val = original_sample.get(field)
            lambda_val = lambda_sample.get(field)
            match = orig_val == lambda_val
            
            print(f"    {field:20}: {'✅' if match else '❌'}")
            if not match:
                print(f"      Original: {orig_val}")
                print(f"      Lambda:   {lambda_val}")
    
    # Check if exact same questions exist
    print(f"\n🎯 QUESTION ID OVERLAP")
    original_ids = {q['question_id'] for q in original_analysis['all_questions']}
    lambda_ids = {q['question_id'] for q in lambda_analysis['all_questions']}
    
    overlap = original_ids.intersection(lambda_ids)
    only_original = original_ids - lambda_ids
    only_lambda = lambda_ids - original_ids
    
    print(f"  • Overlapping question IDs: {len(overlap)}")
    print(f"  • Only in original: {len(only_original)}")
    print(f"  • Only in lambda: {len(only_lambda)}")
    
    if len(overlap) == len(original_ids) == len(lambda_ids):
        print(f"  ✅ PERFECT MATCH: All questions are identical!")
    else:
        print(f"  ⚠️  Different question sets")
        if only_original:
            print(f"    Missing in lambda: {sorted(list(only_original))[:5]}...")
        if only_lambda:
            print(f"    Extra in lambda: {sorted(list(only_lambda))[:5]}...")
    
    print()
    print("=" * 70)
    print("🎉 Question Format Comparison Complete!")

if __name__ == "__main__":
    compare_questions()
