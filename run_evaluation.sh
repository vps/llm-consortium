#!/bin/bash

LOGS_DB="/home/thomas/.config/io.datasette.llm/logs.db"
EVAL_DIR="evaluation_results"
AGENT_SCRIPT="/home/thomas/Projects/claude.sh-bak-2/agent_bash.sh"

# Max concurrent jobs
MAX_CONCURRENT_JOBS=2
active_jobs=0

# Ensure EVAL_DIR exists
mkdir -p "$EVAL_DIR"

# Function to extract content between <FINAL_ANSWER> tags
get_final_answer() {
    local output="$1"
    local start_tag="<FINAL_ANSWER>"
    local end_tag="</FINAL_ANSWER>"
    
    # Use awk to extract content between tags
    echo "$output" | awk -v start="$start_tag" -v end="$end_tag" '
        BEGIN { found_start = 0; content = "" }
        {
            if (found_start) {
                end_pos = index($0, end)
                if (end_pos > 0) {
                    content = content substr($0, 1, end_pos - 1)
                    print content
                    exit
                } else {
                    content = content $0 "\n"
                }
            } else {
                start_pos = index($0, start)
                if (start_pos > 0) {
                    found_start = 1
                    remainder = substr($0, start_pos + length(start))
                    end_pos = index(remainder, end)
                    if (end_pos > 0) {
                        print substr(remainder, 1, end_pos - 1)
                        exit
                    } else {
                        content = remainder "\n"
                    }
                }
            }
        }
        END {
            if (found_start && content != "") {
                print content
            }
        }
    '
}

