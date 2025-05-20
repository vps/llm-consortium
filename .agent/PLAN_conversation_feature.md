# Plan: Adding Conversation Continuation Support to llm-consortium

## 1. Goal
Modify `/home/thomas/Projects/llm/plugins/Utilities/llm-consortium/llm_consortium/__init__.py` to enable the consortium plugin to load and utilize conversation history when a `conversation_id` is provided via the `llm` command line (e.g., `llm -m consortium_model -c --cid <id> "prompt"`).

## 2. Assumptions
*   The `llm` CLI tool passes the `conversation_id` (specified via `--cid`) to the plugin instance's execution method (likely `__call__`) within its `**kwargs`.
*   The standard `llm` conversation log database (`~/.config/io.datasette.llm/logs.db`) is accessible and structured as expected by `llm.load_conversation`.

## 3. Implementation Steps (`llm_consortium/__init__.py`)

### 3.1. Import Necessary Function
Add the `load_conversation` function from the `llm` library at the beginning of the file:
```python
# Add this import near existing llm imports
from llm import load_conversation, Response, Conversation
import logging # Ensure logging is imported if not already

# Get a logger instance (or use an existing one if the plugin already has one)
logger = logging.getLogger(__name__)
```
*(Self-correction: Also added `Response`, `Conversation` for potential type hinting or direct use, and `logging` for error messages.)*

### 3.2. Modify `ConsortiumModel.__call__` (or equivalent entry point)
The primary method called by `llm` when the plugin is invoked needs to:
*   Accept `**kwargs`.
*   Extract `conversation_id` from `kwargs`.
*   Pass `conversation_id` to the `ConsortiumOrchestrator` during initialization.

```python
# Inside the ConsortiumModel class (or equivalent plugin entry class)
# Assuming a method like __call__ or execute is the entry point:
# Adjust method signature if needed
def __call__(self, prompt: str, **kwargs) -> Response: # Example signature
    conversation_id = kwargs.get("conversation_id") # Extract cid

    # Ensure configuration is loaded (adjust based on actual implementation)
    # Example: config = self.load_config()

    orchestrator = ConsortiumOrchestrator(
        # Pass existing configuration parameters...
        models=self.config.get('models'),
        confidence_threshold=self.config.get('confidence_threshold', 0.7),
        max_iterations=self.config.get('max_iterations', 3),
        arbiter=self.config.get('arbiter'),
        strategy=self.config.get('strategy'),
        strategy_params=self.config.get('strategy_params', {}),
        # Pass the conversation_id
        conversation_id=conversation_id
    )

    # Existing logic to run orchestrator and return response
    # Example:
    # response_text = asyncio.run(orchestrator.orchestrate(prompt, system_prompt=self.config.get('system_prompt')))
    # return Response.fake(text=response_text, model="consortium_model", prompts=[prompt]) # Adjust response creation
    # ... rest of the method ...
```
*(Note: The exact method signature and response creation might differ based on the actual `llm-consortium` code, but the principle of extracting `conversation_id` from `kwargs` and passing it remains.)*

### 3.3. Modify `ConsortiumOrchestrator.__init__`
Update the orchestrator's constructor to accept and store the `conversation_id`.

```python
# Inside ConsortiumOrchestrator class
def __init__(self,
             models,
             confidence_threshold=0.7,
             max_iterations=3,
             arbiter=None,
             strategy=None,
             strategy_params=None,
             conversation_id=None): # Add conversation_id parameter
    self.models = models
    self.confidence_threshold = confidence_threshold
    self.max_iterations = max_iterations
    self.arbiter_model_id = arbiter
    self.strategy_name = strategy or "weighted_confidence"
    self.strategy_params = strategy_params or {}
    self.conversation_id = conversation_id # Store the conversation_id
    self.strategy = self._get_strategy(self.strategy_name)
    # ... rest of the init ...
```

### 3.4. Modify `ConsortiumOrchestrator.orchestrate`
Modify the main orchestration logic to:
*   Check if `self.conversation_id` exists.
*   If yes, call `load_conversation(self.conversation_id)`.
*   Handle potential `KeyError` or other exceptions if the conversation is not found.
*   Format the loaded conversation history (prompts and responses).
*   Prepend the formatted history to the user's current `prompt` before passing it to the consortium members.

```python
# Inside ConsortiumOrchestrator class
async def orchestrate(self, prompt: str, system_prompt: str = None) -> str:
    conversation_history_prompt = ""
    if self.conversation_id:
        try:
            logger.info(f"Loading conversation history for ID: {self.conversation_id}")
            conversation: Conversation = load_conversation(self.conversation_id)
            if conversation and conversation.responses:
                history_parts = []
                for resp in conversation.responses:
                    # Use resp.prompt.prompt for the text of the prompt
                    history_parts.append(f"Human: {resp.prompt.prompt}")
                    # Use resp.text() for the response text
                    history_parts.append(f"Assistant: {resp.text()}")
                conversation_history_prompt = "\n".join(history_parts) + "\n"
                logger.info(f"Loaded {len(conversation.responses)} prior exchanges.")
            else:
                 logger.info(f"No previous responses found for conversation ID: {self.conversation_id}")

        except KeyError:
            logger.warning(f"Conversation ID not found: {self.conversation_id}")
        except Exception as e:
            logger.error(f"Error loading conversation {self.conversation_id}: {e}", exc_info=True)

    # Prepend history (if any) to the current prompt
    full_prompt = f"{conversation_history_prompt}Human: {prompt}" if conversation_history_prompt else prompt

    # --- Existing Orchestration Logic ---
    # Use 'full_prompt' instead of 'prompt' when calling member models
    # Make sure 'system_prompt' is handled appropriately as well (passed separately usually)

    # Example modification point (conceptual):
    # results = await self.strategy.execute(
    #     orchestrator=self,
    #     prompt=full_prompt, # Use the modified prompt
    #     system_prompt=system_prompt
    # )
    # ... rest of orchestration logic ...
```

## 4. Verification
After implementation, verify the changes using `git diff /home/thomas/Projects/llm/plugins/Utilities/llm-consortium/llm_consortium/__init__.py` or `cat` the file to ensure only the planned modifications were made.

## 5. Minimal Changes Principle
This plan focuses only on adding the necessary logic for conversation loading and integration. No unrelated refactoring, variable renaming, or style changes should be included in the implementation step.