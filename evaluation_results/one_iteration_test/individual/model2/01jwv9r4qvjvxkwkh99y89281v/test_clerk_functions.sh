#!/bin/bash

# Set up environment
export LLM_LOGS_DB="./test_logs.db"
rm -f "$LLM_LOGS_DB" 2>/dev/null  # Start fresh

# Source the clerk script
source clerk_scripts.sh

# Initialize test database
init_test_db

# Test 1: Add tasks
echo "=== TEST 1: Adding tasks ==="
vibelab_clerk "First task: Analyze sensor data"
vibelab_clerk "Second task: Review documentation"
vibelab_clerk "Third task: Optimize database queries"

# Test 2: List pending tasks
echo "=== TEST 2: Listing pending tasks ==="
vibelab_list_pending

# Test 3: Mark last task complete
echo "=== TEST 3: Marking last task complete ==="
vibelab_mark_last_complete

# Test 4: Mark task by keyword
echo "=== TEST 4: Marking task by keyword ==="
vibelab_mark_complete_by_keyword "sensor"

# Test 5: List pending and completed tasks
echo "=== TEST 5: Final task lists ==="
echo "Pending tasks:"
vibelab_list_pending
echo "Completed tasks:"
vibelab_list_completed

# Database inspection for verification
echo "=== DATABASE VERIFICATION ==="
sqlite3 "$LLM_LOGS_DB" "SELECT id, conversation_id, prompt FROM responses;"
