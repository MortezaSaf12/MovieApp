#!/usr/bin/env python3
"""
generate_tests.py — Generates Swift tests using RAG + Claude Sonnet 4.5.

Two modes:
  RAG mode (recommended):
    python3 generate_tests.py \
        --query "movie recommendations genre frequency scoring" \
        --output "Movie Recommendation AppTests/Generated_FetchRecommendationsTests.swift" \
        --feature "fetchRecommendations"

  Manual mode (override RAG, specify source file directly):
    python3 generate_tests.py \
        --source "Movie Recommendation App/ViewModels/HomeViewModel.swift" \
        --output "Movie Recommendation AppTests/Generated_HomeViewModelTests.swift" \
        --feature "fetchRecommendations"

Environment variables:
    ANTHROPIC_API_KEY  — Required.
    PINECONE_API_KEY   — Required for RAG mode.

Outputs:
    - Generated Swift test file at --output path
    - hitl_logs/interactions.jsonl  — Full audit log of every API call
    - hitl_logs/budget_tracker.json — Cumulative spend tracking
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
    print("ERROR: pip install anthropic")
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
BUDGET_WARNING_THRESHOLD = 95.0
BUDGET_FILE = Path("hitl_logs/budget_tracker.json")

# Logging
LOG_DIR = Path("hitl_logs")
INTERACTION_LOG = LOG_DIR / "interactions.jsonl"

# RAG defaults
DEFAULT_TOP_K = 5

# ──────────────────────────────────────────────
# System prompt — version-controlled.
# Increment SYSTEM_PROMPT_VERSION when you edit.
# This is your primary lever for RQ1 analysis.
# ──────────────────────────────────────────────
SYSTEM_PROMPT_VERSION = "v1"

SYSTEM_PROMPT = """\
You are a senior iOS test engineer. You generate Swift test code for an iOS \
application called MovieApp that uses SwiftUI, SwiftData, and the TMDB API.

## Hard rules
- Use the **Swift Testing** framework: `import Testing`, `@Test("description")`, `#expect(...)`.
- Do NOT use XCTestCase, XCTAssert*, setUp/tearDown, or any XCTest APIs.
- Every test struct must be annotated with `@MainActor`.
- Use `@testable import Movie_Recommendation_App`.
- Import SwiftData and Foundation as needed.
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


# ──────────────────────────────────────────────
# Budget tracking
# ──────────────────────────────────────────────
def load_budget() -> dict:
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
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(BUDGET_FILE, "w") as f:
        json.dump(budget, f, indent=2)


def check_budget(budget: dict):
    spent = budget["total_cost_usd"]
    if spent >= BUDGET_LIMIT:
        print(f"BUDGET EXHAUSTED: ${spent:.4f} / ${BUDGET_LIMIT:.2f}. Aborting.")
        sys.exit(1)
    if spent >= BUDGET_WARNING_THRESHOLD:
        print(f"⚠ Budget at ${spent:.4f} / ${BUDGET_LIMIT:.2f}. "
              f"Only ${BUDGET_LIMIT - spent:.4f} remaining.")


# ──────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────
def log_interaction(record: dict):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with open(INTERACTION_LOG, "a") as f:
        f.write(json.dumps(record) + "\n")


# ──────────────────────────────────────────────
# Context retrieval (RAG or manual)
# ──────────────────────────────────────────────
def get_context_via_rag(query: str, top_k: int) -> tuple[str, list[str]]:
    """
    Use Pinecone RAG to retrieve relevant source files.
    Returns (context_string, list_of_retrieved_file_paths).
    """
    try:
        from rag_retrieve import retrieve_context
    except ImportError:
        print("ERROR: rag_retrieve.py not found. Place it in the same directory.")
        sys.exit(1)

    pinecone_key = os.environ.get("PINECONE_API_KEY")
    if not pinecone_key:
        print("ERROR: PINECONE_API_KEY not set (required for RAG mode).")
        sys.exit(1)

    context = retrieve_context(query, top_k=top_k, api_key=pinecone_key)

    # Extract file paths from the context string for logging
    retrieved_files = []
    for line in context.split("\n"):
        if line.startswith("// ── ") and "(relevance:" in line:
            path = line.split("// ── ")[1].split(" (relevance:")[0]
            retrieved_files.append(path)

    return context, retrieved_files


def get_context_manual(source_path: str) -> tuple[str, list[str]]:
    """Read a single source file directly."""
    path = Path(source_path)
    if not path.exists():
        print(f"ERROR: Source file not found: {source_path}")
        sys.exit(1)
    return path.read_text(), [source_path]


# ──────────────────────────────────────────────
# Prompt assembly
# ──────────────────────────────────────────────
def build_user_prompt(
    context: str,
    feature: str,
    reference_tests: str = "",
    feedback: str = "",
) -> str:
    """
    Assemble the user prompt from retrieved context, feature name,
    optional reference tests, and optional human feedback (for iterations).
    """
    parts = []

    parts.append(f"## Target feature\n{feature}\n")
    parts.append(f"## Source code context (retrieved via RAG)\n```swift\n{context}\n```\n")

    if reference_tests:
        parts.append(
            f"## Existing test patterns (follow these conventions)\n"
            f"```swift\n{reference_tests}\n```\n"
        )

    if feedback:
        parts.append(
            f"## Human feedback from previous iteration\n"
            f"The previous version of these tests was rejected. "
            f"Address this feedback:\n{feedback}\n"
        )

    parts.append(
        "Generate a complete Swift test file covering the target feature. "
        "Include tests for: normal behavior, edge cases, and error handling."
    )

    return "\n".join(parts)


