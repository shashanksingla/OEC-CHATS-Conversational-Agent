"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Fetch a live AAF run and print a diagnostic summary (status, node,
turnRequest, recommendedActions, paymentResult, formattedResponse). Always
dumps the full run JSON to a local file for deeper inspection.

Usage:
    py tools/aaf_admin/fetch_run.py <run_id> [--out path] [--full]

    --out   Where to write the full run JSON. Default: tools/aaf_admin/.cache/run_<id>.json
    --full  Also print the full context dict (large) instead of just the summary keys.
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient  # noqa: E402

SUMMARY_KEYS = (
    "turnRequest",
    "routerClassification",
    "recommendedActions",
    "shownActionIds",
    "ccare_turn_request_finalizer_py",
    "progressMessage",
    "formattedResponse",
    "human_gate",
    "sessionState",
    "attendance_cache_gate",
    "payment_cache_gate",
    "payout_impact_gate",
    "response_exit_gate",
    "action_dispatch",
    "provider_validated_gate",
    "ccare_scope_cache_gate_py",
)


def main():
    parser = argparse.ArgumentParser(description="Fetch and summarize a live AAF run.")
    parser.add_argument("run_id", help="Run UUID from the admin/runs URL")
    parser.add_argument("--out", default=None, help="Path to dump the full run JSON")
    parser.add_argument("--full", action="store_true", help="Print the full context dict")
    args = parser.parse_args()

    client = AafClient()
    data = client.get_run(args.run_id)

    out_path = args.out or os.path.join(os.path.dirname(__file__), ".cache", f"run_{args.run_id}.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Full run JSON written to: {out_path}")

    ctx = data.get("context", {})
    print(f"\nSTATUS: {data.get('status')}   NODE: {data.get('current_node_id')}   ERROR: {data.get('error')}")
    print(f"process_ref: {data.get('process_ref')}  process_version: {data.get('process_version')}")

    if args.full:
        print("\n--- FULL CONTEXT ---")
        print(json.dumps(ctx, indent=2, ensure_ascii=False))
        return

    for key in SUMMARY_KEYS:
        if key not in ctx:
            continue
        print(f"\n---- {key} ----")
        print(json.dumps(ctx[key], indent=2, ensure_ascii=False))

    payment_result = ctx.get("paymentResult")
    if isinstance(payment_result, dict):
        summary = {k: v for k, v in payment_result.items() if k != "rows"}
        print("\n---- paymentResult (summary, rows omitted) ----")
        print(json.dumps(summary, indent=2, ensure_ascii=False))
        print(f"rows_count: {len(payment_result.get('rows') or [])}")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________