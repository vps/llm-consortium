#!/bin/bash

# Ensure script exits on error
set -e

# --- Test Configuration ---
TEST_DB_DIR=$(mktemp -d)
TEST_DB="$TEST_DB_DIR/test_logs.db"
echo "Using test database: $TEST_DB"

# Create the responses table with the same schema as llm
sqlite3 "$TEST_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS "responses" (
    "id" TEXT,
    "model" TEXT,
    "prompt" TEXT,
    "system" TEXT,
    "prompt_json" TEXT,
    "options_json" BLOB,
    "response" TEXT,
    "response_json" TEXT,
    "conversation_id" TEXT,
    "duration_ms" INTEGER,
    "datetime_utc" TEXT,
    "input_tokens" INTEGER,
    "output_tokens" INTEGER,
    "token_details" TEXT,
    "bookmark" INTEGER,
    "session_id" INTEGER,
    "schema_id" TEXT,
    "consortium_id" TEXT,
    "is_arbiter_response" INTEGER DEFAULT 0,
    "consortium_group_id" TEXT,
    PRIMARY KEY("id")
);
SQL

echo "Created test database schema."

# Test CIDs
TEST_PENDING_CID="test_pending_$(date +%s)"
TEST_COMPLETED_CID="test_completed_$(date +%s)"

# Mock vibelab_clerk function that adds to test database
mock_vibelab_clerk() {
    local prompt="$1"
    if [ -z "$prompt" ]; then
        echo "Usage: mock_vibelab_clerk \"<prompt>\""
        return 1
    fi
    
    local task_id="test_$(date +%s%N)" # Unique ID
    
    sqlite3 "$TEST_DB" "INSERT INTO responses (id, conversation_id, prompt, response, model, datetime_utc) VALUES ('$task_id', '$TEST_PENDING_CID', '$prompt', 'Mock response', 'test_model', datetime('now', 'localtime'));"
    
    if [ $? -eq 0 ]; then
        echo "VibeLab Clerk: Added task - '$prompt' (ID: $task_id) to $TEST_PENDING_CID"
    else
        echo "ERROR: Failed to add task"
        return 1
    fi
}

# Mock task management functions that use test database
mock_vibelab_mark_last_complete() {
    local response_id=$(sqlite3 -noheader "$TEST_DB" \
        "SELECT id FROM responses WHERE conversation_id = '$TEST_PENDING_CID' ORDER BY datetime_utc DESC LIMIT 1;")

    if [ -z "$response_id" ]; then
        echo "VibeLab: No pending tasks found to mark complete."
        return 1 # Return 1 for no tasks found, but not an error for the test
    fi

    sqlite3 "$TEST_DB" \
        "UPDATE responses SET conversation_id = '$TEST_COMPLETED_CID' WHERE id = '$response_id';"

    if [ $? -eq 0 ]; then
        echo "VibeLab: Moved last pending task (ID: $response_id) from $TEST_PENDING_CID to $TEST_COMPLETED_CID."
    else
        echo "VibeLab: Failed to move task (ID: $response_id)."
        return 1 # Critical error
    fi
}

mock_vibelab_mark_complete_by_keyword() {
    local keyword="$1"
    if [ -z "$keyword" ]; then
        echo "Usage: mock_vibelab_mark_complete_by_keyword \"<partial_prompt_text>\""
        return 1
    fi

    local safe_keyword=$(echo "$keyword" | sed "s/'/''/g")
    
    local response_id=$(sqlite3 -noheader "$TEST_DB" \
        "SELECT id FROM responses WHERE conversation_id = '$TEST_PENDING_CID' AND prompt IS NOT NULL AND prompt LIKE '%$safe_keyword%' ORDER BY datetime_utc DESC LIMIT 1;")

    if [ -z "$response_id" ]; then
        echo "VibeLab: No pending task found matching '$keyword'."
        return 1 # Return 1 for no tasks found, but not an error for the test
    fi

    sqlite3 "$TEST_DB" \
        "UPDATE responses SET conversation_id = '$TEST_COMPLETED_CID' WHERE id = '$response_id';"

    if [ $? -eq 0 ]; then
        echo "VibeLab: Moved task (ID: $response_id, matched by '$keyword') from $TEST_PENDING_CID to $TEST_COMPLETED_CID."
    else
        echo "VibeLab: Failed to move task (ID: $response_id, matched by '$keyword')."
        return 1 # Critical error
    fi
}

