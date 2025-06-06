# Chain clerks for complex workflows
clerk_pipeline() {
    local input="$1"
    shift
    local clerks=("$@")
    
    local current_input="$input"
    
    for clerk in "${clerks[@]}"; do
        echo "Processing with $clerk..."
        current_input=$(echo "$current_input" | $clerk)
    done
    
    echo "$current_input"
}

# Example usage:
# clerk_pipeline "Design a new feature" deep-bloom llm-notes vibelab_clerk

# Cross-clerk knowledge transfer
clerk_sync() {
    local source_cid="$1"
    local target_clerk="$2"
    
    # Extract key concepts from source
    local knowledge=$(sqlite3 $(llm logs path) "
        SELECT response FROM responses 
        WHERE conversation_id='$source_cid' 
        AND bookmark=1
    " | llm-compressor)
    
    # Inject into target clerk
    echo "Knowledge transfer: $knowledge" | $target_clerk
}
