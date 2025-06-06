        #!/bin/bash

        # Source the configurations
        CONFIG_FILE_PATH="${HOME}/.config/shelllm/clerk_configs.sh"
        if [ -f "$CONFIG_FILE_PATH" ]; then
            source "$CONFIG_FILE_PATH"
        else
            echo "Error: Clerk configuration file not found at $CONFIG_FILE_PATH" >&2
            # exit 1 # Or handle appropriately
        fi

        LLM_LOG_DB_PATH_CACHE=""
        get_llm_log_db_path() {
            if [ -z "$LLM_LOG_DB_PATH_CACHE" ]; then
                LLM_LOG_DB_PATH_CACHE_RAW=$(llm logs path 2>/dev/null)
                if [ -z "$LLM_LOG_DB_PATH_CACHE_RAW" ]; then
                    echo "Error: Could not retrieve LLM logs path. Is 'llm' installed and configured?" >&2
                    return 1
                fi
                LLM_LOG_DB_PATH_CACHE="$LLM_LOG_DB_PATH_CACHE_RAW"

            fi
            echo "$LLM_LOG_DB_PATH_CACHE"
            return 0
        }

        # Generic function to run a clerk interaction
        # Usage: _run_clerk_interaction <clerk_type> <context_suffix> [llm_prompt_args...]
        # <clerk_type>: e.g., "vibelab", "deep_bloom" (maps to CLERK_BASE_CIDS)
        # <context_suffix>: e.g., "pending", "completed", "main". "main" or empty uses base CID.
        _run_clerk_interaction() {
            local clerk_type="$1"
            local context_suffix="$2"
            shift 2 # Remove clerk_type and context_suffix

            local base_cid_for_clerk="${CLERK_BASE_CIDS[$clerk_type]}"
            if [ -z "$base_cid_for_clerk" ]; then
                echo "Error: Base CID for clerk type '$clerk_type' not found in config." >&2
                return 1
            fi

            local effective_cid="$base_cid_for_clerk" # Default to base CID
            if [ -n "$context_suffix" ] && [ "$context_suffix" != "main" ]; then
                effective_cid="${base_cid_for_clerk}_${context_suffix}"
            fi

            # Determine system prompt: specific for type+suffix, or fallback to type only
            local system_prompt_key="${clerk_type}_${context_suffix}"
            local system_prompt_for_clerk="${CLERK_SYSTEM_PROMPTS[$system_prompt_key]}"
            if [ -z "$system_prompt_for_clerk" ]; then
                system_prompt_for_clerk="${CLERK_SYSTEM_PROMPTS[$clerk_type]}" # Fallback to base system prompt for the clerk type
            fi

            if [ -z "$system_prompt_for_clerk" ]; then
                echo "Error: System prompt for clerk '$clerk_type' (context: '$context_suffix') not found." >&2
                return 1
            fi

            local stdin_data=""
            local args_to_pass=("$@")

            if [ ! -t 0 ]; then # Check if stdin is not a terminal (i.e., data is piped)
                stdin_data=$(cat)
            fi

            if [ ${#args_to_pass[@]} -eq 0 ] && [ -n "$stdin_data" ]; then
                args_to_pass=("$stdin_data")
            fi
            
            # The -c flag for continuing a conversation is implicitly handled by llm using the --cid
            llm "${args_to_pass[@]}" --system "$system_prompt_for_clerk" --cid "$effective_cid" -c
        }

        ### --- Clerk Definitions ---

        # VibeLab Clerk (Example of Bifurcated Contexts)
        vibelab_clerk() {
            # Default interaction with VibeLab pending tasks
            _run_clerk_interaction "vibelab" "pending" "$@"
        }

        vibelab_add_task() {
            if [ $# -eq 0 ] && [ -t 0 ]; then echo "Usage: vibelab_add_task <task description> OR echo <task description> | vibelab_add_task"; return 1; fi
            _run_clerk_interaction "vibelab" "pending" "New Task: $*"
            echo "Task added to VibeLab pending context (${CLERK_BASE_CIDS["vibelab"]}_pending)."
        }

        vibelab_review_completed() {
            _run_clerk_interaction "vibelab" "completed" "$@"
        }

        vibelab_complete_task() {
            local task_id_or_keywords="$1"
            if [ -z "$task_id_or_keywords" ]; then
                echo "Usage: vibelab_complete_task <response_id_of_task | keywords_to_find_task>"
                echo "Tip: Use 'llm logs -c ${CLERK_BASE_CIDS["vibelab"]}_pending -n 10' to find recent task IDs."
                return 1
            fi

            local db_path=$(get_llm_log_db_path)
            if [ $? -ne 0 ]; then return 1; fi # Error message already printed by get_llm_log_db_path

            local pending_cid="${CLERK_BASE_CIDS["vibelab"]}_pending"
            local completed_cid="${CLERK_BASE_CIDS["vibelab"]}_completed"
            local task_response_id=""

            # Check if input is a plausible LLM response ID (26 char, alphanumeric)
            if [[ "$task_id_or_keywords" =~ ^[0-9a-zA-Z]{26}$ ]]; then
                task_response_id_check=$(sqlite3 "$db_path" "SELECT id FROM responses WHERE id='$task_id_or_keywords' AND conversation_id='$pending_cid' LIMIT 1;")
                if [ -n "$task_response_id_check" ]; then
                    task_response_id="$task_response_id_check"
                fi
            fi

            if [ -z "$task_response_id" ]; then
                echo "Searching for task by keywords: '$task_id_or_keywords' in $pending_cid"
                # simplistic keyword search, might need fzf or more advanced search for robustness
                task_response_id=$(sqlite3 "$db_path" "SELECT id FROM responses WHERE conversation_id='$pending_cid' AND (prompt LIKE '%$task_id_or_keywords%' OR response LIKE '%$task_id_or_keywords%') ORDER BY datetime_utc DESC LIMIT 1;")
                if [ -z "$task_response_id" ]; then
                    echo "Error: Task not found with ID or keywords '$task_id_or_keywords' in VibeLab pending context ($pending_cid)."
                    return 1
                fi
                echo "Found task with ID: $task_response_id matching keywords."
            fi
            
            sqlite3 "$db_path" "UPDATE responses SET conversation_id='${completed_cid}' WHERE id='${task_response_id}';"
            
            if [ $? -eq 0 ]; then
                echo "Task (ID: $task_response_id) moved from VibeLab pending ($pending_cid) to completed ($completed_cid) context."
                local task_prompt_content=$(sqlite3 "$db_path" "SELECT prompt FROM responses WHERE id='${task_response_id}' LIMIT 1;")
                _run_clerk_interaction "vibelab" "completed" "System Note: Task (ID: $task_response_id, Original Prompt: \"$task_prompt_content\") has been marked as completed and moved to this context."
            else
                echo "Error moving task (ID: $task_response_id)."
            fi
        }

        # Deep Bloom Clerk (Example of a Single-Context Clerk)
        deep-bloom() {
            # "main" context_suffix means it uses the CLERK_BASE_CIDS["deep_bloom"] directly.
            _run_clerk_interaction "deep_bloom" "main" "$@"
        }
        
        # LLM Notes Clerk
        llm-notes() {
            _run_clerk_interaction "llm_notes" "main" "$@"
        }

        # ... Define other clerks from your original script (compressor, note_today, glossary_clerk, note_llm_plugins) similarly using _run_clerk_interaction ...
        # For example:
        # llm_compressor() {
        #     _run_clerk_interaction "compressor" "main" "$@"
        # }
        # alias glossary=glossary_clerk
        # glossary_clerk() {
        #    _run_clerk_interaction "glossary" "main" "$@"
        # }
        ```
