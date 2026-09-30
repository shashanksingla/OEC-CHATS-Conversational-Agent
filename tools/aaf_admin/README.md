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
- **Before editing any local task file, run a dry-run diff first**
  (`deploy_task.py <task_id> <local_file>` without `--yes`, answer `n`) to
  confirm local actually matches live. A local file can silently drift from
  what a task_id serves live (e.g. someone else deploying through the portal
  directly) — editing a stale local copy and deploying it overwrites real
  live changes. This happened once (2026-09-30): the local
  `ccare_payment_engine.py` had drifted to an old payment-only version while
  the live `ccare_payment_engine` task_id was actually serving the
  consolidated payment+attendance+payout-impact engine — deploying the stale
  file would have deleted `ATTENDANCE`/`STARTER` handling in production. A
  0-diff dry run against the live task_id is the cheapest way to confirm you
  are editing the right base before writing anything.

## Live task_id -> local file map (current `ccare_provider_agent_process`)

Only files referenced by a `bound_task` in the live process graph are real —
verify against `fetch_process.py <process_id>` (no `--node` filter) whenever
in doubt, not against local file *names* alone (a task_id and its serving
file's internal name can differ, as the incident above shows).

| Live task_id | Node(s) that bind it | Local file |
|---|---|---|
| `ccare_scope_cache_gate_py` | `ccare_action_shortcut_gate_py` | `tasks/python/ccare_scope_cache_gate_py.py` |
| `ccare_unified_intent_router` | `ccare_unified_intent_router` | LLM task — prompt lives in `tasks/ccare_unified_intent_router.yaml` only, no `.py` |
| `ccare_turn_request_finalizer_py` | `ccare_turn_request_finalizer_py` | `tasks/python/ccare_turn_request_finalizer_py.py` |
| `ccare_provider_data_py` | `ccare_provider_data_py` | `tasks/python/ccare_provider_data_py.py` |
| `ccare_data_collection` | `ccare_data_collection` | `tasks/python/ccare_data_collection.py` |
| `ccare_payment_engine` | `ccare_calc_engine_py` (node name differs from task_id — this is the consolidated payment+attendance-risk+payout-impact engine) | `tasks/python/ccare_payment_engine.py` |
| `ccare_response_formatter` | `ccare_response_formatter` | `tasks/python/ccare_response_formatter.py` |

Any other `.py`/`.yaml` file under `aaf-export/tasks/` not in this table is
**not wired into the current live process** — treat as dead unless a fresh
`fetch_process.py` shows otherwise. As of 2026-09-30, `attendance_risks_analyzer_py`,
`ccare_action_recommender`, `ccare_data_freshness_check_py`,
`ccare_payout_impact_correlator`, `ccare_progress_emitter`, and
`ccare_response_renderer` were removed as orphans (their logic was
consolidated into `ccare_payment_engine`/`ccare_response_formatter`/
`ccare_turn_request_finalizer_py` per the process's own 2026-09-30
consolidation description).