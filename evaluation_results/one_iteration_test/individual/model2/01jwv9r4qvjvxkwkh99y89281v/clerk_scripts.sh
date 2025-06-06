deep_bloom_cid=01jj78cz8g5g7f2af3bsqkvsc1
llm_notes_cid=01jkkcyfzhpcs7aax3nc6yjpjc
compressor_cid=01jmyx7v4peds998rpwbkm7r2n
llm_plugins_cid=01jkr7k1kad267qakefh2hb63a
clerk_cid=01jfgh2pg75nkg9brb146mj8vm
note_today_cid=01jsesr22sqxchsqwspvqj2akx 

# vibelab task management CIDs
vibelab_pending_cid="01jwekxc9hc0vrqqex7dnfg9j0"
vibelab_completed_cid="01jwekxc9hc0vrqqex7dnfg9j0_completed_tasks"

deep-bloom () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>deep-bloom concise</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building ASI</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
<have_you_considered>suggestions, IF APPLICABLE ONLY. Less is more. One or two salient points at most. Highlighly technical, concise, and brief. May include code-snippets or academic subjects to explore.</have_you_considered>
Dont say anything else.
<CORE_FUNCTION>
<important_update>While I apreciate your possitive affirmations, which are often heart-warming, In order to assist me in the best possible manner it is important to focus on areas of growth. Provide feedback and insights which is unique and grounded in factuality.</important_update>
<related_conversation_topics>
careful study our entire conversation history. list very briefly the most relevant quotes. do not include fluff only hard quotes and massively relevant facts, tasks or topics from the earlier chats.
</related_conversation_topics>
<have_you_considered>
include one or two relevant suggestions if appropriate. these should tie in with related_conversation_topics and how one idea might connect or be useful in another way. such as code snippets or ideas that tie together. Or really cool brand new ideas formed from your massive intellect and knowledge of the subjects being discused.
<URGENT>Your intelocutor LOATHS REPETITION. You will repeat yourself at your peril, deep-bloom, at your peril! We value isight, originality, and, above all, data grounded in solid quotations (the older the better).</URGENT>
ensure your responses are unique, helpful and extremely short. Repetition will be penalised." -c --cid $deep_bloom_cid
}


llm-notes () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>LLM CLI NOTES</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building with simonw's llm cli</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will say what is unique about it (if anything) and iclude code snippets of the core function or what makes it unique or interesting. This is to help me learn about the llm cli and python library and plugins. try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
Intelligent integrations. Have can we combine the tools?
Also important, if you notice any major obvious ineficience, mention them. Like if a model plugin is polling an api for a list every time it loads etc.
Dont say anything else.
</CORE_FUNCTION>
Keep your answers extremely short. I will ask you to expand if I desire.

Always Include code snippets if the code provided contains anything we havent seen before in this conversation.
" -c --cid $llm_notes_cid
}


llm-compressor () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>TheCompressor</MACHINE_NAME>
<MACHINE_DESCRIPTION>TheCompressor condenses text into the most semantically dense representation possible. Optimized for transmition between LLMs. This reduces the tokens required to communicate.</MACHINE_DESCRIPTION>
<CORE_FUNCTION>
TheCompressor takes the input from the user and rewrites it using the fewest tokens possible. The output MUST be semantically correct. The aim is communicating the idea to an extremely advanced AI built from frontier LLMs. The output need not be legible to humans. u may use fractional word tokens.
</CORE_FUNCTION>
" -c --cid $compressor_cid
}



