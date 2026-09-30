"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Deploy a full structural process rewrite (nodes/edges added/removed) from a
local process YAML file, as opposed to deploy_process.py's narrow single-
branch-field patch. Fetches live process JSON, replaces tasks[]/edges[] with
the local YAML's, bumps version, PUTs, and re-reads to verify node/edge
counts actually landed.

Usage:
    py tools/aaf_admin/deploy_process_full.py <process_id> <local_yaml_path> [--yes]
"""

import argparse
import os
import sys

import yaml

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient, bump_version  # noqa: E402


def main():
    parser = argparse.ArgumentParser(description="Deploy a full structural process rewrite from a local YAML file.")
    parser.add_argument("process_id")
    parser.add_argument("local_yaml_path")
    parser.add_argument("--yes", action="store_true")
    args = parser.parse_args()

    with open(args.local_yaml_path, "r", encoding="utf-8") as f:
        local = yaml.safe_load(f)

    client = AafClient()
    live = client.get_process(args.process_id)

    print(f"LIVE:  version={live.get('version')} nodes={len(live.get('tasks') or [])} edges={len(live.get('edges') or [])}")
    print(f"LOCAL: nodes={len(local.get('tasks') or [])} edges={len(local.get('edges') or [])}")

    live_node_ids = {t.get("node_id") for t in (live.get("tasks") or [])}
    local_node_ids = {t.get("node_id") for t in (local.get("tasks") or [])}
    print(f"Nodes removed: {sorted(live_node_ids - local_node_ids)}")
    print(f"Nodes added:   {sorted(local_node_ids - live_node_ids)}")

    if not args.yes:
        answer = input("\nDeploy this structural change? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted.")
            sys.exit(0)

    old_version = live["version"]
    live["tasks"] = local["tasks"]
    live["edges"] = local["edges"]
    live["description"] = local.get("description", live.get("description"))
    live["version"] = bump_version(old_version)

    result = client.put_process(args.process_id, live)
    print(f"PUT response: version={result.get('version')}")

    verify = client.get_process(args.process_id)
    v_nodes = len(verify.get("tasks") or [])
    v_edges = len(verify.get("edges") or [])
    v_node_ids = {t.get("node_id") for t in (verify.get("tasks") or [])}
    print(f"VERIFIED (re-read): version={verify.get('version')} nodes={v_nodes} edges={v_edges}")
    if v_node_ids != local_node_ids:
        print(f"WARNING: verified node set differs from local. Missing: {sorted(local_node_ids - v_node_ids)}, Extra: {sorted(v_node_ids - local_node_ids)}")
    else:
        print("VERIFIED: node set matches local exactly.")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________