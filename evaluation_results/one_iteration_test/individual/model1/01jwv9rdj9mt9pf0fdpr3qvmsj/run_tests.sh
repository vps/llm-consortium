#!/bin/bash
# Comprehensive test suite for LLM clerk enhancement scripts

source ./setup_mocks.sh
source ./script_1.sh
source ./script_2.sh
source ./script_3.sh
source ./script_4.sh
source ./script_5.sh
source ./script_6.sh

echo '=== Testing Script 1: Dynamic Conversation Management ==='

# Test 1.1: Create new conversation
echo -e '\n--- Test 1.1: New conversation ---'
dynamic_clerk 'test_clerk' 'new'

# Test 1.2: Fork conversation
echo -e '\n--- Test 1.2: Fork conversation ---'
dynamic_clerk 'my_clerk' 'fork' '' 'test_source_cid'

# Test 1.3: Archive tasks
echo -e '\n--- Test 1.3: Archive tasks ---'
dynamic_clerk 'test_clerk' 'archive'

echo -e '\n=== Testing Script 2: Task State Management ==='

# Test 2.1: Active task tracking
echo -e '\n--- Test 2.1: Active task tracking ---'
echo 'Test task description' | vibelab_active

# Test 2.2: Task transition
echo -e '\n--- Test 2.2: Task transition ---'
vibelab_transition 'Complete authentication module'

echo -e '\n=== Testing Script 3: Meta-Clerk Factory ==='

# Test 3.1: Generate new clerk
echo -e '\n--- Test 3.1: Generate new clerk ---'
clerk_factory 'security' 'authentication' 'OAuth2 implementation'
# Check if dynamic clerks file was created
[ -f ~/.clerk_dynamic.sh ] && echo 'Dynamic clerks file created' || echo 'Dynamic clerks file NOT created'

# Test 3.2: Smart clerk selector
echo -e '\n--- Test 3.2: Smart clerk selector ---'
smart_clerk 'Need help with database design'

echo -e '\n=== Testing Script 4: Analytics ==='

# Test 4.1: Conversation analytics
echo -e '\n--- Test 4.1: Conversation analytics ---'
clerk_analytics 'test_cid'

# Test 4.2: Extract insights
echo -e '\n--- Test 4.2: Extract insights ---'
clerk_insights 'test_cid'

echo -e '\n=== Testing Script 5: Advanced Integration ==='

# Test 5.1: Clerk pipeline
echo -e '\n--- Test 5.1: Clerk pipeline ---'
clerk_pipeline 'Design a new feature' deep-bloom llm-notes vibelab_clerk

# Test 5.2: Cross-clerk sync
echo -e '\n--- Test 5.2: Cross-clerk sync ---'
clerk_sync 'test_source_cid' 'my_clerk'

echo -e '\n=== Testing Script 6: Database-Driven Enhancements ==='

# Test 6.1: Resume clerk
echo -e '\n--- Test 6.1: Resume clerk ---'
clerk_resume 'my_clerk'

# Test 6.2: Bookmark exchanges
echo -e '\n--- Test 6.2: Bookmark exchanges ---'
clerk_bookmark 'important_keyword'

echo -e '\n=== All tests completed ===' 
