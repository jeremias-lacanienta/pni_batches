#!/bin/bash

# ===========================================
#!/bin/bash

# ===========================================
# HTTPie API Testing Scripts for PNI Learning Platform
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
DEFAULT_USER_ID="default-user"

# Helper functions
print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if server is running
check_server() {
    if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
        print_error "Server is not running at $BASE_URL"
        print_info "Please start the server first with: ./scripts/restart-servers.sh"
        exit 1
    fi
    print_success "Server is running at $BASE_URL"
}

# User Progress API Tests
test_user_progress() {
    print_header "Testing User Progress API"
    
    # Get user progress
    print_info "Getting user progress..."
    http GET "$BASE_URL/api/user-progress" userId=="$DEFAULT_USER_ID"
    
    echo ""
    print_info "Saving user progress..."
    http POST "$BASE_URL/api/user-progress" 
        userId="$DEFAULT_USER_ID" 
        progressData:='{
            "lesson_id": 1,
            "lesson_level": "beginner",
            "status": "completed",
            "score": 95,
            "completion_time": 1690000000,
            "last_accessed": "2025-08-29T12:00:00Z",
            "created_at": "2025-08-29T10:00:00Z",
            "totalTimeSpent": 1800,
            "attemptCount": 2,
            "responses": [
                {
                    "questionIndex": 0,
                    "question": "What is a noun?",
                    "userAnswer": "Person, place, or thing",
                    "correctAnswer": "Person, place, or thing",
                    "isCorrect": true,
                    "explanation": "A noun names a person, place, or thing."
                }
            ]
        }'
}

# Lesson Progress Manager API Tests
test_lesson_progress_manager() {
    print_header "Testing Lesson Progress Manager API"
    
    # Start a lesson
    print_info "Starting a lesson..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="start" 
        userId="$DEFAULT_USER_ID" 
        lessonId:=6 
        level="beginner"
    
    echo ""
    print_info "Setting lesson to in progress..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="setInProgress" 
        userId="$DEFAULT_USER_ID" 
        lessonId:=6 
        level="beginner" 
        answeredQuestions:=2 
        responses:='[
            {"questionIndex": 0, "question": "What is the main idea?", "userAnswer": "Water cycle", "correctAnswer": "Water cycle", "isCorrect": true},
            {"questionIndex": 1, "question": "What is precipitation?", "userAnswer": "Rain", "correctAnswer": "Rain", "isCorrect": true}
        ]' 
        lessonState:='{
            "currentQuestionIndex": 2,
            "waitingForAnswer": true,
            "lessonComplete": false,
            "partialAnswers": {"0": "Water cycle", "1": "Rain"},
            "sessionState": "active",
            "timestamp": "2025-08-29T14:00:00Z"
        }'
    
    echo ""
    print_info "Completing the lesson..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="complete" 
        userId="$DEFAULT_USER_ID" 
        lessonId:=6 
        level="beginner" 
        totalQuestions:=5 
        answeredQuestions:=5 
        score:=90 
        responses:='[
            {"questionIndex": 0, "question": "What is the main idea?", "userAnswer": "Water cycle", "correctAnswer": "Water cycle", "isCorrect": true},
            {"questionIndex": 1, "question": "What is precipitation?", "userAnswer": "Rain", "correctAnswer": "Rain", "isCorrect": true},
            {"questionIndex": 2, "question": "What causes evaporation?", "userAnswer": "Sun", "correctAnswer": "Sun", "isCorrect": true},
            {"questionIndex": 3, "question": "Where does water collect?", "userAnswer": "Rivers", "correctAnswer": "Bodies of water", "isCorrect": false},
            {"questionIndex": 4, "question": "Why is water cycle important?", "userAnswer": "Life", "correctAnswer": "Life", "isCorrect": true}
        ]' 
        lessonState:='{
            "currentQuestionIndex": 4,
            "waitingForAnswer": false,
            "lessonComplete": true,
            "partialAnswers": {},
            "sessionState": "completed",
            "timestamp": "2025-08-29T14:30:00Z"
        }'
    
    echo ""
    print_info "Getting lesson progress summary..."
    http GET "$BASE_URL/api/lesson-progress-manager" 
        userId=="$DEFAULT_USER_ID" 
        lessonId==6 
        level==beginner
}

