"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_response_formatter, v1.3.0. Merged with ccare_action_recommender
(2026-09-26, less process-graph visual complexity) -- this task now computes
recommendedActions AND builds every Markdown table/count/disclaimer in one
deterministic pass. Canonical columns: Child | Authorization | County |
Service date | Attendance type | Status | Scheduled/Attended/Care hours |
Amount | Amount type | Reason.

Runtime affordances: read_context, write_context, respond().
"""

import json
import re
from decimal import Decimal

if "read_context" not in globals():
    _STATE: dict = {}

    def read_context(key):
        return _STATE.get(key)

if "write_context" not in globals():

    def write_context(key, value):
        return value

if "respond" not in globals():

    def respond(payload, **kw):
        return payload

log = print

DISCLAIMER_GLOBAL = (
    "*⚠️ Amounts shown are estimates based on current attendance, authorizations, and fiscal rates on file. "
    "Final amounts are determined at county payment processing.*"
)

TABLE_ROW_LIMIT = 5

SEVERITY_LABEL = {"URGENT": "[Urgent]", "REVIEW": "[Review]", "INFO": "[Info]"}
_MONTH_ABBR = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
_MONTH_FULL = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
CONFIRMATION_WINDOW_DAYS = 9

MAX_ACTIONS = 3
FULL_BREAKDOWN_ID = "view_full_breakdown"



def _ctx(key, default=None):
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


# ==============================================================================
# RECOMMENDED ACTIONS (merged from ccare_action_recommender, v1.1.0)
# ==============================================================================

def _candidate(id_, label, action, sub_filter, severity):
    return {"id": id_, "label": label, "action": action, "subFilter": sub_filter, "severity": severity}


def _distinct_child_count(rows):
    keys = {
        str(row.get("child_id") or row.get("child_name")).strip()
        for row in rows
        if isinstance(row, dict) and (row.get("child_id") or row.get("child_name"))
    }
    return len(keys)


def _absence_day_counts(rows):
    """Count near-limit absence days separately from days beyond the limit."""
    approaching_days = 0
    crossed_days = 0
    for row in rows if isinstance(rows, list) else []:
        if not isinstance(row, dict):
            continue
        confirmed_dates = {str(value) for value in row.get("confirmed_absence_dates") or [] if value}
        tentative_dates = {str(value) for value in row.get("tentative_absence_dates") or [] if value}
        try:
            confirmed_count = len(confirmed_dates) or int(row.get("confirmed_absence_count") or 0)
        except (TypeError, ValueError):
            confirmed_count = len(confirmed_dates)
        try:
            tentative_count = len(tentative_dates) or int(row.get("tentative_absence_count") or 0)
        except (TypeError, ValueError):
            tentative_count = len(tentative_dates)
        try:
            limit = int(row.get("absence_limit") or 0)
        except (TypeError, ValueError):
            limit = 0
        status = row.get("status") or ""
        if status == "OVER_LIMIT":
            crossed_days += max(confirmed_count - limit, 0)
        elif status == "POTENTIAL_OVER_LIMIT":
            crossed_days += max(confirmed_count + tentative_count - limit, 0)
        else:
            approaching_days += confirmed_count + tentative_count
    return approaching_days, crossed_days


def _absence_finding(rows):
    child_count = _distinct_child_count(rows)
    approaching_days, crossed_days = _absence_day_counts(rows)
    if not child_count:
        return "No children currently near or over county monthly absence limits"
    return (
        f"{approaching_days} day(s) approaching the limit; "
        f"{crossed_days} day(s) over the limit across {child_count} child(ren)"
    )


def _build_candidates(current_action, current_sub_filter):
    """Every possible recommended action for THIS turn's data, in no
    particular order yet -- dedup/priority/deprioritize happens after."""
    candidates = []

    if current_action == "END":
        return candidates

    if current_action == "CLARIFY":
        return [
            _candidate("kickstart_attendance", "Check attendance and confirmations", "ATTENDANCE", "ALL", "INFO"),
            _candidate("kickstart_payment", "Review a payout or payment", "PAYMENT", "NEXT_PAYOUT", "INFO"),
            _candidate("kickstart_overview", "Show today's overview", "STARTER", None, "INFO"),
        ]

    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    payment_result = _ctx("paymentResult") or {}
    attendance_scope = current_action in ("STARTER", "ATTENDANCE")

    pending_days = snapshot.get("pending_confirmation_days", 0) or 0
    overview_scope = current_action == "STARTER" or (current_action == "ATTENDANCE" and current_sub_filter == "ALL")
    if overview_scope and pending_days:
        _conf_label = f"Confirm {pending_days} pending day(s)"
        impact_result = _ctx("payoutImpactResult") or {}
        _at_risk_amt = impact_result.get("unconfirmed_risk_amount")
        try:
            if _at_risk_amt and float(_at_risk_amt) > 0:
                _conf_label += f" — {_fmt_money(_at_risk_amt)} at risk"
        except (TypeError, ValueError):
            pass
        candidates.append(
            _candidate(
                "pending_confirmations",
                _conf_label,
                "ATTENDANCE",
                "PENDING_CONFIRMATIONS",
                "URGENT",
            )
        )
    elif attendance_scope and current_sub_filter == "PENDING_CONFIRMATIONS":
        pending_impact_rows = [
            row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
            if isinstance(row, dict)
            and row.get("risk_category") == "unconfirmed"
            and row.get("amount") is not None
        ]
        if pending_impact_rows:
            candidates.append(
                _candidate(
                    "payout_impact",
                    "See estimated payout impact of these pending days",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )

    approaching = analyzer.get("approaching_absence_limits") or [] if attendance_scope else []
    if approaching and overview_scope:
        absence_child_count = _distinct_child_count(approaching)
        approaching_days, crossed_days = _absence_day_counts(approaching)
        crossed_count = sum(
            1 for r in approaching if isinstance(r, dict) and r.get("status") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
        )
        severity = "URGENT" if crossed_count else "REVIEW"
        candidates.append(
            _candidate(
                "absence_limits",
                f"Review absence risk -- {approaching_days} day(s) approaching, {crossed_days} over limit ({absence_child_count} child(ren))",
                "ATTENDANCE",
                "ABSENCE_LIMITS",
                severity,
            )
        )
    if approaching and current_sub_filter == "ABSENCE_LIMITS":
        impact = _ctx("payoutImpactResult") or {}
        impact_rows = impact.get("rows") or []
        resolved_absence_rows = [
            row for row in impact_rows
            if isinstance(row, dict) and row.get("risk_category") == "absence" and row.get("amount") is not None
        ]
        if resolved_absence_rows:
            candidates.append(
                _candidate(
                    "payout_impact",
                    "See estimated payout impact of these absence risks",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )

    unconfirmed = analyzer.get("unconfirmed_attendance_last_9_days") or [] if attendance_scope else []
    impact_rows = (_ctx("payoutImpactResult") or {}).get("rows") or []
    incomplete_attendance = [
        row for row in impact_rows
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ] if attendance_scope else []
    if incomplete_attendance and overview_scope:
            incomplete_days = len({
                str(row.get("service_date") or row.get("date") or "").strip()
                for row in incomplete_attendance
                if row.get("service_date") or row.get("date")
            }) or len(incomplete_attendance)
            candidates.append(
                _candidate(
                    "incomplete_attendance",
                    f"Review missing check-in/check-out -- {incomplete_days} day(s)",
                    "ATTENDANCE",
                    "INCOMPLETE_ATTENDANCE",
                    "REVIEW",
                )
            )
    if incomplete_attendance and current_sub_filter == "INCOMPLETE_ATTENDANCE":
        incomplete_impact_rows = [
            row for row in incomplete_attendance
            if row.get("amount") is not None
        ]
        if incomplete_impact_rows:
            candidates.append(
                _candidate(
                    "payout_impact",
                    "See estimated payout impact of these missing records",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )
    # snapshot.risk_categories.incomplete_attendance fallback removed: its count
    # disagrees with the analyzer's authoritative result and produces false-positive
    # actions that resolve to "no records found". Only surface INCOMPLETE_ATTENDANCE
    # when the analyzer has actually run and found records.
    if overview_scope and not approaching:
        _snap_risk = (snapshot.get("risk_categories") or {})
        _snap_cross = (_snap_risk.get("crossed_absence_limits") or {})
        _snap_appr = (_snap_risk.get("approaching_absence_limits") or {})
        _snap_abs_children = (_snap_cross.get("children", 0) or 0) + (_snap_appr.get("children", 0) or 0)
        if _snap_abs_children:
            _abs_sev = "URGENT" if (_snap_cross.get("children", 0) or 0) > 0 else "REVIEW"
            candidates.append(
                _candidate(
                    "absence_limits",
                    f"Review absence-limit risk -- {_snap_abs_children} child(ren)",
                    "ATTENDANCE",
                    "ABSENCE_LIMITS",
                    _abs_sev,
                )
            )

    # Payment actions are scoped to a payment turn. paymentResult may remain
    # cached after a prior payment request and must not create actions for an
    # attendance, explanation, or starter response.
    if current_action != "PAYMENT":
        payment_result = {}

    # Payment scenario actions -- locked per the scenario table (Section C):
    # settled/blocked get their own action; a normal calculated/at-risk
    # period gets the full-breakdown drill-down, exempt from dedup like the
    # evergreen action (see action deduplication).
    turn_request = _ctx("turnRequest") or {}
    is_payment_summary = not (turn_request.get("childNames") or turn_request.get("countyNames"))
    if (
        payment_result.get("mode") != "multi_period"
        and payment_result.get("status") != "needs_period_selection"
        and current_sub_filter != "FULL_BREAKDOWN"
        and is_payment_summary
    ):
        settled = payment_result.get("payment_history_found") is True
        payment_rows = payment_result.get("rows") or []
        has_payable_rows = any(
            isinstance(row, dict) and row.get("status") in ("calculated", "at_risk")
            for row in payment_rows
        )
        _bd_at_risk = payment_result.get("at_risk_day_count", 0) or 0
        if settled and has_payable_rows:
            candidates.append(
                _candidate(FULL_BREAKDOWN_ID, "View breakdown of this settled amount", "PAYMENT", "FULL_BREAKDOWN", "INFO")
            )
        elif has_payable_rows:
            _bd_label = (
                f"Review full breakdown — {_bd_at_risk} at-risk entr{'y' if _bd_at_risk == 1 else 'ies'}"
                if _bd_at_risk > 0
                else "View full attendance breakdown for this period"
            )
            candidates.append(
                _candidate(FULL_BREAKDOWN_ID, _bd_label, "PAYMENT", "FULL_BREAKDOWN", "INFO")
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
    scope = json.dumps(
        {
            "action": current_action,
            "subFilter": current_sub_filter,
            "dateFilter": turn_request.get("dateFilter"),
            "dateFrom": turn_request.get("dateFrom"),
            "dateTo": turn_request.get("dateTo"),
            "servicePeriodId": turn_request.get("servicePeriodId"),
            "childNames": turn_request.get("childNames") or [],
            "countyNames": turn_request.get("countyNames") or [],
        },
        sort_keys=True,
    )
    provider_status = (_ctx("ccare_provider_data_py") or {}).get("status")
    if provider_status in ("failed", "needs_clarification"):
        write_context("shownActionIds", list(_ctx("shownActionIds") or []))
        write_context("recommendedActionScope", scope)
        return [], list(_ctx("shownActionIds") or [])
    shown_ids = list(_ctx("shownActionIds") or []) if _ctx("recommendedActionScope") == scope else []

    # The full-breakdown drill-down can re-surface when payment data supports
    # it; risk actions remain one-time within the same request context.
    _never_expire = {FULL_BREAKDOWN_ID}

    # Recommendations are intentionally deterministic. The conversational
    # model may route to an action, but it cannot invent a new action here.
    candidates = _build_candidates(current_action, current_sub_filter)

    # Keep the first candidate for each action identity and discard anything
    # already shown in this conversation (never-expire IDs bypass this check).
    unique = []
    seen_keys = {}
    for candidate in candidates:
        key = (candidate["id"], candidate.get("action"), candidate.get("subFilter"))
        if key in seen_keys:
            continue
        if candidate["id"] in shown_ids and candidate["id"] not in _never_expire:
            continue
        seen_keys[key] = True
        unique.append(candidate)

    # Drop the action currently being answered; recommendations should advance
    # the conversation rather than repeat the current request.
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

    # Never-expire IDs are not tracked in shownActionIds so they remain
    # available every turn and do not consume a shown-history slot.
    new_ids = [c["id"] for c in selected if c["id"] not in _never_expire]
    updated_shown = list(dict.fromkeys(shown_ids + new_ids))
    write_context("recommendedActionScope", scope)

    return selected, updated_shown


# ==============================================================================
# FORMATTING HELPERS
# ==============================================================================

def _fmt_date(value):
    """Human-readable date for every provider-facing table -- 'Sep 25, 2026'.
    ISO stays internal-only; anything unparseable passes through as-is."""
    text = str(value or "")[:10]
    try:
        y, m, d = (int(p) for p in text.split("-"))
        return f"{_MONTH_ABBR[m - 1]} {d}, {y}"
    except Exception:
        return text or "--"


def _fmt_money(value):
    if value is None:
        return "--"
    try:
        return "${:,.2f}".format(float(value))
    except (TypeError, ValueError):
        return "--"


def _fmt_hours(value):
    if value is None:
        return "--"
    try:
        return "%.1f" % float(value)
    except (TypeError, ValueError):
        return "--"


def _fmt_date_range(start_iso, end_iso):
    if not start_iso or not end_iso:
        return None
    return f"{_fmt_date(start_iso)} - {_fmt_date(end_iso)}"


def _period_label():
    """Human-readable period string for the current turn's date filter."""
    turn_req = _ctx("turnRequest") or {}
    date_filter = (turn_req.get("dateFilter") or "").upper()
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    ref_date = (analyzer.get("reference_date") or "")[:10]
    try:
        y, m, _ = (int(p) for p in ref_date.split("-"))
        if date_filter == "LAST_MONTH":
            m, y = (12, y - 1) if m == 1 else (m - 1, y)
        label = f"{_MONTH_FULL[m - 1]} {y}"
        if date_filter == "THIS_MONTH":
            return f"{label} (this month)"
        if date_filter == "LAST_MONTH":
            return f"{label} (last month)"
        return label
    except Exception:
        pass
    date_from = turn_req.get("dateFrom")
    date_to = turn_req.get("dateTo")
    if date_from and date_to:
        return _fmt_date_range(date_from, date_to)
    return ""


