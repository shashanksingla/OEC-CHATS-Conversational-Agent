"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Shared authenticated HTTP client for the AAF admin portal (Ascend Agentic
Framework). Every other script in tools/aaf_admin/ imports from here instead
of re-implementing login + request logic.

Credentials default to the known dev portal login but can be overridden via
environment variables (AAF_BASE_URL, AAF_USERNAME, AAF_PASSWORD) without
editing this file.
"""

import json
import os
import urllib.error
import urllib.request
import http.cookiejar

DEFAULT_BASE_URL = "https://d3thytbs9a5a1.cloudfront.net"
DEFAULT_USERNAME = "child.care"
DEFAULT_PASSWORD = "ChildCare@1"


class AafClient:
    """Thin wrapper around a logged-in urllib opener for the AAF admin API.

    Usage:
        client = AafClient()
        run = client.get(f"/executor/api/runs/{run_id}")
        task = client.get(f"/admin/api/tasks/{task_id}")
        client.put(f"/admin/api/tasks/{task_id}", updated_task_dict)
    """

    def __init__(self, base_url=None, username=None, password=None):
        self.base_url = base_url or os.environ.get("AAF_BASE_URL", DEFAULT_BASE_URL)
        self.username = username or os.environ.get("AAF_USERNAME", DEFAULT_USERNAME)
        self.password = password or os.environ.get("AAF_PASSWORD", DEFAULT_PASSWORD)
        self._cj = http.cookiejar.CookieJar()
        self._opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self._cj))
        self._logged_in = False

    def login(self):
        if self._logged_in:
            return
        req = urllib.request.Request(
            self.base_url + "/admin/api/auth/login",
            data=json.dumps({"username": self.username, "password": self.password}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with self._opener.open(req, timeout=30) as resp:
            if resp.status != 200:
                raise RuntimeError(f"AAF login failed: HTTP {resp.status}")
        self._logged_in = True

    def get(self, path, timeout=30):
        """GET a path under base_url; returns parsed JSON."""
        self.login()
        req = urllib.request.Request(self.base_url + path, headers={"Accept": "application/json"})
        with self._opener.open(req, timeout=timeout) as resp:
            return json.loads(resp.read())

    def put(self, path, body, timeout=30):
        """PUT a JSON-serializable body to a path under base_url; returns parsed JSON response."""
        self.login()
        data = json.dumps(body).encode("utf-8")
        req = urllib.request.Request(
            self.base_url + path,
            data=data,
            headers={"Content-Type": "application/json", "Accept": "application/json"},
            method="PUT",
        )
        with self._opener.open(req, timeout=timeout) as resp:
            return json.loads(resp.read())

    def get_task(self, task_id):
        return self.get(f"/admin/api/tasks/{task_id}")

    def put_task(self, task_id, task_body):
        return self.put(f"/admin/api/tasks/{task_id}", task_body)

    def get_process(self, process_id):
        return self.get(f"/admin/api/processes/{process_id}")

    def put_process(self, process_id, process_body):
        return self.put(f"/admin/api/processes/{process_id}", process_body)

    def get_run(self, run_id):
        return self.get(f"/executor/api/runs/{run_id}")


def bump_version(version):
    """Increment the last dot-separated segment of a semver-like string."""
    parts = str(version).split(".")
    parts[-1] = str(int(parts[-1]) + 1)
    return ".".join(parts)


def contains_replacement_char(text):
    """True if the string contains U+FFFD, the mojibake replacement character --
    used to verify a deploy payload was not corrupted before/after transit."""
    return "\ufffd" in (text or "")

# __________________________GenAI: Generated code ends here______________________________