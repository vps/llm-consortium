#!/bin/bash

# Override HOME for this testing session
export ORIGINAL_HOME_FOR_TEST="$HOME" # Use a unique name to avoid clashes
export HOME="$(pwd)"
echo "Testing with HOME=$HOME"

# Ensure local llm_mock.sh is prioritized
export PATH="$(pwd):$PATH"
echo "Updated PATH for test script: $PATH"
echo "Which llm: $(which llm)" # Should point to ./llm_mock.sh

# Source the clerk manager script
source ./clerk_manager.sh

# Clear mock llm log
echo "" > /tmp/llm_mock_activity.log
# echo "" > /tmp/llm_mock_known_cids.log # Don't clear known CIDs if we want to test continuity over multiple calls

echo "=== Test 1: Verify functions are loaded ==="
type create_dynamic_clerk >/dev/null 2>&1 && echo "✓ create_dynamic_clerk loaded" || echo "✗ create_dynamic_clerk missing"
type vibelab_clerk >/dev/null 2>&1 && echo "✓ vibelab_clerk loaded" || echo "✗ vibelab_clerk missing"

echo -e "\n=== Test 2: Create dynamic clerk ==="
create_dynamic_clerk test_clerk "You are a helpful test assistant."
list_dynamic_clerks

echo -e "\n=== Test 3: Invoke dynamic clerk (first time) ==="
test_clerk "Hello from test_clerk, first call"

echo -e "\n=== Test 4: Invoke dynamic clerk (second time, should be continue) ==="
test_clerk "Hello from test_clerk, second call"


echo -e "\n=== Test 5: Invoke static clerk (first time) ==="
vibelab_clerk "Update on task ABC, first call"

echo -e "\n=== Test 6: Invoke static clerk (second time, should be continue) ==="
vibelab_clerk "Update on task ABC, second call"

echo -e "\n=== Test 7: Add vibelab task ==="
vibelab_add_task "Implement feature XYZ"


echo -e "\n\n=== Test Output Capturing Ends Here ===\n"

# Restore original HOME
export HOME="$ORIGINAL_HOME_FOR_TEST"
unset ORIGINAL_HOME_FOR_TEST