# Passages API Tests (New)
test_passages_api() {
    print_header "Testing Passages API"
    
    # Get passages by lesson ID
    print_info "Getting passages for lesson 1..."
    http GET "$BASE_URL/api/passages" lessonId==1
    
    echo ""
    print_info "Getting specific passage..."
    http GET "$BASE_URL/api/passages" lessonId==1 passageId==passage-1
    
    echo ""
    print_info "Getting passages by proficiency..."
    http GET "$BASE_URL/api/passages" proficiency==beginner
}

# Lesson API Tests
test_lessons_api() {
    print_header "Testing Lessons API"
    
    # Get lessons by level
    print_info "Getting beginner lessons..."
    http GET "$BASE_URL/api/lessons/beginner"
    
    echo ""
    print_info "Getting specific lesson..."
    http GET "$BASE_URL/api/lessons/beginner/1"
}

# Comprehensive Test Suite
run_full_test_suite() {
    print_header "Running Full API Test Suite"
    
    # Check server first
    check_server
    
    # Run all tests
    test_user_progress
    echo ""
    test_lesson_progress_manager
    echo ""
    test_passages_api
    echo ""
    test_lessons_api
    
    print_success "All tests completed!"
}

# Individual test functions for manual use
test_start_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Starting lesson $lesson_id for user $user_id..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="start" 
        userId="$user_id" 
        lessonId:=$lesson_id 
        level="$level"
}

test_complete_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    local score=${4:-85}
    
    print_info "Completing lesson $lesson_id for user $user_id with score $score..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="complete" 
        userId="$user_id" 
        lessonId:=$lesson_id 
        level="$level" 
        totalQuestions:=10 
        answeredQuestions:=10 
        score:=$score 
        responses:='[
            {"questionIndex": 0, "question": "Sample Q1", "userAnswer": "Sample A1", "correctAnswer": "Sample A1", "isCorrect": true},
            {"questionIndex": 1, "question": "Sample Q2", "userAnswer": "Sample A2", "correctAnswer": "Sample A2", "isCorrect": true}
        ]'
}

test_retry_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Retrying lesson $lesson_id for user $user_id..."
    http POST "$BASE_URL/api/lesson-progress-manager" 
        action="retry" 
        userId="$user_id" 
        lessonId:=$lesson_id 
        level="$level"
}

test_get_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Getting progress for lesson $lesson_id, user $user_id..."
    http GET "$BASE_URL/api/lesson-progress-manager" 
        userId=="$user_id" 
        lessonId==$lesson_id 
        level==$level
}

# User Progress Deletion Functions
clear_all_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_info "🧹 Clearing ALL progress for user: $user_id"
    http POST "$BASE_URL/api/user-progress" \
        "Content-Type:application/json" \
        userId="$user_id" \
        progressData:='{
            "profile": {"name": "Student", "avatar": ""},
            "completedLessons": [],
            "progress": []
        }'
    
    print_success "✅ All progress cleared for user: $user_id"
}

clear_specific_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "🧹 Clearing lesson $lesson_id ($level) for user: $user_id"
    http DELETE "$BASE_URL/api/clear-lesson?userId=$user_id&lessonId=$lesson_id&level=$level"
    
    print_success "✅ Lesson $lesson_id ($level) cleared for user: $user_id"
}

