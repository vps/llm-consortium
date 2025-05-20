# Plan to Fix `conversation_id` Persistence in `llm-consortium`

## Problem Summary

The `llm-consortium` plugin currently fails to maintain conversation context (`conversation_id` or CID) across sequential requests. Unlike standalone models (e.g., `fast-qwq`), using a consortium model results in a new conversation starting with each prompt, ignoring previous interactions.

## Root Cause

The investigation identified two main issues within `/home/thomas/Projects/llm/plugins/Utilities/llm-consortium/llm_consortium/__init__.py`:

1.  **Missing CID Propagation:** The `conversation_id` received by `ConsortiumModel.execute` from the `llm` framework is not passed down through the `ConsortiumOrchestrator` to the individual member model calls (`model.prompt(...)`).
2.  **Missing CID Handling:** The `ConsortiumOrchestrator` methods don't explicitly manage the `conversation_id`, and the final `llm.Response` object returned by the consortium might lack the correct CID needed by the `llm` framework to continue the conversation.

## Proposed Code Modifications (`llm_consortium/__init__.py`)

The following changes are required to thread the `conversation_id` correctly through the plugin's execution flow:

1.  **Update `ConsortiumModel.execute`:**
    *   Modify the method signature or logic to explicitly capture the `conversation_id` passed by the `llm` framework (it likely arrives via `**kwargs`). Store this value (it could be `None` for the first message in a conversation).
    *   Pass this captured `conversation_id` when initializing or calling the `ConsortiumOrchestrator` (e.g., `orchestrator.orchestrate(..., conversation_id=captured_cid)`).

2.  **Update `ConsortiumOrchestrator.orchestrate`:**
    *   Modify the method signature to accept the `conversation_id` (e.g., `async def orchestrate(self, prompt_text, ..., conversation_id=None):`).
    *   Pass this `conversation_id` down when calling internal methods like `_get_model_responses`.

3.  **Update `ConsortiumOrchestrator._get_model_responses` (or similar method calling member models):**
    *   Ensure the method accepts the `conversation_id`.
    *   Modify the call to the member models' `prompt()` method to include the `conversation_id`:
        ```python
        # Inside the loop calling member models
        response = await model.prompt(
            current_prompt,
            # ... other args ...
            conversation_id=conversation_id  # Crucial addition
        )
        ```

4.  **Ensure Correct CID in Final Response:**
    *   Verify that the `llm.Response` object ultimately yielded or returned by `ConsortiumModel.execute` has its `.conversation_id` attribute correctly set to the *original* `conversation_id` received at the start of the `execute` call. This ensures the `llm` framework receives the correct ID to link the next prompt.

## Verification

After applying these changes:

1.  Run sequential `llm` commands using a consortium model.
2.  Verify that the second command correctly continues the conversation started by the first (using debug logs or by checking the `llm` database if necessary).
3.  Confirm that the CID remains consistent across related requests.