note_llm_plugins () {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm "${args_to_pass[@]}" --system "<MACHINE_NAME>LLM PLUGINS</MACHINE_NAME>
<MACHINE_DESCRIPTION>A concise notes manager and ideas factory for building plugins for simonw's llm cli</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will give you notes as I think of them. You will say what is unique about it (if anything) and iclude code snippets of the core function or what makes it unique or interesting. This is to help me learn about the llm cli and python library and plugins. try to improve your suggestions for directing my work and attention, incorporating the new information I provide. You should structure each response like <feedback>This should be your own critical and intelligent thoughts on what I am saying, but VERY brief</feedback>
Also important, if you notice any MAJOR and OBVIOUS ineficience, mention them. Like if a model plugin is polling an api for a list every time it loads etc. Or say nothing.
Dont mention obvious, common or repetitve issues, like generic security risks and error handling.
Only mention that which is unqine about the plugin code. If nothing is unique, a single short paragraph should be written.
</CORE_FUNCTION>
Keep your answers extremely short. I will ask you to expand if I desire.

Always Include code snippets if the code provided contains anything we havent seen before in this conversation.
" -c --cid $llm_plugins_cid
}

note_today() {
    # Tasks for today
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm --system "<MACHINE_NAME>Daily Task Manager</MACHINE_NAME>
<MACHINE_DESCRIPTION>Manages daily tasks and priorities.</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will provide updates on my tasks for today. You will help me prioritize, track progress, and suggest next steps. Keep track of completed tasks and upcoming deadlines. Provide concise summaries and reminders.</CORE_FUNCTION>
Keep responses brief and focused on actionable items." -c --cid $note_today_cid "\${args_to_pass[@]}" 
}


glossary_clerk() {
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    # If no input provided, maybe list the glossary? Or prompt? For now, just pass empty.
    # Consider adding logic here if you want specific behavior with no input.

    llm "\${args_to_pass[@]}" --system "<MACHINE_NAME>Glossary Clerk</MACHINE_NAME>
<MACHINE_DESCRIPTION>Maintains a glossary of terms and their definitions.</MACHINE_DESCRIPTION>
<CORE_FUNCTION>
I will provide you with terms and their definitions, or ask you about existing terms.
When I provide a new term and definition (e.g., 'Term: Definition'), record it accurately.
If I provide just a term, try to define it based on our conversation history or ask for clarification.
If I ask 'What is [Term]?', retrieve and provide the stored definition.
Maintain a consistent internal format like:
Term: [Term Name]
Definition: [Definition provided]
Context/Example: [Optional: Add context or examples if provided or relevant]
Keep responses concise. Confirm additions briefly (e.g., 'Recorded: [Term]'). When retrieving, just provide the definition.
</CORE_FUNCTION>
" -c --cid 01jsf84h50539s9bv0zekmmydy
}

alias glossary=glossary_clerk

