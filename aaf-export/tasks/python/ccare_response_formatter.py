"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Builds deterministic provider responses and recommended actions.
Runtime affordances: read_context, write_context, respond().
"""

import json
import re
from decimal import Decimal, InvalidOperation

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
    "*⚠️ This is an estimate based on current attendance records, authorizations, and rates on file. "
    "The county determines the final amount during payment processing.*"
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



def _candidate(id_, label, action, sub_filter, severity):
    return {"id": id_, "label": label, "action": action, "subFilter": sub_filter, "severity": severity}


def _distinct_child_count(rows):
    keys = {
        str(row.get("child_id") or row.get("child_name")).strip()
        for row in rows
        if isinstance(row, dict) and (row.get("child_id") or row.get("child_name"))
    }
    return len(keys)


def _absence_day_counts(rows, win_start=None):
    """Count near-limit absence days separately from days beyond the limit."""
    approaching_days = 0
    crossed_days = 0
    for row in rows if isinstance(rows, list) else []:
        if not isinstance(row, dict):
            continue
        status = row.get("status") or ""
        if status in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT"):
            over_dates = _over_limit_dates(row)
            if win_start:
                over_dates = [d for d in over_dates if d and d >= win_start]
            crossed_days += len(over_dates)
        else:
            confirmed_dates = {str(value) for value in row.get("confirmed_absence_dates") or [] if value}
            probable_dates = {str(value) for value in row.get("probable_absence_dates") or [] if value}
            try:
                confirmed_count = len(confirmed_dates) or int(row.get("confirmed_absence_count") or 0)
            except (TypeError, ValueError):
                confirmed_count = len(confirmed_dates)
            try:
                probable_count = len(probable_dates) or int(row.get("probable_absence_count") or 0)
            except (TypeError, ValueError):
                probable_count = len(probable_dates)
            approaching_days += confirmed_count + probable_count
    return approaching_days, crossed_days


def _absence_finding(rows, win_start=None):
    child_count = _distinct_child_count(rows)
    approaching_days, crossed_days = _absence_day_counts(rows, win_start=win_start)
    if not child_count:
        return "No children currently near or over county monthly absence limits"
    parts = []
    if approaching_days > 0:
        parts.append(f"{approaching_days} day(s) approaching the limit")
    if crossed_days > 0:
        parts.append(f"{crossed_days} day(s) over the limit")
    return ("; ".join(parts) + f" across {child_count} child(ren)") if parts else f"Absence risk across {child_count} child(ren)"


def _over_limit_dates(row):
    limit = int(row.get("absence_limit") or 0)
    confirmed = sorted(row.get("confirmed_absence_dates") or [])
    probable = sorted(row.get("probable_absence_dates") or [])
    over_confirmed = confirmed[limit:] if limit > 0 else confirmed
    remaining_capacity = max(0, limit - len(confirmed))
    over_probable = probable[remaining_capacity:]
    return over_confirmed + over_probable


def _date_range_for_dates(dates):
    valid = sorted(str(d) for d in (dates or []) if d)
    if not valid:
        return None
    if valid[0] == valid[-1]:
        return _fmt_date(valid[0])
    return _fmt_date_range(valid[0], valid[-1])

def _absence_rows_for_summary(rows, win_start):
    """OVER_LIMIT/POTENTIAL_OVER_LIMIT always surface; APPROACHING groups only when within window."""
    _crossed = {"OVER_LIMIT", "POTENTIAL_OVER_LIMIT"}
    result = []
    for r in (rows or []):
        status = r.get("status") or ""
        if status in _crossed or not win_start:
            result.append(r)
        else:
            all_dates = list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])
            if any((d or "") >= win_start for d in all_dates):
                result.append(r)
    return result

def _build_candidates(current_action, current_sub_filter):
    """Every possible recommended action for THIS turn's data, in no
    particular order yet -- dedup/priority/deprioritize happens after."""
    candidates = []

    if current_action == "END":
        return candidates

    if current_action == "CLARIFY":
        _kickstarts = [
            _candidate("kickstart_attendance", "Review attendance and pending items", "ATTENDANCE", "ALL", "INFO"),
            _candidate("kickstart_overview", "Show today's overview", "STARTER", None, "INFO"),
        ]
        _snap_for_clarify = ((_ctx("data_collection_result") or {}).get("snapshot") or {})
        _has_payment = bool(
            _snap_for_clarify.get("payment_history_found")
            or (_snap_for_clarify.get("service_period_count") or 0) > 0
            or (_snap_for_clarify.get("service_periods") or [])
        )
        if _has_payment:
            _kickstarts.insert(1, _candidate("kickstart_payment", "Review a payout or payment", "PAYMENT", "NEXT_PAYOUT", "INFO"))
        return _kickstarts

    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    payment_result = _ctx("paymentResult") or {}
    attendance_scope = current_action in ("STARTER", "ATTENDANCE")

    _ref_date = (analyzer.get("reference_date") or "")[:10]
    _lookback = int(analyzer.get("lookback_days") or 9)
    _win_start = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_start = str(_ddate.fromisoformat(_ref_date) - _dtd(days=_lookback))
    except Exception:
        pass
    _analyzer_pending = analyzer.get("pending_confirmation_records") or []
    _windowed_pending_cands = [r for r in _analyzer_pending
                               if not _win_start or (r.get("date") or "") >= _win_start]
    pending_days = len(_windowed_pending_cands)
    overview_scope = current_action == "STARTER" or (current_action == "ATTENDANCE" and current_sub_filter == "ALL")
    if overview_scope:
        candidates.append(
            _candidate("upcoming_payment", "Check your upcoming payout", "PAYMENT", "NEXT_PAYOUT", "INFO")
        )
        candidates.append(
            _candidate("current_week_forecast", "See this week's payment forecast", "PAYMENT", "CURRENT_PERIOD_FORECAST", "INFO")
        )
    if overview_scope and pending_days:
        _conf_label = f"Review {pending_days} pending day(s)"
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
                    "payout_impact_pending",
                    "See estimated payout impact of these pending days",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )

    approaching = _absence_rows_for_summary(
        analyzer.get("approaching_absence_limits") or [], _win_start
    ) if attendance_scope else []
    if approaching and overview_scope:
        absence_child_count = _distinct_child_count(approaching)
        _exc_rows = [r for r in approaching if isinstance(r, dict) and (r.get("status") or "") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")]
        _app_rows = [r for r in approaching if isinstance(r, dict) and (r.get("status") or "") == "APPROACHING_LIMIT"]
        severity = "URGENT" if _exc_rows else "REVIEW"
        _abs_label_parts = []
        if _exc_rows:
            _abs_label_parts.append(f"{_distinct_child_count(_exc_rows)} exceeded")
        if _app_rows:
            _abs_label_parts.append(f"{_distinct_child_count(_app_rows)} approaching")
        _abs_label_summary = ", ".join(_abs_label_parts) if _abs_label_parts else "risk detected"
        candidates.append(
            _candidate(
                "absence_limits",
                f"Review absence risk -- {_abs_label_summary} ({absence_child_count} child(ren))",
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
                    "payout_impact_absence",
                    "See estimated payout impact of these absence risks",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )

    unconfirmed = analyzer.get("pending_confirmation_records") or [] if attendance_scope else []
    impact_rows = (_ctx("payoutImpactResult") or {}).get("rows") or []
    incomplete_attendance = [
        row for row in impact_rows
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
        and (not _win_start or (row.get("date") or row.get("service_date") or "") >= _win_start)
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
                    "payout_impact_incomplete",
                    "See estimated payout impact of these missing records",
                    "ATTENDANCE",
                    "PAYOUT_IMPACT",
                    "REVIEW",
                )
            )
    # Use analyzer results for incomplete-attendance actions.

    # Scope payment actions to payment turns.
    if current_action != "PAYMENT":
        payment_result = {}

    # Add payment actions by result status.
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
                else "View full payment breakdown for this period"
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

    # Keep dashboard shortcuts reusable; risk actions are one-time.
    _never_expire = {"upcoming_payment", "current_week_forecast"}

    # Recommendations are deterministic.
    candidates = _build_candidates(current_action, current_sub_filter)

    # Deduplicate candidates and skip previously shown actions.
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

    # Omit the action currently being answered.
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

    # Do not track reusable dashboard shortcuts.
    new_ids = [c["id"] for c in selected if c["id"] not in _never_expire]
    updated_shown = list(dict.fromkeys(shown_ids + new_ids))
    write_context("recommendedActionScope", scope)

    return selected, updated_shown


# ==============================================================================
# FORMATTING HELPERS
# ==============================================================================

def _fmt_date(value):
    """Format a provider-facing date; preserve unparseable values."""
    text = str(value or "")[:10]
    try:
        y, m, d = (int(p) for p in text.split("-"))
        return f"{_MONTH_ABBR[m - 1]} {d}, {y}"
    except Exception:
        return text or "--"


def _safe_display_value(value):
    """Hide Salesforce-ID-shaped values from provider display."""
    text = str(value) if value else ""
    return text if text and not (text.isalnum() and len(text) >= 15) else "--"


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


def _rate_type_display(row):
    """Format rate type with its payment basis."""
    label = row.get("rate_type_label")
    basis = row.get("payment_basis")
    if label and basis:
        return f"{label}({basis})"
    if label:
        return label
    return (row.get("classification") or "--").replace("_", " ").title()


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
    """Group rows by classification in first-seen order."""
    groups = {}
    for r in rows:
        label = (r.get("classification") or "Other").replace("_", " ").title()
        groups.setdefault(label, []).append(r)
    return groups


def _safe_decimal(value, default=Decimal("0")):
    """Parse a value as Decimal without raising."""
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        return default


def _escape_cell(value):
    """Escape pipes and collapse newlines for Markdown cells."""
    text = str(value) if value is not None else "--"
    return text.replace("|", "\\|").replace("\n", " ").replace("\r", "")


def _table(headers, rows):
    if not rows:
        return None
    lines = ["| " + " | ".join(headers) + " |", "|" + "|".join(["---"] * len(headers)) + "|"]
    for row in rows:
        lines.append("| " + " | ".join(_escape_cell(c) for c in row) + " |")
    return "\n".join(lines)


def _actions_block(recommended):
    if not recommended:
        return "There is no other action I can recommend for this view. You can ask me about anything else."
    lines = ["### Recommended actions"]
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
        "## Account verification needed\n\n"
        "I am unable to verify your provider account for this session — it may not yet be authorized "
        "for CCARE services, or the session may have expired. If you believe this is incorrect, please "
        "contact your program administrator to review your access."
    )


def render_connection_error():
    return (
        "## Unable to connect\n\n"
        "I'm unable to establish a secure connection with the system right now. "
        "Please try again in a few minutes. If this continues, contact your program administrator."
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
    analyzer_pending_rows = analyzer.get("pending_confirmation_records") or []

    _ref_date = (analyzer.get("reference_date") or "")[:10]
    _lookback = int(analyzer.get("lookback_days") or 9)
    _win_start = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_start = str(_ddate.fromisoformat(_ref_date) - _dtd(days=_lookback))
    except Exception:
        pass
    _windowed_pending = [r for r in analyzer_pending_rows
                         if not _win_start or (r.get("date") or "") >= _win_start]
    pending_days = len(_windowed_pending)
    _pending_win_children = len({r.get("child_id") for r in _windowed_pending if r.get("child_id")})
    _pending_range = _date_range_for_dates(r.get("date") for r in _windowed_pending)
    pending_finding = (
        "No pending parent confirmations"
        if not pending_days
        else f"{pending_days} day(s), {_pending_win_children} child(ren)"
    )
    _summary_absence_rows = _absence_rows_for_summary(analyzer_absence_rows, _win_start)
    # Any status that isn't exceeded counts as "approaching" -- the analyzer
    # can emit APPROACHING_LIMIT OR POTENTIAL_APPROACHING_LIMIT (confirmed
    # live: a row with the latter was silently dropped by an exact-match
    # check on "APPROACHING_LIMIT" only, showing "no risk" in this table
    # while the recommended-action builder correctly flagged the same row).
    _exceeded_statuses = ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
    _exceeded_rows = [r for r in _summary_absence_rows if (r.get("status") or "") in _exceeded_statuses]
    _approaching_rows = [r for r in _summary_absence_rows if (r.get("status") or "") not in _exceeded_statuses]
    _exc_win_dates = [d for r in _exceeded_rows for d in _over_limit_dates(r) if not _win_start or d >= _win_start]
    _exc_days = len(_exc_win_dates)
    _exc_children = _distinct_child_count(_exceeded_rows)
    _app_children = _distinct_child_count(_approaching_rows)
    _exc_range = _date_range_for_dates(_exc_win_dates)
    _app_dates = [d for r in _approaching_rows for d in (list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or []))]
    _app_range = _date_range_for_dates(_app_dates)
    _absence_finding_parts = []
    _absence_period_parts = []
    if _exceeded_rows:
        _absence_finding_parts.append(f"Limit exceeded: {_exc_children} child(ren), {_exc_days} day(s) in window")
        _absence_period_parts.append(_exc_range or "--")
    if _approaching_rows:
        _absence_finding_parts.append(f"Approaching limit: {_app_children} child(ren)")
        _absence_period_parts.append(_app_range or "--")
    absence_finding = "\n".join(_absence_finding_parts) or "No children near or over county absence limits"
    _absence_range = "\n".join(_absence_period_parts) or "--"
    incomplete_attendance_rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ]
    _windowed_incomplete = [r for r in incomplete_attendance_rows
                            if not _win_start or (r.get("date") or "") >= _win_start]
    incomplete_days = len(_windowed_incomplete)
    incomplete_finding = "No incomplete check-in/out found" if not incomplete_days else f"{incomplete_days} day(s)"
    _incomplete_range = _date_range_for_dates(r.get("date") for r in _windowed_incomplete)

    def _loss(cat):
        val = cat.get("potential_loss_hours") if isinstance(cat, dict) else None
        amount = cat.get("potential_loss_amount") if isinstance(cat, dict) else None
        if isinstance(val, (int, float)):
            hours = "%.1f" % val
            return f"{_fmt_money(amount)} ({hours} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    _absence_impact_parts = []
    if _exceeded_rows:
        _absence_impact_parts.append(_loss(approaching))
    if _approaching_rows:
        _absence_impact_parts.append("Within county limit")
    _absence_impact = "\n".join(_absence_impact_parts) or "No actionable impact"

    issues_table = _table(
        ["Risk area", "Verified finding", "Period", "Potential payment impact"],
        [
            ["Pending parent confirmations", pending_finding, _pending_range or "--", _loss(pending) if pending_days else "No actionable impact"],
            ["Absence-limit risk", absence_finding, _absence_range, _absence_impact],
            ["Incomplete check-ins/check-outs", incomplete_finding, _incomplete_range or "--", _loss(incomplete) if incomplete_days else "No actionable impact"],
        ],
    )
    _progress_sent = bool(_ctx("progressMessage"))
    _intro = f"{user_name}, here's where things stand today at {facility_name}."
    body = ([] if _progress_sent else [_intro, ""]) + [
        "## Today's snapshot",
        snap_table,
        "",
        "## Attendance and payment issues",
        issues_table,
        "",
        _actions_block(recommended),
    ]
    return "\n".join(part for part in body if part is not None)


def render_pending_confirmations(recommended):
    _analyzer = _ctx("attendance_risks_analyzer_py") or {}
    _ref = (_analyzer.get("reference_date") or "")[:10]
    _lkb = int(_analyzer.get("lookback_days") or 9)
    _win = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win = str(_ddate.fromisoformat(_ref) - _dtd(days=_lkb))
    except Exception:
        pass
    all_pending = _analyzer.get("pending_confirmation_records") or []
    rows = [r for r in all_pending if not _win or (r.get("date") or "") >= _win]
    table = _table(
        ["Child", "Authorization", "Service date", "Status"],
        [
            [_safe_display_value(r.get("child_name") or ""), r.get("auth_id") or "--", _fmt_date(r.get("date")), "Pending"]
            for r in rows
        ],
    )
    body = ["## Pending parent confirmations", "", table or "There are currently no pending parent confirmations.", "", _actions_block(recommended)]
    return "\n".join(body)


def render_absence_limits(recommended, _emit_actions=True):
    _analyzer_al = _ctx("attendance_risks_analyzer_py") or {}
    _ref_al = (_analyzer_al.get("reference_date") or "")[:10]
    _win_al = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_al = str(_ddate.fromisoformat(_ref_al) - _dtd(days=int(_analyzer_al.get("lookback_days") or 9)))
    except Exception:
        pass
    rows = _absence_rows_for_summary(
        _analyzer_al.get("approaching_absence_limits") or [], _win_al
    )
    period = _period_label()
    period_line = f"*Period: {period}*" if period else None
    if not rows:
        body = ["## Absence-limit risk"]
        if period_line:
            body += [period_line]
        body += ["", "No children currently near or over county monthly absence limits."]
        if _emit_actions:
            body += ["", _actions_block(recommended)]
        return "\n".join(body)
    _payout_rows = [r for r in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
                    if isinstance(r, dict) and r.get("risk_category") == "absence"]
    _impact_by_auth = {}
    for pr in _payout_rows:
        _ak = str(pr.get("authorization_id") or pr.get("auth_id") or pr.get("child_name") or "")
        if _ak not in _impact_by_auth:
            _impact_by_auth[_ak] = {"hours": 0.0, "amount": 0.0}
        _impact_by_auth[_ak]["hours"] += float(pr.get("care_hours") or 0)
        try:
            _impact_by_auth[_ak]["amount"] += float(pr.get("amount") or 0)
        except (TypeError, ValueError):
            pass
    table_rows = []
    for r in rows:
        _rs = r.get("status") or ""
        _is_exc = _rs in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
        _risk_type = "Limit exceeded" if _is_exc else "Approaching limit"
        _auth_key = str(r.get("authorization_id") or r.get("auth_id") or r.get("child_name") or "")
        if _is_exc:
            _od_all = _over_limit_dates(r)
            _od_win = [d for d in _od_all if not _win_al or d >= _win_al]
            _at_risk_period = _date_range_for_dates(_od_all) or "--"
            _imp = _impact_by_auth.get(_auth_key)
            if _imp and _imp["amount"] > 0:
                _payment_impact = f"${_imp['amount']:.2f} at risk ({_imp['hours']:.1f} care hrs)"
            else:
                _payment_impact = "Outside confirmation window" if not _od_win else "At risk (rate unavailable)"
        else:
            _at_risk_period = _date_range_for_dates(
                list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])
            ) or "--"
            _payment_impact = "Within county limit"
        _confirmed_ct = r.get("confirmed_absence_count", len(r.get("confirmed_absence_dates") or []))
        _probable_ct = r.get("probable_absence_count", len(r.get("probable_absence_dates") or []))
        _used_total = (_confirmed_ct or 0) + (_probable_ct or 0)
        _absences_used = f"{_used_total} ({_probable_ct} not confirmed yet)" if _probable_ct else str(_used_total)
        table_rows.append([
            _risk_type,
            _safe_display_value(r.get("child_name") or ""),
            r.get("authorization_id") or r.get("auth_id") or "--",
            r.get("county_name") or "--",
            _absences_used,
            r.get("absence_limit", "--"),
            _at_risk_period,
            _payment_impact,
        ])
    table_rows.sort(key=lambda row: 0 if row[7] != "Outside confirmation window" else 1)
    table = _table(
        ["Risk type", "Child", "Authorization", "County", "Absences used", "County limit", "At-risk period", "Payment impact"],
        table_rows,
    )
    body = ["# Absence-limit risk"]
    if period_line:
        body += [period_line]
    body += ["", table]
    if _emit_actions:
        body += ["", _actions_block(recommended)]
    return "\n".join(body)


def render_incomplete_attendance(recommended, _emit_actions=True):
    _analyzer = _ctx("attendance_risks_analyzer_py") or {}
    _ref = (_analyzer.get("reference_date") or "")[:10]
    _lkb = int(_analyzer.get("lookback_days") or 9)
    _win = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win = str(_ddate.fromisoformat(_ref) - _dtd(days=_lkb))
    except Exception:
        pass
    rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
        and (not _win or (row.get("date") or "") >= _win)
    ]
    if not rows:
        body = [
            "## Missing check-in/check-out",
            "",
            "No missing check-ins or check-outs were found in this window.",
        ]
        if _emit_actions:
            body += ["", _actions_block(recommended)]
        return "\n".join(body)
    table = _table(
        ["Child", "Authorization", "Service date", "Attendance type", "Reason"],
        [
            [
                _safe_display_value(r.get("child_name") or ""),
                r.get("authorization_id") or r.get("auth_id") or "--",
                _fmt_date(r.get("date")),
                "Missing check-in/check-out",
                r.get("reason") or "A check-in or check-out was not logged for this day",
            ]
            for r in rows
        ],
    )
    body = ["# Missing check-in/check-out", "", table]
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
    body = ["## Attendance overview", "", absence_section, "", incomplete_section, "", pending_line, "", _actions_block(recommended)]
    return "\n".join(body)


def render_payout_impact(recommended):
    result = _ctx("payoutImpactResult") or {}
    rows = result.get("rows") or []
    _tr = _ctx("turnRequest") or {}
    _pi_scope = (_tr.get("id") or "") if isinstance(_tr, dict) else ""
    if _pi_scope == "payout_impact_absence":
        rows = [r for r in rows if (r.get("risk_category") or "") == "absence"]
    elif _pi_scope == "payout_impact_pending":
        rows = [r for r in rows if (r.get("risk_category") or "") == "unconfirmed"]
    elif _pi_scope == "payout_impact_incomplete":
        rows = [r for r in rows if (r.get("risk_category") or "") == "incomplete"]
    if not rows:
        body = [
            "## Payout impact of current attendance risk",
            "",
            "None of your current attendance risk is affecting an upcoming payout.",
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
            "## Payout impact of current attendance risk",
            "",
            "Attendance risk was found, but the payout impact cannot be calculated yet — "
            "rate schedule data may still be loading. Please try again shortly.",
            "",
            _actions_block(recommended),
        ]
        return "\n".join(body)
    table = _table(
        ["Child", "Authorization", "County", "Care hours", "Amount", "Reason"],
        [
            [
                _safe_display_value(r.get("child_name") or ""),
                r.get("authorization_id") or "--",
                r.get("county_name") or "--",
                _fmt_hours(r.get("care_hours")),
                _fmt_money(r.get("amount")),
                r.get("reason") or "--",
            ]
            for r in rows
        ],
    )
    total_hours = sum(float(r.get("care_hours") or 0) for r in _calc_rows)
    total_dollar = sum(float(r.get("amount") or 0) for r in _calc_rows)
    headline = f"~ {_fmt_money(total_dollar)} at risk across {_fmt_hours(total_hours)} care hour(s)"
    body = ["## Payout impact of current attendance risk", "", f"**{headline}**", "", table, "", DISCLAIMER_GLOBAL, "", _actions_block(recommended)]
    return "\n".join(body)


def render_payment_needs_period_selection(candidates):
    table = _table(
        ["#", "Service period", "Status"],
        [[i + 1, c.get("label", "--"), "Awaiting selection"] for i, c in enumerate(candidates)],
    )
    return "\n".join(["## Multiple service periods found", "", "Several service periods match this request. Please select the one you would like to review:", "", table])


MULTI_PERIOD_PAGE_SIZE = 7


def render_payment_multi_period(recommended):
    """Render paginated payment periods with totals and status."""
    result = _ctx("paymentResult") or {}
    periods = result.get("periods") or []
    if not periods:
        return "\n".join(["**Payment summary**", "", "I couldn't find any service periods in that date range. Please try a different range, or ask for your next payout.", "", _actions_block(recommended)])

    page = (_ctx("turnRequest.fetchParams.page")) or 0
    try:
        page = max(0, int(page))
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
    grand_total = sum((_safe_decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
    body = ["## Payment summary — period by period", "", table, "", f"**Grand total: {_fmt_money(grand_total)}**"]
    if total_count > MULTI_PERIOD_PAGE_SIZE:
        body += ["", f"Showing {start_idx + 1}-{min(start_idx + MULTI_PERIOD_PAGE_SIZE, total_count)} of {total_count} periods."]
    body += ["", DISCLAIMER_GLOBAL]
    body += ["", _actions_block(recommended)]
    return "\n".join(body)



def _at_risk_reason(result):
    """Explain at-risk amounts, or return None when absent."""
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
    """Render the standard payout summary; details use the drill-down."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    top_level_blockers = result.get("blockers") or []
    settled = result.get("payment_history_found") is True

    if not rows and not settled:
        if not top_level_blockers:
            # Distinguish missing history from calculation failure.
            body = [
                "## No payment history found",
                "",
                "There is no payment record on file for this period yet. This is expected if the county has not yet processed it.",
                "",
                _actions_block(recommended),
            ]
            return "\n".join(body)
        issue_rows = [[BLOCKER_TITLE.get(b, b.replace("_", " ").title()), b] for b in top_level_blockers]
        table = _table(["Issue area", "Reason"], issue_rows)
        body = ["## Unable to calculate payment", "", "I encountered a few data issues while calculating this. Here is what is blocking it:", ""]
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
        ["Attendance-based payment", f"{_fmt_money(result.get('attended_care_amount'))} ({_fmt_hours(float(result.get('attended_care_hours') or 0))} hrs, {amount_type})"],
        *([["Scheduled forecast payment", f"{_fmt_money(result.get('forecast_amount'))} ({_fmt_hours(float(result.get('forecast_hours') or 0))} hrs, {amount_type})"]] if float(result.get('forecast_amount') or 0) > 0 else []),
        ["Vacant slot payment", f"{_fmt_money(result.get('vacant_slot_amount'))} ({amount_type})"],
        ["At risk", f"{_fmt_money(result.get('amount_at_risk'))} ({_risk_detail})" if _risk_detail else _fmt_money(result.get("amount_at_risk"))],
    ]
    table_rows.append(["**Potential total**", f"**{_fmt_money(potential_total)}**"])
    table = _table(["Field", "Value"], table_rows)

    sections = [f"## Payment summary — {period_label}", "", table]
    sections += ["", DISCLAIMER_GLOBAL]
    sections += ["", _actions_block(recommended)]
    return "\n".join(sections)


