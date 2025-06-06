# Add pending task
vibelab "!pending Implement new visualization module"

# Complete task (moves to completed thread)
vibelab "!completed Finished visualization module"

# View pending tasks
llm logs --cid $(sqlite3 clerks.db "SELECT cid FROM threads WHERE clerk_name='vibelab' AND thread_type='pending'")

# Move specific response to completed
move_response "01HP0XKJZJQZP" $(sqlite3 clerks.db "SELECT cid FROM threads WHERE thread_type='completed'")