clear_all_lessons_by_level() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local level=${2:-"beginner"}
    local max_lessons=${3:-5}
    
    print_info "🧹 Clearing all $level lessons (1-$max_lessons) for user: $user_id"
    
    for ((i=1; i<=max_lessons; i++)); do
        print_info "Clearing lesson $i..."
        http DELETE "$BASE_URL/api/clear-lesson?userId=$user_id&lessonId=$i&level=$level" > /dev/null 2>&1
    done
    
    print_success "✅ All $level lessons cleared for user: $user_id"
}

clear_all_lessons_all_levels() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local max_lessons=${2:-5}
    
    print_info "🧹 Clearing ALL lessons (all levels, 1-$max_lessons) for user: $user_id"
    
    local levels=("beginner" "intermediate" "advanced")
    
    for level in "${levels[@]}"; do
        print_info "Clearing all $level lessons..."
        for ((i=1; i<=max_lessons; i++)); do
            http DELETE "$BASE_URL/api/clear-lesson?userId=$user_id&lessonId=$i&level=$level" > /dev/null 2>&1
        done
        print_success "✓ All $level lessons cleared"
    done
    
    print_success "✅ All lessons cleared for user: $user_id"
}

verify_user_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_info "📊 Checking current progress for user: $user_id"
    http GET "$BASE_URL/api/user-progress?userId=$user_id"
}

reset_and_verify() {
    local user_id=${1:-$DEFAULT_USER_ID}
    
    print_header "Complete Reset and Verification for $user_id"
    
    # Clear all progress
    clear_all_user_progress "$user_id"
    
    echo ""
    print_info "Verifying deletion..."
    verify_user_progress "$user_id"
}

# Menu system
show_menu() {
    clear
    print_header "HTTPie API Testing Tool for PNI Learning Platform"
    echo -e "${YELLOW}Base URL: $BASE_URL${NC}"
    echo -e "${YELLOW}Default User: $DEFAULT_USER_ID${NC}"
    echo ""
    echo -e "${CYAN}QUICK TESTS:${NC}"
    echo "1)  Run full test suite"
    echo "2)  Test user progress API"
    echo "3)  Test lesson progress manager"
    echo "4)  Test passages API"
    echo "5)  Test lessons API"
    echo ""
    echo -e "${CYAN}LESSON OPERATIONS:${NC}"
    echo "6)  Start a lesson"
    echo "7)  Complete a lesson"
    echo "8)  Retry a lesson"
    echo "9)  Get lesson progress"
    echo ""
    echo -e "${RED}USER PROGRESS DELETION:${NC}"
    echo "10) Clear ALL user progress (complete reset)"
    echo "11) Clear specific lesson"
    echo "12) Clear all lessons by level"
    echo "13) Clear all lessons (all levels)"
    echo "14) Verify user progress"
    echo "15) Reset and verify"
    echo ""
    echo -e "${CYAN}CUSTOM TESTS:${NC}"
    echo "16) Custom HTTPie command"
    echo "17) Load test data"
    echo ""
    echo -e "${CYAN}SETTINGS:${NC}"
    echo "18) Change base URL"
    echo "19) Change default user ID"
    echo ""
    echo "0)  Exit"
    echo ""
    echo -n "Select an option [0-19]: "
}

# Load realistic test data
load_test_data() {
    print_header "Loading Test Data"
    
    local users=("student-1" "student-2" "student-3" "test-user")
    local lessons=(1 2 3)
    local levels=("beginner" "intermediate" "advanced")
    
    for user in "${users[@]}"; do
        for lesson in "${lessons[@]}"; do
            for level in "${levels[@]}"; do
                print_info "Creating progress for $user - Lesson $lesson ($level)"
                
                # Start lesson
                http POST "$BASE_URL/api/lesson-progress-manager" 
                    action="start" 
                    userId="$user" 
                    lessonId:=$lesson 
                    level="$level" > /dev/null 2>&1
                
                # Complete with random score
                local score=$((60 + RANDOM % 40))
                http POST "$BASE_URL/api/lesson-progress-manager" 
                    action="complete" 
                    userId="$user" 
                    lessonId:=$lesson 
                    level="$level" 
                    totalQuestions:=10 
                    answeredQuestions:=10 
                    score:=$score 
                    responses:='[{"questionIndex": 0, "question": "Test", "userAnswer": "Test", "correctAnswer": "Test", "isCorrect": true}]' > /dev/null 2>&1
                
                print_success "✓ $user - Lesson $lesson ($level) - Score: $score"
            done
        done
    done
    
    print_success "Test data loaded successfully!"
}

