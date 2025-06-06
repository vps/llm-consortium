# Bifurcated task management for vibelab_clerk
vibelab_active() {
    llm --system "<MACHINE_NAME>VibeLab Active Tasks</MACHINE_NAME>
<CORE_FUNCTION>Active task tracking for VibeLab project. When tasks are completed, use 'vibelab_complete' to archive them.</CORE_FUNCTION>" \
    -c --cid $vibelab_active_cid "$@"
}

vibelab_complete() {
    llm --system "<MACHINE_NAME>VibeLab Completed Tasks</MACHINE_NAME>
<CORE_FUNCTION>Archive of completed VibeLab tasks. Maintains completion history and lessons learned.</CORE_FUNCTION>" \
    -c --cid $vibelab_complete_cid "$@"
}

# Task transition helper
vibelab_transition() {
    local task_description="$1"
    
    # Mark as complete in active stream
    echo "COMPLETED: $task_description" | vibelab_active
    
    # Archive in completion stream with timestamp
    echo "$(date): ARCHIVED - $task_description" | vibelab_complete
    
    # Update task status in database
    sqlite3 $(llm logs path) "
        UPDATE responses 
        SET bookmark = 1 
        WHERE conversation_id='$vibelab_active_cid' 
        AND prompt LIKE '%$task_description%'
    "
}
