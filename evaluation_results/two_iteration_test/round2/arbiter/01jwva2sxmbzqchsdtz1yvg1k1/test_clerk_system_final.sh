#!/bin/bash

# Override HOME for this testing session
export ORIGINAL_HOME_FOR_TEST="$HOME"
export HOME="$(pwd)"
echo "Testing with HOME=$HOME"

# Create a function override for llm that uses our mock
llm() {
    $(pwd)/llm_mock.sh "$@"
}
export -f llm  # Export so subshells can use it

echo "Using mock llm at: $(pwd)/llm_mock.sh"

# Source the clerk manager script
source ./clerk_manager.sh

# Clear mock llm log and known CIDs for fresh test
> /tmp/llm_mock_activity.log
> /tmp/llm_mock_known_cids.log

echo "=== Test 1: Verify functions are loaded ==="
type create_dynamic_clerk >/dev/null 2>&1 && echo "✓ create_dynamic_clerk loaded" || echo "✗ create_dynamic_clerk missing"
type vibelab_clerk >/dev/null 2>&1 && echo "✓ vibelab_clerk loaded" || echo "✗ vibelab_clerk missing"

echo -e "\n=== Test 2: Create dynamic clerk ==="
create_dynamic_clerk test_clerk "You are a helpful test assistant."
list_dynamic_clerks

echo -e "\n=== Test 3: Invoke dynamic clerk (first time) ==="
test_clerk "Hello from test_clerk, first call"

echo -e "\n=== Test 4: Invoke dynamic clerk (second time, should continue) ==="
test_clerk "Hello from test_clerk, second call"

echo -e "\n=== Test 5: Invoke static clerk vibelab (first time) ==="
vibelab_clerk "Update on task ABC"

echo -e "\n=== Test 6: Add vibelab task ==="
vibelab_add_task "Implement feature XYZ"

echo -e "\n=== Test 7: Complete a task (vibelab_complete_task test) ==="
# This function likely expects task selection, let's see if it works
echo "Testing vibelab_complete_task - may fail if it needs fzf"
vibelab_complete_task "feature" 2>&1 || echo "vibelab_complete_task failed (expected if fzf required)"

# Restore original HOME
export HOME="$ORIGINAL_HOME_FOR_TEST"
unset ORIGINAL_HOME_FOR_TEST
echo "Restored HOME to $HOME"