# Read user input
read_input() {
    local choice
    read choice
    case $choice in
        1) run_full_test_suite ;;
        2) test_user_progress ;;
        3) test_lesson_progress_manager ;;
        4) test_passages_api ;;
        5) test_lessons_api ;;
        6)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_start_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        7)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            echo -n "Score (default: 85): "
            read score
            test_complete_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}" "${score:-85}"
            ;;
        8)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_retry_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        9)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_get_progress "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        10)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -e "${RED}⚠️  This will delete ALL progress for user: ${user_id:-$DEFAULT_USER_ID}${NC}"
            echo -n "Are you sure? (y/N): "
            read confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                clear_all_user_progress "${user_id:-$DEFAULT_USER_ID}"
            else
                print_info "Operation cancelled"
            fi
            ;;
        11)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            clear_specific_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        12)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Level (beginner/intermediate/advanced, default: beginner): "
            read level
            echo -n "Max lessons to clear (default: 5): "
            read max_lessons
            clear_all_lessons_by_level "${user_id:-$DEFAULT_USER_ID}" "${level:-beginner}" "${max_lessons:-5}"
            ;;
        13)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Max lessons per level to clear (default: 5): "
            read max_lessons
            echo -e "${RED}⚠️  This will clear ALL lessons for user: ${user_id:-$DEFAULT_USER_ID}${NC}"
            echo -n "Are you sure? (y/N): "
            read confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                clear_all_lessons_all_levels "${user_id:-$DEFAULT_USER_ID}" "${max_lessons:-5}"
            else
                print_info "Operation cancelled"
            fi
            ;;
        14)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            verify_user_progress "${user_id:-$DEFAULT_USER_ID}"
            ;;
        15)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -e "${RED}⚠️  This will RESET ALL progress for user: ${user_id:-$DEFAULT_USER_ID}${NC}"
            echo -n "Are you sure? (y/N): "
            read confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                reset_and_verify "${user_id:-$DEFAULT_USER_ID}"
            else
                print_info "Operation cancelled"
            fi
            ;;
        16)
            echo ""
            echo "Enter custom HTTPie command (without 'http'):"
            echo "Example: GET $BASE_URL/api/user-progress userId==test-user"
            echo -n "> http "
            read custom_command
            if [ -n "$custom_command" ]; then
                eval "http $custom_command"
            fi
            ;;
        17) load_test_data ;;
        18)
            echo ""
            echo -n "Enter new base URL: "
            read new_url
            if [ -n "$new_url" ]; then
                BASE_URL="$new_url"
                print_success "Base URL changed to: $BASE_URL"
            fi
            ;;
        19)
            echo ""
            echo -n "Enter new default user ID: "
            read new_user_id
            if [ -n "$new_user_id" ]; then
                DEFAULT_USER_ID="$new_user_id"
                print_success "Default user ID changed to: $DEFAULT_USER_ID"
            fi
            ;;
        0)
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check if HTTPie is installed
    if ! command -v http &> /dev/null; then
        print_error "HTTPie is not installed. Please install it first:"
        print_info "  pip install httpie"
        print_info "  or"
        print_info "  brew install httpie"
        exit 1
    fi
    
    # Main loop
    while true; do
        show_menu
        read_input
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Allow individual function calls
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        main
    else
        # Call specific function if provided as argument
        "$@"
    fi
