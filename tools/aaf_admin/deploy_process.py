"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Deploy a single decision-node config change to a live AAF process, replacing
the previous one-off "_fix_exit_gate.py"-style scratch scripts. Fetches the
live process, lets you patch one node's branch by index via a small inline
edit, bumps the process version, and PUTs it back -- then re-reads the
process to verify the change actually stuck.

This script is intentionally narrow (one branch field at a time) rather than
accepting an arbitrary JSON blob, so a mistyped path can't silently corrupt
the whole graph. For structural changes (new/removed nodes or edges), edit
the process JSON via fetch_process.py's dump and use deploy_process_full.py
(not yet needed as of this writing -- add it if that case comes up).

Usage:
    py tools/aaf_admin/deploy_process.py <process_id> <node_id> <branch_value> <field> <new_value> [--yes]

Example -- the response_exit_gate substring-collision fix:
    py tools/aaf_admin/deploy_process.py ccare_provider_agent_process response_exit_gate END operator equals
"""

import argparse
import sys

sys.path.insert(0, __import__("os").path.dirname(__file__))
from aaf_client import AafClient, bump_version  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Patch one branch field on one decision node and deploy.")
    parser.add_argument("process_id")
    parser.add_argument("node_id")
    parser.add_argument("branch_value", help="The branch's 'value' field used to locate it (e.g. END)")
    parser.add_argument("field", help="The branch field to change (e.g. operator)")
    parser.add_argument("new_value", help="The new value for that field")
    parser.add_argument("--yes", action="store_true", help="Skip confirmation prompt")
    args = parser.parse_args()

    client = AafClient()
    data = client.get_process(args.process_id)

    node = next((t for t in data.get("tasks") or [] if t.get("node_id") == args.node_id), None)
    if node is None:
        print(f"ERROR: node '{args.node_id}' not found in process '{args.process_id}'.")
        sys.exit(1)

    branches = (node.get("config") or {}).get("branches") or []
    branch = next((b for b in branches if b.get("value") == args.branch_value), None)
    if branch is None:
        print(f"ERROR: no branch with value='{args.branch_value}' on node '{args.node_id}'.")
        print(f"Available branches: {[b.get('value') for b in branches]}")
        sys.exit(1)

    old_value = branch.get(args.field)
    print(f"process_id: {args.process_id}   node: {args.node_id}   branch.value: {args.branch_value}")
    print(f"BEFORE: {args.field} = {old_value!r}")
    print(f"AFTER:  {args.field} = {args.new_value!r}")

    if old_value == args.new_value:
        print("No change -- field already has that value.")
        sys.exit(0)

    if not args.yes:
        answer = input("\nDeploy this change? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted -- nothing deployed.")
            sys.exit(0)

    branch[args.field] = args.new_value
    old_version = data["version"]
    data["version"] = bump_version(old_version)

    client.put_process(args.process_id, data)

    # Re-read to verify the change actually stuck, not just that the PUT returned 200.
    verify = client.get_process(args.process_id)
    verify_node = next((t for t in verify.get("tasks") or [] if t.get("node_id") == args.node_id), None)
    verify_branch = next(
        (b for b in (verify_node.get("config") or {}).get("branches") or [] if b.get("value") == args.branch_value),
        None,
    ) if verify_node else None

    if verify_branch and verify_branch.get(args.field) == args.new_value:
        print(f"\nVERIFIED (re-read): {args.field} = {verify_branch.get(args.field)!r}")
    else:
        print(f"\nWARNING: re-read did not confirm the change -- got {verify_branch!r}")

    print(f"DEPLOYED {args.process_id}: {old_version} -> {verify.get('version')}")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________