-- PostgreSQL Query: Questions with Passages and Lessons
-- This query retrieves all questions along with their associated passages and lessons
-- Organized hierarchically: Lessons -> Passages -> Questions

-- Query 1: Complete hierarchical view with all details
SELECT 
    -- Lesson information
    l.id as lesson_id,
    l.title as lesson_title,
    l.description as lesson_description,
    l.topic as lesson_topic,
    l.proficiency_level as lesson_proficiency,
    l.estimated_duration as lesson_duration_minutes,
    l.approval_status as lesson_approval_status,
    l.text as lesson_text,
    
    -- Passage information
    p.id as passage_id,
    p.title as passage_title,
    p.content as passage_content,
    p.sort_order as passage_sort_order,
    p.approval_status as passage_approval_status,
    p.word_count as passage_word_count,
    p.reading_level as passage_reading_level,
    p.source as passage_source,
    
    -- Question information
    q.id as question_id,
    q.question_text as question,
    q.question_type as question_type,
    q.options as question_options,
    q.correct_answer_index as correct_answer_index,
    q.correct_answer as correct_answer,
    q.acceptable_answers as acceptable_answers,
    q.word_limit as question_word_limit,
    q.placeholder as question_placeholder,
    q.sort_order as question_sort_order,
    q.points as question_points,
    q.approval_status as question_approval_status
    
FROM practise_improve_pilot.lessons l
LEFT JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
LEFT JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND (p.approval_status = 'approved' OR p.approval_status IS NULL)
    AND (q.approval_status = 'approved' OR q.approval_status IS NULL)
ORDER BY 
    l.topic,
    l.id,
    p.sort_order NULLS LAST,
    q.sort_order NULLS LAST;

-- Query 2: Questions only with lesson and passage context (simplified view)
SELECT 
    l.title as lesson_title,
    l.topic as lesson_topic,
    l.proficiency_level,
    p.title as passage_title,
    q.question_text as question,
    q.question_type,
    q.correct_answer,
    q.points,
    q.sort_order as question_order
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.approval_status = 'approved'
ORDER BY 
    l.topic,
    l.id,
    p.sort_order,
    q.sort_order;

-- Query 3: Question count by lesson and passage
SELECT 
    l.id as lesson_id,
    l.title as lesson_title,
    l.topic,
    l.proficiency_level,
    p.id as passage_id,
    p.title as passage_title,
    COUNT(q.id) as question_count,
    SUM(q.points) as total_points
FROM practise_improve_pilot.lessons l
LEFT JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
LEFT JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND (p.approval_status = 'approved' OR p.approval_status IS NULL)
    AND (q.approval_status = 'approved' OR q.approval_status IS NULL)
GROUP BY 
    l.id, l.title, l.topic, l.proficiency_level,
    p.id, p.title
ORDER BY 
    l.topic,
    l.id,
    p.sort_order NULLS LAST;

-- Query 4: Questions by proficiency level (beginner/intermediate/advanced mapping)
SELECT 
    CASE 
        WHEN l.proficiency_level LIKE 'A%' THEN 'beginner'
        WHEN l.proficiency_level LIKE 'B%' THEN 'intermediate'
        WHEN l.proficiency_level LIKE 'C%' THEN 'advanced'
        ELSE l.proficiency_level
    END as proficiency_category,
    l.id as lesson_id,
    l.title as lesson_title,
    l.topic,
    p.title as passage_title,
    q.question_text as question,
    q.question_type,
    q.points
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.approval_status = 'approved'
ORDER BY 
    proficiency_category,
    l.topic,
    l.id,
    p.sort_order,
    q.sort_order;

-- Query 5: Multiple Choice Questions (MCQ) with options
SELECT 
    l.title as lesson_title,
    l.topic,
    p.title as passage_title,
    q.question_text as question,
    q.options,
    q.correct_answer_index,
    q.points
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.approval_status = 'approved'
    AND q.question_type = 'mcq'
ORDER BY 
    l.topic,
    l.id,
    p.sort_order,
    q.sort_order;

-- Query 6: Short Answer Questions
SELECT 
    l.title as lesson_title,
    l.topic,
    p.title as passage_title,
    q.question_text as question,
    q.correct_answer,
    q.acceptable_answers,
    q.word_limit,
    q.points
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.approval_status = 'approved'
    AND q.question_type = 'short_answer'
ORDER BY 
    l.topic,
    l.id,
    p.sort_order,
    q.sort_order;

-- Query 7: Complete Sentence Questions
SELECT 
    l.title as lesson_title,
    l.topic,
    p.title as passage_title,
    q.question_text as question,
    q.correct_answer,
    q.acceptable_answers,
    q.word_limit,
    q.placeholder,
    q.points
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
INNER JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.approval_status = 'approved'
    AND q.question_type = 'complete_sentence'
ORDER BY 
    l.topic,
    l.id,
    p.sort_order,
    q.sort_order;

-- Query 8: Data validation - check for orphaned records
-- Lessons without passages
SELECT 
    l.id,
    l.title,
    'No passages found' as issue
FROM practise_improve_pilot.lessons l
LEFT JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
WHERE l.approval_status = 'approved'
    AND p.id IS NULL

UNION ALL

-- Passages without questions
SELECT 
    l.id,
    l.title || ' -> ' || p.title,
    'No questions found' as issue
FROM practise_improve_pilot.lessons l
INNER JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
LEFT JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND p.approval_status = 'approved'
    AND q.id IS NULL

UNION ALL

-- Questions without valid passage references
SELECT 
    q.id,
    'Question ID: ' || q.id,
    'Orphaned question - no valid passage' as issue
FROM practise_improve_pilot.questions q
LEFT JOIN practise_improve_pilot.passages p ON q.passage_id = p.id::text
WHERE q.approval_status = 'approved'
    AND p.id IS NULL;

-- Query 9: Statistics summary
SELECT 
    'Summary Statistics' as report_type,
    COUNT(DISTINCT l.id) as total_lessons,
    COUNT(DISTINCT p.id) as total_passages,
    COUNT(DISTINCT q.id) as total_questions,
    COUNT(DISTINCT l.topic) as distinct_topics,
    COUNT(DISTINCT l.proficiency_level) as proficiency_levels
FROM practise_improve_pilot.lessons l
LEFT JOIN practise_improve_pilot.passages p ON p.lesson_id = l.id
LEFT JOIN practise_improve_pilot.questions q ON q.passage_id = p.id::text
WHERE l.approval_status = 'approved'
    AND (p.approval_status = 'approved' OR p.approval_status IS NULL)
    AND (q.approval_status = 'approved' OR q.approval_status IS NULL);
