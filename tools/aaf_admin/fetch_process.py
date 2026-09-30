"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Fetch a live AAF process definition (graph nodes/edges/decision branches),
for inspection before making a process-level fix (e.g. a decision-node
operator bug like the response_exit_gate substring-collision case).

Usage:
    py tools/aaf_admin/fetch_process.py <process_id> [--node <node_id>] [--out path]

    --node  Print only the matching node's config instead of the whole process
    --out   Path to dump the full process JSON. Default: tools/aaf_admin/.cache/process_<id>.json
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Fetch a live AAF process definition.")
    parser.add_argument("process_id")
    parser.add_argument("--node", default=None, help="Only print this node_id's config")
    parser.add_argument("--out", default=None, help="Path to dump the full process JSON")
    args = parser.parse_args()

    client = AafClient()
    data = client.get_process(args.process_id)

    out_path = args.out or os.path.join(os.path.dirname(__file__), ".cache", f"process_{args.process_id}.json")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Full process JSON written to: {out_path}")

    print(f"\nprocess_id: {data.get('id')}   version: {data.get('version')}")
    tasks = data.get("tasks") or []
    edges = data.get("edges") or []
    print(f"node_count: {len(tasks)}   edge_count: {len(edges)}")

    if args.node:
        match = next((t for t in tasks if t.get("node_id") == args.node), None)
        if match is None:
            print(f"\nNode '{args.node}' not found.")
            sys.exit(1)
        print(f"\n---- node: {args.node} ----")
        print(json.dumps(match, indent=2, ensure_ascii=False))
        related_edges = [e for e in edges if e.get("from") == args.node or e.get("to") == args.node]
        print(f"\n---- edges touching this node ({len(related_edges)}) ----")
        print(json.dumps(related_edges, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________