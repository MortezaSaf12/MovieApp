#!/usr/bin/env python3
"""
generate_tests.py — Calls Claude Sonnet 4.5 to generate Swift test code.

Usage:
    python3 generate_tests.py \
        --source "Movie Recommendation App/ViewModels/HomeViewModel.swift" \
        --output "Movie Recommendation AppTests/Generated_HomeViewModelTests.swift" \
        --feature "fetchRecommendations"

Environment variables:
    ANTHROPIC_API_KEY — Required. Your Claude API key.

Part of the HITL workflow for LLM-assisted test generation.
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("ERROR: anthropic package not installed. Run: pip install anthropic")
    sys.exit(1)

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────
MODEL = "claude-sonnet-4-5-20250929"
TEMPERATURE = 0.0
MAX_OUTPUT_TOKENS = 8192

# Pricing (USD per token)
INPUT_COST_PER_TOKEN = 3.0 / 1_000_000
OUTPUT_COST_PER_TOKEN = 15.0 / 1_000_000

# Budget
BUDGET_LIMIT = 100.0
BUDGET_WARNING_THRESHOLD = 95.0  # Warn at $95, hard-stop at $100
BUDGET_FILE = Path("hitl_logs/budget_tracker.json")

# Logging
LOG_DIR = Path("hitl_logs")
INTERACTION_LOG = LOG_DIR / "interactions.jsonl"

# ──────────────────────────────────────────────
# System prompt — version-controlled, update as
# prompt engineering evolves (RQ1)
# ──────────────────────────────────────────────
SYSTEM_PROMPT = """\
You are a senior iOS test engineer. You generate Swift test code for an iOS \
application called MovieApp that uses SwiftUI, SwiftData, and the TMDB API.

## Hard rules
- Use the **Swift Testing** framework: `import Testing`, `@Test("description")`, `#expect(...)`.
- Do NOT use XCTestCase, XCTAssert*, setUp/tearDown, or any XCTest APIs.
- Every test struct must be annotated with `@MainActor`.
- Use `@testable import Movie_Recommendation_App`.
- Use in-memory SwiftData containers:
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: <ModelType>.self, configurations: config)
    let context = container.mainContext
- Use the existing MockAPIService pattern for API tests (see reference tests).
- Name test functions descriptively: `func testFeatureBehavior()`.
- Each test must have a clear doc comment explaining what it validates.

## Output format
- Return ONLY the Swift source code for the test file.
- Do NOT include markdown fences, explanations, or commentary.
- The file must compile and run standalone with the existing project imports.

## Quality criteria
- Tests must verify behavior, not just that code runs without crashing.
- Cover both success and failure/edge cases.
- Assert on specific expected values, not just non-nil checks.
- Each test should be independent (no shared mutable state between tests).
"""


def load_budget() -> dict:
    """Load cumulative budget tracking data."""
    if BUDGET_FILE.exists():
        with open(BUDGET_FILE, "r") as f:
            return json.load(f)
    return {
        "total_input_tokens": 0,
        "total_output_tokens": 0,
        "total_cost_usd": 0.0,
        "call_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


def save_budget(budget: dict):
    """Persist budget tracking data."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(BUDGET_FILE, "w") as f:
        json.dump(budget, f, indent=2)


def check_budget(budget: dict):
    """Abort if budget is exhausted."""
    spent = budget["total_cost_usd"]
    if spent >= BUDGET_LIMIT:
        print(f"BUDGET EXHAUSTED: ${spent:.4f} / ${BUDGET_LIMIT:.2f}. Aborting.")
        sys.exit(1)
    if spent >= BUDGET_WARNING_THRESHOLD:
        print(f"WARNING: Budget at ${spent:.4f} / ${BUDGET_LIMIT:.2f}. "
              f"Only ${BUDGET_LIMIT - spent:.4f} remaining.")


def log_interaction(record: dict):
    """Append a single interaction record to the JSONL log."""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(INTERACTION_LOG, "a") as f:
        f.write(json.dumps(record) + "\n")


def build_user_prompt(source_code: str, feature: str, reference_tests: str = "") -> str:
    """Construct the user prompt from source code and feature target."""
    prompt_parts = []

    prompt_parts.append(f"## Target feature\n{feature}\n")
    prompt_parts.append(f"## Source code under test\n```swift\n{source_code}\n```\n")

    if reference_tests:
        prompt_parts.append(
            f"## Existing reference tests (follow these patterns)\n"
            f"```swift\n{reference_tests}\n```\n"
        )

    prompt_parts.append(
        "Generate a complete Swift test file covering the target feature. "
        "Include tests for: normal behavior, edge cases, and error handling."
    )

    return "\n".join(prompt_parts)


