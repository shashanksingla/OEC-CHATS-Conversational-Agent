"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_action_recommender, v1.0.0. Builds context.recommendedActions each
turn: {id, label, action, subFilter, severity} entries, deduped once shown
this conversation, deprioritizing the just-answered action/subFilter, with
excluding the action answered on the current turn.

Runtime affordances: read_context, write_context, respond().
"""

if "read_context" not in globals():
    def read_context(key):
        return None

if "write_context" not in globals():

    def write_context(key, value):
        return value

if "respond" not in globals():

    def respond(payload, **kw):
        return payload

log = print

MAX_ACTIONS = 4
EVERGREEN_ID = "next_payout"


def _ctx(key, default=None):
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


def _candidate(id_, label, action, sub_filter, severity):
    return {"id": id_, "label": label, "action": action, "subFilter": sub_filter, "severity": severity}


def _build_candidates():
    """Every possible recommended action for THIS turn's data, in no
    particular order yet -- dedup/priority/deprioritize happens after."""
    candidates = []

    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    analyzer = _ctx("attendance_risks_analyzer_py") or {}

    pending_days = snapshot.get("pending_confirmation_days", 0) or 0
    if pending_days:
        candidates.append(
            _candidate(
                "pending_confirmations",
                f"Review pending confirmations -- {pending_days} day(s)",
                "ATTENDANCE",
                "PENDING_CONFIRMATIONS",
                "URGENT",
            )
        )

    approaching = analyzer.get("approaching_absence_limits") or []
    if approaching:
        crossed_count = sum(
            1 for r in approaching if isinstance(r, dict) and r.get("status") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
        )
        severity = "URGENT" if crossed_count else "REVIEW"
        candidates.append(
            _candidate(
                "absence_limits",
                f"Review absence-limit risk -- {len(approaching)} child(ren)",
                "ATTENDANCE",
                "ABSENCE_LIMITS",
                severity,
            )
        )
        # Payout impact only makes sense once there is an actual attendance
        # risk to correlate against a payout -- never offered on its own.
        candidates.append(
            _candidate(
                "payout_impact",
                "View how these attendance risks could affect your payout",
                "ATTENDANCE",
                "PAYOUT_IMPACT",
                "REVIEW",
            )
        )

    unconfirmed = analyzer.get("unconfirmed_attendance_last_9_days") or []
    if unconfirmed:
        candidates.append(
            _candidate(
                "incomplete_attendance",
                f"Review incomplete attendance -- {len(unconfirmed)} day(s)",
                "ATTENDANCE",
                "INCOMPLETE_ATTENDANCE",
                "REVIEW",
            )
        )

    # Evergreen -- always present, never deduped away, so the list can never
    # go fully empty unless the conversation has ended.
    candidates.append(
        _candidate(EVERGREEN_ID, "View upcoming payout summary", "PAYMENT", "NEXT_PAYOUT", "INFO")
    )

    return candidates


def _rank(candidate, current_action, current_sub_filter):
    just_shown_this_turn = (
        candidate["action"] == current_action and candidate.get("subFilter") == current_sub_filter
    )
    severity_rank = {"URGENT": 0, "REVIEW": 1, "INFO": 2}.get(candidate["severity"], 3)
    return (1 if just_shown_this_turn else 0, severity_rank)


def _recommend():
    turn_request = _ctx("turnRequest") or {}
    current_action = turn_request.get("action")
    current_sub_filter = turn_request.get("subFilter")
    shown_ids = list(_ctx("shownActionIds") or [])

    candidates = _build_candidates()

    unique = []
    seen_keys = {}
    for candidate in candidates:
        key = (candidate["id"], candidate.get("action"), candidate.get("subFilter"))
        if key in seen_keys or candidate["id"] in shown_ids:
            continue
        seen_keys[key] = True
        unique.append(candidate)

    remaining = [
        c for c in unique
        if not (
            c.get("action") == current_action
            and c.get("subFilter") == current_sub_filter
            and current_action is not None
        )
    ]

    remaining.sort(key=lambda c: _rank(c, current_action, current_sub_filter))
    selected = remaining[:MAX_ACTIONS]

    new_ids = [c["id"] for c in selected]
    updated_shown = list(dict.fromkeys(shown_ids + new_ids))


_selected, _updated_shown = _recommend()
write_context("recommendedActions", _selected)
write_context("shownActionIds", _updated_shown)
respond({"recommendedActions": _selected}, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________