fi
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
DEFAULT_USER_ID="default-user"

# Helper functions
print_header() {
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Check if server is running
check_server() {
    if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
        print_error "Server is not running at $BASE_URL"
        print_info "Please start the server first with: ./scripts/restart-servers.sh"
        exit 1
    fi
    print_success "Server is running at $BASE_URL"
}

# User Progress API Tests
test_user_progress() {
    print_header "Testing User Progress API"
    
    # Get user progress
    print_info "Getting user progress..."
    http GET "$BASE_URL/api/user-progress" userId=="$DEFAULT_USER_ID"
    
    echo ""
    print_info "Saving user progress..."
    http POST "$BASE_URL/api/user-progress" \
        userId="$DEFAULT_USER_ID" \
        progressData:='{
            "lesson_id": 1,
            "lesson_level": "beginner",
            "status": "completed",
            "score": 95,
            "completion_time": 1690000000,
            "last_accessed": "2025-08-29T12:00:00Z",
            "created_at": "2025-08-29T10:00:00Z",
            "totalTimeSpent": 1800,
            "attemptCount": 2,
            "responses": [
                {
                    "questionIndex": 0,
                    "question": "What is a noun?",
                    "userAnswer": "Person, place, or thing",
                    "correctAnswer": "Person, place, or thing",
                    "isCorrect": true,
                    "explanation": "A noun names a person, place, or thing."
                }
            ]
        }'
}

# Lesson Progress Manager API Tests
test_lesson_progress_manager() {
    print_header "Testing Lesson Progress Manager API"
    
    # Start a lesson
    print_info "Starting a lesson..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="start" \
        userId="$DEFAULT_USER_ID" \
        lessonId:=6 \
        level="beginner"
    
    echo ""
    print_info "Setting lesson to in progress..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="setInProgress" \
        userId="$DEFAULT_USER_ID" \
        lessonId:=6 \
        level="beginner" \
        answeredQuestions:=2 \
        responses:='[
            {"questionIndex": 0, "question": "What is the main idea?", "userAnswer": "Water cycle", "correctAnswer": "Water cycle", "isCorrect": true},
            {"questionIndex": 1, "question": "What is precipitation?", "userAnswer": "Rain", "correctAnswer": "Rain", "isCorrect": true}
        ]' \
        lessonState:='{
            "currentQuestionIndex": 2,
            "waitingForAnswer": true,
            "lessonComplete": false,
            "partialAnswers": {"0": "Water cycle", "1": "Rain"},
            "sessionState": "active",
            "timestamp": "2025-08-29T14:00:00Z"
        }'
    
    echo ""
    print_info "Completing the lesson..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="complete" \
        userId="$DEFAULT_USER_ID" \
        lessonId:=6 \
        level="beginner" \
        totalQuestions:=5 \
        answeredQuestions:=5 \
        score:=90 \
        responses:='[
            {"questionIndex": 0, "question": "What is the main idea?", "userAnswer": "Water cycle", "correctAnswer": "Water cycle", "isCorrect": true},
            {"questionIndex": 1, "question": "What is precipitation?", "userAnswer": "Rain", "correctAnswer": "Rain", "isCorrect": true},
            {"questionIndex": 2, "question": "What causes evaporation?", "userAnswer": "Sun", "correctAnswer": "Sun", "isCorrect": true},
            {"questionIndex": 3, "question": "Where does water collect?", "userAnswer": "Rivers", "correctAnswer": "Bodies of water", "isCorrect": false},
            {"questionIndex": 4, "question": "Why is water cycle important?", "userAnswer": "Life", "correctAnswer": "Life", "isCorrect": true}
        ]' \
        lessonState:='{
            "currentQuestionIndex": 4,
            "waitingForAnswer": false,
            "lessonComplete": true,
            "partialAnswers": {},
            "sessionState": "completed",
            "timestamp": "2025-08-29T14:30:00Z"
        }'
    
    echo ""
    print_info "Getting lesson progress summary..."
    http GET "$BASE_URL/api/lesson-progress-manager" \
        userId=="$DEFAULT_USER_ID" \
        lessonId==6 \
        level==beginner
}

