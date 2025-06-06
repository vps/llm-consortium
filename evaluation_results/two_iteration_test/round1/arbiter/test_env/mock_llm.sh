#!/bin/bash
# Mock llm command for testing
if [ "$1" = "logs" ] && [ "$2" = "path" ]; then
    echo "$(pwd)/test_logs.db" # Use db in current dir
else
    # For actual llm calls, just echo the parameters
    echo "Mock LLM call with args: $@"
fi
