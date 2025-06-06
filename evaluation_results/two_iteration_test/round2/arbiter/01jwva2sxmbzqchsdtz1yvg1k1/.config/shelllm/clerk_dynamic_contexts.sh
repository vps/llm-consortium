#!/bin/bash
declare -A DYNAMIC_CLERK_CIDS
declare -A DYNAMIC_CLERK_SYSTEM_PROMPTS
# Dynamic clerk function definitions will be appended here.
DYNAMIC_CLERK_CIDS["test_clerk"]="2bb54d1b2257435baefb9e3f82"
DYNAMIC_CLERK_SYSTEM_PROMPTS["test_clerk"]='You are a helpful test assistant.'
test_clerk() { _run_dynamic_clerk_interaction "test_clerk" "$@"; }

DYNAMIC_CLERK_CIDS["test_clerk"]="18659f2a49224a5b9a3e26536a"
DYNAMIC_CLERK_SYSTEM_PROMPTS["test_clerk"]='You are a helpful test assistant.'
test_clerk() { _run_dynamic_clerk_interaction "test_clerk" "$@"; }

