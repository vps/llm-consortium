#!/bin/bash
export HOME="$(pwd)"
source ./clerk_manager.sh

# Override _run_dynamic_clerk_interaction to debug
_run_dynamic_clerk_interaction() {
    echo "DEBUG: _run_dynamic_clerk_interaction called with:"
    echo "  arg1 (cid): '$1'"
    echo "  arg2 (system_prompt): '$2'"
    echo "  remaining args: '${@:3}'"
    
    local cid="$1"
    local system_prompt="$2"
    shift 2
    
    echo "  processed cid: '$cid'"
    echo "  processed system_prompt: '$system_prompt'"
    
    # Call the actual llm command
    llm "$@" --system "$system_prompt" --cid "$cid" -c
}

# Try to invoke the test_clerk
echo "=== Invoking test_clerk ==="
test_clerk "debug test message"
