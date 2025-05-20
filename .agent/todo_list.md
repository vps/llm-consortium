# LLM Consortium - Next Steps TODO List

## Phase 1: Stabilize & Enhance Core

1.  **[BUGFIX] Fix Arbiter Response Parsing:**
    *   **Goal:** Ensure the final synthesis and analysis are correctly extracted from the arbiter's response.
    *   **Tasks:**
        *   Investigate why `_parse_arbiter_response` often fails (resulting in "No synthesis found").
        *   Examine raw arbiter responses logged in the `responses` table (or debug logs).
        *   Refine the regex patterns in `_parse_arbiter_response` for more robustness.
        *   *Alternatively/Additionally:* Consider refining `arbiter_prompt.xml` to encourage stricter adherence to the output format by the arbiter model.
        *   Test with various prompts and arbiter models.

2.  **[FEATURE] Implement Evaluation Metric Calculation:**
    *   **Goal:** Calculate and potentially store key evaluation metrics based on the new database schema.
    *   **Tasks:**
        *   Review `.agent/evaluation_metrics.md` and prioritize specific metrics to implement first (e.g., duration, iterations, final confidence, confidence progression).
        *   Decide on storage strategy:
            *   Option A: Add an `evaluation_metrics` JSON column to `consortium_runs` and update it post-run.
            *   Option B: Create a new `evaluation_results` table linked to `run_id`.
            *   Option C: Calculate metrics on-demand via API calls (simpler initially, potentially slower later).
        *   Implement Python functions to query the DB and perform calculations.
        *   Integrate calculations into the `ConsortiumOrchestrator` or create a separate evaluation script/module.

## Phase 2: Dashboard Development

3.  **[FEATURE] Dashboard Backend API:**
    *   **Goal:** Create a REST API to serve data for the web dashboard.
    *   **Tasks:**
        *   Choose a framework (e.g., FastAPI, Flask).
        *   Design API endpoints:
            *   `GET /runs`: List recent consortium runs (with status, basic info).
            *   `GET /runs/{run_id}`: Get full details for a specific run (metadata, iteration history, linked response IDs).
            *   `GET /responses/{response_id}`: Get details of a specific response (prompt, response text).
            *   `GET /configs`: List saved consortium configurations.
            *   `POST /configs`: Save a new consortium configuration.
            *   `DELETE /configs/{name}`: Remove a saved configuration.
            *   `POST /runs`: (Optional) Trigger a new consortium run via the API.
            *   `GET /runs/{run_id}/evaluations`: (Optional) Endpoint for calculated metrics if not stored directly.
        *   Implement API logic using `sqlite-utils` to query the database.

4.  **[FEATURE] Dashboard Frontend:**
    *   **Goal:** Build a web UI for interacting with the consortium.
    *   **Tasks:**
        *   Design UI mockups/wireframes.
        *   Choose a frontend framework (React was suggested).
        *   Implement components for:
            *   Listing/searching past runs.
            *   Visualizing a single run's details (prompt, config, iterations, model responses, arbiter feedback, confidence progression). Allow showing/hiding details.
            *   Creating/saving/loading consortium configurations.
            *   Triggering new runs.
            *   Displaying calculated evaluation metrics (tables, charts).

## Phase 3: Documentation & Refinement

5.  **[DOCS] Update Project README:**
    *   **Goal:** Document the new features, database schema, and usage for end-users and developers.
    *   **Tasks:**
        *   Explain the new logging system and database tables.
        *   Update CLI usage examples.
        *   Document available evaluation metrics and how to access them (if applicable).
        *   Add instructions for setting up/running the dashboard (once built).

6.  **[REFACTOR] Code Cleanup & Optimization:**
    *   **Goal:** Review the codebase for potential improvements.
    *   **Tasks:**
        *   Refactor complex functions for clarity.
        *   Optimize database queries if performance issues arise.
        *   Add more unit/integration tests.