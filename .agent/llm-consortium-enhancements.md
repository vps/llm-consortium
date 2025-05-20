# LLM Consortium Enhancements Tracking

## Project Goal

Enhance the `llm-consortium` plugin to:
1.  Facilitate extracting automated model evaluations from the consortium process.
2.  Lay the groundwork for a web dashboard to manage and run consortiums.
3.  Reconsider and potentially redesign how consortium runs are logged.

## Summary of Work Done (Phase 1 - Logging Redesign)

*   **Analysis**: Analyzed original code, prompts, and logging limitations. Determined that modifying the base `llm` logging was unreliable.
*   **Redesign**: Proposed and implemented a new database schema with dedicated tables: `consortium_runs`, `consortium_iterations`, `consortium_iteration_responses`. Schema diagram available in `.agent/db_schema.md`.
*   **Implementation**: Refactored `llm_consortium/__init__.py` (v0.6.0+) to:
    *   Use `manual_log_response` function for direct inserts into the `responses` table, capturing response IDs.
    *   Populate the new consortium tables with run/iteration data and link them correctly using the captured response IDs.
    *   Improve error handling, logging, and overall structure.
*   **Verification**: Confirmed through test runs and database inspection that the new logging mechanism works correctly, storing run data and linking responses appropriately.
*   **Evaluation Foundation**: The new structure supports extracting various evaluation metrics, documented in `.agent/evaluation_metrics.md`.
*   **Dashboard Foundation**: The queryable database structure provides the necessary backend data source for a web dashboard.

## Task Breakdown & Progress

-   [X] **Phase 1: Discovery & Planning & Logging Redesign**
    -   [X] Read README.md
    -   [X] Create tracking document (`.agent/llm-consortium-enhancements.md`)
    -   [X] Examine `llm_consortium/__init__.py` (initial)
    -   [X] Examine prompt files
    -   [X] Clarify CLI syntax
    -   [X] Analyze original logging mechanism (sqlite schema)
    -   [X] Research LLM evaluation techniques & dashboard design
    -   [X] Identify issues with original logging approach (`consortium_id` injection failed)
    -   [X] Design new DB schema (dedicated tables)
    -   [X] Implement new DB schema and manual logging logic (`__init__.py` v0.6.0+)
    -   [X] Test and verify new logging mechanism
    -   [X] Create schema diagram (`.agent/db_schema.md`)
    -   [X] Document derivable evaluation metrics (`.agent/evaluation_metrics.md`)
-   [ ] **Phase 2: Evaluation & Stabilization (Next Steps)**
    -   [ ] **Fix Arbiter Parsing:** Investigate and fix the "No synthesis found" issue (likely in `_parse_arbiter_response` or `arbiter_prompt.xml`).
    -   [ ] **Implement Metric Calculation:** Choose metrics and implement logic to calculate/store/retrieve them (e.g., add `evaluation_metrics` to `consortium_runs` or create new table).
-   [ ] **Phase 3: Dashboard Development**
    -   [ ] Develop dashboard backend API (FastAPI/Flask).
    -   [ ] Develop dashboard frontend (React).
-   [ ] **Phase 4: Documentation & Finalization**
    -   [ ] Update project README.md.
    -   [ ] Add design/architecture documents.
    -   [ ] Code cleanup and testing.

## Known Issues

*   **Arbiter Parsing:** The `_parse_arbiter_response` function often fails to extract `<synthesis>` and `<analysis>` content, resulting in "No synthesis found" output. Needs debugging (regex refinement or prompt adjustment).

## Agent Self-Tracking (Meta)

-   **Goal:** Test DEEPBLOOM capabilities and agent harness features.
-   **Plan:**
    *   Use various `shelllm` functions (`shelp`, `code_refactor`, `structured_chain_of_thought`, `task_plan_generator`, `search_engineer`). _(Note: Some failed due to external quota issues)._
    *   Utilize different LLM models and consortiums. _(Used basic models for testing)._
    *   Engage user with `kdialog`. _(Not needed in this phase)._
    *   Create diagrams using markdown/mermaid. _(Done for DB schema)._`)._
    *   Maintain this section in the tracking doc. _(Done)._
-   **Log:**
    -   Turn 1-7: Initial analysis, research, proposed logging redesign.
    -   Turn 8-16: Attempted implementation of `consortium_id` injection, faced multiple errors (Pydantic validation, DB update failures), debugged using logs and direct DB queries.
    -   Turn 17-18: Pivoted to major redesign using dedicated tables and manual logging.
    -   Turn 19-25: Implemented and tested the new logging system, verifying its success through DB queries.
    -   Turn 26: Generated final documentation (schema, metrics) and updated tracking doc.