# ──────────────────────────────────────────────
# Main generation logic
# ──────────────────────────────────────────────
def generate_tests(
    feature: str,
    output_path: str,
    query: str | None = None,
    source_path: str | None = None,
    reference_path: str | None = None,
    feedback: str | None = None,
    top_k: int = DEFAULT_TOP_K,
    iteration: int = 1,
) -> dict:
    """
    Generate tests and return a metadata dict (used by CI for PR body).
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY not set.")
        sys.exit(1)

    # Get source context — either via RAG or manual file
    if query:
        print(f"[RAG] Retrieving context for: \"{query}\" (top_k={top_k})")
        context, retrieved_files = get_context_via_rag(query, top_k)
    elif source_path:
        print(f"[Manual] Reading source: {source_path}")
        context, retrieved_files = get_context_manual(source_path)
    else:
        print("ERROR: Provide either --query (RAG) or --source (manual).")
        sys.exit(1)

    # Read reference tests if provided
    reference_tests = ""
    if reference_path:
        ref = Path(reference_path)
        if ref.exists():
            reference_tests = ref.read_text()
        else:
            print(f"WARNING: Reference file not found: {reference_path}")

    # Build prompt
    user_prompt = build_user_prompt(context, feature, reference_tests, feedback or "")

    # Check budget
    budget = load_budget()
    check_budget(budget)

    # Call Claude
    client = anthropic.Anthropic(api_key=api_key)

    print(f"\nCalling {MODEL} (temperature={TEMPERATURE})...")
    print(f"Feature: {feature}")
    print(f"Iteration: {iteration}")
    print(f"Budget: ${budget['total_cost_usd']:.4f} / ${BUDGET_LIMIT:.2f}\n")

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
        log_interaction({
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "status": "error",
            "error": str(e),
            "feature": feature,
            "model": MODEL,
            "iteration": iteration,
        })
        sys.exit(1)

    elapsed = time.time() - start_time

    # Extract generated code
    generated_code = response.content[0].text

    # Strip markdown fences if model wraps them
    if generated_code.startswith("```"):
        lines = generated_code.split("\n")
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        generated_code = "\n".join(lines)

    # Cost tracking
    input_tokens = response.usage.input_tokens
    output_tokens = response.usage.output_tokens
    call_cost = (input_tokens * INPUT_COST_PER_TOKEN) + (output_tokens * OUTPUT_COST_PER_TOKEN)

    budget["total_input_tokens"] += input_tokens
    budget["total_output_tokens"] += output_tokens
    budget["total_cost_usd"] += call_cost
    budget["call_count"] += 1
    budget["last_call_at"] = datetime.now(timezone.utc).isoformat()
    save_budget(budget)

    # Build metadata (used for PR body and logging)
    metadata = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "success",
        "model": MODEL,
        "temperature": TEMPERATURE,
        "feature": feature,
        "query": query,
        "source_path": source_path,
        "reference_path": reference_path,
        "retrieved_files": retrieved_files,
        "system_prompt_version": SYSTEM_PROMPT_VERSION,
        "iteration": iteration,
        "feedback": feedback,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": round(call_cost, 6),
        "cumulative_cost_usd": round(budget["total_cost_usd"], 6),
        "elapsed_seconds": round(elapsed, 2),
        "stop_reason": response.stop_reason,
        "output_path": output_path,
    }

    # Log full interaction (prompt + response for thesis data)
    log_record = metadata.copy()
    log_record["user_prompt"] = user_prompt
    log_record["generated_code"] = generated_code
    log_interaction(log_record)

    # Write output file
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(generated_code)

    # Print summary
    print(f"Generated: {output_path}")
    print(f"Retrieved: {', '.join(retrieved_files)}")
    print(f"Tokens:    {input_tokens} in / {output_tokens} out")
    print(f"Cost:      ${call_cost:.4f} (cumulative: ${budget['total_cost_usd']:.4f})")
    print(f"Time:      {elapsed:.1f}s")
    print(f"Stop:      {response.stop_reason}")

    # Write metadata to a file so the CI workflow can read it for the PR body
    metadata_path = LOG_DIR / "last_run_metadata.json"
    with open(metadata_path, "w") as f:
        json.dump(metadata, f, indent=2)

    return metadata


def main():
    parser = argparse.ArgumentParser(
        description="Generate Swift tests using RAG + Claude Sonnet 4.5"
    )
    parser.add_argument("--query", help="Descriptive query for RAG retrieval (recommended)")
    parser.add_argument("--source", help="Direct path to source file (overrides RAG)")
    parser.add_argument("--output", required=True, help="Where to write the generated test file")
    parser.add_argument("--feature", required=True, help="Feature name/description to test")
    parser.add_argument("--reference", default=None, help="Existing test file for style reference")
    parser.add_argument("--feedback", default=None, help="Human feedback from rejected PR")
    parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K, help="Number of files to retrieve via RAG")
    parser.add_argument("--iteration", type=int, default=1, help="Iteration number (for tracking)")

    args = parser.parse_args()

    if not args.query and not args.source:
        parser.error("Provide either --query (RAG mode) or --source (manual mode)")

    generate_tests(
        feature=args.feature,
        output_path=args.output,
        query=args.query,
        source_path=args.source,
        reference_path=args.reference,
        feedback=args.feedback,
        top_k=args.top_k,
        iteration=args.iteration,
    )


if __name__ == "__main__":
    main()
