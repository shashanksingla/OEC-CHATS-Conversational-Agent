"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Attempts to create a brand-new AAF task from a local Python file. CONFIRMED
NON-FUNCTIONAL on this portal as of 2026-09-30: POST to /admin/api/tasks
returns a 200 with an echoed body but never actually persists (task absent
from /admin/api/tasks afterward); PUT-by-id also fails with 404 ("Task not
found") for an id that doesn't already exist, i.e. PUT is update-only here,
not upsert. No confirmed API exists on this portal to create a genuinely new
task -- use list_tasks.py to check for one first.

Working alternative for "I need a new calculation/task node": repurpose an
EXISTING task's slot via deploy_task.py (deploy new code under an existing
task_id) and point the process graph's new node at that existing bound_task.
This is what ccare_calc_engine_py's process node actually does -- it is
bound_task: ccare_payment_engine, not a separately-created task.

Usage (kept for future re-verification if the portal's API changes):
    py tools/aaf_admin/create_task.py <task_id> <task_name> <local_file_path> [--timeout SECONDS] [--yes]
"""

import argparse
import os
import sys
import urllib.error

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient, contains_replacement_char  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Create a new AAF task from a local file.")
    parser.add_argument("task_id")
    parser.add_argument("task_name")
    parser.add_argument("local_file_path")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--yes", action="store_true")
    args = parser.parse_args()

    with open(args.local_file_path, "r", encoding="utf-8") as f:
        code = f.read()

    if contains_replacement_char(code):
        print("ERROR: local file contains U+FFFD (mojibake) -- refusing to create. Fix the encoding first.")
        sys.exit(1)

    client = AafClient()
    client.login()

    try:
        existing = client.get_task(args.task_id)
        print(f"Task '{args.task_id}' already exists (version {existing.get('version')}) -- use deploy_task.py instead.")
        sys.exit(1)
    except urllib.error.HTTPError as e:
        if e.code != 404:
            print(f"Unexpected error checking for existing task: HTTP {e.code}")
            sys.exit(1)

    body = {
        "id": args.task_id,
        "name": args.task_name,
        "version": "1.0.0",
        "description": "",
        "model": None,
        "model_error": None,
        "task_type": "deterministic",
        "system_prompt": "",
        "max_turns": 10,
        "code": code,
        "timeout": args.timeout,
        "allowed_tools": [],
        "knowledge_base_scope": None,
        "tags": ["Child Care"],
        "response": None,
    }

    print(f"Creating task '{args.task_id}' ({len(code)} chars of code) via PUT-by-id...")
    if not args.yes:
        answer = input("Proceed? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted.")
            sys.exit(0)

    try:
        result = client.put_task(args.task_id, body)
    except urllib.error.HTTPError as e:
        print(f"PUT failed: HTTP {e.code} {e.read()[:500]}")
        sys.exit(1)
    print(f"PUT response: version={result.get('version')}")

    verify_client = AafClient()
    try:
        verify = verify_client.get_task(args.task_id)
        print(f"VERIFIED (re-read): version={verify.get('version')} code_len={len(verify.get('code') or '')}")
    except urllib.error.HTTPError as e:
        print(f"WARNING: re-read failed (HTTP {e.code}) -- task may not have actually persisted.")
        sys.exit(1)


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________