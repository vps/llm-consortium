        # In your clerk_scripts.sh
        vibelab_clerk_add_task() {
            clerk-interact "vibelab_clerk" "pending" "$@"
        }

        vibelab_clerk_list_pending() {
            local pending_cid=$(_clerk-ensure-thread "vibelab_clerk" "pending")
            echo "--- VibeLab Pending Tasks (CID: $pending_cid) ---"
            llm logs -c "$pending_cid" --nl # Or other formatting
        }

        vibelab_clerk_list_completed() {
            local completed_cid=$(_clerk-ensure-thread "vibelab_clerk" "completed")
            echo "--- VibeLab Completed Tasks (CID: $completed_cid) ---"
            llm logs -c "$completed_cid" --nl # Or other formatting
        }

        vibelab_clerk_mark_last_pending_complete() {
            local log_db_path=$(_get_llm_log_db_path)
            local pending_cid=$(_clerk-ensure-thread "vibelab_clerk" "pending")

            local response_to_move_id=$(sqlite3 "$log_db_path" \
                "SELECT id FROM responses WHERE conversation_id = '$pending_cid' ORDER BY datetime_utc DESC LIMIT 1;")

            if [ -z "$response_to_move_id" ]; then
                echo "VibeLab: No pending tasks found to mark complete."
                return 1
            fi

            clerk-move-response "$response_to_move_id" "vibelab_clerk" "completed"
            echo "VibeLab: Moved last pending task (ID: $response_to_move_id) to 'completed' thread."
        }

        # To mark a specific task by keyword (more complex, needs careful ID retrieval)
        vibelab_clerk_mark_task_complete_by_keyword() {
            local keyword="$1"
            local log_db_path=$(_get_llm_log_db_path)
            local pending_cid=$(_clerk-ensure-thread "vibelab_clerk" "pending")

            # This finds the most recent response in the pending thread matching the keyword in the prompt
            local response_to_move_id=$(sqlite3 "$log_db_path" \
                "SELECT id FROM responses WHERE conversation_id = '$pending_cid' AND prompt LIKE '%$keyword%' ORDER BY datetime_utc DESC LIMIT 1;")

            if [ -z "$response_to_move_id" ]; then
                echo "VibeLab: No pending task found matching '$keyword'."
                return 1
            fi

            clerk-move-response "$response_to_move_id" "vibelab_clerk" "completed"
            echo "VibeLab: Moved task (ID: $response_to_move_id, matched '$keyword') to 'completed' thread."
        }
