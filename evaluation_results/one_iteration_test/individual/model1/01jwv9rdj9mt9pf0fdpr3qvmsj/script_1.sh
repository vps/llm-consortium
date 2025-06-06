# Enhanced clerk with conversation lifecycle management
dynamic_clerk() {
    local clerk_name="$1"
    local action="${2:-continue}"  # continue, fork, archive, merge
    local system_prompt="$3"
    
    case "$action" in
        "new")
            # Create new conversation branch
            local new_cid=$(uuidgen | tr '[:upper:]' '[:lower:]' | sed 's/-//g' | cut -c1-26)
            echo "Created new conversation: $new_cid"
            ;;
        "fork")
            # Fork current conversation at specific point
            fork_conversation "$clerk_name" "$4"  # $4 = source_cid
            ;;
        "archive")
            # Move completed tasks to archive conversation
            archive_completed_tasks "$clerk_name"
            ;;
    esac
}

# Fork conversation preserving context up to specific point
fork_conversation() {
    local clerk_name="$1"
    local source_cid="$2"
    local cutoff_id="${3:-latest}"
    
    # Query recent context for seeding new conversation
    local context=$(sqlite3 $(llm logs path) "
        SELECT prompt || ' -> ' || response 
        FROM responses 
        WHERE conversation_id='$source_cid' 
        ORDER BY datetime_utc DESC 
        LIMIT 5
    " | tr '\n' ' ')
    
    # Create new conversation with context injection
    local new_cid=$(generate_cid)
    eval "${clerk_name}_cid=$new_cid"
    
    # Seed with compressed context
    echo "Previous context: $context" | llm-compressor | $clerk_name
}