# Passages API Tests (New)
test_passages_api() {
    print_header "Testing Passages API"
    
    # Get passages by lesson ID
    print_info "Getting passages for lesson 1..."
    http GET "$BASE_URL/api/passages" lessonId==1
    
    echo ""
    print_info "Getting specific passage..."
    http GET "$BASE_URL/api/passages" lessonId==1 passageId==passage-1
    
    echo ""
    print_info "Getting passages by proficiency..."
    http GET "$BASE_URL/api/passages" proficiency==beginner
}

# Lesson API Tests
test_lessons_api() {
    print_header "Testing Lessons API"
    
    # Get lessons by level
    print_info "Getting beginner lessons..."
    http GET "$BASE_URL/api/lessons/beginner"
    
    echo ""
    print_info "Getting specific lesson..."
    http GET "$BASE_URL/api/lessons/beginner/1"
}

# Comprehensive Test Suite
run_full_test_suite() {
    print_header "Running Full API Test Suite"
    
    # Check server first
    check_server
    
    # Run all tests
    test_user_progress
    echo ""
    test_lesson_progress_manager
    echo ""
    test_passages_api
    echo ""
    test_lessons_api
    
    print_success "All tests completed!"
}

# Individual test functions for manual use
test_start_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Starting lesson $lesson_id for user $user_id..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="start" \
        userId="$user_id" \
        lessonId:=$lesson_id \
        level="$level"
}

test_complete_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    local score=${4:-85}
    
    print_info "Completing lesson $lesson_id for user $user_id with score $score..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="complete" \
        userId="$user_id" \
        lessonId:=$lesson_id \
        level="$level" \
        totalQuestions:=10 \
        answeredQuestions:=10 \
        score:=$score \
        responses:='[
            {"questionIndex": 0, "question": "Sample Q1", "userAnswer": "Sample A1", "correctAnswer": "Sample A1", "isCorrect": true},
            {"questionIndex": 1, "question": "Sample Q2", "userAnswer": "Sample A2", "correctAnswer": "Sample A2", "isCorrect": true}
        ]'
}

test_retry_lesson() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Retrying lesson $lesson_id for user $user_id..."
    http POST "$BASE_URL/api/lesson-progress-manager" \
        action="retry" \
        userId="$user_id" \
        lessonId:=$lesson_id \
        level="$level"
}

test_get_progress() {
    local user_id=${1:-$DEFAULT_USER_ID}
    local lesson_id=${2:-1}
    local level=${3:-"beginner"}
    
    print_info "Getting progress for lesson $lesson_id, user $user_id..."
    http GET "$BASE_URL/api/lesson-progress-manager" \
        userId=="$user_id" \
        lessonId==$lesson_id \
        level==$level
}

# Menu system
show_menu() {
    clear
    print_header "HTTPie API Testing Tool for PNI Learning Platform"
    echo -e "${YELLOW}Base URL: $BASE_URL${NC}"
    echo -e "${YELLOW}Default User: $DEFAULT_USER_ID${NC}"
    echo ""
    echo -e "${CYAN}QUICK TESTS:${NC}"
    echo "1)  Run full test suite"
    echo "2)  Test user progress API"
    echo "3)  Test lesson progress manager"
    echo "4)  Test passages API"
    echo "5)  Test lessons API"
    echo ""
    echo -e "${CYAN}LESSON OPERATIONS:${NC}"
    echo "6)  Start a lesson"
    echo "7)  Complete a lesson"
    echo "8)  Retry a lesson"
    echo "9)  Get lesson progress"
    echo ""
    echo -e "${CYAN}CUSTOM TESTS:${NC}"
    echo "10) Custom HTTPie command"
    echo "11) Load test data"
    echo ""
    echo -e "${CYAN}SETTINGS:${NC}"
    echo "12) Change base URL"
    echo "13) Change default user ID"
    echo ""
    echo "0)  Exit"
    echo ""
    echo -n "Select an option [0-13]: "
}

