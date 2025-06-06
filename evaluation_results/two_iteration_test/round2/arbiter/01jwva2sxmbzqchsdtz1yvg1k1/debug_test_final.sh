#!/bin/bash
export HOME="$(pwd)"
source ./clerk_manager.sh

# Create a wrapper around the llm command to see what's happening
llm() {
    echo "WRAPPER: llm called with args: $@" >> /tmp/debug_llm_calls.log
    ./llm_mock.sh "$@"
}

# Export so subshells can see it
export -f llm

echo "=== Testing dynamic clerk with debug wrapper ==="
test_clerk "debug test with wrapper"

echo "=== Testing static clerk with debug wrapper ==="
vibelab_clerk "debug test static"

echo "=== Debug log ==="
cat /tmp/debug_llm_calls.log 2>/dev/null || echo "No debug log found"

echo "=== Mock activity log ==="
cat /tmp/llm_mock_activity.log 2>/dev/null || echo "No mock activity log found"