def _group_by_classification(rows):
    """Preserves first-seen order -- used for the compact category summary
    that replaces the always-inline day-by-day table."""
    groups = {}
    for r in rows:
        label = (r.get("classification") or "Other").replace("_", " ").title()
        groups.setdefault(label, []).append(r)
    return groups


def _table(headers, rows):
    if not rows:
        return None
    lines = ["| " + " | ".join(headers) + " |", "|" + "|".join(["---"] * len(headers)) + "|"]
    for row in rows:
        lines.append("| " + " | ".join(str(c) if c is not None else "--" for c in row) + " |")
    return "\n".join(lines)


def _actions_block(recommended):
    if not recommended:
        return "There is no other action I can recommend for this view. You can ask me about anything else."
    lines = ["**Recommended actions**"]
    for i, item in enumerate(recommended, start=1):
        label = SEVERITY_LABEL.get(item.get("severity"), "[Info]")
        lines.append(f"{i}. {label} {item.get('label', '')}")
    return "\n".join(lines)


def _contains_at_risk_or_forecast(text):
    return bool(text) and ("At-risk" in text or "Forecasted" in text)


# ==============================================================================
# RENDER FUNCTIONS
# ==============================================================================

def render_unauthorized():
    return (
        "I wasn't able to complete that request. The provider account on this session couldn't be "
        "verified, or is outside the authorized CCARE services for this program. If this seems "
        "incorrect, please contact your program administrator."
    )


def render_greeting(recommended):
    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    user_name = snapshot.get("user_name")
    if not user_name or str(user_name).isdigit():
        user_name = "Provider"
    facility_name = snapshot.get("facility_name") or "your facility"

    today = snapshot.get("today") or {}
    scheduled = today.get("scheduled_children", snapshot.get("children_scheduled_count", 0))
    checked_in = today.get("checked_in_children", snapshot.get("checked_in_count", 0))

    snap_table = _table(
        ["Measure", "Verified count"],
        [["Children scheduled", scheduled], ["Children checked in", checked_in]],
    )

    risk = snapshot.get("risk_categories") or {}
    pending = risk.get("pending_parent_confirmations") or {}
    approaching = risk.get("approaching_absence_limits") or {}
    crossed = risk.get("crossed_absence_limits") or {}
    incomplete = risk.get("incomplete_attendance") or {}
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    analyzer_absence_rows = analyzer.get("approaching_absence_limits") or []
    analyzer_incomplete_rows = analyzer.get("unconfirmed_attendance_last_9_days") or []

    pending_days = pending.get("days", 0) or 0
    pending_finding = (
        "No pending parent confirmations"
        if not pending_days
        else f"{pending_days} day(s), {pending.get('children', 0)} child(ren)"
    )
    absence_finding = _absence_finding(analyzer_absence_rows)
    incomplete_attendance_rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ]
    incomplete_days = len(incomplete_attendance_rows) or incomplete.get("days", 0) or 0
    incomplete_finding = "No incomplete check-in/out found" if not incomplete_days else f"{incomplete_days} day(s)"

    def _loss(cat):
        val = cat.get("potential_loss_hours") if isinstance(cat, dict) else None
        amount = cat.get("potential_loss_amount") if isinstance(cat, dict) else None
        if isinstance(val, (int, float)):
            hours = "%.1f" % val
            return f"{_fmt_money(amount)} ({hours} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    issues_table = _table(
        ["Risk area", "Verified finding", "Potential payment impact"],
        [
            ["Pending parent confirmations", pending_finding, _loss(pending)],
            ["Absence-limit risk", absence_finding, _loss(approaching)],
            ["Incomplete check-ins/check-outs", incomplete_finding, _loss(incomplete)],
        ],
    )
    body = [
        f"Greetings for the day, {user_name}. Here's where things stand today at {facility_name}.",
        "",
        "**Today's snapshot**",
        snap_table,
        "",
        "**Attendance and payment issues**",
        issues_table,
        "",
        _actions_block(recommended),
    ]
    return "\n".join(part for part in body if part is not None)


