# LLM Consortium Handoff Document

**Date:** 2025-04-12

## 1. Project Overview

`llm-consortium` is a plugin for the `llm` CLI tool that orchestrates multiple Large Language Models (LLMs) to collaboratively solve problems using an iterative refinement process guided by an "arbiter" model.

The recent development effort focused on preparing the plugin for:
*   **Automated Evaluation:** Extracting metrics about the performance of the consortium and individual models within a run.
*   **Web Dashboard:** Laying the groundwork for a web UI to configure, run, monitor, and analyze consortium executions.

## 2. Current State & Recent Changes

The most significant change was a **complete redesign of the database logging mechanism**.

*   **New DB Schema:** Instead of trying to force a `consortium_id` into the standard `llm` `responses` table, we introduced dedicated tables:
    *   `consortium_runs`: Tracks overall run metadata.
    *   `consortium_iterations`: Tracks each iteration within a run, linking to the arbiter's response.
    *   `consortium_iteration_responses`: Links each iteration to the responses from individual models used in that iteration.
    *   **Schema Diagram:** See `.agent/db_schema.md` for a Mermaid diagram.
*   **Manual Logging:** The plugin now uses a `manual_log_response` function to directly insert records into the `responses` table for both member models and the arbiter. This bypasses potential conflicts with the base `llm` library's logging and ensures reliable capture of `response_id` values needed for linking in the new consortium tables.
*   **Evaluation Metrics Foundation:** The new schema provides the necessary data structure to query and calculate various evaluation metrics. See `.agent/evaluation_metrics.md` for potential metrics.
*   **Code Refactoring:** The main script (`llm_consortium/__init__.py`) has been significantly refactored to implement the new schema, improve error handling, and use Pydantic models for data structures.
*   **Known Issue:** Test runs often output "No synthesis found." This appears to be an issue with the arbiter model not consistently following the prompt format (especially the XML tags) or with the parsing logic (`_parse_arbiter_response` function) failing to extract the content correctly. This needs investigation but is separate from the logging/evaluation groundwork.

## 3. Key Code Locations

*   **Main Logic & Schema:** `/home/thomas/Projects/llm/plugins/Utilities/llm-consortium/llm_consortium/__init__.py`
    *   `ensure_consortium_tables`: Defines and creates the new DB tables.
    *   `manual_log_response`: Handles inserts into the `responses` table.
    *   `ConsortiumOrchestrator`: Contains the main orchestration logic.
    *   `_store_iteration_data`: Populates the new consortium tables.
    *   `_parse_arbiter_response`: Parses the arbiter's output (potential area for improvement).
*   **Prompt Templates:** Files like `arbiter_prompt.xml`, `iteration_prompt.txt`, `system_prompt.txt` in the same directory define the instructions given to the LLMs.

## 4. How to Run/Test

*   **Standard Run:** `llm consortium run "Your prompt here" -m model1:count -m model2:count --arbiter arbiter_model`
*   **Check DB:** Use `sqlite3 ~/.config/io.datasette.llm/logs.db` to inspect the `responses`, `consortium_runs`, `consortium_iterations`, and `consortium_iteration_responses` tables.
*   **Debug Log:** Check `~/.config/io.datasette.llm/consortium.log` (set to DEBUG level).

## 5. Next Steps Overview

The immediate next steps involve fixing the arbiter parsing issue, implementing the calculation and storage/display of evaluation metrics, and building the API/frontend for the web dashboard. See the detailed TODO list.