mock_vibelab_list_pending() {
    echo "--- VibeLab Pending Tasks (CID: $TEST_PENDING_CID) ---"
    sqlite3 -header "$TEST_DB" "SELECT id, datetime_utc, substr(prompt,1,60) AS prompt_preview FROM responses WHERE conversation_id = '$TEST_PENDING_CID' ORDER BY datetime_utc DESC;"
}

mock_vibelab_list_completed() {
    echo "--- VibeLab Completed Tasks (CID: $TEST_COMPLETED_CID) ---"
    sqlite3 -header "$TEST_DB" "SELECT id, datetime_utc, substr(prompt,1,60) AS prompt_preview FROM responses WHERE conversation_id = '$TEST_COMPLETED_CID' ORDER BY datetime_utc DESC;"
}

# --- Test Execution ---
echo ""
echo "=== Testing VibeLab Task Management (Mock Implementation) ==="

echo ""
echo "1. Listing initial pending tasks (should be empty)"
mock_vibelab_list_pending

echo ""
echo "2. Listing initial completed tasks (should be empty)"
mock_vibelab_list_completed

echo ""
echo "3. Adding task 1: 'Investigate data ingestion methods'"
mock_vibelab_clerk "Investigate data ingestion methods"
sleep 0.1 # Ensure datetime_utc is unique enough for reliable ORDER BY

echo ""
echo "4. Adding task 2: 'Design UI mockups for dashboard'"
mock_vibelab_clerk "Design UI mockups for dashboard"
sleep 0.1

echo ""
echo "5. Adding task 3: 'Setup CI/CD pipeline'"
mock_vibelab_clerk "Setup CI/CD pipeline"

echo ""
echo "6. Listing pending tasks (should show 3 tasks, newest first)"
mock_vibelab_list_pending

echo ""
echo "7. Marking the last task ('Setup CI/CD pipeline') as complete"
mock_vibelab_mark_last_complete

echo ""
echo "8. Listing pending tasks (should show 2 tasks)"
mock_vibelab_list_pending

echo ""
echo "9. Listing completed tasks (should show 1 task: 'Setup CI/CD pipeline')"
mock_vibelab_list_completed

echo ""
echo "10. Marking a task by keyword ('data ingestion')"
mock_vibelab_mark_complete_by_keyword "data ingestion"

echo ""
echo "11. Listing pending tasks (should show 1 task: 'Design UI mockups')"
mock_vibelab_list_pending

echo ""
echo "12. Listing completed tasks (should show 2 tasks)"
mock_vibelab_list_completed

echo ""
echo "13. Attempting to mark non-existent keyword (should gracefully report not found)"
mock_vibelab_mark_complete_by_keyword "nonexistent_keyword_xyz" || echo "(Gracefully handled: Task not found)"


echo ""
echo "14. Marking last remaining task complete"
mock_vibelab_mark_last_complete

echo ""
echo "15. Final pending tasks (should be empty)"
mock_vibelab_list_pending

echo ""
echo "16. Final completed tasks (should show all 3 tasks)"
mock_vibelab_list_completed

echo ""
echo "17. Attempting to mark complete when no pending tasks (should gracefully report not found)"
mock_vibelab_mark_last_complete || echo "(Gracefully handled: No pending tasks)"


# --- Cleanup ---
echo ""
echo "--- Cleaning up ---"
rm -rf "$TEST_DB_DIR"
echo "Test completed successfully!"