# Function to process a response
process_response() {
    local id="$1"
    local group="$2"
    local round="$3"
    local type="$4"
    local model_name="${5:-}"
    
    local target_dir="$EVAL_DIR/$group/$round/$type"
    if [ -n "$model_name" ]; then
        target_dir="$target_dir/$model_name"
    else
        target_dir="$target_dir/$id"
    fi
    
    mkdir -p "$target_dir"
    
    echo "Processing $id -> $target_dir"
    
    # Get prompt and response from logs
    prompt=$(sqlite3 "$LOGS_DB" "SELECT prompt FROM responses WHERE conversation_id = '$id'" 2>/dev/null)
    response=$(sqlite3 "$LOGS_DB" "SELECT response FROM responses WHERE conversation_id = '$id'" 2>/dev/null)
    
    if [ -z "$prompt" ] || [ -z "$response" ]; then
        echo "Warning: Could not retrieve data for conversation_id: $id"
        return 1
    fi
    
    echo "$prompt" > "$target_dir/prompt.txt"
    echo "$response" > "$target_dir/response.txt"
    
    # Create agent instructions
    cat << 'AGENT_PROMPT' > "$target_dir/agent_instructions.txt"
You are an evaluation agent. Your task is to:
1. Implement any code found in response.txt
2. Test the code functionality
3. Document any fixes needed
4. Grade the response quality (A-F)

Steps:
- Extract ALL code blocks from response.txt
- Write each code block to appropriately named files
- Attempt to execute the code
- If errors occur, make MINIMAL fixes and document changes
- Compare output against prompt requirements
- Write evaluation report to test_result.txt

Report format:
1. Original code implementation status
2. Modifications made (if any)
3. Test output
4. Grade (A-F) with justification

Note: Work exclusively in this directory.

Put your final evaluation report inside <FINAL_ANSWER> tags.
AGENT_PROMPT

    echo "Starting agent evaluation for $id..."
    
    # Run agent and capture full output
    cd "$target_dir" || exit 1
    agent_output=$("$AGENT_SCRIPT" "$(cat agent_instructions.txt)
<COMMAND>
pwd
<COMMAND>
$(pwd)" \
        --prompt-file=/home/thomas/Projects/claude.sh-bak-2/DEEPBLOOM-opus.md \
        --skip-enhance \
        -m=ALTERNATE 2>&1)
    
    # Save full agent output for debugging
    echo "$agent_output" > "agent_full_output.txt"
    
    # Extract and save just the final answer
    final_answer=$(get_final_answer "$agent_output")
    
    if [ -n "$final_answer" ]; then
        echo "$final_answer" > "evaluation_report.txt"
        echo "✓ Evaluation completed for $id"
        # Print full path to the report
        echo "Report: $(realpath "evaluation_report.txt")"
    else
        echo "⚠ Warning: No <FINAL_ANSWER> tags found in agent output for $id"
        echo "  Check agent_full_output.txt for raw output"
        # Fallback: save the raw output as the report
        echo "$agent_output" > "evaluation_report.txt"
        # Print full path to the report (even if it's raw output)
        echo "Report (raw output): $(realpath "evaluation_report.txt")"
    fi

    cd - > /dev/null || exit 1
    echo "---"
}

echo "Starting evaluation process..."
echo "Logs DB: $LOGS_DB"
echo "Agent Script: $AGENT_SCRIPT"
echo "Output Directory: $EVAL_DIR"
echo "Max concurrent jobs: $MAX_CONCURRENT_JOBS"
echo ""

# Function to run a command in the background and manage job count
run_in_background() {
    # All arguments to this function are the command and its arguments
    # The actual process_response function will be called in a subshell
    (
        process_response "$@"
    ) &
    ((active_jobs++))
    # If we've hit the max, wait for one to finish
    if [[ "$active_jobs" -ge "$MAX_CONCURRENT_JOBS" ]]; then
        wait -n # Waits for any child process to finish
        ((active_jobs--))
    fi
}

# Process one iteration test
echo "Processing one iteration test..."
run_in_background "01jwv9wk52w2a2cnnrd7d4thdq" "one_iteration_test" "arbiter" "arbiter"
run_in_background "01jwv9rdj9mt9pf0fdpr3qvmsj" "one_iteration_test" "individual" "model1"
run_in_background "01jwv9r4qvjvxkwkh99y89281v" "one_iteration_test" "individual" "model2"
run_in_background "01jwv9wk31h6nqq7nvzsnevzde" "one_iteration_test" "individual" "model3"

# Process two iteration test - Round 1
echo "Processing two iteration test - Round 1..."
run_in_background "01jwv9t6zyhxnhq0dxypm1ah4z" "two_iteration_test" "round1" "arbiter"
run_in_background "01jwv9t6y2a66g3wt3hs6f0qv9" "two_iteration_test" "round1" "model1"
run_in_background "01jwv9r30shqkxvkdb7825gv4m" "two_iteration_test" "round1" "model2"
run_in_background "01jwv9rj1pgnq7xaaem20ms65t" "two_iteration_test" "round1" "model3"

# Process two iteration test - Round 2
echo "Processing two iteration test - Round 2..."
run_in_background "01jwva2sxmbzqchsdtz1yvg1k1" "two_iteration_test" "round2" "arbiter"
run_in_background "01jwva0q2ax8dfxf37zkq6x3ze" "two_iteration_test" "round2" "model1"
run_in_background "01jwva08t7gwc14267b3n9s303" "two_iteration_test" "round2" "model2"
run_in_background "01jwva2swsw4crwnhkm2bh6vyf" "two_iteration_test" "round2" "model3"

# Wait for all remaining background jobs to complete
echo "Waiting for remaining jobs to finish ($active_jobs jobs)..."
while [[ "$active_jobs" -gt 0 ]]; do
    wait -n
    ((active_jobs--))
    echo "A job finished, $active_jobs jobs remaining."
done

echo ""
echo "All evaluations completed!"
echo "Results saved to: $EVAL_DIR"
echo ""
echo "Directory structure (showing evaluation reports):"
find "$EVAL_DIR" -name "evaluation_report.txt" -exec realpath {} \; | sort