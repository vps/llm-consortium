#!/bin/bash

# Mock llm CLI

LOG_FILE="/tmp/llm_mock_activity.log"
DB_PATH_ARG=""
KNOWN_CIDS_LOG="/tmp/llm_mock_known_cids.log"
touch "$KNOWN_CIDS_LOG" # Ensure it exists

echo "Mock llm called with: $@" >> "$LOG_FILE"

if [[ "$1" == "logs" && "$2" == "path" ]]; then
    echo "$(pwd)/.local/share/llm/logs.db"
    exit 0
fi

if [[ "$1" == "logs" && "$2" == "--database" ]]; then
    DB_PATH_ARG="$3"
    echo "Mock llm: Simulating SQL update on $DB_PATH_ARG with params: $4 $5 $6 $7 $8 $9" >> "$LOG_FILE"
    echo "Mock llm: Database operation for '$DB_PATH_ARG' simulated."
    if [[ "$6" == *"_pending"* || "$6" == *"_completed"* ]]; then
        echo "Task operation on $6" > "./.local/share/llm/$6.taskmarker"
    fi
    exit 0
fi

SYSTEM_PROMPT=""
CID=""
IS_CONTINUE=0 # Flag for -c
MODEL_ARG=""
MESSAGE_ARGS=()
TEMP_ARGS=("$@") # Process arguments carefully

# First pass: extract options like -s, -c, --cid, --system, -m
# These can appear anywhere.
# The 'llm' CLI allows messages before or after options.
# E.g., llm "message" -s "prompt" OR llm -s "prompt" "message"

# Let's find the main message part first.
# It's usually the non-option arguments.
# The structure from clerk_manager.sh is: llm "message" --system "sys" --cid "cid" -c

idx=0
while [ $idx -lt ${#TEMP_ARGS[@]} ]; do
    arg="${TEMP_ARGS[$idx]}"
    case "$arg" in
        -s|--system)
            SYSTEM_PROMPT="${TEMP_ARGS[$((idx+1))]}"
            unset TEMP_ARGS[$idx]
            unset TEMP_ARGS[$((idx+1))]
            idx=$((idx+2))
            ;;
        --cid) # --cid explicitly sets the CID
            CID="${TEMP_ARGS[$((idx+1))]}"
            unset TEMP_ARGS[$idx]
            unset TEMP_ARGS[$((idx+1))]
            idx=$((idx+2))
            ;;
        -c|--continue)
            # This can be tricky. `llm -c CID` or `llm CID -c`
            # The clerk_manager.sh uses `llm ... -c` without a following CID.
            # The CID is expected to be set by --cid.
            IS_CONTINUE=1
            unset TEMP_ARGS[$idx]
            idx=$((idx+1))
            ;;
        -m|--model)
            MODEL_ARG="${TEMP_ARGS[$((idx+1))]}"
            unset TEMP_ARGS[$idx]
            unset TEMP_ARGS[$((idx+1))]
            idx=$((idx+2))
            ;;
        *)
            # If it's not an option, and CID isn't set yet, and it looks like a CID, it might be `llm <CID_VALUE> ...`
            # However, clerk_manager.sh always uses --cid. So, other args are message.
            MESSAGE_ARGS+=("$arg")
            unset TEMP_ARGS[$idx] # Not strictly necessary after adding, but good for consistency
            idx=$((idx+1))
            ;;
    esac
done

# Rebuild MESSAGE_ARGS from remaining TEMP_ARGS if any were missed (they should be unset)
# This is a bit redundant with current logic but safe.
# Actually, the above loop correctly assigns to MESSAGE_ARGS.

FULL_MESSAGE="${MESSAGE_ARGS[*]}"

echo "Mock llm processing:" >> "$LOG_FILE"
echo "  System Prompt: [$SYSTEM_PROMPT]" >> "$LOG_FILE"
echo "  CID: [$CID]" >> "$LOG_FILE"
echo "  Is Continue (-c): [$IS_CONTINUE]" >> "$LOG_FILE"
echo "  Model: [$MODEL_ARG]" >> "$LOG_FILE"
echo "  Message: [$FULL_MESSAGE]" >> "$LOG_FILE"

IS_KNOWN_CID=0
if [[ -n "$CID" ]]; then
    grep -qFx "$CID" "$KNOWN_CIDS_LOG" && IS_KNOWN_CID=1
fi

if [[ "$IS_CONTINUE" -eq 1 && "$IS_KNOWN_CID" -eq 0 && -n "$CID" ]]; then
    echo "  Mock Info: Treating '-c' for new CID '$CID' as initial creation." >> "$LOG_FILE"
    echo "$CID" >> "$KNOWN_CIDS_LOG"
elif [[ -n "$CID" && "$IS_KNOWN_CID" -eq 0 ]]; then
    echo "  Mock Info: Saw new CID '$CID' (not a continue)." >> "$LOG_FILE"
    echo "$CID" >> "$KNOWN_CIDS_LOG"
elif [[ -n "$CID" && "$IS_KNOWN_CID" -eq 1 ]]; then
    echo "  Mock Info: Continuing known CID '$CID'." >> "$LOG_FILE"
fi

if [[ -n "$CID" ]]; then
    echo "This is a mock LLM response for CID '$CID' regarding: $FULL_MESSAGE"
else
    GENERATED_CID="new_mock_cid_$(date +%s%N | shasum | head -c 10)"
    echo "This is a mock LLM response for a new conversation regarding: $FULL_MESSAGE (System: $SYSTEM_PROMPT)"
    echo "  Mock Info: Generated new CID '$GENERATED_CID'" >> "$LOG_FILE"
    echo "$GENERATED_CID"
    echo "$GENERATED_CID" >> "$KNOWN_CIDS_LOG"
fi
exit 0
