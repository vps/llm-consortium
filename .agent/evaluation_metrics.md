# LLM Consortium Evaluation Metrics

The redesigned database schema allows for the extraction of various metrics to evaluate consortium runs and individual model performance within those runs.

## Run-Level Metrics (from `consortium_runs`)

*   **Success/Failure Status**: `status` ('completed' vs 'failed'), `error_message`.
*   **Total Duration**: Calculated from `start_timestamp` and `end_timestamp`.
*   **Number of Iterations**: `iterations_performed`.
*   **Final Confidence**: `final_confidence` (as determined by the arbiter in the last iteration).
*   **Consortium Configuration**: `consortium_config` (allows comparing performance across different model sets, arbiters, thresholds).
*   **Final Output Quality**: `final_synthesis` (can be evaluated externally or using LLM-as-judge).

## Iteration-Level Metrics (from `consortium_iterations`)

*   **Confidence Progression**: `arbiter_parsed_confidence` per `iteration_number` shows how confidence evolved.
*   **Iteration Decisions**: `arbiter_parsed_needs_iteration` shows when the arbiter decided refinement was needed.
*   **Arbiter Response Analysis**: The linked `arbiter_response_id` allows retrieval of the arbiter's full text response (from the `responses` table) for qualitative analysis (e.g., analyzing the `<analysis>`, `<dissent>`, `<refinement_areas>` tags).

## Model Response-Level Metrics (joining `consortium_iteration_responses` and `responses`)

*   **Individual Response Retrieval**: Link iterations to specific model responses in the `responses` table using `response_id`.
*   **Response Time**: `duration_ms` for individual model calls (from `responses` table).
*   **Response Quality (per Iteration)**: Analyze the `response` text linked via `consortium_iteration_responses` in the context of the arbiter's feedback for that iteration (retrieved via `consortium_iterations.arbiter_response_id`).
*   **Model Self-Assessed Confidence**: Can be extracted from the model `response` text if the model followed the `<confidence>` tag instruction (requires parsing the text from the `responses` table).
*   **Truncation Flags**: Can potentially be inferred by checking `finish_reason` in the `response_json` field of the `responses` table (if populated by the underlying model API).

## Cross-Iteration Analysis

*   **Model Improvement**: Compare a specific model instance's response (`response_id` linked through `consortium_iteration_responses`) across different `iteration_number`s within the same `run_id` to see how it reacted to arbiter feedback.
*   **Arbiter Consistency**: Analyze the `arbiter_response_id` contents across iterations for consistency in analysis and feedback.

This structure provides a solid foundation for building automated evaluation dashboards and reports.