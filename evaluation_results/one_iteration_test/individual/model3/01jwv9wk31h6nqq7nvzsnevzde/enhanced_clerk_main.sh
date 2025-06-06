#!/bin/bash
# Enhanced Clerk Pattern with Dynamic Conversation Management

# Clerk registry database path
CLERK_DB="$HOME/.config/llm/clerks.db"

# Ensure directory exists
mkdir -p "$(dirname "$CLERK_DB")"

# Initialize clerk database
init_clerk_db() {
    echo "CREATE TABLE IF NOT EXISTS clerks (name TEXT PRIMARY KEY, system_prompt TEXT, default_cid TEXT);" | sqlite3 "$CLERK_DB"
    
    echo "CREATE TABLE IF NOT EXISTS threads (cid TEXT PRIMARY KEY, clerk_name TEXT, thread_type TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(clerk_name) REFERENCES clerks(name));" | sqlite3 "$CLERK_DB"
}

# Create new clerk with dynamic CID
register_clerk() {
    local name=$1
    local system_prompt=$2
    local cid=$(uuidgen)
    
    echo "INSERT OR REPLACE INTO clerks (name, system_prompt, default_cid) VALUES ('$name', '$system_prompt', '$cid');" | sqlite3 "$CLERK_DB"
    
    echo "$cid"
}

# Create new conversation thread
create_thread() {
    local clerk_name=$1
    local thread_type=${2:-"default"}
    local cid=$(uuidgen)
    
    echo "INSERT INTO threads (cid, clerk_name, thread_type) VALUES ('$cid', '$clerk_name', '$thread_type');" | sqlite3 "$CLERK_DB"
    
    echo "$cid"
}

# Clerk execution function
clerk() {
    local clerk_name=$1
    shift
    local thread_type=""
    local cid=""
    local args=()
    
    # Parse thread type if specified
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --thread)
                thread_type=$2
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Get or create CID
    if [[ -n "$thread_type" ]]; then
        cid=$(echo "SELECT cid FROM threads WHERE clerk_name='$clerk_name' AND thread_type='$thread_type' LIMIT 1;" | sqlite3 "$CLERK_DB")
        [[ -z "$cid" ]] && cid=$(create_thread "$clerk_name" "$thread_type")
    else
        cid=$(echo "SELECT default_cid FROM clerks WHERE name='$clerk_name';" | sqlite3 "$CLERK_DB")
    fi
    
    # Get system prompt
    local system_prompt=$(echo "SELECT system_prompt FROM clerks WHERE name='$clerk_name';" | sqlite3 "$CLERK_DB")
    
    # Execute LLM command
    llm "${args[@]}" --system "$system_prompt" --cid "$cid"
}

# Move response between threads
move_response() {
    local response_id=$1
    local target_cid=$2
    local db_path=$(llm logs path)
    
    echo "UPDATE responses SET conversation_id = '$target_cid' WHERE id = '$response_id';" | sqlite3 "$db_path"
}

# Task completion handler
complete_task() {
    local response_id=$1
    local clerk_name=$2
    local pending_cid=$(echo "SELECT cid FROM threads WHERE clerk_name='$clerk_name' AND thread_type='pending';" | sqlite3 "$CLERK_DB")
    local completed_cid=$(echo "SELECT cid FROM threads WHERE clerk_name='$clerk_name' AND thread_type='completed';" | sqlite3 "$CLERK_DB")
    
    [[ -z "$completed_cid" ]] && completed_cid=$(create_thread "$clerk_name" "completed")
    
    move_response "$response_id" "$completed_cid"
}

[[ ! -f "$CLERK_DB" ]] && init_clerk_db
