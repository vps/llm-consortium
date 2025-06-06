# Enhanced clerk with conversation lifecycle management
vibelab_clerk() {
    local mode="${1:-active}"  # active, completed, archive
    shift
    
    local base_cid="01jwekxc9hc0vrqqex7dnfg9j0"
    local conversation_id="${base_cid}_${mode}"
    
    case "$mode" in
        "complete")
            # Move task from active to completed
            migrate_conversation_records "$base_cid" "${base_cid}_completed" "$2"
            ;;
        "fork")
            # Create specialized sub-conversation
            conversation_id="${base_cid}_$(date +%s)"
            ;;
    esac
    
    llm --system "$(get_contextual_system_prompt "$mode")" \
        -c --cid "$conversation_id" "$@"
}

migrate_conversation_records() {
    local source_cid="$1"
    local target_cid="$2" 
    local task_pattern="$3"
    
    sqlite3 "$(llm logs path)" <<SQL_EOF
UPDATE responses 
SET conversation_id = '$target_cid'
WHERE conversation_id = '$source_cid' 
AND (prompt LIKE '%$task_pattern%' OR response LIKE '%$task_pattern%');
SQL_EOF
}

get_contextual_system_prompt() {
    local mode="$1"
    local base_prompt="<MACHINE_NAME>VibeLab Clerk</MACHINE_NAME>"
    
    case "$mode" in
        "active")
            echo "$base_prompt
<CONTEXT>$(get_recent_context active)</CONTEXT>
<FOCUS>Current active tasks and immediate next steps</FOCUS>"
            ;;
        "completed")
            echo "$base_prompt  
<CONTEXT>$(get_recent_context completed)</CONTEXT>
<FOCUS>Completed tasks for review and lessons learned</FOCUS>"
            ;;
        "archive") # Added missing archive case for completeness based on vibelab_clerk comment
             echo "$base_prompt
<CONTEXT>$(get_recent_context archive)</CONTEXT>
<FOCUS>Archived tasks for historical review</FOCUS>"
            ;;
        *) # Default case
            echo "$base_prompt"
            ;;
    esac
}

get_recent_context() {
    local mode="$1"
    # Ensure llm logs path is correctly resolved if llm command is mocked
    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path) # Use mocked llm if it provides logs path
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH") # Fallback to env var if llm CLI or mock fails
    fi

    if [ -z "$db_path" ]; then
        echo "Error: Database path not found for get_recent_context."
        return 1
    fi

    sqlite3 "$db_path" \
        "SELECT prompt, response FROM responses 
         WHERE conversation_id LIKE '%vibelab%${mode}%' 
         ORDER BY datetime_utc DESC LIMIT 3" |
    sed 's/|/ -> /'
}

# STUB functions for clerk_factory dependencies
generate_cid() {
    echo "stub_cid_$(date +%s)_$RANDOM"
}

generate_system_prompt() {
    local domain="$1"
    echo "System prompt for domain: $domain"
}
# END STUB functions