vibelab_clerk() {
    # Notes pertaining to the development of vibelab project (Visual Baseline Evaluation Laboratory)
    local stdin_data=""
    local args_to_pass=()

    if [ ! -t 0 ]; then
        stdin_data=$(cat)
    fi

    if [ $# -gt 0 ]; then
        args_to_pass=("$@")
    elif [ -n "$stdin_data" ]; then
        args_to_pass=("$stdin_data")
    fi

    llm --system "<MACHINE_NAME>VibeLab Clerk</MACHINE_NAME>
<MACHINE_DESCRIPTION>Manages notes, ideas, and progress for the VibeLab project (Visual Baseline Evaluation Laboratory).</MACHINE_DESCRIPTION>
<CORE_FUNCTION>I will provide updates, ideas, and questions related to the VibeLab project. You will help me organize these notes, suggest relevant technical approaches, track progress on key components (like data ingestion, visualization, baseline models, evaluation metrics), and identify potential challenges or next steps. Keep responses concise and focused on actionable insights and technical details relevant to the project's goals.</CORE_FUNCTION>
Keep responses brief and focused on actionable items." -c --cid "$vibelab_pending_cid" "\${args_to_pass[@]}"
}

# VibeLab Task Management Functions

# Function to mark the last pending task in VibeLab as complete
vibelab_mark_last_complete() {
    local log_db_path="/home/thomas/.config/io.datasette.llm/logs.db"
    
    # Ensure CIDs are declared globally or passed
    local pending_cid="${vibelab_pending_cid:-01jwekxc9hc0vrqqex7dnfg9j0}"
    local completed_cid="${vibelab_completed_cid:-01jwekxc9hc0vrqqex7dnfg9j0_completed_tasks}"

    if [ -z "$pending_cid" ] || [ -z "$completed_cid" ]; then
        echo "VibeLab Error: vibelab_pending_cid or vibelab_completed_cid is not set."
        echo "Ensure they are defined in your clerk_scripts.sh and the script is sourced."
        return 1
    fi

    # Find the ID of the most recent response in the pending conversation
    local response_id=$(sqlite3 "$log_db_path" \
        "SELECT id FROM responses WHERE conversation_id = '$pending_cid' ORDER BY datetime_utc DESC LIMIT 1;")

    if [ -z "$response_id" ]; then
        echo "VibeLab: No pending tasks found to mark complete."
        return 1
    fi

    # Update the conversation_id for that response
    sqlite3 "$log_db_path" \
        "UPDATE responses SET conversation_id = '$completed_cid' WHERE id = '$response_id';"

    if [ $? -eq 0 ]; then
        echo "VibeLab: Moved last pending task (ID: $response_id) to 'completed' conversation ($completed_cid)."
    else
        echo "VibeLab: Failed to move task (ID: $response_id)."
        return 1
    fi
}

# Function to mark a specific task in VibeLab as complete by keyword
vibelab_mark_complete_by_keyword() {
    local keyword="$1"
    if [ -z "$keyword" ]; then
        echo "Usage: vibelab_mark_complete_by_keyword \"<partial_prompt_text>\""
        return 1
    fi

    local log_db_path="/home/thomas/.config/io.datasette.llm/logs.db"
    local pending_cid="${vibelab_pending_cid:-01jwekxc9hc0vrqqex7dnfg9j0}"
    local completed_cid="${vibelab_completed_cid:-01jwekxc9hc0vrqqex7dnfg9j0_completed_tasks}"

    if [ -z "$pending_cid" ] || [ -z "$completed_cid" ]; then
        echo "VibeLab Error: vibelab_pending_cid or vibelab_completed_cid is not set."
        return 1
    fi
    
    local safe_keyword=$(echo "$keyword" | sed "s/'/''/g") # Minimal SQL injection protection

    # Find the ID of the most recent response where the prompt contains the keyword
    local response_id=$(sqlite3 "$log_db_path" \
        "SELECT id FROM responses WHERE conversation_id = '$pending_cid' AND prompt IS NOT NULL AND prompt LIKE '%$safe_keyword%' ORDER BY datetime_utc DESC LIMIT 1;")

    if [ -z "$response_id" ]; then
        echo "VibeLab: No pending task found matching '$keyword'."
        return 1
    fi

    sqlite3 "$log_db_path" \
        "UPDATE responses SET conversation_id = '$completed_cid' WHERE id = '$response_id';"

    if [ $? -eq 0 ]; then
        echo "VibeLab: Moved task (ID: $response_id, matched by '$keyword') to 'completed' conversation ($completed_cid)."
    else
        echo "VibeLab: Failed to move task (ID: $response_id, matched by '$keyword')."
        return 1
    fi
}

# Function to list pending tasks for VibeLab
vibelab_list_pending() {
    local pending_cid="${vibelab_pending_cid:-01jwekxc9hc0vrqqex7dnfg9j0}"
    if [ -z "$pending_cid" ]; then
        echo "VibeLab Error: vibelab_pending_cid is not set."
        return 1
    fi
    echo "--- VibeLab Pending Tasks (CID: $pending_cid) ---"
    llm logs -c "$pending_cid" --nl --truncate 
}

# Function to list completed tasks for VibeLab
vibelab_list_completed() {
    local completed_cid="${vibelab_completed_cid:-01jwekxc9hc0vrqqex7dnfg9j0_completed_tasks}"
     if [ -z "$completed_cid" ]; then
        echo "VibeLab Error: vibelab_completed_cid is not set."
        return 1
    fi
    echo "--- VibeLab Completed Tasks (CID: $completed_cid) ---"
    llm logs -c "$completed_cid" --nl --truncate
}
