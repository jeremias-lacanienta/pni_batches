# PNI Learning Platform - API Testing & Database Management Tools

This directory contains pure HTTPie testing scripts and database management tools for the PNI Learning Platform.

## 📁 Directory Structure

```
tools/
├── dynamodb-manager.sh          # Interactive DynamoDB management tool
├── httpie-tests.sh              # Interactive HTTPie API testing tool
└── README.md                    # This file

postman/                         # Renamed from "postman" but contains pure HTTPie
├── user-progress-api.httpie.txt       # User progress API commands
├── lesson-progress-manager.httpie.txt # Lesson progress manager commands
└── lesson-progress-manager-postman.json # Legacy Postman (can be deleted)
```

## 🛠️ Tools Overview

### 1. DynamoDB Manager (`dynamodb-manager.sh`)

Interactive shell script for managing DynamoDB tables and data.

**Features:**
- ✅ User progress management (list, delete, view all users)
- ✅ Lesson management (list lessons, get details)
- ✅ Passage management (list passages, get details) 
- ✅ Database operations (table stats, backups)
- ✅ HTTPie API testing integration
- ✅ Interactive menu system
- ✅ Configurable AWS region and default user

**Usage:**
```bash
./tools/dynamodb-manager.sh
```

**Prerequisites:**
- AWS CLI installed and configured
- jq installed for JSON processing
- Appropriate AWS permissions for DynamoDB

### 2. HTTPie API Tester (`httpie-tests.sh`)

Interactive shell script for testing all API endpoints with HTTPie.

**Features:**
- ✅ Full API test suite automation
- ✅ Individual endpoint testing
- ✅ Test data generation
- ✅ Error condition testing
- ✅ Interactive menu system
- ✅ Custom HTTPie command execution
- ✅ Configurable base URL and user ID

**Usage:**
```bash
./tools/httpie-tests.sh
```

**Individual function calls:**
```bash
# Test specific endpoints
./tools/httpie-tests.sh test_user_progress
./tools/httpie-tests.sh test_lesson_progress_manager
./tools/httpie-tests.sh run_full_test_suite
```

**Prerequisites:**
- HTTPie installed (`pip install httpie` or `brew install httpie`)
- PNI server running on localhost:3000

## 📄 HTTPie Command Files

### user-progress-api.httpie.txt

Pure HTTPie commands for testing user progress functionality:

- **User Progress Operations**: Get/save user progress
- **Lesson Progress Operations**: Manage lesson states and progress
- **Lesson Scoring**: Save detailed scores and responses
- **Passage-Focused Testing**: New passage-based API tests
- **Completion Tracking**: Check completion status
- **Batch Operations**: Create multiple test users
- **Error Testing**: Test invalid inputs
- **Performance Testing**: Concurrent request templates

### lesson-progress-manager.httpie.txt

Pure HTTPie commands for lesson lifecycle management:

- **Lesson Lifecycle**: Start → In Progress → Complete → Retry
- **Passage-Focused Lessons**: Support for new passage-based flow
- **Testing Scenarios**: Complete workflow testing
- **Bulk Operations**: Create multiple user scenarios
- **Error Handling**: Test invalid operations
- **Performance Testing**: Concurrent request templates

## 🚀 Quick Start

1. **Start the PNI server:**
   ```bash
   ./scripts/restart-servers.sh
   ```

2. **Test APIs interactively:**
   ```bash
   ./tools/httpie-tests.sh
   ```

3. **Manage DynamoDB data:**
   ```bash
   ./tools/dynamodb-manager.sh
   ```

4. **Run specific HTTPie commands:**
   ```bash
   # Copy commands from .httpie.txt files
   http GET http://localhost:3000/api/user-progress userId==default-user
   ```

## 🎯 Common Use Cases

### Testing New Features
```bash
# Run full test suite
./tools/httpie-tests.sh
# Select option 1: "Run full test suite"
```

### Debugging User Issues
```bash
# Check user progress in database
./tools/dynamodb-manager.sh
# Select option 1: "List user progress"
# Enter user ID to investigate
```

### Creating Test Data
```bash
# Load test data via HTTPie tool
./tools/httpie-tests.sh
# Select option 11: "Load test data"
```

### Cleaning Up Data
```bash
# Delete user progress
./tools/dynamodb-manager.sh
# Select option 2: "Delete user progress"
```

## 🔧 Configuration

### Environment Variables
```bash
# DynamoDB Manager
export AWS_REGION="eu-west-1"
export DEFAULT_USER_ID="default-user"

# HTTPie Tester  
export BASE_URL="http://localhost:3000"
export DEFAULT_USER_ID="default-user"
```

### Table Names
- `user-progress` - User progress data
- `pni-lessons` - Lesson content (legacy)
- `pni-passages` - Passage content (new)

## 📊 API Endpoints Covered

### User Progress
- `GET /api/user-progress` - Get user progress
- `POST /api/user-progress` - Save user progress

### Lesson Progress Manager
- `GET /api/lesson-progress-manager` - Get lesson progress
- `POST /api/lesson-progress-manager` - Update lesson progress
  - Actions: `start`, `setInProgress`, `complete`, `retry`, `update`

### Passages (New)
- `GET /api/passages` - Get passages by lesson/proficiency
- Support for passage-focused lesson flow

### Lessons
- `GET /api/lessons/{level}` - Get lessons by level
- `GET /api/lessons/{level}/{id}` - Get specific lesson

## 🔍 Troubleshooting

### Server Not Running
```bash
# Start the server
./scripts/restart-servers.sh

# Check if running
curl http://localhost:3000
```

### AWS CLI Issues
```bash
# Check AWS configuration
aws sts get-caller-identity

# Configure if needed
aws configure
```

### HTTPie Not Found
```bash
# Install HTTPie
pip install httpie
# or
brew install httpie
```

### DynamoDB Access Issues
```bash
# Check AWS permissions
aws dynamodb list-tables --region eu-west-1

# Verify region
aws configure get region
```

## 📈 Performance Testing

### Load Testing with HTTPie
```bash
# Multiple concurrent requests
for i in {1..10}; do
  http GET http://localhost:3000/api/user-progress userId==test-user-$i &
done
wait
```

### Database Performance
```bash
# Check table statistics
./tools/dynamodb-manager.sh
# Select option 9: "Table statistics"
```

## 🔒 Security Notes

- Default user ID is `default-user` for testing
- Scripts include error handling for invalid inputs
- AWS credentials are required for DynamoDB operations
- Server should be running locally for API tests

## 📝 Development Notes

### Adding New API Tests
1. Add HTTPie commands to appropriate `.httpie.txt` file
2. Update `httpie-tests.sh` with new test functions
3. Update menu options if needed

### Adding New DynamoDB Operations
1. Add function to `dynamodb-manager.sh`
2. Update menu system
3. Add error handling and validation

### Migration Notes
- Old Postman collections can be deleted after verifying HTTPie equivalents
- All scripts use pure HTTPie syntax (no Postman dependencies)
- Modular design allows individual function execution

---

**Last Updated**: August 29, 2025  
**Compatible With**: PNI Learning Platform v3.0+ (Passage-focused architecture)