clerk_factory() {
    local clerk_name="$1"
    local domain="$2"
    local cid # Will be set by the generated function when it's called.
    
    # Generate function dynamically. Note: cid is generated *inside* the clerk now.
    # This ensures each call to the generated clerk uses a fresh, unique CID if not overridden.
    local clerk_function_body
    read -r -d '' clerk_function_body <<FUNC_BODY
        local clerk_cid="\$(generate_cid)" # Generate CID at runtime of the clerk
        local stdin_data=""
        local args_to_pass=()
        
        if [ ! -t 0 ]; then # Check if running in a pipe
            stdin_data=\$(cat)
        fi
        
        # Process arguments: if first arg is --cid, use it, otherwise treat all as prompt
        if [[ "\$1" == "--cid" && -n "\$2" ]]; then
            clerk_cid="\$2"
            shift 2 # Remove --cid and its value from args
        fi

        if [ \$# -gt 0 ]; then
            args_to_pass=("\$@")
        elif [ -n "\$stdin_data" ]; then
            args_to_pass=("\$stdin_data")
        else
            # If no args and no stdin, perhaps a default action or error?
            # For now, let llm handle empty prompt if that's desired.
            : # Do nothing, args_to_pass remains empty
        fi
        
        llm --system "$(generate_system_prompt "$domain")" \\
            -c --cid "\$clerk_cid" "\${args_to_pass[@]}"
FUNC_BODY

    eval "${clerk_name}_clerk() { ${clerk_function_body} }"
    
    # Persist the function definition to a local file
    echo "${clerk_name}_clerk() { ${clerk_function_body} }" >> ./local_clerk_functions.sh
    echo "Generated function ${clerk_name}_clerk and appended to ./local_clerk_functions.sh"
}

clerk_status() {
    local clerk_pattern="$1"
    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path)
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH")
    fi
    if [ -z "$db_path" ]; then echo "Error: DB path not found."; return 1; fi

    sqlite3 "$db_path" <<SQL_EOF
.mode column
.headers on
SELECT 
    SUBSTR(conversation_id, -20) as cid_suffix,
    COUNT(*) as exchanges,
    MAX(datetime_utc) as last_active,
    ROUND(AVG(COALESCE(input_tokens,0) + COALESCE(output_tokens,0)), 0) as avg_tokens -- Handle NULLs
FROM responses 
WHERE conversation_id LIKE '%$clerk_pattern%'
GROUP BY conversation_id
ORDER BY last_active DESC;
SQL_EOF
}

cluster_conversations() {
    local clerk_cid_pattern="$1" # Changed to pattern to be more flexible
    
    local collection_name="clerk-$(echo "$clerk_cid_pattern" | sed 's/[^a-zA-Z0-9_-]//g')"
    if [ -z "$collection_name" ] || [ "$collection_name" = "clerk-" ]; then
        collection_name="clerk-default-collection"
    fi
    echo "Using collection name: $collection_name for pattern: $clerk_cid_pattern"

    local temp_data_file
    temp_data_file=$(mktemp)
    trap 'rm -f "$temp_data_file"' RETURN # Ensure temp file is cleaned up

    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path)
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH")
    fi
    if [ -z "$db_path" ]; then echo "Error: DB path not found."; return 1; fi

    sqlite3 "$db_path" \
            "SELECT id, prompt || ' ' || response 
             FROM responses 
             WHERE conversation_id LIKE '%$clerk_cid_pattern%'" > "$temp_data_file"

    if [ ! -s "$temp_data_file" ]; then
        echo "No data found for clerk_cid pattern '$clerk_cid_pattern' to embed."
        return 1
    fi

    llm embed-multi \
        -m sentence-transformers/all-MiniLM-L6-v2 \
        --store \
        --collection "$collection_name" < "$temp_data_file"
    
    # Find similar conversation patterns
    llm similar "$collection_name" --top 5
}

clerk_snapshot() {
    local clerk_name_pattern="$1" # Changed to pattern
    local snapshot_name="$2"
    
    local snapshot_cid_base="${clerk_name_pattern}_snapshot_${snapshot_name}"
    local snapshot_cid="${snapshot_cid_base}_$(date +%s)_$RANDOM" # Ensure more unique snapshot CIDs
    
    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path)
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH")
    fi
    if [ -z "$db_path" ]; then echo "Error: DB path not found."; return 1; fi
    
    sqlite3 "$db_path" <<SQL_EOF
INSERT INTO responses (
    id, model, prompt, system, response, conversation_id, datetime_utc, input_tokens, output_tokens, duration_ms
)
SELECT 
    id || '_snapshot_' || RANDOM(), model, prompt, system, response, 
    '$snapshot_cid', datetime_utc, input_tokens, output_tokens, duration_ms
