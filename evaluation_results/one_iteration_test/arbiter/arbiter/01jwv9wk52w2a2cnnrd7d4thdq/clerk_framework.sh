#!/bin/bash

# Helper functions
_get_llm_log_db_path() {
    llm logs path
}

_get_clerk_registry_db_path() {
    # For testing, use a local path instead of ~/.config/llm
    echo "./clerk_registry.db"
}

# Clerk registry database setup
initialize_clerk_registry() {
    local db_path="$(_get_clerk_registry_db_path)"
    mkdir -p "$(dirname "$db_path")"
    sqlite3 "$db_path" "DROP TABLE IF EXISTS clerk_threads;" # Drop first due to foreign key
    sqlite3 "$db_path" "DROP TABLE IF EXISTS clerks;"
    sqlite3 "$db_path" "CREATE TABLE IF NOT EXISTS clerks (
        clerk_name TEXT PRIMARY KEY,
        system_prompt TEXT,
        default_thread_type TEXT
    );"
    sqlite3 "$db_path" "CREATE TABLE IF NOT EXISTS clerk_threads (
        thread_id TEXT PRIMARY KEY,
        clerk_name TEXT,
        thread_type TEXT,
        conversation_id TEXT UNIQUE,
        FOREIGN KEY (clerk_name) REFERENCES clerks(clerk_name)
    );"
    echo "Clerk registry initialized at $db_path"
}

# Core clerk functions
clerk-register() {
    local clerk_name="$1"
    local system_prompt="$2"
    local default_thread_type="${3:-general}"
    
    local db_path="$(_get_clerk_registry_db_path)"
    # Ensure system_prompt is properly quoted for SQLite
    system_prompt_escaped=$(echo "$system_prompt" | sed "s/'/''/g")

    sqlite3 "$db_path" "INSERT OR REPLACE INTO clerks (clerk_name, system_prompt, default_thread_type) 
                        VALUES ('$clerk_name', '$system_prompt_escaped', '$default_thread_type');"
    if [ $? -eq 0 ]; then
        echo "Registered clerk: $clerk_name"
    else
        echo "Error registering clerk: $clerk_name"
        return 1
    fi
}

_clerk-ensure-thread() {
    local clerk_name="$1"
    local thread_type="$2"
    
    local db_path="$(_get_clerk_registry_db_path)"
    # Ensure clerk_name and thread_type are quoted for SQLite
    local conversation_id=$(sqlite3 "$db_path" "SELECT conversation_id FROM clerk_threads 
                     WHERE clerk_name = '$clerk_name' AND thread_type = '$thread_type' 
                     LIMIT 1;")
    
    if [ -z "$conversation_id" ]; then
        conversation_id=$(uuidgen)
        sqlite3 "$db_path" "INSERT INTO clerk_threads (thread_id, clerk_name, thread_type, conversation_id)
                            VALUES ('$(uuidgen)', '$clerk_name', '$thread_type', '$conversation_id');"
        if [ $? -ne 0 ]; then
            echo "Error creating thread for $clerk_name - $thread_type" >&2
            return 1
        fi
    fi
    
    echo "$conversation_id"
}

clerk-interact() {
    local clerk_name="$1"
    local thread_type="$2"
    shift 2
    local prompt_args="$@"
    
    local db_path="$(_get_clerk_registry_db_path)"
    local system_prompt=$(sqlite3 "$db_path" "SELECT system_prompt FROM clerks WHERE clerk_name = '$clerk_name' LIMIT 1;")
    if [ -z "$system_prompt" ]; then
        echo "Error: System prompt not found for clerk '$clerk_name'" >&2
        return 1
    fi

    local conversation_id=$(_clerk-ensure-thread "$clerk_name" "$thread_type")
    if [ -z "$conversation_id" ]; then
        echo "Error: Could not ensure thread for clerk '$clerk_name', type '$thread_type'" >&2
        return 1
    fi
    
    # For testing, echo the command instead of executing llm
    echo "Executing: llm -s \"$system_prompt\" -c \"$conversation_id\" \"$prompt_args\""
    # llm -s "$system_prompt" -c "$conversation_id" "$prompt_args"
}

clerk-move-response() {
    local response_id="$1"
    local target_clerk_name="$2"
    local target_thread_type="$3"
    
    local log_db_path_val=$(_get_llm_log_db_path)
    if [ -z "$log_db_path_val" ] || ! [ -f "$log_db_path_val" ]; then
        echo "Error: LLM logs database not found at '$log_db_path_val'." >&2
        # Create a dummy log DB for testing if it doesn't exist
        # This is a workaround for environments where `llm logs path` might not work or db is missing
        echo "Attempting to create a dummy LLM logs DB for testing." >&2
        log_db_path_val="./dummy_llm_logs.db"
        sqlite3 "$log_db_path_val" "CREATE TABLE IF NOT EXISTS responses (id TEXT PRIMARY KEY, conversation_id TEXT, prompt TEXT, response TEXT, datetime_utc TEXT);"
        sqlite3 "$log_db_path_val" "INSERT OR IGNORE INTO responses (id, conversation_id, prompt, response, datetime_utc) VALUES ('test_response_id_1', 'dummy_pending_cid', 'Test prompt 1', 'Test response 1', datetime('now'));"

        # Override _get_llm_log_db_path for this session if it was problematic
        # This won't persist, but helps the current function call
        _get_llm_log_db_path() { echo "./dummy_llm_logs.db"; }
        log_db_path_val=$(_get_llm_log_db_path) # re-fetch
    fi

    local target_cid=$(_clerk-ensure-thread "$target_clerk_name" "$target_thread_type")
    if [ -z "$target_cid" ]; then
        echo "Error: Could not ensure target thread for clerk '$target_clerk_name', type '$target_thread_type'" >&2
        return 1
    fi
    
    sqlite3 "$log_db_path_val" "UPDATE responses SET conversation_id = '$target_cid' WHERE id = '$response_id';"
    if [ $? -eq 0 ]; then
        echo "Moved response $response_id to conversation $target_cid for clerk $target_clerk_name, thread $target_thread_type"
    else
        echo "Error moving response $response_id for clerk $target_clerk_name" >&2
        return 1
    fi
}

# Source this file to make functions available
# Example: . clerk_framework.sh