def render_pending_confirmations(recommended):
    dcr = _ctx("data_collection_result") or {}
    rows = (dcr.get("snapshot") or {}).get("pending_confirmations") or []
    _mask_id = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
    table = _table(
        ["Child", "Authorization", "Service date", "Status"],
        [
            [_mask_id(r.get("child_name") or ""), r.get("authorization_id") or "--", _fmt_date(r.get("service_date")), "Pending"]
            for r in rows
        ],
    )
    body = ["**Pending parent confirmations**", "", table or "No pending parent confirmations found.", "", _actions_block(recommended)]
    return "\n".join(body)


def render_absence_limits(recommended, _emit_actions=True):
    rows = (_ctx("attendance_risks_analyzer_py") or {}).get("approaching_absence_limits") or []
    period = _period_label()
    period_line = f"*Period: {period}*" if period else None
    if not rows:
        body = ["**Absence-limit risk**"]
        if period_line:
            body += [period_line]
        body += ["", "No children currently near or over county monthly absence limits."]
        if _emit_actions:
            body += ["", _actions_block(recommended)]
        return "\n".join(body)
    table = _table(
        ["Child", "Authorization", "County", "Absences used", "Absence limit", "Status"],
        [
            [
                # Salesforce record IDs (15-18 alphanumeric) are internal and
                # unreadable to providers — hide them rather than showing auth ID,
                # which is already visible in the Authorization column.
                (lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--")
                (r.get("child_name") or ""),
                r.get("authorization_id") or r.get("auth_id") or "--",
                r.get("county_name") or "--",
                r.get("confirmed_absence_count", r.get("absence_used", 0)),
                r.get("absence_limit", "--"),
                {"OVER_LIMIT": "Exceeded", "POTENTIAL_OVER_LIMIT": "At risk",
                 "APPROACHING_LIMIT": "Near limit", "POTENTIAL_APPROACHING_LIMIT": "Near limit"}
                .get(r.get("status") or "", (r.get("status") or "--").replace("_", " ").title()),
            ]
            for r in rows
        ],
    )
    body = ["**Absence-limit risk**"]
    if period_line:
        body += [period_line]
    body += ["", _absence_finding(rows), "", table]
    if _emit_actions:
        body += ["", _actions_block(recommended)]
    return "\n".join(body)


def render_incomplete_attendance(recommended, _emit_actions=True):
    rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ]
    if not rows:
        body = [
            "**Missing check-in/check-out**",
            "",
            "No incomplete attendance found in the current window.",
        ]
        if _emit_actions:
            body += ["", _actions_block(recommended)]
        return "\n".join(body)
    _mask_id = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
    table = _table(
        ["Child", "Authorization", "Service date", "Attendance type", "Reason"],
        [
            [
                _mask_id(r.get("child_name") or ""),
                r.get("auth_id") or "--",
                _fmt_date(r.get("date")),
                "Missing check-in/check-out",
                r.get("reason") or "A scheduled day is missing one attendance event",
            ]
            for r in rows
        ],
    )
    body = ["**Missing check-in/check-out**", "", table]
    if _emit_actions:
        body += ["", _actions_block(recommended)]
    return "\n".join(body)


def render_attendance_all(recommended):
    absence_section = render_absence_limits([], _emit_actions=False)
    incomplete_section = render_incomplete_attendance([], _emit_actions=False)
    dcr = _ctx("data_collection_result") or {}
    pending_cat = ((dcr.get("snapshot") or {}).get("risk_categories") or {}).get("pending_parent_confirmations") or {}
    pending_line = (
        "No pending parent confirmations"
        if not pending_cat.get("days")
        else f"Pending parent confirmations: {pending_cat.get('days')} day(s), {pending_cat.get('children', 0)} child(ren)"
    )
    body = ["**Attendance overview**", "", absence_section, "", incomplete_section, "", pending_line, "", _actions_block(recommended)]
    return "\n".join(body)