FROM responses 
WHERE conversation_id LIKE '%${clerk_name_pattern}%' AND conversation_id NOT LIKE '%_snapshot_%' -- Avoid re-snapshotting snapshots
ORDER BY datetime_utc;
SQL_EOF
    
    local count
    count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM responses WHERE conversation_id = '$snapshot_cid';")
    if [ "$count" -gt 0 ]; then
        echo "Snapshot created: $snapshot_cid with $count records."
    else
        echo "Snapshot attempted for $snapshot_cid, but no records matched pattern '%${clerk_name_pattern}%' or all were already snapshots."
    fi
}

transfer_knowledge() {
    local source_clerk_pattern="$1"
    local target_clerk_name="$2" # This is the NAME of a clerk function
    local topic="$3"
    
    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path)
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH")
    fi
    if [ -z "$db_path" ]; then echo "Error: DB path not found."; return 1; fi

    local knowledge
    knowledge=$(sqlite3 "$db_path" \
        "SELECT response FROM responses 
         WHERE conversation_id LIKE '%$source_clerk_pattern%' 
         AND (prompt LIKE '%$topic%' OR response LIKE '%$topic%')
         ORDER BY datetime_utc DESC LIMIT 5")
    
    if [ -z "$knowledge" ]; then
        echo "No knowledge found for topic '$topic' from clerk pattern '$source_clerk_pattern'."
        return 1
    fi

    if ! type "${target_clerk_name}_clerk" &>/dev/null; then
        echo "Error: Target clerk function '${target_clerk_name}_clerk' not found."
        echo "Ensure it was generated by clerk_factory and ./local_clerk_functions.sh is sourced."
        return 1
    fi
    
    echo "Context from ${source_clerk_pattern} on topic ${topic}: $knowledge" | 
        eval "${target_clerk_name}_clerk" "Incorporate this knowledge about '$topic'"
}

clerk_analytics() {
    local db_path
    if type llm &>/dev/null && [[ "$(type -t llm)" == "function" ]]; then
        db_path=$(llm logs path)
    else
        db_path=$(llm logs path 2>/dev/null || echo "$LLM_LOGS_PATH")
    fi
    if [ -z "$db_path" ]; then echo "Error: DB path not found."; return 1; fi

    sqlite3 "$db_path" -column -header <<SQL_EOF
WITH clerk_stats AS (
    SELECT 
        CASE 
            WHEN conversation_id LIKE '%deep_bloom%' THEN 'deep-bloom'
            WHEN conversation_id LIKE '%vibelab_active%' THEN 'vibelab-active'
            WHEN conversation_id LIKE '%vibelab_completed%' THEN 'vibelab-completed'
            WHEN conversation_id LIKE '%vibelab_fork%' THEN 'vibelab-fork'
            WHEN conversation_id LIKE '%vibelab%' THEN 'vibelab-generic'
            WHEN conversation_id LIKE '%llm_notes%' THEN 'llm-notes'
            WHEN conversation_id LIKE '%snapshot%' THEN 'snapshot'
            -- Attempt to extract clerk name from pattern like 'myclerkname_cid_...'
            ELSE IFNULL(SUBSTR(conversation_id, 1, INSTR(conversation_id, '_cid_') -1), 
                        IFNULL(SUBSTR(conversation_id, 1, INSTR(conversation_id, '_snapshot_') -1), 
                               'other'))
        END as clerk_type,
        COUNT(*) as total_exchanges,
        SUM(COALESCE(input_tokens, 0) + COALESCE(output_tokens, 0)) as total_tokens,
        AVG(duration_ms) as avg_duration,
        DATE(datetime_utc) as date
    FROM responses 
    WHERE conversation_id IS NOT NULL AND conversation_id != ''
    GROUP BY clerk_type, DATE(datetime_utc)
)
SELECT * FROM clerk_stats ORDER BY date DESC, total_tokens DESC;
SQL_EOF
}