def estimate_cost(input_tokens: int, output_tokens: int) -> float:
    """Calculate USD cost for a single API call."""
    return (input_tokens * INPUT_COST_PER_TOKEN) + (output_tokens * OUTPUT_COST_PER_TOKEN)


def generate_tests(
    source_path: str,
    output_path: str,
    feature: str,
    reference_path: str | None = None,
) -> str:
    """Call Claude API and write the generated test file."""
    # Validate API key
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY environment variable not set.")
        sys.exit(1)

    # Read source code
    source_file = Path(source_path)
    if not source_file.exists():
        print(f"ERROR: Source file not found: {source_path}")
        sys.exit(1)
    source_code = source_file.read_text()

    # Read reference tests if provided
    reference_tests = ""
    if reference_path:
        ref_file = Path(reference_path)
        if ref_file.exists():
            reference_tests = ref_file.read_text()
        else:
            print(f"WARNING: Reference test file not found: {reference_path}")

    # Build prompt
    user_prompt = build_user_prompt(source_code, feature, reference_tests)

    # Check budget before calling
    budget = load_budget()
    check_budget(budget)

    # Call Claude API
    client = anthropic.Anthropic(api_key=api_key)

    print(f"Calling {MODEL} (temperature={TEMPERATURE})...")
    print(f"Source: {source_path}")
    print(f"Feature: {feature}")
    print(f"Budget so far: ${budget['total_cost_usd']:.4f} / ${BUDGET_LIMIT:.2f}")
    print()

    start_time = time.time()

    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=MAX_OUTPUT_TOKENS,
            temperature=TEMPERATURE,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_prompt}],
        )
    except anthropic.APIError as e:
        print(f"API ERROR: {e}")
        # Log the failed attempt
        log_interaction({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "status": "error",
            "error": str(e),
            "source_path": source_path,
            "feature": feature,
            "model": MODEL,
        })
        sys.exit(1)

    elapsed = time.time() - start_time

    # Extract response
    generated_code = response.content[0].text

    # Strip markdown fences if the model wraps them anyway
    if generated_code.startswith("```"):
        lines = generated_code.split("\n")
        # Remove first and last fence lines
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        generated_code = "\n".join(lines)

    # Token usage and cost
    input_tokens = response.usage.input_tokens
    output_tokens = response.usage.output_tokens
    call_cost = estimate_cost(input_tokens, output_tokens)

    # Update budget
    budget["total_input_tokens"] += input_tokens
    budget["total_output_tokens"] += output_tokens
    budget["total_cost_usd"] += call_cost
    budget["call_count"] += 1
    budget["last_call_at"] = datetime.now(timezone.utc).isoformat()
    save_budget(budget)

    # Log interaction
    interaction_record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "success",
        "model": MODEL,
        "temperature": TEMPERATURE,
        "source_path": source_path,
        "feature": feature,
        "reference_path": reference_path,
        "system_prompt_version": "v1",  # Increment as you iterate on prompts (RQ1)
        "user_prompt": user_prompt,
        "generated_code": generated_code,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": call_cost,
        "cumulative_cost_usd": budget["total_cost_usd"],
        "elapsed_seconds": round(elapsed, 2),
        "stop_reason": response.stop_reason,
    }
    log_interaction(interaction_record)

    # Write output file
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(generated_code)

    # Print summary
    print(f"Generated: {output_path}")
    print(f"Tokens:    {input_tokens} in / {output_tokens} out")
    print(f"Cost:      ${call_cost:.4f} (cumulative: ${budget['total_cost_usd']:.4f})")
    print(f"Time:      {elapsed:.1f}s")
    print(f"Stop:      {response.stop_reason}")

    return generated_code


def main():
    parser = argparse.ArgumentParser(
        description="Generate Swift tests using Claude Sonnet 4.5"
    )
    parser.add_argument(
        "--source",
        required=True,
        help="Path to the Swift source file under test",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path where the generated test file will be written",
    )
    parser.add_argument(
        "--feature",
        required=True,
        help="Name/description of the feature to test (e.g. 'fetchRecommendations')",
    )
    parser.add_argument(
        "--reference",
        default=None,
        help="Path to existing test file to use as style reference",
    )

    args = parser.parse_args()
    generate_tests(args.source, args.output, args.feature, args.reference)


if __name__ == "__main__":
    main()
