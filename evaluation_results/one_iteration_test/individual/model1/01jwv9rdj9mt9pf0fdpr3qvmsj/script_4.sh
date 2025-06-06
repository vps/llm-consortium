# Analyze conversation patterns
clerk_analytics() {
    local clerk_cid="$1"
    
    sqlite3 $(llm logs path) "
        SELECT 
            COUNT(*) as total_exchanges,
            AVG(input_tokens) as avg_input_tokens,
            AVG(output_tokens) as avg_output_tokens,
            AVG(duration_ms) as avg_duration_ms,
            datetime(MIN(datetime_utc)) as first_interaction,
            datetime(MAX(datetime_utc)) as last_interaction
        FROM responses 
        WHERE conversation_id='$clerk_cid'
    " | column -t -s '|'
}

# Extract key insights from conversation
clerk_insights() {
    local clerk_cid="$1"
    
    # Get conversation summary
    sqlite3 $(llm logs path) "
        SELECT prompt || ' -> ' || substr(response, 1, 100) || '...'
        FROM responses 
        WHERE conversation_id='$clerk_cid'
        ORDER BY datetime_utc DESC 
        LIMIT 10
    " | llm-compressor | llm --system "Extract 3 key insights from this conversation history. Be extremely concise." "Analyze patterns"
}
