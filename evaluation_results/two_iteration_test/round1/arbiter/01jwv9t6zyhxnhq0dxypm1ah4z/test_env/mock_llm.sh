#!/bin/bash
# Enhanced mock llm command for testing
if [ "$1" = "logs" ] && [ "$2" = "path" ]; then
    echo "$(pwd)/test_logs.db"
    exit 0
fi
# For normal calls - simulate command execution
echo "LLM_CALL: $@"
