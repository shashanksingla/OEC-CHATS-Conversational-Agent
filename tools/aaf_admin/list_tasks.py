"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

List all live AAF tasks (or search by substring), for verifying whether a
task was actually created/exists, without guessing at a single task_id path.

Usage:
    py tools/aaf_admin/list_tasks.py [substring]
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from aaf_client import AafClient  # noqa: E402


def main():
    needle = sys.argv[1].lower() if len(sys.argv) > 1 else None
    client = AafClient()
    data = client.get("/admin/api/tasks")
    tasks = data if isinstance(data, list) else data.get("tasks") or data.get("data") or data.get("items") or []
    print(f"Total tasks: {len(tasks)}")
    for t in tasks:
        tid = t.get("id") if isinstance(t, dict) else str(t)
        if needle and needle not in str(tid).lower():
            continue
        print(f"  {tid}  v{t.get('version') if isinstance(t, dict) else ''}")


if __name__ == "__main__":
    main()

# __________________________GenAI: Generated code ends here______________________________