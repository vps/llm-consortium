#!/bin/bash

# Exit on error
set -e

echo "--- Test Environment Setup ---"
export LLM_LOGS_PATH="$(pwd)/test_db.sqlite"
echo "LLM_LOGS_PATH set to: $LLM_LOGS_PATH"
rm -f "$LLM_LOGS_PATH" 2>/dev/null
touch "$LLM_LOGS_PATH" # Ensure file exists for llm logs path command

# Create database schema (more robustly)
sqlite3 "$LLM_LOGS_PATH" <<SQL_INIT
DROP TABLE IF EXISTS responses;
CREATE TABLE responses (
    id TEXT PRIMARY KEY,
    model TEXT,
    prompt TEXT,
    system TEXT,
    response TEXT,
    conversation_id TEXT,
    datetime_utc TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    duration_ms INTEGER
);
SQL_INIT
echo "Test database schema created."

# Mock llm command (enhanced for testing)
llm() {
    echo "Mock llm called. Args: $@" >> test_output.log
    local command_type="$1"
    shift

    # Basic conversation logging
    if [[ "$command_type" == "--system" || "$command_type" == "-c" || "$command_type" == "--cid" ]]; then
        local prompt_text="Default prompt"
        local conv_id_val="unknown_conv"
        local system_prompt_val="Default system"

        while [[ $# -gt 0 ]]; do
            case "$1" in
                --system) system_prompt_val="$2"; shift 2 ;;
                -c|--cid) conv_id_val="$2"; shift 2 ;;
                *) prompt_text="$1"; shift ;;
            esac
        done
        
        local mock_response="Mock response to: $prompt_text"
        local new_id="mock_resp_$(date +%s)_$RANDOM"
        echo "LLM log: conv_id='$conv_id_val', prompt='$prompt_text', response='$mock_response'" >> test_output.log
        sqlite3 "$LLM_LOGS_PATH" "INSERT INTO responses (id, model, prompt, system, response, conversation_id, datetime_utc, input_tokens, output_tokens, duration_ms) VALUES ('$new_id', 'mock-model', '$prompt_text', '$system_prompt_val', '$mock_response', '$conv_id_val', datetime('now'), 10, 20, 100);"
        echo "$mock_response" # Output the response
        return 0
    fi
    
    # Mock embed-multi
    if [[ "$command_type" == "embed-multi" ]]; then
        echo "Mock llm embed-multi called. Args: $@" >> test_output.log
        # Simulate reading from stdin if input is piped
        if [ ! -t 0 ]; then
            local count=0
            while IFS= read -r line; do
                echo "Embedding: $line" >> test_output.log
                count=$((count+1))
            done
            echo "Embedded $count items." >> test_output.log
        else
             echo "Mock embed-multi expected input via pipe." >> test_output.log
        fi
        return 0
    fi

    # Mock similar
    if [[ "$command_type" == "similar" ]]; then
        echo "Mock llm similar called. Args: $@" >> test_output.log
        echo "Top 5 similar items for collection $2: item1, item2, item3, item4, item5" >> test_output.log
        return 0
    fi
    
    # Mock logs path
    if [[ "$command_type" == "logs" && "$2" == "path" ]]; then
        echo "$LLM_LOGS_PATH"
        return 0
    fi

    echo "Unknown mock llm command: $command_type $@" >> test_output.log
    return 1
}
export -f llm # Export the function so subshells (like in command substitution) can see it

# Source the functions
echo "Sourcing clerk_functions.sh..." >> test_output.log
source ./clerk_functions.sh >> test_output.log 2>&1

# Clean up previous local functions if any
rm -f ./local_clerk_functions.sh 2>/dev/null

# --- Test Execution ---
echo -e "\n--- Test 1: clerk_factory ---" >> test_output.log
clerk_factory my_test_clerk "General Queries" >> test_output.log 2>&1
if [ -f ./local_clerk_functions.sh ]; then
    echo "local_clerk_functions.sh created." >> test_output.log
    source ./local_clerk_functions.sh >> test_output.log 2>&1
    echo "my_test_clerk function definition:" >> test_output.log
    type my_test_clerk_clerk >> test_output.log 2>&1
