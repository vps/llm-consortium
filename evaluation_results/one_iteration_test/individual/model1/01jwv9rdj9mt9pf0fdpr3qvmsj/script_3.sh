# Meta-clerk that generates new clerks on demand
clerk_factory() {
    local domain="$1"
    local specialization="$2"
    local context="$3"
    
    # Generate clerk definition
    local clerk_def=$(llm --system "Generate a bash function for a specialized clerk assistant. 
Domain: $domain, Specialization: $specialization, Context: $context
Output only the function definition with appropriate system prompt." \
    "Create clerk function")
    
    # Write to dynamic clerks file
    echo "$clerk_def" >> ~/.clerk_dynamic.sh
    source ~/.clerk_dynamic.sh
    
    echo "Generated and loaded: ${domain}_clerk"
}

# Context-aware clerk selector
smart_clerk() {
    local input="$1"
    
    # Analyze input to suggest appropriate clerk
    local suggested_clerk=$(echo "$input" | llm --system "
        Based on this input, suggest the most appropriate clerk from: 
        deep-bloom, llm-notes, vibelab_clerk, glossary_clerk
        Output only the function name." "Analyze input context")
    
    echo "Suggested clerk: $suggested_clerk"
    echo "$input" | $suggested_clerk
}
