
### 2. Dynamic Clerk Configuration (`~/.config/shelllm/clerk_dynamic_contexts.sh`)

This file will be automatically created and populated by the `create_dynamic_clerk` function. It will store definitions for dynamically generated clerks.

Initial content (created if it doesn't exist):
```bash
#!/bin/bash
declare -A DYNAMIC_CLERK_CIDS
declare -A DYNAMIC_CLERK_SYSTEM_PROMPTS
# Dynamic clerk function definitions will be appended here.
