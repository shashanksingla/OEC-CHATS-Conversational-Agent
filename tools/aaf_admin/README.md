# AAF Admin Tooling

Permanent, reusable scripts for interacting with the live AAF admin portal
(`https://d3thytbs9a5a1.cloudfront.net`). Replaces the one-off
`_check_run*.py` / `_deploy*.py` scratch scripts that were previously created
and deleted for every diagnostic/deploy pass.

Browser automation (playwright-cli) is blocked by system policy in this
environment for reaching the AAF admin portal — these scripts use direct
authenticated HTTP calls instead (`urllib` + cookie-based login), which is
the only reliable access method here.

## Files

- `aaf_client.py` — shared login/HTTP client. Import this from any new script
  instead of re-implementing login logic.
- `fetch_run.py` — fetch a live run by ID, dump full JSON, print a diagnostic
  summary (turnRequest, recommendedActions, paymentResult, formattedResponse, etc).
- `fetch_task.py` — fetch a live task's code/version for inspection.
- `deploy_task.py` — diff a local task .py file against live, then deploy
  (bumps version, PUTs, verifies no mojibake corruption).
- `fetch_process.py` — fetch a live process definition (graph nodes/edges),
  optionally filtered to one node.
- `deploy_process.py` — patch a single decision-node branch field (e.g. an
  operator) and deploy, with a re-read verification step.

## Usage

```powershell
# Investigate a run reported by the user
py tools/aaf_admin/fetch_run.py <run_id>

# Inspect a live task before editing
py tools/aaf_admin/fetch_task.py ccare_response_formatter

# Deploy a fixed task file (shows diff, prompts for confirmation)
py tools/aaf_admin/deploy_task.py ccare_response_formatter aaf-export/tasks/python/ccare_response_formatter.py

# Deploy without the confirmation prompt (scripted use)
py tools/aaf_admin/deploy_task.py ccare_response_formatter aaf-export/tasks/python/ccare_response_formatter.py --yes

# Inspect one decision node in the process graph
py tools/aaf_admin/fetch_process.py ccare_provider_agent_process --node response_exit_gate

# Fix a decision-node branch operator/value and deploy (the substring-collision
# fix from 2026-09-29 as an example):
py tools/aaf_admin/deploy_process.py ccare_provider_agent_process response_exit_gate END operator equals
```

## Credentials

Default to the known dev portal login (`child.care` / `ChildCare@1`). Override
via environment variables if they ever change, without editing the scripts:

```powershell
$env:AAF_USERNAME = "..."
$env:AAF_PASSWORD = "..."
$env:AAF_BASE_URL = "https://..."
```

## Conventions

- `deploy_task.py` and `deploy_process.py` always diff against live before
  writing, to catch upstream drift (the live portal can be ahead of the local
  `aaf-export/` snapshot).
- Both deploy scripts verify the change actually landed (re-read after PUT),
  rather than trusting the HTTP 200 alone.
- `.cache/` (gitignored) holds dumped run/process JSON from `fetch_run.py` /
  `fetch_process.py` for later inspection — safe to delete anytime, it is
  regenerated on each fetch.
- If a structural process change is ever needed (new/removed nodes or edges,
  not just a branch field), extend `deploy_process.py` rather than writing a
  new scratch script.