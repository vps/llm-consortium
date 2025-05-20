- [] Save consortium prompts to a seperate table in llm logs db than the rest of the logs.
- [] The final prompt which uses the consortium name for the model should continue to be saved in the llm logs table.
- [] Extract evals from consortium responses. Figure out a way reliably find old consortium prompts in the logs and label or organize them.
- [] We can get the list of consortium model names and search the logs for them. 
- [] For iteration, I am considering changing the approach to take advantage of conversation prompt caching in models which support it. I think it might be best to record the conversation_id for each instance, and then reply to that conversation id with feedback. This way we would not need to explicitly construct iteration history as it would be handled by the llm python library. What do you think? Pros and cons etc?

1. [ ] Rank models by their contribution - apply regret to models that answer poorly.
2. [ ] Add multi-functional consortiums: models with tools that can be used for different tasks. web search, : 
3. [ ] Make iterations cheaper by replying to the conversation_id and taking advantage of prompt caching when available
4. [ ] Record evals for each model. elo win rate for each model. reviews. counterfactual regret (where a model is penalized for failing to answer a question that another model answered correctly)
5. [ ] Currently, when you continue last conversation in llm, if that was a consortium, it does not pass through the conevrsation history.
6. [ ] I think this is due to how the final message is constructed and saved in the logs db, the one that uses the consortium model name. I think we should stop saving that extracted response, and then the last response in the logs db will be the last arbiter response, and we can continue a conversation against that.

Here are some ideas for improving the llm-consortium tool:

        1.  Develop a plugin that automates the creation of consortium configurations by analyzing user needs and suggesting optimal model combinations.
        2.  Implement a feature to visualize the performance and decision-making process of a consortium, providing insights into model contributions and iteration outcomes.
        3.  Create a dynamic prompt optimization tool that adjusts prompts based on real-time feedback from models within the consortium, improving synthesis and results.
        4.  Introduce a "model weighting" system that allows users to prioritize certain models within the consortium based on expertise or reliability.
        5.  Design a modular system where custom synthesis strategies can be plugged in, enabling users to tailor how responses from models are combined and evaluated.
        6.  Incorporate a continuous learning mechanism that refines the arbiter's decision-making process over time based on successful consortium outcomes.
        7.  Build an interface for A/B testing different consortium configurations and system prompts to determine the most effective setup for specific tasks.
        8.  Add support for real-time collaboration, allowing multiple users to interact with and refine a consortium's output in a shared environment.

        1.  **AI-Powered Dynamic Configuration:** Develop an AI tool that dynamically selects and configures language models within the consortium based on the user's specific query, optimizing for response quality and efficiency.

        2.  **Decentralized Refinement Platform:** Create a platform where users can contribute to and vote on refinements to language model outputs, incentivizing collaborative improvement.

        3.  **Open-Source Arbiter Library:** Design an open-source library of pre-trained arbiter models, each specialized in evaluating and synthesizing responses from different model combinations.

        4.  **Automated Prompt Exploration:** Implement a system for automatically generating diverse prompts based on the initial user input, feeding these to the consortium for a wider range of potential solutions.

        5.  **Model Personality Marketplace:** Build a marketplace where users can create and share customized ensembles of language models with specific biases and expertise, facilitating targeted brainstorming.

        6.  **Confidence Calibration Technique:** Research and develop a novel "confidence calibration" technique to normalize confidence scores across different language models for more accurate synthesis.

        7.  **Hybrid AI-Human Brainstorming:** Create a platform combining human creativity with the processing power of a language model consortium for iterative idea refinement.

        8. **Adaptive Weighting System:** Explore an adaptive weighting system that adjusts model contributions based on their historical performance and query characteristics.

        9.  **Tiered Consortium System:** Implement a tiered consortium where initial prompts are run through smaller, faster models, escalating to larger consortiums for high-confidence requirements.
        10. 
- llm logs list --help              ✔  .artefacts  
Usage: llm logs list [OPTIONS]

  Show recent logged prompts and their responses

Options:
  -n, --count INTEGER         Number of entries to show - defaults to 3, use 0
                              for all
  -p, --path FILE             Path to log database
  -m, --model TEXT            Filter by model or model alias
  -q, --query TEXT            Search for logs matching this string
  --schema TEXT               JSON schema, filepath or ID
  --schema-multi TEXT         JSON schema used for multiple results
  --data                      Output newline-delimited JSON data for schema
  --data-array                Output JSON array of data for schema
  --data-key TEXT             Return JSON objects from array in this key
  --data-ids                  Attach corresponding IDs to JSON objects
  -t, --truncate              Truncate long strings in output
  -s, --short                 Shorter YAML output with truncated prompts
  -u, --usage                 Include token usage
  -r, --response              Just output the last response
  -x, --extract               Extract first fenced code block
  --xl, --extract-last        Extract last fenced code block
  -c, --current               Show logs from the current conversation
  --cid, --conversation TEXT  Show logs for this conversation ID
  --id-gt TEXT                Return responses with ID > this
  --id-gte TEXT               Return responses with ID >= this
  --json                      Output logs as JSON
  --help                      Show this message and exit.