def render_payout_impact(recommended):
    result = _ctx("payoutImpactResult") or {}
    rows = result.get("rows") or []
    if not rows:
        body = [
            "**Payout impact of current attendance risk**",
            "",
            "No attendance risk currently affects an upcoming payout.",
            "",
            _actions_block(recommended),
        ]
        return "\n".join(body)
    # When every row failed schedule lookup the dollar total is $0 —
    # surface a cleaner message rather than "$0.00 at risk" which implies
    # there's genuinely nothing to pay.
    _calc_rows = [r for r in rows if r.get("amount") is not None]
    if not _calc_rows:
        body = [
            "**Payout impact of current attendance risk**",
            "",
            "Attendance risk entries were found but payout amounts couldn't be calculated — "
            "rate schedule data may still be loading.",
            "",
            _actions_block(recommended),
        ]
        return "\n".join(body)
    table = _table(
        ["Child", "Authorization", "County", "Care hours", "Amount", "Amount type", "Reason"],
        [
            [
                (lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--")
                (r.get("child_name") or ""),
                r.get("authorization_id") or "--",
                r.get("county_name") or "--",
                _fmt_hours(r.get("care_hours")),
                _fmt_money(r.get("amount")),
                r.get("amount_type") or "--",
                r.get("reason") or "--",
            ]
            for r in rows
        ],
    )
    total_hours = result.get("total_hours_at_risk")
    total_dollar = result.get("total_dollar_at_risk")
    headline = f"~ {_fmt_money(total_dollar)} at risk across {_fmt_hours(total_hours)} care hour(s)"
    body = ["**Payout impact of current attendance risk**", "", f"**{headline}**", "", table, "", DISCLAIMER_GLOBAL, "", _actions_block(recommended)]
    return "\n".join(body)


def render_payment_needs_period_selection(candidates):
    table = _table(
        ["#", "Service period", "Status"],
        [[i + 1, c.get("label", "--"), "Awaiting selection"] for i, c in enumerate(candidates)],
    )
    return "\n".join(["I found more than one service period matching that request. Which one did you mean?", "", table])


MULTI_PERIOD_PAGE_SIZE = 7


def render_payment_multi_period(recommended):
    """Compact table -- one row per period, total only, flat status label
    (Calculated/At-risk). Category breakdown per period is a drill-down
    (name a specific period -> renders render_payment()'s table for it).
    Paginated at MULTI_PERIOD_PAGE_SIZE via turnRequest.fetchParams.page."""
    result = _ctx("paymentResult") or {}
    periods = result.get("periods") or []
    if not periods:
        return "\n".join(["**Payment summary**", "", "No service periods found for that range.", "", _actions_block(recommended)])

    page = (_ctx("turnRequest.fetchParams.page")) or 0
    try:
        page = int(page)
    except (TypeError, ValueError):
        page = 0

    all_rows = []
    for p in periods:
        period_range = _fmt_date_range(p.get("service_period_start"), p.get("service_period_end"))
        period_label = period_range or (p.get("service_period_id") or "--")
        payout_date = _fmt_date(p.get("payment_release_date")) if p.get("payment_release_date") else "--"
        potential_total = p.get("potential_total_amount") or p.get("total_amount")
        status = "Calculated" if p.get("payment_history_found") else (
            "At-risk" if (p.get("at_risk_day_count") or 0) > 0 else "Expected"
        )
        all_rows.append([period_label, payout_date, _fmt_money(potential_total), status])

    total_count = len(all_rows)
    start_idx = page * MULTI_PERIOD_PAGE_SIZE
    page_rows = all_rows[start_idx:start_idx + MULTI_PERIOD_PAGE_SIZE]
    table = _table(["Service period", "Payout date", "Potential total", "Status"], page_rows)
    grand_total = sum((Decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
    body = ["**Payment summary -- period by period**", "", table, "", f"**Grand total: {_fmt_money(grand_total)}**"]
    if total_count > MULTI_PERIOD_PAGE_SIZE:
        body += ["", f"Showing {start_idx + 1}-{min(start_idx + MULTI_PERIOD_PAGE_SIZE, total_count)} of {total_count} periods."]
    body += ["", DISCLAIMER_GLOBAL]
    body += ["", _actions_block(recommended)]
    return "\n".join(body)



def _at_risk_reason(result):
    """Short inline note explaining why the at-risk amount is at risk.
    Returns None when there is nothing at risk."""
    rows = result.get("rows") or []
    at_risk_rows = [r for r in rows if r.get("status") == "at_risk"]
    if not at_risk_rows:
        return None
    risk_types = {}
    for r in at_risk_rows:
        k = r.get("confirmation_risk") or "pending review"
        risk_types[k] = risk_types.get(k, 0) + 1
    day_count = result.get("at_risk_day_count") or len(at_risk_rows)
    parts = []
    if "MISSING_ATTENDANCE" in risk_types:
        parts.append(f"{day_count} missing confirmation{'s' if day_count != 1 else ''}")
    for k in risk_types:
        if k != "MISSING_ATTENDANCE":
            parts.append(k.replace("_", " ").lower())
    return "; ".join(parts) if parts else "under review"

def render_payment(recommended):
    """Single consistent 2-column payout summary table -- Service period,
    Payout date, Attendance-based payment, Vacant slot payment, At risk,
    Potential total. Always shown, no conditional omission. Day-by-day
    detail and per-classification breakdown live only in
    render_payment_full_breakdown() (drill-down action)."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    top_level_blockers = result.get("blockers") or []
    settled = result.get("payment_history_found") is True

    if not rows and not settled:
        if not top_level_blockers:
            # No rows, no blockers — genuine absence of payment history,
            # not a calculation failure.
            body = [
                "**No payment history found**",
                "",
                "No payment records are available for the requested period.",
                "",
                _actions_block(recommended),
            ]
            return "\n".join(body)
        issue_rows = [[BLOCKER_TITLE.get(b, b.replace("_", " ").title()), b] for b in top_level_blockers]
        table = _table(["Issue area", "Reason"], issue_rows)
        body = ["That payment view couldn't be fully calculated right now.", ""]
        body += [table] if table else ["No further detail is available for this issue."]
        body += ["", _actions_block(recommended)]
        return "\n".join(body)

    amount_type = "Calculated" if settled else "Expected"
    period_range = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end"))
    period_label = period_range or (result.get("service_period_id") or "--")
    payout_date = result.get("payment_release_date")
    at_risk_days = result.get("at_risk_day_count") or 0
    has_at_risk = at_risk_days > 0
    potential_total = result.get("potential_total_amount") or result.get("total_amount")

    _risk_detail = _at_risk_reason(result)
    table_rows = [
        ["Service period", period_label],
        ["Payout date", _fmt_date(payout_date) if payout_date else "--"],
        ["Attendance-based payment", f"{_fmt_money(result.get('attended_care_amount'))} ({amount_type})"],
        ["Vacant slot payment", f"{_fmt_money(result.get('vacant_slot_amount'))} ({amount_type})"],
        ["At risk", f"{_fmt_money(result.get('amount_at_risk'))} ({_risk_detail})" if _risk_detail else _fmt_money(result.get("amount_at_risk"))],
    ]
    table_rows.append(["**Potential total**", f"**{_fmt_money(potential_total)}**"])
    table = _table(["Field", "Value"], table_rows)

    sections = [table]
    sections += ["", DISCLAIMER_GLOBAL]
    sections += ["", _actions_block(recommended)]
    return "\n".join(sections)


FULL_BREAKDOWN_PAGE_SIZE = 7


def render_payment_full_breakdown(recommended):
    """The full day-by-day detail -- a drill-down action (subFilter=
    FULL_BREAKDOWN) rather than the default view. Paginated at
    FULL_BREAKDOWN_PAGE_SIZE rows via turnRequest.fetchParams.page -- this is
    a chat interface, a 40+ row table in one response is bad UX."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    calculated_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    settled = result.get("payment_history_found") is True
    period_range = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end"))
    period_label = period_range or (result.get("service_period_id") or "--")

    page = _ctx("turnRequest.fetchParams.page") or 0
    try:
        page = int(page)
    except (TypeError, ValueError):
        page = 0

    sections = [f"**Full attendance breakdown -- service period {period_label}**"]

    total_calc = len(calculated_rows)
    start_idx = page * FULL_BREAKDOWN_PAGE_SIZE
    page_rows = calculated_rows[start_idx:start_idx + FULL_BREAKDOWN_PAGE_SIZE]
    if page_rows:
        detail = _table(
            ["Service date", "Attendance type", "Care hours", "Amount", "Amount type"],
            [
                [
                    _fmt_date(r.get("service_date")),
                    (r.get("classification") or "--").replace("_", " ").title(),
                    _fmt_hours(r.get("payable_hours")),
                    _fmt_money(r.get("amount")),
                    "At-risk" if r.get("status") == "at_risk" else ("Calculated" if settled else "Expected"),
                ]
                for r in page_rows
            ],
        )
        if detail:
            sections += ["", detail]
        if total_calc > FULL_BREAKDOWN_PAGE_SIZE:
            shown_end = min(start_idx + FULL_BREAKDOWN_PAGE_SIZE, total_calc)
            sections += ["", f"Showing {start_idx + 1}-{shown_end} of {total_calc} days."]

    sections += ["", DISCLAIMER_GLOBAL, "", _actions_block(recommended)]
    return "\n".join(sections)


def _child_rows(rows, child_key):
    """Matches by authorization_name (e.g. "963383") or authorization_id --
    there is no confirmed child-name field anywhere in this pipeline (same
    known gap documented in attendance_risks_analyzer_py.py), so the
    authorization identifier is the honest display fallback, not a
    fabricated child name."""
    key = str(child_key or "").strip().lower()
    return [
        r for r in rows
        if r.get("kind") == "ATTENDED_CARE"
        and key in {str(r.get("authorization_name") or "").strip().lower(), str(r.get("authorization_id") or "").strip().lower()}
    ]


def render_payment_child_detail(recommended, child_key):
    """Level 1a drill-down -- header liner (Authorization + County) then a
    classification-level summary table (Days/Hours/Amount per category),
    not raw individual dates (that's Level 2, render_payment_full_breakdown)."""
    result = _ctx("paymentResult") or {}
    rows = _child_rows(result.get("rows") or [], child_key)
    if not rows:
        return "\n".join([f"I couldn't find attendance for \"{child_key}\" in this service period.", "", _actions_block(recommended)])

    auth_name = rows[0].get("authorization_name") or child_key
    county_name = rows[0].get("county_name") or "--"
    header = f"Authorization: {auth_name} \u00b7 County: {county_name}"

    payable_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    category_rows = []
    total_days, total_hours, total_amount = 0, Decimal("0"), Decimal("0")
    for label, group in _group_by_classification(payable_rows).items():
        days = len(group)
        hours = sum((Decimal(str(r.get("payable_hours") or "0")) for r in group), Decimal("0"))
        amount = sum((Decimal(r["amount"]) for r in group), Decimal("0"))
        category_rows.append([label, days, _fmt_hours(float(hours)), _fmt_money(str(amount))])
        total_days += days
        total_hours += hours
        total_amount += amount
    if category_rows:
        category_rows.append(["**Total**", f"**{total_days}**", f"**{_fmt_hours(float(total_hours))}**", f"**{_fmt_money(str(total_amount))}**"])
    table = _table(["Category", "Days", "Hours", "Amount"], category_rows)

    sections = [header, "", (table or "No payable days found for this authorization in this service period."), "", _actions_block(recommended)]
    return "\n".join(sections)


def render_payment_county_detail(recommended, county_key):
    """Level 1b drill-down -- single aggregated row (Attendance-based
    payment, Vacant slot payment, hours bracketed). No per-child breakout at
    this level -- name a specific child to go deeper (Level 1a)."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    key = str(county_key or "").strip().lower()
    matching = [r for r in rows if str(r.get("county_name") or "").strip().lower() == key]
    if not matching:
        return "\n".join([f"I couldn't find payment data for county \"{county_key}\" in this service period.", "", _actions_block(recommended)])

    attended = [r for r in matching if r.get("kind") == "ATTENDED_CARE" and r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    attended_amount = sum((Decimal(r["amount"]) for r in attended), Decimal("0"))
    attended_hours = sum((Decimal(str(r.get("payable_hours") or "0")) for r in attended), Decimal("0"))
    vacant_amount = sum((Decimal(r["amount"]) for r in vacant), Decimal("0"))

    county_name = matching[0].get("county_name") or county_key
    header = f"County: {county_name}"
    table = _table(
        ["Attendance-based payment", "Vacant slot payment"],
        [[f"{_fmt_money(str(attended_amount))} ({_fmt_hours(float(attended_hours))} hrs)", _fmt_money(str(vacant_amount))]],
    )
    sections = [header, "", table, "", "To see a specific child's detail, ask about that child's authorization by name.", "", _actions_block(recommended)]
    return "\n".join(sections)


BLOCKER_TITLE = {
    "age_group_code_unresolved": "Child's age band could not be determined",
    "care_unit_mapping_unconfirmed": "Care unit could not be resolved from attended hours",
    "fiscal_schedule": "No matching fiscal schedule on file for this provider/county",
    "fiscal_rate": "No matching fiscal rate on file for this day",
    "authorization_relationship": "Could not link this day to an authorization",
    "attendance_hours": "Attendance hours are missing for this day",
    "absence_limit_exceeded": "This absence is beyond the county's approved monthly limit",
    "drop_in_not_allowed": "Drop-in care is not allowed under this county's policy",
    "drop_in_limit_exceeded": "This drop-in day is beyond the county's approved monthly limit",
    "vacant_slot_rate_fields": "Vacant slot is missing rate information",
    "vacant_slot_rate_ambiguous_age_group": "Vacant slot rate is ambiguous across age groups",
    "service_period": "No matching service period found",
    "service_period_dates": "Service period dates are invalid or missing",
}


def render_clarify(recommended, prior_recommended=None):
    session_state = _ctx("sessionState") or {}
    provider_verified = session_state.get("providerVerified", False)
    provider_name = (session_state.get("providerName") or "").strip()
    if provider_verified and provider_name:
        greeting_line = f"What can I help you with next, {provider_name}?"
    elif provider_verified:
        greeting_line = "What can I help you with next?"
    else:
        greeting_line = "Welcome to Provider Assist. What would you like to look at today?"
    body = [
        greeting_line,
        "",
        "Choose an option below, or tell me in your own words.",
        "",
        _actions_block(recommended),
    ]
    return "\n".join(body)


def render_explain(recommended):
    snapshot = (_ctx("data_collection_result") or {}).get("snapshot") or {}
    payment_result = _ctx("paymentResult") or {}
    sections = []

    # Explain at-risk concept when there is live at-risk data to reference.
    at_risk_amt = payment_result.get("amount_at_risk")
    at_risk_days = payment_result.get("at_risk_day_count") or 0
    try:
        _at_risk_float = float(at_risk_amt) if at_risk_amt else 0
    except (TypeError, ValueError):
        _at_risk_float = 0

    if _at_risk_float > 0:
        _detail = _at_risk_reason(payment_result)
        sections += [
            "**About \"at risk\" amounts**", "",
            "A day is marked **at risk** when care was provided but parent "
            "confirmation is still pending. The county holds payment on those "
            "days until the parent confirms.",
            "",
            f"Your current at-risk amount: **{_fmt_money(at_risk_amt)}** "
            f"({at_risk_days} day(s) — {_detail or 'awaiting confirmation'})",
            "",
        ]

    # Current-period status digest.
    risk = snapshot.get("risk_categories") or {}
    pending_days = (risk.get("pending_parent_confirmations") or {}).get("days", 0) or 0
    absence_children = (
        ((risk.get("approaching_absence_limits") or {}).get("children", 0) or 0)
        + ((risk.get("crossed_absence_limits") or {}).get("children", 0) or 0)
    )
    incomplete_days = (risk.get("incomplete_attendance") or {}).get("days", 0) or 0

    summary_rows = []
    if pending_days:
        summary_rows.append(["Pending confirmations", f"{pending_days} day(s) need parent sign-off"])
    if absence_children:
        summary_rows.append(["Absence limits", f"{absence_children} child(ren) near or over the monthly limit"])
    if incomplete_days:
        summary_rows.append(["Incomplete attendance", f"{incomplete_days} day(s) missing check-in or check-out"])

    if summary_rows:
        sections += ["**Current items requiring attention**", "", _table(["Area", "Status"], summary_rows), ""]
    elif not sections:
        sections += ["No outstanding items found for the current period.", ""]

    sections += [_actions_block(recommended)]
    return "\n".join(sections)


def render_fallback(recommended):
    body = [
        "I couldn't load today's provider snapshot. Please try again later or contact your system administrator.",
        "",
        _actions_block(recommended),
    ]
    return "\n".join(body)



# ==============================================================================
# RICH UI BLOCKS (chat-ui format for React renderer)
# ==============================================================================

DISCLAIMER_TEXT = (
    "Amounts shown are estimates based on current attendance, authorizations, "
    "and fiscal rates on file. Final amounts are determined at county payment processing."
)


def _mk_table(caption, col_specs, row_list):
    """col_specs: list of (key, label) or (key, label, align) tuples.
    row_list: list of dicts keyed by col_specs[*][0]."""
    if not row_list:
        return None
    total = len(row_list)
    if total > TABLE_ROW_LIMIT:
        row_list = row_list[:TABLE_ROW_LIMIT]
        note = f"Showing {TABLE_ROW_LIMIT} of {total}"
        caption = f"{caption} — {note}" if caption else note
    cols = []
    for spec in col_specs:
        col = {"key": spec[0], "label": spec[1]}
        if len(spec) > 2 and spec[2]:
            col["align"] = spec[2]
        cols.append(col)
    return {"version": 1, "type": "table", "caption": caption, "columns": cols, "rows": row_list}


def _mk_buttons(recommended):
    if not recommended:
        return None
    items = []
    for i, r in enumerate(recommended):
        item = {"label": r["label"], "value": r["label"]}
        if i == 0:
            item["variant"] = "primary"
        items.append(item)
    return {"version": 1, "type": "buttons", "items": items}


def _mk_accordion(items):
    return {"version": 1, "type": "accordion", "items": items}


def _mk_text(content, italic=False):
    block = {"version": 1, "type": "text", "content": content}
    if italic:
        block["italic"] = True
    return block


def _blocks_greeting(recommended):
    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    user_name = snapshot.get("user_name")
    if not user_name or str(user_name).isdigit():
        user_name = "Provider"
    facility_name = snapshot.get("facility_name") or "your facility"
    today = snapshot.get("today") or {}
    scheduled = today.get("scheduled_children", snapshot.get("children_scheduled_count", 0))
    checked_in = today.get("checked_in_children", snapshot.get("checked_in_count", 0))
    blocks = [_mk_text(f"Greetings for the day, {user_name}. Here's where things stand today at {facility_name}.")]
    snap_tbl = _mk_table(
        "Today's snapshot",
        [("measure", "Measure"), ("count", "Verified count", "right")],
        [{"measure": "Children scheduled", "count": scheduled},
         {"measure": "Children checked in", "count": checked_in}],
    )
    if snap_tbl:
        blocks.append(snap_tbl)
    risk = snapshot.get("risk_categories") or {}
    pending = risk.get("pending_parent_confirmations") or {}
    approaching = risk.get("approaching_absence_limits") or {}
    incomplete = risk.get("incomplete_attendance") or {}
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    analyzer_absence_rows = analyzer.get("approaching_absence_limits") or []
    pending_days = pending.get("days", 0) or 0
    absence_finding = _absence_finding(analyzer_absence_rows)
    incomplete_attendance_rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ]
    incomplete_days = len(incomplete_attendance_rows) or incomplete.get("days", 0) or 0

    def _loss(cat):
        val = cat.get("potential_loss_hours") if isinstance(cat, dict) else None
        amount = cat.get("potential_loss_amount") if isinstance(cat, dict) else None
        if isinstance(val, (int, float)):
            return f"{_fmt_money(amount)} ({'%.1f' % val} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    issues_tbl = _mk_table(
        "Attendance and payment issues",
        [("area", "Risk area"), ("finding", "Verified finding"), ("impact", "Potential payment impact")],
        [
            {"area": "Pending parent confirmations",
             "finding": "No pending parent confirmations" if not pending_days else f"{pending_days} day(s), {pending.get('children', 0)} child(ren)",
             "impact": _loss(pending)},
            {"area": "Absence-limit risk",
             "finding": absence_finding,
             "impact": _loss(approaching)},
            {"area": "Incomplete check-ins/check-outs",
             "finding": "No incomplete check-in/out found" if not incomplete_days else f"{incomplete_days} day(s)",
             "impact": _loss(incomplete)},
        ],
    )
    if issues_tbl:
        blocks.append(issues_tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_pending_confirmations(recommended):
    dcr = _ctx("data_collection_result") or {}
    rows = (dcr.get("snapshot") or {}).get("pending_confirmations") or []
    blocks = []
    if rows:
        _mask = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
        tbl = _mk_table(
            "Pending parent confirmations",
            [("child", "Child"), ("authorization", "Authorization"),
             ("service_date", "Service date"), ("status", "Status")],
            [{"child": _mask(r.get("child_name") or ""), "authorization": r.get("authorization_id") or "--",
              "service_date": _fmt_date(r.get("service_date")), "status": "Pending"} for r in rows],
        )
        if tbl:
            blocks.append(tbl)
    else:
        blocks.append(_mk_text("No pending parent confirmations found."))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_absence_limits(recommended):
    rows = (_ctx("attendance_risks_analyzer_py") or {}).get("approaching_absence_limits") or []
    _mask = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
    _STATUS_MAP = {"OVER_LIMIT": "Exceeded", "POTENTIAL_OVER_LIMIT": "At risk",
                   "APPROACHING_LIMIT": "Near limit", "POTENTIAL_APPROACHING_LIMIT": "Near limit"}
    period = _period_label()
    blocks = []
    if period:
        blocks.append(_mk_text(f"Period: {period}", italic=True))
    if not rows:
        blocks.append(_mk_accordion([{"title": "Absence-limit risk", "content": "No children currently near or over county monthly absence limits."}]))
    else:
        blocks.append(_mk_text(_absence_finding(rows)))
        tbl = _mk_table(
            "Absence-limit risk",
            [("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
             ("absences_used", "Absences used", "right"), ("absence_limit", "Absence limit", "right"), ("status", "Status")],
            [{"child": _mask(r.get("child_name") or ""),
              "authorization": r.get("authorization_id") or r.get("auth_id") or "--",
              "county": r.get("county_name") or "--",
              "absences_used": r.get("confirmed_absence_count", r.get("absence_used", 0)),
              "absence_limit": r.get("absence_limit", "--"),
              "status": _STATUS_MAP.get(r.get("status") or "", (r.get("status") or "--").replace("_", " ").title())}
             for r in rows],
        )
        if tbl:
            blocks.append(tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_incomplete_attendance(recommended):
    rows = [row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
            if isinstance(row, dict) and row.get("risk_category") == "incomplete"]
    _mask = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
    blocks = []
    if not rows:
        blocks.append(_mk_accordion([{"title": "Missing check-in/check-out", "content": "No incomplete attendance found in the current window."}]))
    else:
        tbl = _mk_table(
            "Missing check-in/check-out",
            [("child", "Child"), ("authorization", "Authorization"), ("service_date", "Service date"),
             ("attendance_type", "Attendance type"), ("reason", "Reason")],
            [{"child": _mask(r.get("child_name") or ""), "authorization": r.get("auth_id") or "--",
              "service_date": _fmt_date(r.get("date")), "attendance_type": "Missing check-in/check-out",
              "reason": r.get("reason") or "A scheduled day is missing one attendance event"} for r in rows],
        )
        if tbl:
            blocks.append(tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payout_impact(recommended):
    result = _ctx("payoutImpactResult") or {}
    rows = result.get("rows") or []
    _calc_rows = [r for r in rows if r.get("amount") is not None]
    _mask = lambda cn: cn if cn and not (cn.isalnum() and len(cn) >= 15) else "--"
    blocks = []
    if not rows:
        blocks.append(_mk_accordion([{"title": "Payout impact", "content": "No attendance risk currently affects an upcoming payout."}]))
    elif not _calc_rows:
        blocks.append(_mk_accordion([{"title": "Payout impact", "content": "Attendance risk entries were found but payout amounts couldn't be calculated — rate schedule data may still be loading."}]))
    else:
        total_hours = result.get("total_hours_at_risk")
        total_dollar = result.get("total_dollar_at_risk")
        caption = f"~ {_fmt_money(total_dollar)} at risk across {_fmt_hours(total_hours)} care hour(s)"
        blocks.append(_mk_text("Payout impact of current attendance risk"))
        _agg = {}
        for _r in _calc_rows:
            _k = (_mask(_r.get("child_name") or ""), _r.get("authorization_id") or "--", _r.get("county_name") or "--")
            if _k not in _agg:
                _agg[_k] = {"hours": Decimal("0"), "amount": Decimal("0"), "amount_type": _r.get("amount_type") or "--", "reason": _r.get("reason") or "--"}
            _agg[_k]["hours"] += Decimal(str(_r.get("care_hours") or 0))
            _agg[_k]["amount"] += Decimal(str(_r.get("amount") or "0"))
        tbl = _mk_table(
            caption,
            [("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
             ("care_hours", "Care hours", "right"), ("amount", "Amount", "right"),
             ("amount_type", "Amount type"), ("reason", "Reason")],
            [{"child": _k[0], "authorization": _k[1], "county": _k[2],
              "care_hours": _fmt_hours(float(_v["hours"])),
              "amount": _fmt_money(_v["amount"]),
              "amount_type": _v["amount_type"],
              "reason": _v["reason"]}
             for _k, _v in _agg.items()],
        )
        if tbl:
            blocks.append(tbl)
        blocks.append(_mk_text(DISCLAIMER_TEXT, italic=True))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payment(recommended):
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    top_level_blockers = result.get("blockers") or []
    settled = result.get("payment_history_found") is True
    blocks = []
    if not rows and not settled:
        if not top_level_blockers:
            blocks.append(_mk_accordion([{"title": "No payment history found", "content": "No payment records are available for the requested period."}]))
        else:
            blocks.append(_mk_text("That payment view couldn't be fully calculated right now."))
            tbl = _mk_table(
                "Payment issues",
                [("issue_area", "Issue area"), ("reason", "Reason")],
                [{"issue_area": BLOCKER_TITLE.get(b, b.replace("_", " ").title()), "reason": b} for b in top_level_blockers],
            )
            if tbl:
                blocks.append(tbl)
            else:
                blocks.append(_mk_text("No further detail is available for this issue."))
    else:
        amount_type = "Calculated" if settled else "Expected"
        period_range = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end"))
        period_label = period_range or (result.get("service_period_id") or "--")
        payout_date = result.get("payment_release_date")
        _risk_detail = _at_risk_reason(result)
        summary_rows = [
            {"field": "Service period", "value": period_label},
            {"field": "Payout date", "value": _fmt_date(payout_date) if payout_date else "--"},
            {"field": "Attendance-based payment", "value": f"{_fmt_money(result.get('attended_care_amount'))} ({amount_type})"},
            {"field": "Vacant slot payment", "value": f"{_fmt_money(result.get('vacant_slot_amount'))} ({amount_type})"},
            {"field": "At risk", "value": f"{_fmt_money(result.get('amount_at_risk'))} ({_risk_detail})" if _risk_detail else _fmt_money(result.get("amount_at_risk"))},
        ]
        summary_rows.append({"field": "Potential total", "value": _fmt_money(result.get("potential_total_amount") or result.get("total_amount"))})
        tbl = _mk_table("Payment summary", [("field", "Field"), ("value", "Value")], summary_rows)
        if tbl:
            blocks.append(tbl)
        blocks.append(_mk_text(DISCLAIMER_TEXT, italic=True))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payment_multi_period(recommended):
    result = _ctx("paymentResult") or {}
    periods = result.get("periods") or []
    blocks = []
    if not periods:
        blocks.append(_mk_accordion([{"title": "Payment summary", "content": "No service periods found for that range."}]))
    else:
        page = _ctx("turnRequest.fetchParams.page") or 0
        try:
            page = int(page)
        except (TypeError, ValueError):
            page = 0
        all_rows = []
        for p in periods:
            period_range = _fmt_date_range(p.get("service_period_start"), p.get("service_period_end"))
            payout_date = _fmt_date(p.get("payment_release_date")) if p.get("payment_release_date") else "--"
            potential_total = p.get("potential_total_amount") or p.get("total_amount")
            status = "Calculated" if p.get("payment_history_found") else ("At-risk" if (p.get("at_risk_day_count") or 0) > 0 else "Expected")
            all_rows.append({"service_period": period_range or (p.get("service_period_id") or "--"),
                             "payout_date": payout_date, "potential_total": _fmt_money(potential_total), "status": status})
        total_count = len(all_rows)
        start_idx = page * MULTI_PERIOD_PAGE_SIZE
        page_rows = all_rows[start_idx:start_idx + MULTI_PERIOD_PAGE_SIZE]
        grand_total = sum((Decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
        caption = f"Payment summary — period by period · Grand total: {_fmt_money(grand_total)}"
        if total_count > MULTI_PERIOD_PAGE_SIZE:
            shown_end = min(start_idx + MULTI_PERIOD_PAGE_SIZE, total_count)
            caption += f" · Showing {start_idx + 1}–{shown_end} of {total_count} periods"
        tbl = _mk_table(
            caption,
            [("service_period", "Service period"), ("payout_date", "Payout date"),
             ("potential_total", "Potential total", "right"), ("status", "Status")],
            page_rows,
        )
        if tbl:
            blocks.append(tbl)
        blocks.append(_mk_text(DISCLAIMER_TEXT, italic=True))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payment_full_breakdown(recommended):
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    calculated_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    settled = result.get("payment_history_found") is True
    period_range = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end"))
    period_label = period_range or (result.get("service_period_id") or "--")
    page = _ctx("turnRequest.fetchParams.page") or 0
    try:
        page = int(page)
    except (TypeError, ValueError):
        page = 0
    total_calc = len(calculated_rows)
    start_idx = page * FULL_BREAKDOWN_PAGE_SIZE
    page_rows = calculated_rows[start_idx:start_idx + FULL_BREAKDOWN_PAGE_SIZE]
    caption = f"Full attendance breakdown — {period_label}"
    if total_calc > FULL_BREAKDOWN_PAGE_SIZE:
        shown_end = min(start_idx + FULL_BREAKDOWN_PAGE_SIZE, total_calc)
        caption += f" · Showing {start_idx + 1}–{shown_end} of {total_calc} days"
    blocks = []
    if page_rows:
        tbl = _mk_table(
            caption,
            [("service_date", "Service date"), ("attendance_type", "Attendance type"),
             ("care_hours", "Care hours", "right"), ("amount", "Amount", "right"), ("amount_type", "Amount type")],
            [{"service_date": _fmt_date(r.get("service_date")),
              "attendance_type": (r.get("classification") or "--").replace("_", " ").title(),
              "care_hours": _fmt_hours(r.get("payable_hours")),
              "amount": _fmt_money(r.get("amount")),
              "amount_type": "At-risk" if r.get("status") == "at_risk" else ("Calculated" if settled else "Expected")}
             for r in page_rows],
        )
        if tbl:
            blocks.append(tbl)
    blocks.append(_mk_text(DISCLAIMER_TEXT, italic=True))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payment_child_detail(recommended, child_key):
    result = _ctx("paymentResult") or {}
    rows = _child_rows(result.get("rows") or [], child_key)
    blocks = []
    if not rows:
        blocks.append(_mk_text(f"No attendance found for \"{child_key}\" in this service period."))
        btn = _mk_buttons(recommended)
        if btn:
            blocks.append(btn)
        return blocks
    auth_name = rows[0].get("authorization_name") or child_key
    county_name = rows[0].get("county_name") or "--"
    payable_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    category_rows = []
    total_days, total_hours, total_amount = 0, Decimal("0"), Decimal("0")
    for label, group in _group_by_classification(payable_rows).items():
        days = len(group)
        hours = sum((Decimal(str(r.get("payable_hours") or "0")) for r in group), Decimal("0"))
        amount = sum((Decimal(r["amount"]) for r in group), Decimal("0"))
        category_rows.append({"category": label, "days": days, "hours": _fmt_hours(float(hours)), "amount": _fmt_money(str(amount))})
        total_days += days
        total_hours += hours
        total_amount += amount
    category_rows.append({"category": "Total", "days": total_days, "hours": _fmt_hours(float(total_hours)), "amount": _fmt_money(str(total_amount))})
    tbl = _mk_table(
        f"Authorization: {auth_name} · County: {county_name}",
        [("category", "Category"), ("days", "Days", "right"), ("hours", "Hours", "right"), ("amount", "Amount", "right")],
        category_rows,
    )
    if tbl:
        blocks.append(tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_payment_county_detail(recommended, county_key):
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    key = str(county_key or "").strip().lower()
    matching = [r for r in rows if str(r.get("county_name") or "").strip().lower() == key]
    blocks = []
    if not matching:
        blocks.append(_mk_accordion([{"title": f"County detail — {county_key}",
                                      "content": f"No payment data found for county \"{county_key}\" in this service period."}]))
        btn = _mk_buttons(recommended)
        if btn:
            blocks.append(btn)
        return blocks
    attended = [r for r in matching if r.get("kind") == "ATTENDED_CARE" and r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    attended_amount = sum((Decimal(r["amount"]) for r in attended), Decimal("0"))
    attended_hours = sum((Decimal(str(r.get("payable_hours") or "0")) for r in attended), Decimal("0"))
    vacant_amount = sum((Decimal(r["amount"]) for r in vacant), Decimal("0"))
    county_name = matching[0].get("county_name") or county_key
    tbl = _mk_table(
        f"County: {county_name}",
        [("attendance_payment", "Attendance-based payment"), ("vacant_payment", "Vacant slot payment")],
        [{"attendance_payment": f"{_fmt_money(str(attended_amount))} ({_fmt_hours(float(attended_hours))} hrs)",
          "vacant_payment": _fmt_money(str(vacant_amount))}],
    )
    if tbl:
        blocks.append(tbl)
    blocks.append(_mk_accordion([{"title": "Note", "content": "To see a specific child's detail, ask about that child's authorization by name."}]))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_explain(recommended):
    payment_result = _ctx("paymentResult") or {}
    snapshot = (_ctx("data_collection_result") or {}).get("snapshot") or {}
    blocks = []
    at_risk_amt = payment_result.get("amount_at_risk")
    at_risk_days = payment_result.get("at_risk_day_count") or 0
    try:
        _at_risk_float = float(at_risk_amt) if at_risk_amt else 0
    except (TypeError, ValueError):
        _at_risk_float = 0
    if _at_risk_float > 0:
        _detail = _at_risk_reason(payment_result)
        content = (
            "A day is marked **at risk** when care was provided but parent confirmation is still pending. "
            "The county holds payment on those days until the parent confirms.\n\n"
            f"Your current at-risk amount: **{_fmt_money(at_risk_amt)}** "
            f"({at_risk_days} day(s) — {_detail or 'awaiting confirmation'})"
        )
        blocks.append(_mk_accordion([{"title": "About “at risk” amounts", "content": content, "open": True}]))
    risk = snapshot.get("risk_categories") or {}
    pending_days = (risk.get("pending_parent_confirmations") or {}).get("days", 0) or 0
    absence_children = (
        ((risk.get("approaching_absence_limits") or {}).get("children", 0) or 0)
        + ((risk.get("crossed_absence_limits") or {}).get("children", 0) or 0)
    )
    incomplete_days = (risk.get("incomplete_attendance") or {}).get("days", 0) or 0
    summary_rows = []
    if pending_days:
        summary_rows.append({"area": "Pending confirmations", "status": f"{pending_days} day(s) need parent sign-off"})
    if absence_children:
        summary_rows.append({"area": "Absence limits", "status": f"{absence_children} child(ren) near or over the monthly limit"})
    if incomplete_days:
        summary_rows.append({"area": "Incomplete attendance", "status": f"{incomplete_days} day(s) missing check-in or check-out"})
    if summary_rows:
        tbl = _mk_table("Current items requiring attention", [("area", "Area"), ("status", "Status")], summary_rows)
        if tbl:
            blocks.append(tbl)
    elif not blocks:
        blocks.append(_mk_accordion([{"title": "Current status", "content": "No outstanding items found for the current period."}]))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_attendance_all(recommended):
    blocks = [_mk_text("**Attendance overview**")]
    for blk in _blocks_absence_limits([]):
        blocks.append(blk)
    for blk in _blocks_incomplete_attendance([]):
        blocks.append(blk)
    dcr = _ctx("data_collection_result") or {}
    pending_cat = ((dcr.get("snapshot") or {}).get("risk_categories") or {}).get("pending_parent_confirmations") or {}
    pending_days = pending_cat.get("days") or 0
    if pending_days:
        blocks.append(_mk_accordion([{"title": "Pending parent confirmations",
                                      "content": f"{pending_days} day(s), {pending_cat.get('children', 0)} child(ren) — use \"Show pending confirmations\" for detail."}]))
    else:
        blocks.append(_mk_text("No pending parent confirmations"))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks
def _blocks_payment_needs_period_selection(candidates):
    tbl = _mk_table(
        "Service periods found",
        [("num", "#", "right"), ("service_period", "Service period"), ("status", "Status")],
        [{"num": i + 1, "service_period": c.get("label", "--"), "status": "Awaiting selection"} for i, c in enumerate(candidates)],
    )
    blocks = [_mk_text("I found more than one service period matching that request. Which one did you mean?")]
    if tbl:
        blocks.append(tbl)
    return blocks


def _blocks_clarify(recommended, prior_recommended=None):
    session_state = _ctx("sessionState") or {}
    provider_verified = session_state.get("providerVerified", False)
    provider_name = (session_state.get("providerName") or "").strip()
    if provider_verified and provider_name:
        headline = f"What can I help you with next, {provider_name}?"
    elif provider_verified:
        headline = "What can I help you with next?"
    else:
        headline = "Welcome to Provider Assist. What would you like to look at today?"
    content = f"{headline}\n\nChoose an option below, or tell me in your own words."
    blocks = [_mk_text(content)]
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_unauthorized():
    return [_mk_accordion([{"title": "Verification required",
                            "content": "The provider account on this session couldn't be verified, or is outside the authorized CCARE services for this program. If this seems incorrect, please contact your program administrator."}])]


def _blocks_fallback(recommended):
    blocks = [_mk_accordion([{"title": "Unable to load snapshot",
                              "content": "I couldn't load today's provider snapshot. Please try again later or contact your system administrator."}])]
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks



# ==============================================================================
# ENTRY POINT
# ==============================================================================

_previous_recommended = list(_ctx("recommendedActions") or [])
_selected, _updated_shown = _recommend()
write_context("recommendedActions", _selected)
write_context("shownActionIds", _updated_shown)

_turn_request = _ctx("turnRequest") or {}
_action = _turn_request.get("action")
_sub_filter = _turn_request.get("subFilter")
_recommended = _selected
_provider_status = (_ctx("ccare_provider_data_py") or {}).get("status")
_payment_result = _ctx("paymentResult") or {}

if _provider_status == "failed":
    _formatted = render_unauthorized()
elif _action == "STARTER":
    _formatted = render_greeting(_recommended)
elif _provider_status == "needs_clarification" or _action == "CLARIFY":
    _formatted = render_clarify(_recommended, _previous_recommended)
elif _action == "EXPLAIN":
    _formatted = render_explain(_recommended)
elif _action == "PAYMENT":
    _child_names = [c for c in (_turn_request.get("childNames") or []) if c]
    _county_names = [c for c in (_turn_request.get("countyNames") or []) if c]
    if _payment_result.get("mode") == "multi_period":
        _formatted = render_payment_multi_period(_recommended)
    elif _payment_result.get("status") == "needs_period_selection":
        _formatted = render_payment_needs_period_selection(_payment_result.get("candidates") or [])
    elif _sub_filter == "FULL_BREAKDOWN":
        _formatted = render_payment_full_breakdown(_recommended)
    elif _child_names:
        # Level 1a drill-down -- provider named a specific child/authorization.
        _formatted = render_payment_child_detail(_recommended, _child_names[0])
    elif _county_names:
        # Level 1b drill-down -- provider named a specific county.
        _formatted = render_payment_county_detail(_recommended, _county_names[0])
    else:
        # render_payment now handles both "ok" and "blocked" -- a per-row/
        # top-level blocker no longer hides an otherwise-calculated total.
        _formatted = render_payment(_recommended)
elif _action == "ATTENDANCE":
    if _sub_filter == "PENDING_CONFIRMATIONS":
        _formatted = render_pending_confirmations(_recommended)
    elif _sub_filter == "ABSENCE_LIMITS":
        _formatted = render_absence_limits(_recommended)
    elif _sub_filter == "INCOMPLETE_ATTENDANCE":
        _formatted = render_incomplete_attendance(_recommended)
    elif _sub_filter == "PAYOUT_IMPACT":
        _formatted = render_payout_impact(_recommended)
    else:
        _formatted = render_attendance_all(_recommended)
else:
    _formatted = render_fallback(_recommended)

# Every response that exposes a dollar amount must carry the same estimate
# disclaimer, including drill-down and explanation responses.
if "$" in _formatted and DISCLAIMER_GLOBAL not in _formatted:
    _formatted = f"{_formatted}\n\n{DISCLAIMER_GLOBAL}"

# First-turn greeting: prepend "Hi {name}!" on every action except STARTER
# (render_greeting already includes the name for STARTER turns).
_greeting_block = None
if not _ctx("greetingDone") and _action not in (None, "STARTER", "END"):
    _snap = (_ctx("data_collection_result") or {}).get("snapshot") or {}
    _greet_name = (
        _snap.get("user_name")
        or (_ctx("ccare_provider_data_py") or {}).get("providerName")
        or "Provider"
    )
    if str(_greet_name).isdigit():
        _greet_name = "Provider"
    _GREETING_PHRASES = {
        "PAYMENT": {
            "NEXT_PAYOUT":           "Here's your next estimated payout",
            "LAST_PAYOUT":           "Here's a summary of your last payout",
            "CURRENT_PERIOD_FORECAST": "Here's the forecast for your current period",
            "CURRENT_MONTH":         "Here's your payment summary for this month",
            "FULL_BREAKDOWN":        "Here's the full day-by-day breakdown you requested",
            "ALL":                   "Here's your complete payment overview",
            "SPECIFIC_PERIOD":       "Here's the payment detail for that period",
        },
        "ATTENDANCE": {
            "PENDING_CONFIRMATIONS": "Let's take a look at your pending confirmations",
            "ABSENCE_LIMITS":        "Here's a review of your current absence limits",
            "INCOMPLETE_ATTENDANCE": "Here's a look at your incomplete attendance records",
            "PAYOUT_IMPACT":         "Here's how your current attendance activity could affect your payout",
            "ALL":                   "Here's your full attendance overview",
        },
        "EXPLAIN":  {"__default__": "Happy to clarify that for you"},
        "CLARIFY":  {"__default__": "Happy to help you narrow that down"},
    }
    _action_phrases = _GREETING_PHRASES.get(_action) or {}
    _greet_prefix = _action_phrases.get(_sub_filter) or _action_phrases.get("__default__")
    if _greet_prefix:
        _greeting_msg = f"{_greet_prefix}, {_greet_name}."
    else:
        _greeting_msg = f"Welcome back, {_greet_name}."
    _greeting_block = _mk_text(_greeting_msg)
    _formatted = f"{_greeting_msg}\n\n" + _formatted
write_context("greetingDone", True)


# Build formattedBlocks in parallel with the Markdown _formatted above.
if _provider_status == "failed":
    _blocks = _blocks_unauthorized()
elif _action == "STARTER":
    _blocks = _blocks_greeting(_recommended)
elif _provider_status == "needs_clarification" or _action == "CLARIFY":
    _blocks = _blocks_clarify(_recommended, _previous_recommended)
elif _action == "EXPLAIN":
    _blocks = _blocks_explain(_recommended)
elif _action == "PAYMENT":
    _cnb = [c for c in (_turn_request.get("childNames") or []) if c]
    _cob = [c for c in (_turn_request.get("countyNames") or []) if c]
    if _payment_result.get("mode") == "multi_period":
        _blocks = _blocks_payment_multi_period(_recommended)
    elif _payment_result.get("status") == "needs_period_selection":
        _blocks = _blocks_payment_needs_period_selection(_payment_result.get("candidates") or [])
    elif _sub_filter == "FULL_BREAKDOWN":
        _blocks = _blocks_payment_full_breakdown(_recommended)
    elif _cnb:
        _blocks = _blocks_payment_child_detail(_recommended, _cnb[0])
    elif _cob:
        _blocks = _blocks_payment_county_detail(_recommended, _cob[0])
    else:
        _blocks = _blocks_payment(_recommended)
elif _action == "ATTENDANCE":
    if _sub_filter == "PENDING_CONFIRMATIONS":
        _blocks = _blocks_pending_confirmations(_recommended)
    elif _sub_filter == "ABSENCE_LIMITS":
        _blocks = _blocks_absence_limits(_recommended)
    elif _sub_filter == "INCOMPLETE_ATTENDANCE":
        _blocks = _blocks_incomplete_attendance(_recommended)
    elif _sub_filter == "PAYOUT_IMPACT":
        _blocks = _blocks_payout_impact(_recommended)
    else:
        _blocks = _blocks_attendance_all(_recommended)
else:
    _blocks = _blocks_fallback(_recommended)
if _greeting_block:
    _blocks = [_greeting_block] + _blocks
write_context("formattedBlocks", _blocks)
write_context("formattedResponse", _formatted)

_RICH_TYPES_R = {"table", "buttons", "accordion"}
_KEY_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")

def _scalar(v):
    return v is None or isinstance(v, (str, int, float, bool))

def _vld_table(b):
    cols, rows = b.get("columns"), b.get("rows")
    if not isinstance(cols, list) or not 1 <= len(cols) <= 12: return False
    if not isinstance(rows, list) or len(rows) > 100: return False
    keys = []
    for c in cols:
        if not isinstance(c, dict): return False
        k = c.get("key")
        if not isinstance(k, str) or not _KEY_RE.fullmatch(k) or k in keys: return False
        if not isinstance(c.get("label"), str): return False
        if c.get("align") not in (None, "left", "center", "right"): return False
        keys.append(k)
    for r in rows:
        if not isinstance(r, dict) or any(k not in keys for k in r): return False
        if not all(_scalar(r.get(k)) for k in keys): return False
    return True

def _vld_buttons(b):
    items = b.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8: return False
    for i in items:
        if not isinstance(i, dict) or not isinstance(i.get("label"), str): return False
        if "value" in i and not isinstance(i["value"], str): return False
        if i.get("variant") not in (None, "primary", "secondary"): return False
    return True

def _vld_accordion(b):
    items = b.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8: return False
    for i in items:
        if not isinstance(i, dict): return False
        if not isinstance(i.get("title"), str) or not isinstance(i.get("content"), str): return False
        if "```chat-ui" in i["content"]: return False
        if "open" in i and not isinstance(i["open"], bool): return False
    return True

def _vld_block(b):
    if not isinstance(b, dict) or b.get("version") != 1: return False
    t = b.get("type")
    if t == "text":
        return isinstance(b.get("content"), str) and ("italic" not in b or isinstance(b.get("italic"), bool))
    if t not in _RICH_TYPES_R: return False
    if t == "table": return _vld_table(b)
    if t == "buttons": return _vld_buttons(b)
    return _vld_accordion(b)

_parts = []
for _b in _blocks:
    if not _vld_block(_b): continue
    if _b.get("type") == "text":
        _c = _b.get("content", "")
        _parts.append(f"*{_c}*" if _b.get("italic") else _c)
    else:
        _parts.append("```chat-ui\n" + json.dumps(_b, ensure_ascii=False, separators=(",", ":")) + "\n```")

respond(
    "\n\n".join(_parts) if _parts else "I could not load today's provider snapshot. Please try again later or contact your system administrator.",
    confidence=1.0,
)

# __________________________GenAI: Generated code ends here______________________________
