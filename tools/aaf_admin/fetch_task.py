"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Fetch a live AAF task's current code/version, for inspection or as a
pre-deploy drift check. Prints version + code length; optionally dumps the
full task JSON and/or the raw code to files.

Usage:
    py tools/aaf_admin/fetch_task.py <task_id> [--out-json path] [--out-code path]
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Fetch a live AAF task's JSON/code.")
    parser.add_argument("task_id")
    parser.add_argument("--out-json", default=None, help="Path to dump the full task JSON")
    parser.add_argument("--out-code", default=None, help="Path to dump just the task's code field")
    args = parser.parse_args()

    client = AafClient()
    data = client.get_task(args.task_id)

    print(f"task_id: {args.task_id}")
    print(f"version: {data.get('version')}")
    print(f"code length: {len(data.get('code') or '')} chars")

    if args.out_json:
        os.makedirs(os.path.dirname(args.out_json) or ".", exist_ok=True)
        with open(args.out_json, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"Full task JSON written to: {args.out_json}")

    if args.out_code:
        os.makedirs(os.path.dirname(args.out_code) or ".", exist_ok=True)
        with open(args.out_code, "w", encoding="utf-8") as f:
            f.write(data.get("code") or "")
        print(f"Task code written to: {args.out_code}")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________