# Load realistic test data
load_test_data() {
    print_header "Loading Test Data"
    
    local users=("student-1" "student-2" "student-3" "test-user")
    local lessons=(1 2 3)
    local levels=("beginner" "intermediate" "advanced")
    
    for user in "${users[@]}"; do
        for lesson in "${lessons[@]}"; do
            for level in "${levels[@]}"; do
                print_info "Creating progress for $user - Lesson $lesson ($level)"
                
                # Start lesson
                http POST "$BASE_URL/api/lesson-progress-manager" \
                    action="start" \
                    userId="$user" \
                    lessonId:=$lesson \
                    level="$level" > /dev/null 2>&1
                
                # Complete with random score
                local score=$((60 + RANDOM % 40))
                http POST "$BASE_URL/api/lesson-progress-manager" \
                    action="complete" \
                    userId="$user" \
                    lessonId:=$lesson \
                    level="$level" \
                    totalQuestions:=10 \
                    answeredQuestions:=10 \
                    score:=$score \
                    responses:='[{"questionIndex": 0, "question": "Test", "userAnswer": "Test", "correctAnswer": "Test", "isCorrect": true}]' > /dev/null 2>&1
                
                print_success "✓ $user - Lesson $lesson ($level) - Score: $score"
            done
        done
    done
    
    print_success "Test data loaded successfully!"
}

# Read user input
read_input() {
    local choice
    read choice
    case $choice in
        1) run_full_test_suite ;;
        2) test_user_progress ;;
        3) test_lesson_progress_manager ;;
        4) test_passages_api ;;
        5) test_lessons_api ;;
        6)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_start_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        7)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            echo -n "Score (default: 85): "
            read score
            test_complete_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}" "${score:-85}"
            ;;
        8)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_retry_lesson "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        9)
            echo ""
            echo -n "User ID (default: $DEFAULT_USER_ID): "
            read user_id
            echo -n "Lesson ID (default: 1): "
            read lesson_id
            echo -n "Level (default: beginner): "
            read level
            test_get_progress "${user_id:-$DEFAULT_USER_ID}" "${lesson_id:-1}" "${level:-beginner}"
            ;;
        10)
            echo ""
            echo "Enter custom HTTPie command (without 'http'):"
            echo "Example: GET $BASE_URL/api/user-progress userId==test-user"
            echo -n "> http "
            read custom_command
            if [ -n "$custom_command" ]; then
                eval "http $custom_command"
            fi
            ;;
        11) load_test_data ;;
        12)
            echo ""
            echo -n "Enter new base URL: "
            read new_url
            if [ -n "$new_url" ]; then
                BASE_URL="$new_url"
                print_success "Base URL changed to: $BASE_URL"
            fi
            ;;
        13)
            echo ""
            echo -n "Enter new default user ID: "
            read new_user_id
            if [ -n "$new_user_id" ]; then
                DEFAULT_USER_ID="$new_user_id"
                print_success "Default user ID changed to: $DEFAULT_USER_ID"
            fi
            ;;
        0)
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check if HTTPie is installed
    if ! command -v http &> /dev/null; then
        print_error "HTTPie is not installed. Please install it first:"
        print_info "  pip install httpie"
        print_info "  or"
        print_info "  brew install httpie"
        exit 1
    fi
    
    # Main loop
    while true; do
        show_menu
        read_input
        echo ""
        echo -n "Press Enter to continue..."
        read
    done
}

# Allow individual function calls
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        main
    else
        # Call specific function if provided as argument
        "$@"
    fi
fi
