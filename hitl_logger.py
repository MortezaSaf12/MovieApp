#!/usr/bin/env python3
"""
hitl_logger.py — Decision and budget logging for the HITL workflow.

Usage:
    python3 hitl_logger.py log-decision \
        --feature "fetchRecommendations" --iteration 1 \
        --decision "reject" --feedback "Assertions too weak" --pr-number 1

    python3 hitl_logger.py summary
    python3 hitl_logger.py budget
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

LOG_DIR = Path("hitl_logs")
INTERACTION_LOG = LOG_DIR / "interactions.jsonl"
DECISION_LOG = LOG_DIR / "decisions.jsonl"
BUDGET_FILE = LOG_DIR / "budget_tracker.json"

BUDGET_LIMIT = 100.0


def log_decision(feature: str, iteration: int, decision: str,
                 feedback: str = "", pr_number: int = 0):
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "feature": feature,
        "iteration": iteration,
        "decision": decision,
        "feedback": feedback,
        "pr_number": pr_number,
    }

    with open(DECISION_LOG, "a") as f:
        f.write(json.dumps(record) + "\n")

    print(f"Logged: {decision} for {feature} iter {iteration} (PR #{pr_number})")


def print_summary():
    interactions = []
    if INTERACTION_LOG.exists():
        with open(INTERACTION_LOG) as f:
            for line in f:
                line = line.strip()
                if line:
                    interactions.append(json.loads(line))

    decisions = []
    if DECISION_LOG.exists():
        with open(DECISION_LOG) as f:
            for line in f:
                line = line.strip()
                if line:
                    decisions.append(json.loads(line))

    if not interactions:
        print("No interactions logged yet.")
        return

    features = {}
    for entry in interactions:
        if entry.get("status") != "success":
            continue
        feat = entry.get("feature", "unknown")
        if feat not in features:
            features[feat] = []
        features[feat].append(entry)

    decision_lookup = {}
    for d in decisions:
        key = (d["feature"], d["iteration"])
        decision_lookup[key] = d

    print("=" * 90)
    print("HITL WORKFLOW SUMMARY")
    print("=" * 90)

    total_cost = 0
    total_calls = 0

    for feat, entries in sorted(features.items()):
        print(f"\nFeature: {feat}")
        print("-" * 80)
        print(f"{'Iter':<6} {'Tokens In':<12} {'Tokens Out':<12} {'Cost ($)':<10} {'Stop':<12} {'Decision':<10} {'Time (s)':<10}")
        print("-" * 80)

        for entry in sorted(entries, key=lambda x: x.get("iteration", 0)):
            iteration = entry.get("iteration", "?")
            tokens_in = entry.get("input_tokens", 0)
            tokens_out = entry.get("output_tokens", 0)
            cost = entry.get("cost_usd", 0)
            stop = entry.get("stop_reason", "?")
            elapsed = entry.get("elapsed_seconds", 0)

            decision_record = decision_lookup.get((feat, iteration))
            decision = decision_record["decision"] if decision_record else "pending"

            print(f"{iteration:<6} {tokens_in:<12} {tokens_out:<12} {cost:<10.4f} {stop:<12} {decision:<10} {elapsed:<10.1f}")

            total_cost += cost
            total_calls += 1

    print("\n" + "=" * 90)
    print(f"Total API calls: {total_calls}")
    print(f"Total cost:      ${total_cost:.4f}")
    print(f"Budget used:     {total_cost / BUDGET_LIMIT * 100:.1f}%")
    print(f"Budget remaining: ${BUDGET_LIMIT - total_cost:.4f}")
    print("=" * 90)

    feedback_entries = [d for d in decisions if d.get("feedback")]
    if feedback_entries:
        print("\n\nFEEDBACK HISTORY (for RQ2 analysis)")
        print("-" * 80)
        for d in feedback_entries:
            print(f"\n[{d['feature']} iter {d['iteration']}] {d['decision'].upper()}")
            print(f"  PR: #{d['pr_number']}")
            print(f"  Feedback: {d['feedback']}")


def print_budget():
    if not BUDGET_FILE.exists():
        print("No budget data yet.")
        return

    with open(BUDGET_FILE) as f:
        budget = json.load(f)

    spent = budget["total_cost_usd"]
    calls = budget["call_count"]
    remaining = BUDGET_LIMIT - spent

    print(f"Budget:    ${spent:.4f} / ${BUDGET_LIMIT:.2f} ({spent/BUDGET_LIMIT*100:.1f}% used)")
    print(f"Remaining: ${remaining:.4f}")
    print(f"API calls: {calls}")
    if calls > 0:
        print(f"Avg cost:  ${spent/calls:.4f}/call")

    if spent >= BUDGET_LIMIT * 0.8:
        print(f"\nWARNING: Over 80% of budget consumed.")


def main():
    parser = argparse.ArgumentParser(description="HITL workflow logger")
    subparsers = parser.add_subparsers(dest="command", required=True)

    log_parser = subparsers.add_parser("log-decision", help="Log an accept/reject decision")
    log_parser.add_argument("--feature", required=True)
    log_parser.add_argument("--iteration", type=int, required=True)
    log_parser.add_argument("--decision", required=True, choices=["accept", "reject"])
    log_parser.add_argument("--feedback", default="")
    log_parser.add_argument("--pr-number", type=int, default=0)

    subparsers.add_parser("summary", help="Print interaction summary")
    subparsers.add_parser("budget", help="Print budget status")

    args = parser.parse_args()

    if args.command == "log-decision":
        log_decision(args.feature, args.iteration, args.decision,
                     args.feedback, args.pr_number)
    elif args.command == "summary":
        print_summary()
    elif args.command == "budget":
        print_budget()


if __name__ == "__main__":
    main()
