#!/usr/bin/env python3

"""
Test script for LLM Consortium with different model configurations.
This script allows you to easily test various model combinations and settings.

Usage:
  python test_consortium_models.py [options]

Options:
  --models LIST      Comma-separated list of models to use (model:count format supported)
  --arbiter MODEL    Model to use as arbiter
  --prompt TEXT      Test prompt to use (if not provided, will use default test prompts)
  --confidence FLOAT Confidence threshold (default: 0.8)
  --max-iter INT     Maximum iterations (default: 3)
  --min-iter INT     Minimum iterations (default: 1)
  --output FILE      Save results to JSON file
  --test-all         Run all predefined test scenarios
"""

import argparse
import json
import time
from datetime import datetime
from llm_consortium import create_consortium

# Default test prompts for different scenarios
TEST_PROMPTS = {
    "basic": "What is the capital of France?",
    "conflict": "Is JavaScript or Python better for web development?",
    "iteration": "Explain quantum computing in simple terms, then provide progressively more complex explanations.",
    "specialized": "What are the key considerations when designing a multi-model LLM orchestration system?",
    "long": "Write a comprehensive essay on the history and future of artificial intelligence, including key milestones, current capabilities, and ethical considerations."
}

def run_test(models, arbiter, prompt, confidence_threshold=0.8, max_iterations=3, min_iterations=1, output_file=None):
    """Run a single test with the given parameters."""
    print(f"\n{'='*80}")
    print(f"Testing with models: {models}")
    print(f"Arbiter: {arbiter}")
    print(f"Prompt: {prompt[:50]}..." if len(prompt) > 50 else f"Prompt: {prompt}")
    print(f"Confidence threshold: {confidence_threshold}")
    print(f"Iterations: min={min_iterations}, max={max_iterations}")
    print(f"{'='*80}\n")
    
    start_time = time.time()
    
    # Create the consortium
    orchestrator = create_consortium(
        models=models,
        confidence_threshold=confidence_threshold,
        max_iterations=max_iterations,
        min_iterations=min_iterations,
        arbiter=arbiter,
        raw=True
    )
    
    # Run the test
    try:
        result = orchestrator.orchestrate(prompt)
        
        # Display results
        print(f"\nResults:")
        print(f"  Iterations: {result['metadata']['iteration_count']}")
        print(f"  Confidence: {result['synthesis']['confidence']}")
        print(f"  Models used: {result['metadata']['models_used']}")
        print(f"  Execution time: {time.time() - start_time:.2f} seconds")
        
        # Display synthesis
        print(f"\nSynthesis:")
        print(f"{result['synthesis']['synthesis'][:500]}..." if len(result['synthesis']['synthesis']) > 500 else result['synthesis']['synthesis'])
        
        # Save results to file if specified
        if output_file:
            with open(output_file, 'w') as f:
                json.dump({
                    "prompt": prompt,
                    "models": models,
                    "arbiter": arbiter,
                    "confidence_threshold": confidence_threshold,
                    "max_iterations": max_iterations,
                    "min_iterations": min_iterations,
                    "result": result,
                    "execution_time": time.time() - start_time,
                    "timestamp": datetime.now().isoformat()
                }, f, indent=2)
            print(f"\nResults saved to {output_file}")
        
        return result
    except Exception as e:
        print(f"\nError running test: {e}")
        return None

def run_all_tests(models, arbiter, confidence_threshold=0.8, max_iterations=3, min_iterations=1):
    """Run all predefined test scenarios."""
    results = {}
    
    for name, prompt in TEST_PROMPTS.items():
        print(f"\nRunning test scenario: {name}")
        output_file = f"test_results_{name}.json"
        results[name] = run_test(
            models=models, 
            arbiter=arbiter, 
            prompt=prompt,
            confidence_threshold=confidence_threshold,
            max_iterations=max_iterations,
            min_iterations=min_iterations,
            output_file=output_file
        )
    
    return results

def main():
    parser = argparse.ArgumentParser(description="Test LLM Consortium with different model configurations")
    parser.add_argument("--models", type=str, default="claude-3-haiku:1,gpt-3.5-turbo:1",
                        help="Comma-separated list of models to use")
    parser.add_argument("--arbiter", type=str, default="claude-3-haiku",
                        help="Model to use as arbiter")
    parser.add_argument("--prompt", type=str,
                        help="Test prompt to use")
    parser.add_argument("--confidence", type=float, default=0.8,
                        help="Confidence threshold")
    parser.add_argument("--max-iter", type=int, default=3,
                        help="Maximum iterations")
    parser.add_argument("--min-iter", type=int, default=1,
                        help="Minimum iterations")
    parser.add_argument("--output", type=str,
                        help="Save results to JSON file")
    parser.add_argument("--test-all", action="store_true",
                        help="Run all predefined test scenarios")
    
    args = parser.parse_args()
    
    # Parse models list
    models = [model.strip() for model in args.models.split(",")]
    
    if args.test_all:
        run_all_tests(
            models=models,
            arbiter=args.arbiter,
            confidence_threshold=args.confidence,
            max_iterations=args.max_iter,
            min_iterations=args.min_iter
        )
    else:
        prompt = args.prompt if args.prompt else TEST_PROMPTS["basic"]
        run_test(
            models=models,
            arbiter=args.arbiter,
            prompt=prompt,
            confidence_threshold=args.confidence,
            max_iterations=args.max_iter,
            min_iterations=args.min_iter,
            output_file=args.output
        )

if __name__ == "__main__":
    main()
