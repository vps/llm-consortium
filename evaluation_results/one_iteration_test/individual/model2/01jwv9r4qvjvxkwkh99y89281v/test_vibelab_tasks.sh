#!/bin/bash

# Ensure script exits on error
set -e

# --- Test Configuration ---
# Use a temporary, unique database for this test run
TEST_DB_DIR=$(mktemp -d)
export LLM_LOGS_DB="$TEST_DB_DIR/test_logs.db" # llm CLI will use this path if set
echo "Using temporary LLM logs database: $LLM_LOGS_DB"

# Path to the clerk scripts file (assuming it's in the same directory as this test script)
CLERK_SCRIPTS_PATH="./clerk_scripts.sh"

if [ ! -f "$CLERK_SCRIPTS_PATH" ]; then
    echo "ERROR: clerk_scripts.sh not found at $CLERK_SCRIPTS_PATH"
    exit 1
fi

# Source the clerk scripts to make functions available
# shellcheck source=./clerk_scripts.sh
source "$CLERK_SCRIPTS_PATH"

# Check if CIDs are available after sourcing
if [ -z "$vibelab_pending_cid" ] || [ -z "$vibelab_completed_cid" ]; then
    echo "ERROR: vibelab_pending_cid or vibelab_completed_cid not set after sourcing clerk_scripts.sh."
    echo "Ensure they are correctly defined globally in clerk_scripts.sh."
    exit 1
fi
echo "VibeLab Pending CID: $vibelab_pending_cid"
echo "VibeLab Completed CID: $vibelab_completed_cid"


# --- Test Execution ---
echo ""
echo "--- Initializing Test Database Schema (via llm logs) ---"
# Run a simple llm command to ensure the database and tables are created by llm itself
llm logs -n 0 > /dev/null
# Verify table exists
if ! sqlite3 "$LLM_LOGS_DB" ".table responses" | grep -q "responses"; then
    echo "ERROR: 'responses' table not found in $LLM_LOGS_DB after running 'llm logs'."
    sqlite3 "$LLM_LOGS_DB" ".schema" # Print schema for debugging
    exit 1
fi
echo "Test database schema initialized."


echo ""
echo "--- Testing VibeLab Task Management ---"

echo ""
echo "1. Listing initial pending tasks (should be empty)"
vibelab_list_pending

echo ""
echo "2. Listing initial completed tasks (should be empty)"
vibelab_list_completed

echo ""
echo "3. Adding task 1: 'Investigate data ingestion methods'"
vibelab_clerk "Investigate data ingestion methods"
# Small delay to ensure distinct timestamps if tests run very fast
sleep 0.1 

echo ""
echo "4. Adding task 2: 'Design UI mockups for dashboard'"
vibelab_clerk "Design UI mockups for dashboard"
sleep 0.1

echo ""
echo "5. Adding task 3: 'Setup CI/CD pipeline'"
vibelab_clerk "Setup CI/CD pipeline"

echo ""
echo "6. Listing pending tasks (should show 3 tasks)"
vibelab_list_pending

echo ""
echo "7. Marking the last task ('Setup CI/CD pipeline') as complete"
vibelab_mark_last_complete

echo ""
echo "8. Listing pending tasks (should show 2 tasks)"
vibelab_list_pending

echo ""
echo "9. Listing completed tasks (should show 1 task: 'Setup CI/CD pipeline')"
vibelab_list_completed

echo ""
echo "10. Marking a task by keyword ('data ingestion')"
vibelab_mark_complete_by_keyword "data ingestion"

echo ""
echo "11. Listing pending tasks (should show 1 task: 'Design UI mockups')"
vibelab_list_pending

echo ""
echo "12. Listing completed tasks (should show 2 tasks)"
vibelab_list_completed

echo ""
echo "13. Attempting to mark a non-existent keyword"
vibelab_mark_complete_by_keyword "nonexistent_keyword_xyz"

echo ""
echo "14. Marking the last remaining task complete"
vibelab_mark_last_complete

echo ""
echo "15. Listing pending tasks (should be empty)"
vibelab_list_pending

echo ""
echo "16. Listing completed tasks (should show all 3 tasks)"
vibelab_list_completed

echo ""
echo "17. Attempting to mark last complete when no pending tasks"
vibelab_mark_last_complete


# --- Cleanup ---
echo ""
echo "--- Cleaning up temporary database ---"
rm -rf "$TEST_DB_DIR"
echo "Temporary database directory $TEST_DB_DIR removed."

echo ""
echo "--- Test Script Completed Successfully ---"
