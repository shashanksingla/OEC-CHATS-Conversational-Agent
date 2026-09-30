"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Deploy a local task .py file to the live AAF portal, replacing the previous
one-off "_deploy_*.py" scratch scripts. Always diffs local vs. live code
before deploying (to surface upstream drift) and verifies no mojibake
(U+FFFD) corruption landed in the deployed payload.

Usage:
    py tools/aaf_admin/deploy_task.py <task_id> <local_file_path> [--yes]

    <task_id>          e.g. ccare_response_formatter
    <local_file_path>  e.g. aaf-export/tasks/python/ccare_response_formatter.py
    --yes              Skip the confirmation prompt (for scripted use)

Always shows the diff and current->next version before writing, and refuses
to deploy if the diff is empty (nothing changed) or if the resulting payload
would contain a replacement character.
"""

import argparse
import difflib
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient, bump_version, contains_replacement_char  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Deploy a local task file to the live AAF portal.")
    parser.add_argument("task_id")
    parser.add_argument("local_file_path")
    parser.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    args = parser.parse_args()

    if not os.path.isfile(args.local_file_path):
        print(f"ERROR: local file not found: {args.local_file_path}")
        sys.exit(1)

    client = AafClient()
    live = client.get_task(args.task_id)
    live_code = live.get("code") or ""

    with open(args.local_file_path, "r", encoding="utf-8") as f:
        local_code = f.read()

    if contains_replacement_char(local_code):
        print("ERROR: local file contains U+FFFD (mojibake) -- refusing to deploy. Fix the encoding first.")
        sys.exit(1)

    diff = list(difflib.unified_diff(
        live_code.splitlines(), local_code.splitlines(),
        fromfile="LIVE", tofile="LOCAL", lineterm="",
    ))

    old_version = live["version"]
    new_version = bump_version(old_version)

    print(f"task_id: {args.task_id}")
    print(f"live version: {old_version}  ->  next version: {new_version}")
    print(f"diff lines: {len(diff)}")

    if not diff:
        print("No changes detected -- nothing to deploy.")
        sys.exit(0)

    print("\n".join(diff))

    if not args.yes:
        answer = input("\nDeploy this change? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted -- nothing deployed.")
            sys.exit(0)

    live["code"] = local_code
    live["version"] = new_version
    result = client.put_task(args.task_id, live)

    deployed_code = result.get("code") or ""
    if contains_replacement_char(deployed_code):
        print("WARNING: deployed payload contains U+FFFD -- verify manually, this should not happen.")
    else:
        print("Verified: no U+FFFD corruption in deployed payload.")

    print(f"DEPLOYED {args.task_id}: {old_version} -> {result.get('version')}")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________