else
    echo "ERROR: local_clerk_functions.sh not created." >> test_output.log
fi

echo -e "\n--- Test 2: Use generated clerk (my_test_clerk_clerk) ---" >> test_output.log
if type my_test_clerk_clerk > /dev/null 2>&1; then
    my_test_clerk_clerk "Hello from my_test_clerk" >> test_output.log 2>&1
else
    echo "ERROR: my_test_clerk_clerk function not found." >> test_output.log
fi

echo -e "\n--- Test 3: clerk_status ---" >> test_output.log
clerk_status "stub_cid" >> test_output.log 2>&1 # Will use the CID from generate_cid stub

echo -e "\n--- Test 4: vibelab_clerk (active) ---" >> test_output.log
vibelab_clerk active "Vibelab active prompt" >> test_output.log 2>&1

echo -e "\n--- Test 5: vibelab_clerk (complete) ---" >> test_output.log
# Need to add some data for the base_cid for migrate_conversation_records to find
sqlite3 "$LLM_LOGS_PATH" "INSERT INTO responses (id, conversation_id, prompt, response, datetime_utc) VALUES ('vibetest1', '01jwekxc9hc0vrqqex7dnfg9j0', 'task to complete', 'response for task', datetime('now'));"
vibelab_clerk complete "task to complete" >> test_output.log 2>&1

echo -e "\n--- Test 6: clerk_snapshot ---" >> test_output.log
# Use the CID from my_test_clerk which is stub_cid_*
clerk_snapshot "stub_cid" "snap1" >> test_output.log 2>&1

echo -e "\n--- Test 7: cluster_conversations ---" >> test_output.log
# Add data to a specific conversation ID for clustering
CONV_ID_FOR_CLUSTER="cluster_test_conv_$(date +%s)"
sqlite3 "$LLM_LOGS_PATH" "INSERT INTO responses (id, conversation_id, prompt, response, datetime_utc) VALUES ('clust1', '$CONV_ID_FOR_CLUSTER', 'prompt one for clustering', 'response one', datetime('now'));"
sqlite3 "$LLM_LOGS_PATH" "INSERT INTO responses (id, conversation_id, prompt, response, datetime_utc) VALUES ('clust2', '$CONV_ID_FOR_CLUSTER', 'prompt two for clustering', 'response two', datetime('now'));"
cluster_conversations "$CONV_ID_FOR_CLUSTER" >> test_output.log 2>&1
cluster_conversations "non_existent_cid_for_empty_test" >> test_output.log 2>&1


echo -e "\n--- Test 8: transfer_knowledge ---" >> test_output.log
# Create another clerk for transfer target
clerk_factory knowledge_receiver_clerk "Knowledge Receiving Domain" >> test_output.log 2>&1
source ./local_clerk_functions.sh >> test_output.log 2>&1 # Re-source to get the new clerk

echo "Attempting knowledge transfer from my_test_clerk (conv id: stub_cid_*) to knowledge_receiver_clerk" >> test_output.log
# The source clerk 'my_test_clerk' will have conversation ID like 'stub_cid_xxxx'.
# The actual llm calls use these CIDs. clerk_status queries for '%stub_cid%'.
# transfer_knowledge queries for '%my_test_clerk%', but conversation_id in db is 'stub_cid_xxx'
# We'll use 'stub_cid' as the source_clerk pattern to find data.
# The target_clerk is the NAME of the clerk, so 'knowledge_receiver_clerk'.
transfer_knowledge "stub_cid" "knowledge_receiver_clerk" "Hello" >> test_output.log 2>&1
transfer_knowledge "non_existent_source" "knowledge_receiver_clerk" "NoTopic" >> test_output.log 2>&1


echo -e "\n--- Test 9: clerk_analytics ---" >> test_output.log
clerk_analytics >> test_output.log 2>&1

echo -e "\n--- Final DB state ---" >> test_output.log
sqlite3 "$LLM_LOGS_PATH" ".headers on" ".dump responses" >> test_output.log 2>&1

echo "--- Tests Completed ---" >> test_output.log
echo "Test output logged to test_output.log"
