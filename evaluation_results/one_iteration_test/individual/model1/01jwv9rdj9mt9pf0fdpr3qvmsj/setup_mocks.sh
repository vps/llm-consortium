#!/bin/bash

# Mock llm CLI
llm() {
    if [[ "$1" == "logs" && "$2" == "path" ]]; then
        echo "/tmp/mock_llm_logs.db"
    elif [[ "$1" == "--system" && "$2" == *"Generate a bash function for a specialized clerk assistant"* ]]; then
        # Mock for clerk_factory in script_3.sh
        # Extract domain from system prompt to name the generated function correctly
        local system_prompt_str="$2"
        local domain_val=$(echo "$system_prompt_str" | grep -o 'Domain: [^,]*' | sed -n 's/Domain: \([^,]*\).*/\1/p')
        if [ -z "$domain_val" ]; then domain_val="unknown_domain"; fi
        echo "${domain_val}_clerk() { local S_IN; if [ ! -t 0 ]; then S_IN=\$(cat -); fi; echo \"Mocked ${domain_val}_clerk with STDIN: '\$S_IN' ARGS: '\$@'\"; }"
    elif [[ "$*" == *"Analyze input context"* ]]; then # For smart_clerk in script_3.sh
        echo "mock_suggested_clerk"
    elif [[ "$*" == *"Extract 3 key insights"* ]]; then # For clerk_insights in script_4.sh
        echo "Mocked Insight 1\nMocked Insight 2\nMocked Insight 3"
    else
        # Generic LLM mock, attempt to read stdin if present
        local S_IN=""
        if [ ! -t 0 ]; then S_IN=$(cat -); fi
        echo "Mocked LLM Call with STDIN: '$S_IN' ARGS: '$@'"
    fi
}
export -f llm

# Mock sqlite3
sqlite3() {
    local db_path="$1"
    local query="$2"
    # echo "Mocked sqlite3 call: sqlite3 $db_path \"$query\"" # Keep this commented unless debugging
    if [[ "$query" == *"SELECT prompt || ' -> ' || response FROM responses WHERE conversation_id='test_source_cid'"* ]]; then
        echo "prompt1 -> response1"
        echo "prompt2 -> response2"
    elif [[ "$query" == *"SELECT prompt || ' -> ' || substr(response, 1, 100) || '...'"* ]]; then
        echo "insight_prompt1 -> insight_response1..."
        echo "insight_prompt2 -> insight_response2..."
    elif [[ "$query" == *"SELECT response FROM responses WHERE conversation_id='test_source_cid' AND bookmark=1"* ]]; then
        echo "Bookmarked knowledge 1"
        echo "Bookmarked knowledge 2"
    elif [[ "$query" == *"SELECT 'Last discussed: ' || substr(prompt, 1, 50) || '... -> ' || substr(response, 1, 50) || '...'"* ]]; then
        echo "Last discussed: some_prompt... -> some_response..."
    elif [[ "$query" == *"UPDATE responses SET bookmark = 1"* ]]; then
        echo "Mocked UPDATE responses SET bookmark = 1 for query: $query" # Output this for verification
    elif [[ "$query" == *"COUNT(*)"* ]]; then # For clerk_analytics
        echo "total_exchanges|avg_input_tokens|avg_output_tokens|avg_duration_ms|first_interaction|last_interaction"
        echo "10|100|200|500|2023-01-01 00:00:00|2023-01-01 01:00:00"
    fi
}
export -f sqlite3

# Mock uuidgen
uuidgen() {
    echo "mocked-uuid-1234567890abcdef123456"
}
export -f uuidgen

# Mock llm-compressor
llm-compressor() {
    # Reads from stdin and prepends "Compressed Input: "
    echo "Compressed Input: $(cat -)"
}
export -f llm-compressor

# Define generate_cid (needed by script_1.sh - fork_conversation)
generate_cid() {
    echo "generated-cid-$(date +%s%N)"
}
export -f generate_cid

# Helper for mock functions to handle stdin
_read_stdin_if_present() {
    local S_IN=""
    if [ ! -t 0 ]; then # if stdin is not a TTY (i.e., it's a pipe or redirect)
      S_IN=$(cat -)
    fi
    echo "$S_IN"
}
export -f _read_stdin_if_present

# Define mock clerk functions that might receive piped input
my_clerk() { local s_in=$(_read_stdin_if_present); echo "my_clerk called with STDIN: '$s_in' ARGS: '$@'"; }
vibelab_active() { local s_in=$(_read_stdin_if_present); echo "vibelab_active (cid: $vibelab_active_cid) called with STDIN: '$s_in' ARGS: '$@'"; }
vibelab_complete() { local s_in=$(_read_stdin_if_present); echo "vibelab_complete (cid: $vibelab_complete_cid) called with STDIN: '$s_in' ARGS: '$@'"; }
deep-bloom() { local s_in=$(_read_stdin_if_present); echo "deep-bloom received STDIN: '$s_in' ARGS: '$@'"; }
llm-notes() { local s_in=$(_read_stdin_if_present); echo "llm-notes received STDIN: '$s_in' ARGS: '$@'"; }
vibelab_clerk() { local s_in=$(_read_stdin_if_present); echo "vibelab_clerk received STDIN: '$s_in' ARGS: '$@'"; }
glossary_clerk() { local s_in=$(_read_stdin_if_present); echo "glossary_clerk received STDIN: '$s_in' ARGS: '$@'"; }
mock_suggested_clerk() { local s_in=$(_read_stdin_if_present); echo "mock_suggested_clerk received STDIN: '$s_in' ARGS: '$@'"; }


export -f my_clerk vibelab_active vibelab_complete deep-bloom llm-notes vibelab_clerk glossary_clerk mock_suggested_clerk

# Define mock archive_completed_tasks (needed by script_1.sh - dynamic_clerk archive)
archive_completed_tasks() {
    echo "archive_completed_tasks called for clerk: $1"
}
export -f archive_completed_tasks

# CIDs for vibelab tasks
vibelab_active_cid="vibelab_active_cid_initial"
vibelab_complete_cid="vibelab_complete_cid_initial"
export vibelab_active_cid vibelab_complete_cid

# CID for clerk_resume
my_clerk_cid="initial_my_clerk_cid"
export my_clerk_cid

echo "Mock environment setup complete."
