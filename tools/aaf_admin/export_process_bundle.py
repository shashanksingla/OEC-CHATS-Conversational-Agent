"""Export a live process and its directly referenced tasks/tools to aaf-export.

Usage:
    py tools/aaf_admin/export_process_bundle.py <process_id> [--out-dir aaf-export]
"""

import argparse
import json
import os
import sys

import yaml

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient  # noqa: E402


def write_yaml(path, value):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        yaml.safe_dump(value, stream, allow_unicode=True, sort_keys=False, width=120)
    with open(path, "r", encoding="utf-8") as stream:
        yaml.safe_load(stream)


def redact_secrets(value):
    secret_keys = {"token", "access_token", "refresh_token", "password", "client_secret"}
    if isinstance(value, dict):
        return {
            key: "[REDACTED]" if key.lower() in secret_keys else redact_secrets(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [redact_secrets(item) for item in value]
    return value


def main():
    parser = argparse.ArgumentParser(description="Export a process bundle from AAF.")
    parser.add_argument("process_id")
    parser.add_argument("--out-dir", default="aaf-export")
    args = parser.parse_args()
    out_dir = os.path.abspath(args.out_dir)
    client = AafClient()

    process = client.get_process(args.process_id)
    write_yaml(os.path.join(out_dir, "process", f"{args.process_id}.yaml"), process)

    task_ids = list(dict.fromkeys(
        node.get("bound_task")
        for node in process.get("tasks", [])
        if node.get("bound_task")
    ))
    task_records = []
    tool_ids = []
    for task_id in task_ids:
        task = client.get_task(task_id)
        task_records.append(task)
        code = task.get("code") or ""
        if code:
            code_path = os.path.join(out_dir, "tasks", "python", f"{task_id}.py")
            os.makedirs(os.path.dirname(code_path), exist_ok=True)
            with open(code_path, "w", encoding="utf-8", newline="\n") as stream:
                stream.write(code)
            task["code"] = f"SEE_FILE:tasks/python/{task_id}.py"
        write_yaml(os.path.join(out_dir, "tasks", f"{task_id}.yaml"), task)
        for allowed in task.get("allowed_tools") or []:
            tool_id = allowed.get("tool") if isinstance(allowed, dict) else allowed
            if tool_id and tool_id not in tool_ids:
                tool_ids.append(tool_id)

    tool_ids.extend(
        tool_id for tool_id in process.get("tools", [])
        if tool_id not in tool_ids
    )
    for tool_id in tool_ids:
        tool = client.get(f"/admin/api/tools/{tool_id}")
        write_yaml(os.path.join(out_dir, "tools", f"{tool_id}.yaml"), redact_secrets(tool))

    manifest = {
        "kind": "ExportManifest",
        "process_id": args.process_id,
        "source": client.base_url,
        "fetched_at": __import__("datetime").datetime.now().astimezone().isoformat(),
        "process_version": process.get("version"),
        "node_count": len(process.get("tasks") or []),
        "edge_count": len(process.get("edges") or []),
        "bound_tasks": task_ids,
        "referenced_tools": tool_ids,
    }
    write_yaml(os.path.join(out_dir, "manifest-live.yaml"), manifest)
    print(json.dumps({
        "process": args.process_id,
        "version": process.get("version"),
        "nodes": len(process.get("tasks") or []),
        "edges": len(process.get("edges") or []),
        "tasks": task_ids,
        "tools": tool_ids,
        "output": out_dir,
    }, indent=2))


if __name__ == "__main__":
    main()