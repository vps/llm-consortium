# Setup function for vibelab clerk
setup_vibelab_clerk() {
    # Check if already registered
    local existing=$(echo "SELECT name FROM clerks WHERE name='vibelab';" | sqlite3 "$CLERK_DB" 2>/dev/null)
    if [[ -z "$existing" ]]; then
        VIBELAB_CID=$(register_clerk "vibelab" \
"<MACHINE_NAME>VibeLab Clerk</MACHINE_NAME>
<MACHINE_DESCRIPTION>Manages notes, ideas, and progress for the VibeLab project</MACHINE_DESCRIPTION>
<CORE_FUNCTION>Track tasks with !pending and !completed markers. Maintain separate threads for active and finished work.</CORE_FUNCTION>")
        
        create_thread "vibelab" "pending"
        create_thread "vibelab" "completed"
        echo "Vibelab clerk registered with CID: $VIBELAB_CID"
    else
        echo "Vibelab clerk already registered"
    fi
}

# Clerk function with task management
vibelab() {
    local args=("$@")
    local task_marker=""
    
    # Detect task commands
    for arg in "${args[@]}"; do
        if [[ "$arg" =~ ^!(pending|completed) ]]; then
            task_marker="${BASH_REMATCH[1]}"
            break
        fi
    done
    
    # Execute with appropriate thread
    if [[ "$task_marker" == "pending" ]]; then
        clerk vibelab --thread pending "${args[@]}"
    elif [[ "$task_marker" == "completed" ]]; then
        local response_id=$(clerk vibelab --thread completed "${args[@]}" | jq -r '.id')
        complete_task "$response_id" "vibelab"
    else
        clerk vibelab "${args[@]}"
    fi
}
