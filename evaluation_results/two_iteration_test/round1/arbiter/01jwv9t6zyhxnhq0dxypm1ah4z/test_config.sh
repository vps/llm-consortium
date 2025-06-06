declare -A CLERK_BASE_CIDS
declare -A CLERK_SYSTEM_PROMPTS

CLERK_BASE_CIDS["vibelab"]="01jwekxc9hc0vrqqex7dnfg9j0"
CLERK_BASE_CIDS["deep_bloom"]="01jj78cz8g5g7f2af3bsqkvsc1"
CLERK_BASE_CIDS["llm_notes"]="01jkkcyfzhpcs7aax3nc6yjpjc"

CLERK_SYSTEM_PROMPTS["vibelab_pending"]="<MACHINE_NAME>VibeLab Clerk (Pending Tasks)</MACHINE_NAME>"
CLERK_SYSTEM_PROMPTS["vibelab_completed"]="<MACHINE_NAME>VibeLab Clerk (Completed Tasks)</MACHINE_NAME>"
CLERK_SYSTEM_PROMPTS["deep_bloom"]="<MACHINE_NAME>deep-bloom concise</MACHINE_NAME>"
CLERK_SYSTEM_PROMPTS["llm_notes"]="<MACHINE_NAME>LLM CLI NOTES</MACHINE_NAME>"