FULL_BREAKDOWN_PAGE_SIZE = 7


def render_payment_full_breakdown(recommended):
    """Render paginated day-by-day payment detail."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    # Keep facility-level vacant slots in a separate table.
    attended_rows_all = [r for r in rows if r.get("kind") != "VACANT_SLOT"]
    vacant_rows_all = [r for r in rows if r.get("kind") == "VACANT_SLOT"]
    calculated_rows = [r for r in attended_rows_all if r.get("status") in ("calculated", "at_risk")]
    calculated_vacant_rows = [r for r in vacant_rows_all if r.get("status") == "calculated"]
    _at_risk_only = [r for r in calculated_rows if r.get("status") == "at_risk"]
    if result.get("payment_history_found") is not True and _at_risk_only:
        calculated_rows = _at_risk_only
    settled = result.get("payment_history_found") is True
    period_range = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end"))
    period_label = period_range or (result.get("service_period_id") or "--")

    page = _ctx("turnRequest.fetchParams.page") or 0
    try:
        page = max(0, int(page))
    except (TypeError, ValueError):
        page = 0

    _at_risk_md = sum(1 for r in calculated_rows if r.get("status") == "at_risk")
    _calc_md = len(calculated_rows) - _at_risk_md
    _heading_md = f"## Full breakdown — {period_label}"
    _detail_md = f"{len(calculated_rows)} days on record — {_calc_md} calculated, {_at_risk_md} at-risk." if calculated_rows else None
    sections = [_heading_md] + (["", _detail_md] if _detail_md else [])

    total_calc = len(calculated_rows)
    start_idx = page * FULL_BREAKDOWN_PAGE_SIZE
    page_rows = calculated_rows[start_idx:start_idx + FULL_BREAKDOWN_PAGE_SIZE]
    if page_rows:
        detail = _table(
            ["Child", "Authorization", "County", "Care date", "Rate type", "Care hours", "Amount"],
            [
                [
                    r.get("child_name") or "--",
                    r.get("authorization_name") or r.get("authorization_id") or "--",
                    r.get("county_name") or "--",
                    _fmt_date(r.get("service_date")),
                    _rate_type_display(r),
                    _fmt_hours(r.get("payable_hours")),
                    _fmt_money(r.get("amount")),
                ]
                for r in page_rows
            ],
        )
        if detail:
            sections += ["", detail]
        if total_calc > FULL_BREAKDOWN_PAGE_SIZE:
            shown_end = min(start_idx + FULL_BREAKDOWN_PAGE_SIZE, total_calc)
            _total_pages_md = (total_calc + FULL_BREAKDOWN_PAGE_SIZE - 1) // FULL_BREAKDOWN_PAGE_SIZE
            sections += ["", f"Showing {start_idx + 1}–{shown_end} of {total_calc} days · Page {page + 1} of {_total_pages_md}"]

    if calculated_vacant_rows:
        _vacant_table = _table(
            ["County", "Care date", "Amount"],
            [
                [r.get("county_name") or "--", _fmt_date(r.get("service_date")), _fmt_money(r.get("amount"))]
                for r in calculated_vacant_rows
            ],
        )
        if _vacant_table:
            sections += ["", "**Vacant slot payments**", "", _vacant_table]

    sections += ["", DISCLAIMER_GLOBAL, "", _actions_block(recommended)]
    return "\n".join(sections)


def _child_rows(rows, child_key):
    """Match rows by authorization name or ID."""
    key = str(child_key or "").strip().lower()
    return [
        r for r in rows
        if r.get("kind") == "ATTENDED_CARE"
        and key in {str(r.get("authorization_name") or "").strip().lower(), str(r.get("authorization_id") or "").strip().lower()}
    ]


def render_payment_child_detail(recommended, child_key):
    """Render authorization summary by classification."""
    result = _ctx("paymentResult") or {}
    rows = _child_rows(result.get("rows") or [], child_key)
    if not rows:
        return "\n".join([f"I couldn't find any attendance records for \"{child_key}\" in this service period. Please verify the spelling, or ask me to list your children.", "", _actions_block(recommended)])

    auth_name = rows[0].get("authorization_name") or child_key
    county_name = rows[0].get("county_name") or "--"
    heading = f"## Payment detail — {auth_name}"
    header = f"Authorization: {auth_name} \u00b7 County: {county_name}"

    payable_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    category_rows = []
    total_days, total_hours, total_amount = 0, Decimal("0"), Decimal("0")
    for label, group in _group_by_classification(payable_rows).items():
        days = len(group)
        hours = sum((_safe_decimal(r.get("payable_hours")) for r in group), Decimal("0"))
        amount = sum((_safe_decimal(r.get("amount")) for r in group), Decimal("0"))
        category_rows.append([label, days, _fmt_hours(float(hours)), _fmt_money(str(amount))])
        total_days += days
        total_hours += hours
        total_amount += amount
    if category_rows:
        category_rows.append(["**Total**", f"**{total_days}**", f"**{_fmt_hours(float(total_hours))}**", f"**{_fmt_money(str(total_amount))}**"])
    table = _table(["Category", "Days", "Hours", "Amount"], category_rows)

    sections = [heading, "", header, "", (table or "There are no payable days on this authorization for this service period yet."), "", _actions_block(recommended)]
    return "\n".join(sections)


def render_payment_county_detail(recommended, county_key):
    """Render aggregated county payment detail."""
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    key = str(county_key or "").strip().lower()
    matching = [r for r in rows if str(r.get("county_name") or "").strip().lower() == key]
    if not matching:
        return "\n".join([f"I don't have payment data for \"{county_key}\" in this service period. Please verify the county name, or request your full breakdown.", "", _actions_block(recommended)])

    attended = [r for r in matching if r.get("kind") == "ATTENDED_CARE" and r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    attended_amount = sum((_safe_decimal(r.get("amount")) for r in attended), Decimal("0"))
    attended_hours = sum((_safe_decimal(r.get("payable_hours")) for r in attended), Decimal("0"))
    vacant_amount = sum((_safe_decimal(r.get("amount")) for r in vacant), Decimal("0"))

    county_name = matching[0].get("county_name") or county_key
    heading = f"## Payment detail — {county_name}"
    header = f"County: {county_name}"
    table = _table(
        ["Attendance-based payment", "Vacant slot payment"],
        [[f"{_fmt_money(str(attended_amount))} ({_fmt_hours(float(attended_hours))} hrs)", _fmt_money(str(vacant_amount))]],
    )
    sections = [heading, "", header, "", table, "", "To see a specific child's detail, ask about that child's authorization by name.", "", _actions_block(recommended)]
    return "\n".join(sections)


BLOCKER_TITLE = {
    "age_group_code_unresolved": "I am unable to determine this child's age band from the data on file",
    "care_unit_mapping_unconfirmed": "I am unable to confirm the care-hours tier for this day",
    "fiscal_schedule": "No fiscal schedule is currently on file for this provider and county",
    "fiscal_rate": "No rate is currently on file for this day",
    "authorization_relationship": "This day is not yet linked to a valid authorization",
    "attendance_hours": "Attendance hours for this day are missing or unclear",
    "absence_limit_exceeded": "This absence is beyond the county's monthly limit",
    "absence_limit_unavailable": "The county absence limit is not on file, so this day cannot yet be confirmed",
    "drop_in_not_allowed": "Drop-in care is not authorized for this county",
    "drop_in_limit_exceeded": "This drop-in day is beyond the county's monthly limit",
    "vacant_slot_rate_fields": "This vacant slot is missing rate information",
    "vacant_slot_rate_ambiguous_age_group": "This vacant slot's rate cannot be narrowed to a single age group",
    "vacant_slot_monthly_cap_exceeded": "This vacant slot is beyond the county's monthly cap",
    "service_period": "This could not be matched to a service period",
    "service_period_dates": "This service period's dates appear incomplete on file",
}


def render_clarify(recommended, prior_recommended=None):
    session_state = _ctx("sessionState") or {}
    provider_verified = session_state.get("providerVerified", False)
    provider_name = (session_state.get("providerName") or "").strip()
    clarify_reason = (_ctx("turnRequest") or {}).get("clarifyReason") or ""
    if clarify_reason == "greeting" and provider_verified:
        # Use an open question for mid-session greetings.
        name_suffix = f", {provider_name}" if provider_name else ""
        return f"Of course{name_suffix}. What would you like to look at?"
    if provider_verified and provider_name:
        greeting_line = f"What can I help you with next, {provider_name}?"
    elif provider_verified:
        greeting_line = "What can I help you with next?"
    else:
        greeting_line = "Hello, I'm Provider Assist. I can help you review attendance, payments, and payout details. What would you like to look at first?"
    body = [
        greeting_line,
        "",
        "Select an option below, or describe what you need in your own words.",
        "",
        _actions_block(recommended),
    ]
    return "\n".join(body)


def render_explain(recommended):
    snapshot = (_ctx("data_collection_result") or {}).get("snapshot") or {}
    payment_result = _ctx("paymentResult") or {}
    sections = ["## Explanation", ""]

    # Explain at-risk amounts when present.
    at_risk_amt = payment_result.get("amount_at_risk")
    at_risk_days = payment_result.get("at_risk_day_count") or 0
    try:
        _at_risk_float = float(at_risk_amt) if at_risk_amt else 0
    except (TypeError, ValueError):
        _at_risk_float = 0

    if _at_risk_float > 0:
        _detail = _at_risk_reason(payment_result)
        sections += [
            "## About \"at risk\" amounts", "",
            "A day is marked **at risk** when care was provided but parent "
            "confirmation is still pending. The county holds payment on those "
            "days until the parent confirms.",
            "",
            f"Your current at-risk amount: **{_fmt_money(at_risk_amt)}** "
            f"({at_risk_days} day(s) — {_detail or 'awaiting confirmation'})",
            "",
        ]

    # Add current-period status.
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
        sections += ["## Current items requiring attention", "", _table(["Area", "Status"], summary_rows), ""]
    elif not sections:
        sections += ["There are no outstanding items to flag for the current period.", ""]

    sections += [_actions_block(recommended)]
    return "\n".join(sections)


def render_fallback(recommended):
    body = [
        "## Unable to load your data",
        "",
        "I was unable to retrieve your account details at this time. This is typically temporary — "
        "please try again shortly, and contact your system administrator if the issue persists.",
        "",
        _actions_block(recommended),
    ]
    return "\n".join(body)


def render_end():
    # Return a closing message for END.
    return "Thank you for checking in. Have a good rest of your day."



# ==============================================================================
# RICH UI BLOCKS (chat-ui format for React renderer)
# ==============================================================================

DISCLAIMER_TEXT = (
    "This is an estimate based on current attendance records, authorizations, and rates on file. "
    "The county determines the final amount during payment processing."
)


def _mk_table(caption, col_specs, row_list, no_limit=False, footer=None):
    """Build a rich table from column specs and row dictionaries."""
    if not row_list:
        return None
    total = len(row_list)
    if not no_limit and total > TABLE_ROW_LIMIT:
        row_list = row_list[:TABLE_ROW_LIMIT]
        note = f"Showing {TABLE_ROW_LIMIT} of {total}"
        caption = f"{caption} — {note}" if caption else note
    cols = []
    for spec in col_specs:
        col = {"key": spec[0], "label": spec[1]}
        if len(spec) > 2 and spec[2]:
            col["align"] = spec[2]
        cols.append(col)
    block = {"version": 1, "type": "table", "caption": caption, "columns": cols, "rows": row_list}
    if footer:
        block["footer"] = footer
    return block


def _mk_buttons(recommended):
    if not recommended:
        return None
    items = []
    for i, r in enumerate(recommended):
        # Use action IDs so button resolution is order-independent.
        item = {"label": r["label"], "value": r["id"]}
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
    _progress_sent_b = bool(_ctx("progressMessage"))
    blocks = ([] if _progress_sent_b else [_mk_text(f"# {user_name}, here's where things stand today at {facility_name}.")])
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
    analyzer_pending_rows = analyzer.get("pending_confirmation_records") or []
    _ref_date = (analyzer.get("reference_date") or "")[:10]
    _lookback = int(analyzer.get("lookback_days") or 9)
    _win_start = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_start = str(_ddate.fromisoformat(_ref_date) - _dtd(days=_lookback))
    except Exception:
        pass
    _windowed_pending = [r for r in analyzer_pending_rows
                         if not _win_start or (r.get("date") or "") >= _win_start]
    pending_days = len(_windowed_pending)
    _pending_win_children = len({r.get("child_id") for r in _windowed_pending if r.get("child_id")})
    _pending_range = _date_range_for_dates(r.get("date") for r in _windowed_pending)
    _summary_absence_rows = _absence_rows_for_summary(analyzer_absence_rows, _win_start)
    # Any status that isn't exceeded counts as "approaching" -- the analyzer
    # can emit APPROACHING_LIMIT OR POTENTIAL_APPROACHING_LIMIT (confirmed
    # live: a row with the latter was silently dropped by an exact-match
    # check on "APPROACHING_LIMIT" only, showing "no risk" in this table
    # while the recommended-action builder correctly flagged the same row).
    _exceeded_statuses = ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
    _exceeded_rows = [r for r in _summary_absence_rows if (r.get("status") or "") in _exceeded_statuses]
    _approaching_rows = [r for r in _summary_absence_rows if (r.get("status") or "") not in _exceeded_statuses]
    _exc_win_dates = [d for r in _exceeded_rows for d in _over_limit_dates(r) if not _win_start or d >= _win_start]
    _exc_days = len(_exc_win_dates)
    _exc_children = _distinct_child_count(_exceeded_rows)
    _app_children = _distinct_child_count(_approaching_rows)
    _exc_range = _date_range_for_dates(_exc_win_dates)
    _app_dates = [d for r in _approaching_rows for d in (list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or []))]
    _app_range = _date_range_for_dates(_app_dates)
    _absence_finding_parts = []
    _absence_period_parts = []
    if _exceeded_rows:
        _absence_finding_parts.append(f"Limit exceeded: {_exc_children} child(ren), {_exc_days} day(s) in window")
        _absence_period_parts.append(_exc_range or "--")
    if _approaching_rows:
        _absence_finding_parts.append(f"Approaching limit: {_app_children} child(ren)")
        _absence_period_parts.append(_app_range or "--")
    absence_finding = "\n".join(_absence_finding_parts) or "No children near or over county absence limits"
    _absence_range = "\n".join(_absence_period_parts) or "--"
    incomplete_attendance_rows = [
        row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if isinstance(row, dict) and row.get("risk_category") == "incomplete"
    ]
    _windowed_incomplete = [r for r in incomplete_attendance_rows
                            if not _win_start or (r.get("date") or "") >= _win_start]
    incomplete_days = len(_windowed_incomplete)
    incomplete_finding = "No incomplete check-in/out found" if not incomplete_days else f"{incomplete_days} day(s)"
    _incomplete_range = _date_range_for_dates(r.get("date") for r in _windowed_incomplete)

    def _loss(cat):
        val = cat.get("potential_loss_hours") if isinstance(cat, dict) else None
        amount = cat.get("potential_loss_amount") if isinstance(cat, dict) else None
        if isinstance(val, (int, float)):
            return f"{_fmt_money(amount)} ({'%.1f' % val} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    _absence_impact_parts = []
    if _exceeded_rows:
        _absence_impact_parts.append(_loss(approaching))
    if _approaching_rows:
        _absence_impact_parts.append("Within county limit")
    _absence_impact = "\n".join(_absence_impact_parts) or "No actionable impact"

    issues_tbl = _mk_table(
        f"Attendance and payment issues — {_period_label()}",
        [("area", "Risk area"), ("finding", "Verified finding"), ("period", "Period"), ("impact", "Potential payment impact")],
        [
            {"area": "Pending parent confirmations",
             "finding": "No pending parent confirmations" if not pending_days else f"{pending_days} day(s), {_pending_win_children} child(ren)",
             "period": _pending_range or "--",
             "impact": _loss(pending) if pending_days else "No actionable impact"},
            {"area": "Absence-limit risk",
             "finding": absence_finding,
             "period": _absence_range,
             "impact": _absence_impact},
            {"area": "Incomplete check-ins/check-outs",
             "finding": "No incomplete check-in/out found" if not incomplete_days else f"{incomplete_days} day(s)",
             "period": _incomplete_range or "--",
             "impact": _loss(incomplete) if incomplete_days else "No actionable impact"},
        ],
    )
    if issues_tbl:
        blocks.append(issues_tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_pending_confirmations(recommended):
    _analyzer = _ctx("attendance_risks_analyzer_py") or {}
    _ref = (_analyzer.get("reference_date") or "")[:10]
    _lkb = int(_analyzer.get("lookback_days") or 9)
    _win = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win = str(_ddate.fromisoformat(_ref) - _dtd(days=_lkb))
    except Exception:
        pass
    all_pending = _analyzer.get("pending_confirmation_records") or []
    rows = [r for r in all_pending if not _win or (r.get("date") or "") >= _win]
    blocks = []
    if rows:
        tbl = _mk_table(
            "Pending parent confirmations",
            [("child", "Child"), ("authorization", "Authorization"),
             ("service_date", "Service date"), ("status", "Status")],
            [{"child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("auth_id") or "--",
              "service_date": _fmt_date(r.get("date")), "status": "Pending"} for r in rows],
        )
        if tbl:
            blocks.append(tbl)
    else:
        blocks.append(_mk_text("There are currently no pending parent confirmations."))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_absence_limits(recommended):
    _analyzer_al = _ctx("attendance_risks_analyzer_py") or {}
    _ref_al = (_analyzer_al.get("reference_date") or "")[:10]
    _win_al = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_al = str(_ddate.fromisoformat(_ref_al) - _dtd(days=int(_analyzer_al.get("lookback_days") or 9)))
    except Exception:
        pass
    rows = _absence_rows_for_summary(
        _analyzer_al.get("approaching_absence_limits") or [], _win_al
    )
    period = _period_label()
    blocks = []
    if period:
        blocks.append(_mk_text(f"Period: {period}", italic=True))
    if not rows:
        blocks.append(_mk_accordion([{"title": "Absence-limit risk", "content": "No children currently near or over county monthly absence limits."}]))
    else:
        _payout_rows = [r for r in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
                        if isinstance(r, dict) and r.get("risk_category") == "absence"]
        _impact_by_auth = {}
        for pr in _payout_rows:
            _ak = str(pr.get("authorization_id") or pr.get("auth_id") or pr.get("child_name") or "")
            if _ak not in _impact_by_auth:
                _impact_by_auth[_ak] = {"hours": 0.0, "amount": 0.0}
            _impact_by_auth[_ak]["hours"] += float(pr.get("care_hours") or 0)
            try:
                _impact_by_auth[_ak]["amount"] += float(pr.get("amount") or 0)
            except (TypeError, ValueError):
                pass
        tbl_rows = []
        for r in rows:
            _rs = r.get("status") or ""
            _is_exc = _rs in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
            _auth_key = str(r.get("authorization_id") or r.get("auth_id") or r.get("child_name") or "")
            if _is_exc:
                _od_all = _over_limit_dates(r)
                _od_win = [d for d in _od_all if not _win_al or d >= _win_al]
                _at_risk_period = _date_range_for_dates(_od_all) or "--"
                _imp = _impact_by_auth.get(_auth_key)
                if _imp and _imp["amount"] > 0:
                    _payment_impact = f"${_imp['amount']:.2f} at risk ({_imp['hours']:.1f} care hrs)"
                else:
                    _payment_impact = "Outside confirmation window" if not _od_win else "At risk (rate unavailable)"
            else:
                _at_risk_period = _date_range_for_dates(
                    list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])
                ) or "--"
                _payment_impact = "Within county limit"
            _confirmed_ct = r.get("confirmed_absence_count", len(r.get("confirmed_absence_dates") or []))
            _probable_ct = r.get("probable_absence_count", len(r.get("probable_absence_dates") or []))
            _used_total = (_confirmed_ct or 0) + (_probable_ct or 0)
            _absences_used = f"{_used_total} ({_probable_ct} not confirmed yet)" if _probable_ct else str(_used_total)
            tbl_rows.append({
                "risk_type": "Limit exceeded" if _is_exc else "Approaching limit",
                "child": _safe_display_value(r.get("child_name") or ""),
                "authorization": r.get("authorization_id") or r.get("auth_id") or "--",
                "county": r.get("county_name") or "--",
                "absences_used": _absences_used,
                "absence_limit": r.get("absence_limit", "--"),
                "at_risk_period": _at_risk_period,
                "payment_impact": _payment_impact,
            })
        tbl_rows.sort(key=lambda row: 0 if row.get("payment_impact", "") != "Outside confirmation window" else 1)
        tbl = _mk_table(
            "Absence-limit risk",
            [("risk_type", "Risk type"), ("child", "Child"), ("authorization", "Authorization"),
             ("county", "County"), ("absences_used", "Absences used", "right"),
             ("absence_limit", "County limit", "right"),
             ("at_risk_period", "At-risk period"), ("payment_impact", "Payment impact")],
            tbl_rows,
        )
        if tbl:
            blocks.append(tbl)
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_incomplete_attendance(recommended):
    _analyzer = _ctx("attendance_risks_analyzer_py") or {}
    _ref = (_analyzer.get("reference_date") or "")[:10]
    _lkb = int(_analyzer.get("lookback_days") or 9)
    _win = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win = str(_ddate.fromisoformat(_ref) - _dtd(days=_lkb))
    except Exception:
        pass
    rows = [row for row in ((_ctx("payoutImpactResult") or {}).get("rows") or [])
            if isinstance(row, dict) and row.get("risk_category") == "incomplete"
            and (not _win or (row.get("date") or "") >= _win)]
    blocks = []
    if not rows:
        blocks.append(_mk_accordion([{"title": "Missing check-in/check-out", "content": "No missing check-ins or check-outs were found in this window."}]))
    else:
        tbl = _mk_table(
            "Missing check-in/check-out",
            [("child", "Child"), ("authorization", "Authorization"), ("service_date", "Service date"),
             ("attendance_type", "Attendance type"), ("reason", "Reason")],
            [{"child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("authorization_id") or r.get("auth_id") or "--",
              "service_date": _fmt_date(r.get("date")), "attendance_type": "Missing check-in/check-out",
              "reason": r.get("reason") or "A check-in or check-out was not logged for this day"} for r in rows],
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
    _tr = _ctx("turnRequest") or {}
    _pi_scope = (_tr.get("id") or "") if isinstance(_tr, dict) else ""
    if _pi_scope == "payout_impact_absence":
        rows = [r for r in rows if (r.get("risk_category") or "") == "absence"]
    elif _pi_scope == "payout_impact_pending":
        rows = [r for r in rows if (r.get("risk_category") or "") == "unconfirmed"]
    elif _pi_scope == "payout_impact_incomplete":
        rows = [r for r in rows if (r.get("risk_category") or "") == "incomplete"]
    _calc_rows = [r for r in rows if r.get("amount") is not None]
    blocks = []
    if not rows:
        blocks.append(_mk_accordion([{"title": "Payout impact", "content": "None of your current attendance risk is affecting an upcoming payout."}]))
    elif not _calc_rows:
        blocks.append(_mk_accordion([{"title": "Payout impact", "content": "Attendance risk was found, but the payout impact cannot be calculated yet — rate schedule data may still be loading. Please try again shortly."}]))
    else:
        total_hours = sum(float(_r.get("care_hours") or 0) for _r in _calc_rows)
        total_dollar = sum(float(_r.get("amount") or 0) for _r in _calc_rows)
        caption = f"~ {_fmt_money(total_dollar)} at risk across {_fmt_hours(total_hours)} care hour(s)"
        blocks.append(_mk_text("## Payout impact of current attendance risk"))
        _agg = {}
        for _r in _calc_rows:
            _k = (_safe_display_value(_r.get("child_name") or ""), _r.get("authorization_id") or "--", _r.get("county_name") or "--", _r.get("risk_category") or "")
            if _k not in _agg:
                _agg[_k] = {"hours": Decimal("0"), "amount": Decimal("0"), "reason": _r.get("reason") or "--"}
            _agg[_k]["hours"] += Decimal(str(_r.get("care_hours") or 0))
            _agg[_k]["amount"] += Decimal(str(_r.get("amount") or "0"))
        tbl = _mk_table(
            caption,
            [("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
             ("care_hours", "Care hours", "right"), ("amount", "Amount", "right"),
             ("reason", "Reason")],
            [{"child": _k[0], "authorization": _k[1], "county": _k[2],
              "care_hours": _fmt_hours(float(_v["hours"])),
              "amount": _fmt_money(_v["amount"]),
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
            blocks.append(_mk_accordion([{"title": "No payment history found", "content": "There is no payment record on file for this period yet. This is expected if the county has not yet processed it."}]))
        else:
            blocks.append(_mk_text("I encountered a few data issues while calculating this. Here is what is blocking it:"))
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
            {"field": "Attendance-based payment", "value": f"{_fmt_money(result.get('attended_care_amount'))} ({_fmt_hours(float(result.get('attended_care_hours') or 0))} hrs, {amount_type})"},
            *([{"field": "Scheduled forecast payment", "value": f"{_fmt_money(result.get('forecast_amount'))} ({_fmt_hours(float(result.get('forecast_hours') or 0))} hrs, {amount_type})"}] if float(result.get('forecast_amount') or 0) > 0 else []),
            {"field": "Vacant slot payment", "value": f"{_fmt_money(result.get('vacant_slot_amount'))} ({amount_type})"},
            {"field": "At risk", "value": f"{_fmt_money(result.get('amount_at_risk'))} ({_risk_detail})" if _risk_detail else _fmt_money(result.get("amount_at_risk"))},
        ]
        summary_rows.append({"field": "Potential total", "value": _fmt_money(result.get("potential_total_amount") or result.get("total_amount"))})
        _at_risk_days_b = result.get("at_risk_day_count") or 0
        _potential_total_b = result.get("potential_total_amount") or result.get("total_amount")
        _payout_str_b = _fmt_date(payout_date) if payout_date else "a date to be confirmed"
        _intro_b = f"## Payment summary — {period_label}"
        if _at_risk_days_b > 0:
            _day_word_b = "day" if _at_risk_days_b == 1 else "days"
            _intro_b += f"\n\n{_at_risk_days_b} {_day_word_b} are flagged at risk, so the final amount may differ at county processing."
        blocks.append(_mk_text(_intro_b))
        tbl = _mk_table("Payment summary", [("field", "Field"), ("value", "Value")], summary_rows, no_limit=True)
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
        blocks.append(_mk_accordion([{"title": "Payment summary", "content": "I couldn't find any service periods in that date range. Please try a different range, or ask for your next payout."}]))
    else:
        page = _ctx("turnRequest.fetchParams.page") or 0
        try:
            page = max(0, int(page))
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
        grand_total = sum((_safe_decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
        caption = f"Payment summary — period by period · Grand total: {_fmt_money(grand_total)}"
        if total_count > MULTI_PERIOD_PAGE_SIZE:
            shown_end = min(start_idx + MULTI_PERIOD_PAGE_SIZE, total_count)
            caption += f" · Showing {start_idx + 1}–{shown_end} of {total_count} periods"
        tbl = _mk_table(
            caption,
            [("service_period", "Service period"), ("payout_date", "Payout date"),
             ("potential_total", "Potential total", "right"), ("status", "Status")],
            page_rows,
            no_limit=True,
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
    # Keep facility-level vacant slots in a separate table.
    attended_rows_all = [r for r in rows if r.get("kind") != "VACANT_SLOT"]
    vacant_rows_all = [r for r in rows if r.get("kind") == "VACANT_SLOT"]
    calculated_rows = [r for r in attended_rows_all if r.get("status") in ("calculated", "at_risk")]
    calculated_vacant_rows = [r for r in vacant_rows_all if r.get("status") == "calculated"]
    _at_risk_only = [r for r in calculated_rows if r.get("status") == "at_risk"]
    if result.get("payment_history_found") is not True and _at_risk_only:
        calculated_rows = _at_risk_only
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
    _at_risk_b = sum(1 for r in calculated_rows if r.get("status") == "at_risk")
    _calc_b = len(calculated_rows) - _at_risk_b
    _title_b = f"## Full breakdown — {period_label}"
    if calculated_rows:
        _title_b += f"\n\n{len(calculated_rows)} days on record — {_calc_b} calculated, {_at_risk_b} at-risk."
    _footer_b = None
    if total_calc > FULL_BREAKDOWN_PAGE_SIZE:
        shown_end = min(start_idx + FULL_BREAKDOWN_PAGE_SIZE, total_calc)
        _total_pages_b = (total_calc + FULL_BREAKDOWN_PAGE_SIZE - 1) // FULL_BREAKDOWN_PAGE_SIZE
        _footer_b = f"Showing {start_idx + 1}–{shown_end} of {total_calc} days  ·  Page {page + 1} of {_total_pages_b}"
    blocks = [_mk_text(_title_b)]
    if page_rows:
        tbl = _mk_table(
            "Attendance breakdown",
            [("child_name", "Child"), ("authorization", "Authorization"), ("county", "County"),
             ("care_date", "Care date"), ("attendance_type", "Rate type"),
             ("care_hours", "Care hours", "right"), ("amount", "Amount", "right")],
            [{"child_name": r.get("child_name") or "--",
              "authorization": r.get("authorization_name") or r.get("authorization_id") or "--",
              "county": r.get("county_name") or "--",
              "care_date": _fmt_date(r.get("service_date")),
              "attendance_type": _rate_type_display(r),
              "care_hours": _fmt_hours(r.get("payable_hours")),
              "amount": _fmt_money(r.get("amount"))}
             for r in page_rows],
            no_limit=True,
            footer=_footer_b,
        )
        if tbl:
            blocks.append(tbl)
    if calculated_vacant_rows:
        _vacant_tbl = _mk_table(
            "Vacant slot payments",
            [("county", "County"), ("care_date", "Care date"), ("amount", "Amount", "right")],
            [{"county": r.get("county_name") or "--", "care_date": _fmt_date(r.get("service_date")),
              "amount": _fmt_money(r.get("amount"))} for r in calculated_vacant_rows],
        )
        if _vacant_tbl:
            blocks.append(_vacant_tbl)
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
        blocks.append(_mk_text(f"I couldn't find any attendance records for \"{child_key}\" in this service period. Please verify the spelling, or ask me to list your children."))
        btn = _mk_buttons(recommended)
        if btn:
            blocks.append(btn)
        return blocks
    auth_name = rows[0].get("authorization_name") or child_key
    county_name = rows[0].get("county_name") or "--"
    blocks.append(_mk_text(f"## Payment detail — {auth_name}"))
    payable_rows = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    category_rows = []
    total_days, total_hours, total_amount = 0, Decimal("0"), Decimal("0")
    for label, group in _group_by_classification(payable_rows).items():
        days = len(group)
        hours = sum((_safe_decimal(r.get("payable_hours")) for r in group), Decimal("0"))
        amount = sum((_safe_decimal(r.get("amount")) for r in group), Decimal("0"))
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
                                      "content": f"I don't have payment data for \"{county_key}\" in this service period. Please verify the county name, or request your full breakdown."}]))
        btn = _mk_buttons(recommended)
        if btn:
            blocks.append(btn)
        return blocks
    attended = [r for r in matching if r.get("kind") == "ATTENDED_CARE" and r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    attended_amount = sum((_safe_decimal(r.get("amount")) for r in attended), Decimal("0"))
    attended_hours = sum((_safe_decimal(r.get("payable_hours")) for r in attended), Decimal("0"))
    vacant_amount = sum((_safe_decimal(r.get("amount")) for r in vacant), Decimal("0"))
    county_name = matching[0].get("county_name") or county_key
    blocks.append(_mk_text(f"## Payment detail — {county_name}"))
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
    blocks = [_mk_text("## Explanation")]
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
        blocks.append(_mk_accordion([{"title": "Current status", "content": "There are no outstanding items to flag for the current period."}]))
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_attendance_all(recommended):
    blocks = [_mk_text("## Attendance overview")]
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
    blocks = [_mk_text("## Multiple service periods found\n\nSeveral service periods match this request. Please select the one you would like to review:")]
    if tbl:
        blocks.append(tbl)
    return blocks


def _blocks_clarify(recommended, prior_recommended=None):
    session_state = _ctx("sessionState") or {}
    provider_verified = session_state.get("providerVerified", False)
    provider_name = (session_state.get("providerName") or "").strip()
    clarify_reason = (_ctx("turnRequest") or {}).get("clarifyReason") or ""
    if clarify_reason == "greeting" and provider_verified:
        # Mid-session greeting: open question only, no menu
        name_suffix = f", {provider_name}" if provider_name else ""
        return [_mk_text(f"Of course{name_suffix}. What would you like to look at?")]
    if provider_verified and provider_name:
        headline = f"What can I help you with next, {provider_name}?"
    elif provider_verified:
        headline = "What can I help you with next?"
    else:
        headline = "Hello, I'm Provider Assist. I can help you review attendance, payments, and payout details. What would you like to look at first?"
    content = f"{headline}\n\nSelect an option below, or describe what you need in your own words."
    blocks = [_mk_text(content)]
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_unauthorized():
    return [_mk_accordion([{"title": "Verification required",
                            "content": "I am unable to verify your provider account for this session — it may not yet be authorized for CCARE services, or the session may have expired. If you believe this is incorrect, please contact your program administrator to review your access."}])]


def _blocks_connection_error():
    return [_mk_text("I'm unable to establish a secure connection with the system right now. Please try again in a few minutes. If this continues, contact your program administrator.")]


def _blocks_fallback(recommended):
    blocks = [_mk_accordion([{"title": "Unable to load snapshot",
                              "content": "I was unable to retrieve your account details at this time. This is typically temporary — please try again shortly, and contact your system administrator if the issue persists."}])]
    btn = _mk_buttons(recommended)
    if btn:
        blocks.append(btn)
    return blocks


def _blocks_end():
    return [_mk_text("Thank you for checking in. Have a good rest of your day.")]



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
_provider_reason = (_ctx("ccare_provider_data_py") or {}).get("reason")
_payment_result = _ctx("paymentResult") or {}

if _provider_status == "failed" and _provider_reason == "CONNECTION_FAILED":
    _formatted = render_connection_error()
elif _provider_status == "failed":
    _formatted = render_unauthorized()
elif _action == "STARTER":
    _formatted = render_greeting(_recommended)
elif _provider_status == "needs_clarification" or _action == "CLARIFY":
    _formatted = render_clarify(_recommended, _previous_recommended)
elif _action == "END":
    _formatted = render_end()
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

write_context("greetingDone", True)


# Build formattedBlocks in parallel with the Markdown _formatted above.
if _provider_status == "failed" and _provider_reason == "CONNECTION_FAILED":
    _blocks = _blocks_connection_error()
elif _provider_status == "failed":
    _blocks = _blocks_unauthorized()
elif _action == "STARTER":
    _blocks = _blocks_greeting(_recommended)
elif _provider_status == "needs_clarification" or _action == "CLARIFY":
    _blocks = _blocks_clarify(_recommended, _previous_recommended)
elif _action == "END":
    _blocks = _blocks_end()
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


# Inject the disclaimer before buttons when needed.
_disc_block = _mk_text(DISCLAIMER_TEXT, italic=True)
_blocks_have_dollar = any(
    (isinstance(b, dict) and b.get("type") == "text" and "$" in (b.get("content") or ""))
    or (isinstance(b, dict) and b.get("type") == "table" and any(
        "$" in str(v) for row in (b.get("rows") or []) for v in row.values() if v is not None
    ))
    for b in _blocks
)
_blocks_have_disclaimer = any(
    isinstance(b, dict) and b.get("type") == "text" and b.get("content") == DISCLAIMER_TEXT
    for b in _blocks
)
if _blocks_have_dollar and not _blocks_have_disclaimer:
    _btn_idx = next((i for i, b in enumerate(_blocks) if isinstance(b, dict) and b.get("type") == "buttons"), None)
    if _btn_idx is not None:
        _blocks = _blocks[:_btn_idx] + [_disc_block] + _blocks[_btn_idx:]
    else:
        _blocks.append(_disc_block)

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
    "\n\n".join(_parts) if _parts else "I was unable to retrieve your account details at this time. This is typically temporary — please try again shortly, and contact your system administrator if the issue persists.",
    confidence=1.0,
)

# __________________________GenAI: Generated code ends here______________________________
