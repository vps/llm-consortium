# Query-driven clerk initialization
clerk_resume() {
    local clerk_name="$1"
    local cid_var="${clerk_name}_cid"
    local cid="${!cid_var}"
    
    # Get recent context
    local recent_context=$(sqlite3 $(llm logs path) "
        SELECT 'Last discussed: ' || substr(prompt, 1, 50) || '... -> ' || substr(response, 1, 50) || '...'
        FROM responses 
        WHERE conversation_id='$cid'
        ORDER BY datetime_utc DESC 
        LIMIT 3
    ")
    
    echo "Resuming $clerk_name with context:"
    echo "$recent_context"
}

# Bookmark important exchanges
clerk_bookmark() {
    local keyword="$1"
    
    sqlite3 $(llm logs path) "
        UPDATE responses 
        SET bookmark = 1 
        WHERE (prompt LIKE '%$keyword%' OR response LIKE '%$keyword%')
        AND datetime_utc > datetime('now', '-1 day')
    "
    
    echo "Bookmarked recent exchanges containing: $keyword"
}
