"""_______________Restructured by ai-firstify re-engineer pass_______________

Deterministic provider response formatter -- builds formattedResponse
(markdown) and formattedBlocks (chat-ui JSON) plus recommended actions.

WHY THIS IS STRUCTURED DIFFERENTLY FROM THE PREVIOUS VERSION
--------------------------------------------------------------------------
The previous version built every view TWICE: a `render_X` function that
hand-wrote a markdown string, and a `_blocks_X` function that independently
rebuilt the same tables/text as chat-ui JSON blocks -- two full
implementations of the same business logic per view (~15 view pairs), kept
in sync by hand. That's how the progress-message and payout-impact bugs
found in the previous re-engineer pass slipped in: a fix applied to one twin
and not the other.

The chat-ui block schema (text / table / buttons / accordion) is already a
generic, presentation-agnostic shape. So this version keeps exactly ONE
builder per view -- `build_X(...) -> list[block]` -- and adds a single
generic `blocks_to_markdown()` converter that turns ANY block list into
markdown. There is no markdown twin to keep in sync anymore.

Also carries forward, in this single implementation, the fixes made in the
previous re-engineer pass (not reintroduced as duplicate patches, because
there's only one code path now):
  - the greeting's opening line is no longer suppressed by `progressMessage`,
    which is never actually delivered to the provider as its own turn.
  - recommended actions are resolution-based, not shown-once-then-hidden --
    an unresolved risk keeps being recommended across turns.
  - payout-impact drill-downs filter on `turnRequest.actionId`.
  - `greetingDone` is not set on failed provider validation.
  - "incomplete attendance" reads `attendance_risks_analyzer_py.
    incomplete_attendance_records` directly (new, additive field from the
    restructured engine) instead of depending on `payoutImpactResult` having
    run this turn.

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

DISCLAIMER_TEXT = (
    "This is an estimate based on current attendance records, authorizations, and rates on file. "
    "The county determines the final amount during payment processing."
)
TABLE_ROW_LIMIT = 5
SEVERITY_LABEL = {"URGENT": "[Urgent]", "REVIEW": "[Review]", "INFO": "[Info]"}
_MONTH_ABBR = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
_MONTH_FULL = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
               "October", "November", "December"]
MAX_ACTIONS = 3
FULL_BREAKDOWN_ID = "view_full_breakdown"
MULTI_PERIOD_PAGE_SIZE = 7
FULL_BREAKDOWN_PAGE_SIZE = 7

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
    "vacant_slot_monthly_cap_exceeded": "This vacant slot is beyond the county's monthly cap",
    "service_period": "This could not be matched to a service period",
    "service_period_dates": "This service period's dates appear incomplete on file",
}


def _ctx(key, default=None):
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


# ==============================================================================
# SECTION 1 -- FORMATTING HELPERS (unchanged in spirit from the previous version)
# ==============================================================================

def _fmt_date(value):
    text = str(value or "")[:10]
    try:
        y, m, dd = (int(p) for p in text.split("-"))
        return f"{_MONTH_ABBR[m - 1]} {dd}, {y}"
    except Exception:
        return text or "--"


def _safe_display_value(value):
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


def _fmt_date_range(start_iso, end_iso):
    if not start_iso or not end_iso:
        return None
    return f"{_fmt_date(start_iso)} - {_fmt_date(end_iso)}"


def _date_range_for_dates(dates):
    valid = sorted(str(d) for d in (dates or []) if d)
    if not valid:
        return None
    return _fmt_date(valid[0]) if valid[0] == valid[-1] else _fmt_date_range(valid[0], valid[-1])


def _rate_type_display(row):
    label = row.get("rate_type_label")
    basis = row.get("payment_basis")
    if label and basis:
        return f"{label}({basis})"
    return label or (row.get("classification") or "--").replace("_", " ").title()


def _period_label():
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
    date_from, date_to = turn_req.get("dateFrom"), turn_req.get("dateTo")
    return _fmt_date_range(date_from, date_to) if date_from and date_to else ""


def _group_by_classification(rows):
    groups = {}
    for r in rows:
        label = (r.get("classification") or "Other").replace("_", " ").title()
        groups.setdefault(label, []).append(r)
    return groups


def _safe_decimal(value, default=Decimal("0")):
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        return default


def _distinct_child_count(rows):
    keys = {str(r.get("child_id") or r.get("child_name")).strip() for r in rows
            if isinstance(r, dict) and (r.get("child_id") or r.get("child_name"))}
    return len(keys)


def _over_limit_dates(row):
    limit = int(row.get("absence_limit") or 0)
    confirmed = sorted(row.get("confirmed_absence_dates") or [])
    probable = sorted(row.get("probable_absence_dates") or [])
    over_confirmed = confirmed[limit:] if limit > 0 else confirmed
    remaining = max(0, limit - len(confirmed))
    return over_confirmed + probable[remaining:]


def _absence_rows_for_summary(rows, win_start):
    """OVER_LIMIT/POTENTIAL_OVER_LIMIT always surface; APPROACHING groups only when within window."""
    crossed = {"OVER_LIMIT", "POTENTIAL_OVER_LIMIT"}
    result = []
    for r in rows or []:
        if (r.get("status") or "") in crossed or not win_start:
            result.append(r)
        else:
            dates = list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])
            if any((d or "") >= win_start for d in dates):
                result.append(r)
    return result


def _risk_window_start():
    """Shared 9-day lookback window start, used consistently across every view."""
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    ref = (analyzer.get("reference_date") or "")[:10]
    lookback = int(analyzer.get("lookback_days") or 9)
    try:
        from datetime import date as _d, timedelta as _td
        return str(_d.fromisoformat(ref) - _td(days=lookback))
    except Exception:
        return None


# ==============================================================================
# SECTION 2 -- GENERIC BLOCK BUILDERS (the canonical, presentation-agnostic shape)
# ==============================================================================

def _table(caption, col_specs, row_list, no_limit=False, footer=None):
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


def _text(content, italic=False):
    block = {"version": 1, "type": "text", "content": content}
    if italic:
        block["italic"] = True
    return block


def _accordion(items):
    return {"version": 1, "type": "accordion", "items": items}


def _buttons(recommended):
    if not recommended:
        return None
    items = []
    for i, r in enumerate(recommended):
        item = {"label": r["label"], "value": r["id"]}
        if i == 0:
            item["variant"] = "primary"
        items.append(item)
    return {"version": 1, "type": "buttons", "items": items}


def _escape_cell(value):
    text = str(value) if value is not None else "--"
    return text.replace("|", "\\|").replace("\n", " ").replace("\r", "")


# ==============================================================================
# SECTION 3 -- THE ONE GENERIC MARKDOWN CONVERTER
# Replaces every `render_X` function from the previous version: any block
# list -- from any view -- converts through this single path.
# ==============================================================================

def _table_block_to_markdown(block):
    cols, rows = block.get("columns") or [], block.get("rows") or []
    if not cols or not rows:
        return None
    keys = [c["key"] for c in cols]
    lines = []
    if block.get("caption"):
        lines += [f"**{block['caption']}**", ""]
    lines.append("| " + " | ".join(c["label"] for c in cols) + " |")
    lines.append("|" + "|".join(["---"] * len(cols)) + "|")
    for row in rows:
        lines.append("| " + " | ".join(_escape_cell(row.get(k)) for k in keys) + " |")
    if block.get("footer"):
        lines += ["", f"*{block['footer']}*"]
    return "\n".join(lines)


def _accordion_block_to_markdown(block):
    lines = []
    for item in block.get("items") or []:
        lines += [f"## {item.get('title', '')}", "", item.get("content", "")]
    return "\n".join(lines)


def _buttons_block_to_markdown(recommended):
    """Markdown keeps the severity-tagged bullet list; it reads the original
    `recommended` candidates (not the stripped-down buttons block, which the
    chat-ui schema deliberately keeps to label/value/variant only) so the
    [Urgent]/[Review]/[Info] tags survive in plain-text contexts."""
    if not recommended:
        return "There is no other action I can recommend for this view. You can ask me about anything else."
    lines = ["### Recommended actions"]
    for i, item in enumerate(recommended, start=1):
        label = SEVERITY_LABEL.get(item.get("severity"), "[Info]")
        lines.append(f"{i}. {label} {item.get('label', '')}")
    return "\n".join(lines)


def blocks_to_markdown(blocks, recommended):
    parts = []
    for b in blocks:
        t = b.get("type")
        if t == "text":
            content = b.get("content", "")
            parts.append(f"*{content}*" if b.get("italic") else content)
        elif t == "table":
            md = _table_block_to_markdown(b)
            if md:
                parts.append(md)
        elif t == "accordion":
            parts.append(_accordion_block_to_markdown(b))
        # "buttons" blocks are skipped here -- the caller appends the
        # severity-tagged markdown action list once, at the very end,
        # from `recommended` directly (see _buttons_block_to_markdown).
    parts.append(_buttons_block_to_markdown(recommended))
    return "\n\n".join(p for p in parts if p)


# ==============================================================================
# SECTION 4 -- RECOMMENDED ACTIONS (unchanged concern boundary; resolution-based)
# ==============================================================================

def _candidate(id_, label, action, sub_filter, severity):
    return {"id": id_, "label": label, "action": action, "subFilter": sub_filter, "severity": severity}


def _build_candidates(current_action, current_sub_filter):
    candidates = []
    if current_action == "END":
        return candidates

    if current_action == "CLARIFY":
        kickstarts = [
            _candidate("kickstart_attendance", "Review attendance and pending items", "ATTENDANCE", "ALL", "INFO"),
            _candidate("kickstart_overview", "Show today's overview", "STARTER", None, "INFO"),
        ]
        snap = ((_ctx("data_collection_result") or {}).get("snapshot") or {})
        if snap.get("payment_history_found") or (snap.get("service_periods") or []):
            kickstarts.insert(1, _candidate("kickstart_payment", "Review a payout or payment", "PAYMENT", "NEXT_PAYOUT", "INFO"))
        return kickstarts

    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    payment_result = _ctx("paymentResult") or {} if current_action == "PAYMENT" else {}
    attendance_scope = current_action in ("STARTER", "ATTENDANCE")
    win_start = _risk_window_start()

    pending_all = analyzer.get("pending_confirmation_records") or []
    pending = [r for r in pending_all if not win_start or (r.get("date") or "") >= win_start]
    overview_scope = current_action == "STARTER" or (current_action == "ATTENDANCE" and current_sub_filter == "ALL")

    if overview_scope:
        candidates.append(_candidate("upcoming_payment", "Check your upcoming payout", "PAYMENT", "NEXT_PAYOUT", "INFO"))
        candidates.append(_candidate("current_week_forecast", "See this week's payment forecast", "PAYMENT", "CURRENT_PERIOD_FORECAST", "INFO"))
    if overview_scope and pending:
        label = f"Review {len(pending)} pending day(s)"
        at_risk = (_ctx("payoutImpactResult") or {}).get("unconfirmed_risk_amount")
        try:
            if at_risk and float(at_risk) > 0:
                label += f" — {_fmt_money(at_risk)} at risk"
        except (TypeError, ValueError):
            pass
        candidates.append(_candidate("pending_confirmations", label, "ATTENDANCE", "PENDING_CONFIRMATIONS", "URGENT"))
    elif attendance_scope and current_sub_filter == "PENDING_CONFIRMATIONS":
        if any(r.get("risk_category") == "unconfirmed" and r.get("amount") is not None
               for r in (_ctx("payoutImpactResult") or {}).get("rows") or []):
            candidates.append(_candidate("payout_impact_pending", "See estimated payout impact of these pending days", "ATTENDANCE", "PAYOUT_IMPACT", "REVIEW"))

    approaching = _absence_rows_for_summary(analyzer.get("approaching_absence_limits") or [], win_start) if attendance_scope else []
    if approaching and overview_scope:
        exceeded = [r for r in approaching if (r.get("status") or "") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")]
        near = [r for r in approaching if (r.get("status") or "") == "APPROACHING_LIMIT"]
        parts = []
        if exceeded:
            parts.append(f"{_distinct_child_count(exceeded)} exceeded")
        if near:
            parts.append(f"{_distinct_child_count(near)} approaching")
        candidates.append(_candidate(
            "absence_limits", f"Review absence risk -- {', '.join(parts) or 'risk detected'} ({_distinct_child_count(approaching)} child(ren))",
            "ATTENDANCE", "ABSENCE_LIMITS", "URGENT" if exceeded else "REVIEW",
        ))
    if approaching and current_sub_filter == "ABSENCE_LIMITS":
        if any(r.get("risk_category") == "absence" and r.get("amount") is not None
               for r in (_ctx("payoutImpactResult") or {}).get("rows") or []):
            candidates.append(_candidate("payout_impact_absence", "See estimated payout impact of these absence risks", "ATTENDANCE", "PAYOUT_IMPACT", "REVIEW"))

    # Reads directly off the engine's ledger-derived field -- no longer
    # depends on payoutImpactResult having run this turn (see module docstring).
    incomplete_all = analyzer.get("incomplete_attendance_records") or [] if attendance_scope else []
    incomplete = [r for r in incomplete_all if not win_start or (r.get("date") or "") >= win_start]
    if incomplete and overview_scope:
        candidates.append(_candidate("incomplete_attendance", f"Review missing check-in/check-out -- {len(incomplete)} day(s)",
                                      "ATTENDANCE", "INCOMPLETE_ATTENDANCE", "REVIEW"))
    if incomplete and current_sub_filter == "INCOMPLETE_ATTENDANCE":
        if any(r.get("risk_category") == "incomplete" and r.get("amount") is not None
               for r in (_ctx("payoutImpactResult") or {}).get("rows") or []):
            candidates.append(_candidate("payout_impact_incomplete", "See estimated payout impact of these missing records", "ATTENDANCE", "PAYOUT_IMPACT", "REVIEW"))

    turn_request = _ctx("turnRequest") or {}
    is_payment_summary = not (turn_request.get("childNames") or turn_request.get("countyNames"))
    if (payment_result.get("mode") != "multi_period" and payment_result.get("status") != "needs_period_selection"
            and current_sub_filter != "FULL_BREAKDOWN" and is_payment_summary):
        settled = payment_result.get("payment_history_found") is True
        payable_rows = [r for r in payment_result.get("rows") or [] if isinstance(r, dict) and r.get("status") in ("calculated", "at_risk")]
        at_risk_count = payment_result.get("at_risk_day_count", 0) or 0
        if settled and payable_rows:
            candidates.append(_candidate(FULL_BREAKDOWN_ID, "View breakdown of this settled amount", "PAYMENT", "FULL_BREAKDOWN", "INFO"))
        elif payable_rows:
            label = (f"Review full breakdown — {at_risk_count} at-risk entr{'y' if at_risk_count == 1 else 'ies'}"
                     if at_risk_count > 0 else "View full payment breakdown for this period")
            candidates.append(_candidate(FULL_BREAKDOWN_ID, label, "PAYMENT", "FULL_BREAKDOWN", "INFO"))
    return candidates


def _rank(candidate, current_action, current_sub_filter):
    just_shown = candidate["action"] == current_action and candidate.get("subFilter") == current_sub_filter
    severity_rank = {"URGENT": 0, "REVIEW": 1, "INFO": 2}.get(candidate["severity"], 3)
    return (1 if just_shown else 0, severity_rank)


def recommend():
    """Resolution-based: every candidate is recomputed from live risk data
    each turn (see _build_candidates), so an unresolved risk keeps being
    recommended until it's actually resolved -- not suppressed after one
    display, which was the previous version's bug."""
    turn_request = _ctx("turnRequest") or {}
    current_action = turn_request.get("action")
    current_sub_filter = turn_request.get("subFilter")
    provider_status = (_ctx("ccare_provider_data_py") or {}).get("status")
    if provider_status in ("failed", "needs_clarification"):
        return []

    candidates = _build_candidates(current_action, current_sub_filter)
    unique, seen = [], set()
    for c in candidates:
        key = (c["id"], c.get("action"), c.get("subFilter"))
        if key in seen:
            continue
        seen.add(key)
        unique.append(c)

    remaining = [c for c in unique if not (c.get("action") == current_action and c.get("subFilter") == current_sub_filter and current_action is not None)]
    remaining.sort(key=lambda c: _rank(c, current_action, current_sub_filter))
    return remaining[:MAX_ACTIONS]


# ==============================================================================
# SECTION 5 -- VIEW BUILDERS
# Each returns content blocks only (no buttons -- those are appended once,
# generically, by the entry point). This is the ENTIRE presentation layer:
# there is no markdown twin anywhere below.
# ==============================================================================

def build_unauthorized():
    return [_accordion([{"title": "Verification required",
                         "content": "I am unable to verify your provider account for this session — it may not yet be authorized "
                                    "for CCARE services, or the session may have expired. If you believe this is incorrect, please "
                                    "contact your program administrator to review your access."}])]


def build_connection_error():
    return [_text("I'm unable to establish a secure connection with the system right now. Please try again in a few "
                  "minutes. If this continues, contact your program administrator.")]


def build_end():
    return [_text("Thank you for checking in. Have a good rest of your day.")]


def build_fallback():
    return [_accordion([{"title": "Unable to load snapshot",
                         "content": "I was unable to retrieve your account details at this time. This is typically temporary — "
                                    "please try again shortly, and contact your system administrator if the issue persists."}])]


def build_clarify():
    session_state = _ctx("sessionState") or {}
    provider_verified = session_state.get("providerVerified", False)
    provider_name = (session_state.get("providerName") or "").strip()
    clarify_reason = (_ctx("turnRequest") or {}).get("clarifyReason") or ""
    if clarify_reason == "greeting" and provider_verified:
        suffix = f", {provider_name}" if provider_name else ""
        return [_text(f"Of course{suffix}. What would you like to look at?")]
    if provider_verified and provider_name:
        headline = f"What can I help you with next, {provider_name}?"
    elif provider_verified:
        headline = "What can I help you with next?"
    else:
        headline = "Hello, I'm Provider Assist. I can help you review attendance, payments, and payout details. What would you like to look at first?"
    return [_text(f"{headline}\n\nSelect an option below, or describe what you need in your own words.")]


def build_greeting():
    dcr = _ctx("data_collection_result") or {}
    snapshot = dcr.get("snapshot") or {}
    user_name = snapshot.get("user_name")
    if not user_name or str(user_name).isdigit():
        user_name = "Provider"
    facility_name = snapshot.get("facility_name") or "your facility"
    today = snapshot.get("today") or {}

    blocks = [_text(f"# {user_name}, here's where things stand today at {facility_name}.")]
    # (fix, previous pass) The greeting headline is never suppressed by
    # progressMessage -- no node in the live graph actually delivers that
    # message to the provider as its own turn, so its presence must not
    # hide this line.

    snap_tbl = _table("Today's snapshot", [("measure", "Measure"), ("count", "Verified count", "right")], [
        {"measure": "Children scheduled", "count": today.get("scheduled_children", snapshot.get("children_scheduled_count", 0))},
        {"measure": "Children checked in", "count": today.get("checked_in_children", snapshot.get("checked_in_count", 0))},
    ])
    if snap_tbl:
        blocks.append(snap_tbl)

    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    win_start = _risk_window_start()
    pending = [r for r in analyzer.get("pending_confirmation_records") or [] if not win_start or (r.get("date") or "") >= win_start]
    summary_absence = _absence_rows_for_summary(analyzer.get("approaching_absence_limits") or [], win_start)
    exceeded = [r for r in summary_absence if (r.get("status") or "") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")]
    approaching = [r for r in summary_absence if (r.get("status") or "") not in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")]
    incomplete = [r for r in analyzer.get("incomplete_attendance_records") or [] if not win_start or (r.get("date") or "") >= win_start]

    risk = snapshot.get("risk_categories") or {}

    def _loss(cat):
        val, amount = (cat or {}).get("potential_loss_hours"), (cat or {}).get("potential_loss_amount")
        if isinstance(val, (int, float)):
            return f"{_fmt_money(amount)} ({val:.1f} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    exc_dates = [dd for r in exceeded for dd in _over_limit_dates(r) if not win_start or dd >= win_start]
    app_dates = [dd for r in approaching for dd in (list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or []))]
    absence_finding_parts, absence_period_parts, absence_impact_parts = [], [], []
    if exceeded:
        absence_finding_parts.append(f"Limit exceeded: {_distinct_child_count(exceeded)} child(ren), {len(exc_dates)} day(s) in window")
        absence_period_parts.append(_date_range_for_dates(exc_dates) or "--")
        absence_impact_parts.append(_loss(risk.get("approaching_absence_limits")))
    if approaching:
        absence_finding_parts.append(f"Approaching limit: {_distinct_child_count(approaching)} child(ren)")
        absence_period_parts.append(_date_range_for_dates(app_dates) or "--")
        absence_impact_parts.append("Within county limit")

    issues_tbl = _table(
        f"Attendance and payment issues — {_period_label()}",
        [("area", "Risk area"), ("finding", "Verified finding"), ("period", "Period"), ("impact", "Potential payment impact")],
        [
            {"area": "Pending parent confirmations",
             "finding": f"{len(pending)} day(s), {len({r.get('child_id') for r in pending if r.get('child_id')})} child(ren)" if pending else "No pending parent confirmations",
             "period": _date_range_for_dates(r.get("date") for r in pending) or "--",
             "impact": _loss(risk.get("pending_parent_confirmations")) if pending else "No actionable impact"},
            {"area": "Absence-limit risk", "finding": "\n".join(absence_finding_parts) or "No children near or over county absence limits",
             "period": "\n".join(absence_period_parts) or "--", "impact": "\n".join(absence_impact_parts) or "No actionable impact"},
            {"area": "Incomplete check-ins/check-outs",
             "finding": f"{len(incomplete)} day(s)" if incomplete else "No incomplete check-in/out found",
             "period": _date_range_for_dates(r.get("date") for r in incomplete) or "--",
             "impact": _loss(risk.get("incomplete_attendance")) if incomplete else "No actionable impact"},
        ],
    )
    if issues_tbl:
        blocks.append(issues_tbl)
    return blocks


def build_pending_confirmations():
    win_start = _risk_window_start()
    rows = [r for r in (_ctx("attendance_risks_analyzer_py") or {}).get("pending_confirmation_records") or []
            if not win_start or (r.get("date") or "") >= win_start]
    if not rows:
        return [_accordion([{"title": "Pending parent confirmations", "content": "There are currently no pending parent confirmations."}])]
    tbl = _table("Pending parent confirmations", [("child", "Child"), ("authorization", "Authorization"),
                 ("service_date", "Service date"), ("status", "Status")],
                 [{"child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("auth_id") or "--",
                   "service_date": _fmt_date(r.get("date")), "status": "Pending"} for r in rows])
    return [tbl] if tbl else []


def build_absence_limits():
    win_start = _risk_window_start()
    rows = _absence_rows_for_summary((_ctx("attendance_risks_analyzer_py") or {}).get("approaching_absence_limits") or [], win_start)
    period = _period_label()
    blocks = [_text(f"Period: {period}", italic=True)] if period else []
    if not rows:
        blocks.append(_accordion([{"title": "Absence-limit risk", "content": "No children currently near or over county monthly absence limits."}]))
        return blocks

    impact_by_auth = {}
    for pr in (_ctx("payoutImpactResult") or {}).get("rows") or []:
        if isinstance(pr, dict) and pr.get("risk_category") == "absence":
            key = str(pr.get("authorization_id") or pr.get("child_name") or "")
            agg = impact_by_auth.setdefault(key, {"hours": 0.0, "amount": 0.0})
            agg["hours"] += float(pr.get("care_hours") or 0)
            try:
                agg["amount"] += float(pr.get("amount") or 0)
            except (TypeError, ValueError):
                pass

    table_rows = []
    for r in rows:
        is_exceeded = (r.get("status") or "") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")
        auth_key = str(r.get("authorization_id") or r.get("child_name") or "")
        if is_exceeded:
            od_all = _over_limit_dates(r)
            period_range = _date_range_for_dates(od_all) or "--"
            imp = impact_by_auth.get(auth_key)
            if imp and imp["amount"] > 0:
                impact = f"${imp['amount']:.2f} at risk ({imp['hours']:.1f} care hrs)"
            else:
                od_win = [dd for dd in od_all if not win_start or dd >= win_start]
                impact = "At risk (rate unavailable)" if od_win else "Outside confirmation window"
        else:
            period_range = _date_range_for_dates(list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])) or "--"
            impact = "Within county limit"
        confirmed_ct = r.get("confirmed_absence_count", len(r.get("confirmed_absence_dates") or []))
        probable_ct = r.get("probable_absence_count", len(r.get("probable_absence_dates") or []))
        used = f"{confirmed_ct + probable_ct} ({probable_ct} not confirmed yet)" if probable_ct else str(confirmed_ct + probable_ct)
        table_rows.append({
            "risk_type": "Limit exceeded" if is_exceeded else "Approaching limit",
            "child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("authorization_id") or "--",
            "county": r.get("county_name") or "--", "absences_used": used, "absence_limit": r.get("absence_limit", "--"),
            "at_risk_period": period_range, "payment_impact": impact,
        })
    table_rows.sort(key=lambda row: 0 if row.get("payment_impact") != "Outside confirmation window" else 1)
    tbl = _table("Absence-limit risk",
                 [("risk_type", "Risk type"), ("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
                  ("absences_used", "Absences used", "right"), ("absence_limit", "County limit", "right"),
                  ("at_risk_period", "At-risk period"), ("payment_impact", "Payment impact")], table_rows)
    if tbl:
        blocks.append(tbl)
    return blocks


def build_incomplete_attendance():
    win_start = _risk_window_start()
    # Reads the engine's ledger-derived field directly -- decoupled from
    # whether payoutImpactResult happened to run this turn (see docstring).
    rows = [r for r in (_ctx("attendance_risks_analyzer_py") or {}).get("incomplete_attendance_records") or []
            if not win_start or (r.get("date") or "") >= win_start]
    if not rows:
        return [_accordion([{"title": "Missing check-in/check-out", "content": "No missing check-ins or check-outs were found in this window."}])]
    tbl = _table("Missing check-in/check-out",
                 [("child", "Child"), ("authorization", "Authorization"), ("service_date", "Service date"),
                  ("attendance_type", "Attendance type"), ("reason", "Reason")],
                 [{"child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("authorization_id") or "--",
                   "service_date": _fmt_date(r.get("date")), "attendance_type": "Missing check-in/check-out",
                   "reason": r.get("reason") or "A check-in or check-out was not logged for this day"} for r in rows])
    return [tbl] if tbl else []


def build_attendance_all():
    blocks = [_text("## Attendance overview")]
    blocks += build_absence_limits()
    blocks += build_incomplete_attendance()
    dcr = _ctx("data_collection_result") or {}
    pending_cat = ((dcr.get("snapshot") or {}).get("risk_categories") or {}).get("pending_parent_confirmations") or {}
    if pending_cat.get("days"):
        blocks.append(_accordion([{"title": "Pending parent confirmations",
                                   "content": f"{pending_cat['days']} day(s), {pending_cat.get('children', 0)} child(ren) — use "
                                              "\"Show pending confirmations\" for detail."}]))
    else:
        blocks.append(_text("No pending parent confirmations"))
    return blocks


def build_payout_impact():
    result = _ctx("payoutImpactResult") or {}
    rows = result.get("rows") or []
    # (fix, previous pass) filters on the actionId that actually survives the
    # turn-request pipeline -- the previous version checked `turnRequest.id`,
    # a field that was never populated, so all three payout-impact buttons
    # showed the same unfiltered table.
    scope = (_ctx("turnRequest") or {}).get("actionId") or ""
    scope_category = {"payout_impact_absence": "absence", "payout_impact_pending": "unconfirmed",
                       "payout_impact_incomplete": "incomplete"}.get(scope)
    if scope_category:
        rows = [r for r in rows if (r.get("risk_category") or "") == scope_category]
    calc_rows = [r for r in rows if r.get("amount") is not None]

    if not rows:
        return [_accordion([{"title": "Payout impact", "content": "None of your current attendance risk is affecting an upcoming payout."}])]
    if not calc_rows:
        return [_accordion([{"title": "Payout impact", "content": "Attendance risk was found, but the payout impact cannot be calculated "
                             "yet — rate schedule data may still be loading. Please try again shortly."}])]

    total_hours = sum(float(r.get("care_hours") or 0) for r in calc_rows)
    total_dollar = sum(float(r.get("amount") or 0) for r in calc_rows)
    blocks = [_text("## Payout impact of current attendance risk")]
    agg = {}
    for r in calc_rows:
        key = (_safe_display_value(r.get("child_name") or ""), r.get("authorization_id") or "--", r.get("county_name") or "--", r.get("risk_category") or "")
        entry = agg.setdefault(key, {"hours": Decimal("0"), "amount": Decimal("0"), "reason": r.get("reason") or "--"})
        entry["hours"] += Decimal(str(r.get("care_hours") or 0))
        entry["amount"] += Decimal(str(r.get("amount") or "0"))
    tbl = _table(f"~ {_fmt_money(total_dollar)} at risk across {_fmt_hours(total_hours)} care hour(s)",
                 [("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
                  ("care_hours", "Care hours", "right"), ("amount", "Amount", "right"), ("reason", "Reason")],
                 [{"child": k[0], "authorization": k[1], "county": k[2], "care_hours": _fmt_hours(float(v["hours"])),
                   "amount": _fmt_money(v["amount"]), "reason": v["reason"]} for k, v in agg.items()])
    if tbl:
        blocks.append(tbl)
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def _at_risk_reason(result):
    at_risk_rows = [r for r in result.get("rows") or [] if r.get("status") == "at_risk"]
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
    parts += [k.replace("_", " ").lower() for k in risk_types if k != "MISSING_ATTENDANCE"]
    return "; ".join(parts) if parts else "under review"


def build_payment():
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    top_blockers = result.get("blockers") or []
    settled = result.get("payment_history_found") is True

    if not rows and not settled:
        if not top_blockers:
            return [_accordion([{"title": "No payment history found",
                                 "content": "There is no payment record on file for this period yet. This is expected if the "
                                            "county has not yet processed it."}])]
        blocks = [_text("I encountered a few data issues while calculating this. Here is what is blocking it:")]
        tbl = _table("Payment issues", [("issue_area", "Issue area"), ("reason", "Reason")],
                     [{"issue_area": BLOCKER_TITLE.get(b, b.replace("_", " ").title()), "reason": b} for b in top_blockers])
        blocks.append(tbl if tbl else _text("No further detail is available for this issue."))
        return blocks

    amount_type = "Calculated" if settled else "Expected"
    period_label = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end")) or (result.get("service_period_id") or "--")
    payout_date = result.get("payment_release_date")
    at_risk_days = result.get("at_risk_day_count") or 0
    risk_detail = _at_risk_reason(result)
    rows_out = [
        {"field": "Service period", "value": period_label},
        {"field": "Payout date", "value": _fmt_date(payout_date) if payout_date else "--"},
        {"field": "Attendance-based payment", "value": f"{_fmt_money(result.get('attended_care_amount'))} ({_fmt_hours(float(result.get('attended_care_hours') or 0))} hrs, {amount_type})"},
    ]
    if float(result.get("forecast_amount") or 0) > 0:
        rows_out.append({"field": "Scheduled forecast payment", "value": f"{_fmt_money(result.get('forecast_amount'))} ({_fmt_hours(float(result.get('forecast_hours') or 0))} hrs, {amount_type})"})
    rows_out.append({"field": "Vacant slot payment", "value": f"{_fmt_money(result.get('vacant_slot_amount'))} ({amount_type})"})
    rows_out.append({"field": "At risk", "value": f"{_fmt_money(result.get('amount_at_risk'))} ({risk_detail})" if risk_detail else _fmt_money(result.get("amount_at_risk"))})
    rows_out.append({"field": "Potential total", "value": _fmt_money(result.get("potential_total_amount") or result.get("total_amount"))})

    headline = f"## Payment summary — {period_label}"
    if at_risk_days > 0:
        headline += f"\n\n{at_risk_days} day{'s' if at_risk_days != 1 else ''} are flagged at risk, so the final amount may differ at county processing."
    blocks = [_text(headline)]
    tbl = _table("Payment summary", [("field", "Field"), ("value", "Value")], rows_out, no_limit=True)
    if tbl:
        blocks.append(tbl)
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def build_payment_multi_period():
    result = _ctx("paymentResult") or {}
    periods = result.get("periods") or []
    if not periods:
        return [_accordion([{"title": "Payment summary", "content": "I couldn't find any service periods in that date range. "
                             "Please try a different range, or ask for your next payout."}])]
    try:
        page = max(0, int(_ctx("turnRequest.fetchParams.page") or 0))
    except (TypeError, ValueError):
        page = 0
    all_rows = []
    for p in periods:
        period_range = _fmt_date_range(p.get("service_period_start"), p.get("service_period_end"))
        status = "Calculated" if p.get("payment_history_found") else ("At-risk" if (p.get("at_risk_day_count") or 0) > 0 else "Expected")
        all_rows.append({"service_period": period_range or (p.get("service_period_id") or "--"),
                          "payout_date": _fmt_date(p.get("payment_release_date")) if p.get("payment_release_date") else "--",
                          "potential_total": _fmt_money(p.get("potential_total_amount") or p.get("total_amount")), "status": status})
    start_idx = page * MULTI_PERIOD_PAGE_SIZE
    page_rows = all_rows[start_idx:start_idx + MULTI_PERIOD_PAGE_SIZE]
    grand_total = sum((_safe_decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
    caption = f"Payment summary — period by period · Grand total: {_fmt_money(grand_total)}"
    if len(all_rows) > MULTI_PERIOD_PAGE_SIZE:
        caption += f" · Showing {start_idx + 1}–{min(start_idx + MULTI_PERIOD_PAGE_SIZE, len(all_rows))} of {len(all_rows)} periods"
    blocks = []
    tbl = _table(caption, [("service_period", "Service period"), ("payout_date", "Payout date"),
                 ("potential_total", "Potential total", "right"), ("status", "Status")], page_rows, no_limit=True)
    if tbl:
        blocks.append(tbl)
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def build_payment_needs_period_selection():
    candidates = (_ctx("paymentResult") or {}).get("candidates") or []
    blocks = [_text("## Multiple service periods found\n\nSeveral service periods match this request. Please select the one you would like to review:")]
    tbl = _table("Service periods found", [("num", "#", "right"), ("service_period", "Service period"), ("status", "Status")],
                 [{"num": i + 1, "service_period": c.get("label", "--"), "status": "Awaiting selection"} for i, c in enumerate(candidates)])
    if tbl:
        blocks.append(tbl)
    return blocks


def build_payment_full_breakdown():
    result = _ctx("paymentResult") or {}
    rows = result.get("rows") or []
    attended_all = [r for r in rows if r.get("kind") != "VACANT_SLOT"]
    vacant_all = [r for r in rows if r.get("kind") == "VACANT_SLOT"]
    calculated = [r for r in attended_all if r.get("status") in ("calculated", "at_risk")]
    calculated_vacant = [r for r in vacant_all if r.get("status") == "calculated"]
    at_risk_only = [r for r in calculated if r.get("status") == "at_risk"]
    if result.get("payment_history_found") is not True and at_risk_only:
        calculated = at_risk_only
    period_label = _fmt_date_range(result.get("service_period_start"), result.get("service_period_end")) or (result.get("service_period_id") or "--")
    try:
        page = int(_ctx("turnRequest.fetchParams.page") or 0)
    except (TypeError, ValueError):
        page = 0
    start_idx = page * FULL_BREAKDOWN_PAGE_SIZE
    page_rows = calculated[start_idx:start_idx + FULL_BREAKDOWN_PAGE_SIZE]
    at_risk_n = sum(1 for r in calculated if r.get("status") == "at_risk")

    title = f"## Full breakdown — {period_label}"
    if calculated:
        title += f"\n\n{len(calculated)} days on record — {len(calculated) - at_risk_n} calculated, {at_risk_n} at-risk."
    footer = None
    if len(calculated) > FULL_BREAKDOWN_PAGE_SIZE:
        shown_end = min(start_idx + FULL_BREAKDOWN_PAGE_SIZE, len(calculated))
        total_pages = (len(calculated) + FULL_BREAKDOWN_PAGE_SIZE - 1) // FULL_BREAKDOWN_PAGE_SIZE
        footer = f"Showing {start_idx + 1}–{shown_end} of {len(calculated)} days  ·  Page {page + 1} of {total_pages}"

    blocks = [_text(title)]
    if page_rows:
        tbl = _table("Attendance breakdown",
                     [("child_name", "Child"), ("authorization", "Authorization"), ("county", "County"), ("care_date", "Care date"),
                      ("attendance_type", "Rate type"), ("care_hours", "Care hours", "right"), ("amount", "Amount", "right")],
                     [{"child_name": r.get("child_name") or "--", "authorization": r.get("authorization_name") or r.get("authorization_id") or "--",
                       "county": r.get("county_name") or "--", "care_date": _fmt_date(r.get("service_date")),
                       "attendance_type": _rate_type_display(r), "care_hours": _fmt_hours(r.get("payable_hours")),
                       "amount": _fmt_money(r.get("amount"))} for r in page_rows], no_limit=True, footer=footer)
        if tbl:
            blocks.append(tbl)
    if calculated_vacant:
        vtbl = _table("Vacant slot payments", [("county", "County"), ("care_date", "Care date"), ("amount", "Amount", "right")],
                      [{"county": r.get("county_name") or "--", "care_date": _fmt_date(r.get("service_date")), "amount": _fmt_money(r.get("amount"))}
                       for r in calculated_vacant])
        if vtbl:
            blocks.append(vtbl)
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def _child_rows(rows, child_key):
    key = str(child_key or "").strip().lower()
    return [r for r in rows if r.get("kind") == "ATTENDED_CARE"
            and key in {str(r.get("authorization_name") or "").strip().lower(), str(r.get("authorization_id") or "").strip().lower()}]


def build_payment_child_detail(child_key):
    rows = _child_rows((_ctx("paymentResult") or {}).get("rows") or [], child_key)
    if not rows:
        return [_text(f"I couldn't find any attendance records for \"{child_key}\" in this service period. "
                      "Please verify the spelling, or ask me to list your children.")]
    auth_name, county_name = rows[0].get("authorization_name") or child_key, rows[0].get("county_name") or "--"
    payable = [r for r in rows if r.get("status") in ("calculated", "at_risk")]
    category_rows, total_days, total_hours, total_amount = [], 0, Decimal("0"), Decimal("0")
    for label, group in _group_by_classification(payable).items():
        days, hours = len(group), sum((_safe_decimal(r.get("payable_hours")) for r in group), Decimal("0"))
        amount = sum((_safe_decimal(r.get("amount")) for r in group), Decimal("0"))
        category_rows.append({"category": label, "days": days, "hours": _fmt_hours(float(hours)), "amount": _fmt_money(str(amount))})
        total_days += days
        total_hours += hours
        total_amount += amount
    if category_rows:
        category_rows.append({"category": "Total", "days": total_days, "hours": _fmt_hours(float(total_hours)), "amount": _fmt_money(str(total_amount))})
    blocks = [_text(f"## Payment detail — {auth_name}")]
    tbl = _table(f"Authorization: {auth_name} · County: {county_name}",
                 [("category", "Category"), ("days", "Days", "right"), ("hours", "Hours", "right"), ("amount", "Amount", "right")], category_rows)
    if tbl:
        blocks.append(tbl)
    return blocks


def build_payment_county_detail(county_key):
    rows = (_ctx("paymentResult") or {}).get("rows") or []
    matching = [r for r in rows if str(r.get("county_name") or "").strip().lower() == str(county_key or "").strip().lower()]
    if not matching:
        return [_accordion([{"title": f"County detail — {county_key}",
                             "content": f"I don't have payment data for \"{county_key}\" in this service period. Please verify the "
                                        "county name, or request your full breakdown."}])]
    attended = [r for r in matching if r.get("kind") == "ATTENDED_CARE" and r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    attended_amount = sum((_safe_decimal(r.get("amount")) for r in attended), Decimal("0"))
    attended_hours = sum((_safe_decimal(r.get("payable_hours")) for r in attended), Decimal("0"))
    vacant_amount = sum((_safe_decimal(r.get("amount")) for r in vacant), Decimal("0"))
    county_name = matching[0].get("county_name") or county_key
    blocks = [_text(f"## Payment detail — {county_name}")]
    tbl = _table(f"County: {county_name}", [("attendance_payment", "Attendance-based payment"), ("vacant_payment", "Vacant slot payment")],
                 [{"attendance_payment": f"{_fmt_money(str(attended_amount))} ({_fmt_hours(float(attended_hours))} hrs)", "vacant_payment": _fmt_money(str(vacant_amount))}])
    if tbl:
        blocks.append(tbl)
    blocks.append(_accordion([{"title": "Note", "content": "To see a specific child's detail, ask about that child's authorization by name."}]))
    return blocks


def build_explain():
    payment_result = _ctx("paymentResult") or {}
    snapshot = (_ctx("data_collection_result") or {}).get("snapshot") or {}
    blocks = [_text("## Explanation")]
    at_risk_amt = payment_result.get("amount_at_risk")
    at_risk_days = payment_result.get("at_risk_day_count") or 0
    try:
        at_risk_float = float(at_risk_amt) if at_risk_amt else 0
    except (TypeError, ValueError):
        at_risk_float = 0
    if at_risk_float > 0:
        detail = _at_risk_reason(payment_result)
        content = ("A day is marked **at risk** when care was provided but parent confirmation is still pending. "
                   "The county holds payment on those days until the parent confirms.\n\n"
                   f"Your current at-risk amount: **{_fmt_money(at_risk_amt)}** ({at_risk_days} day(s) — {detail or 'awaiting confirmation'})")
        blocks.append(_accordion([{"title": "About \u201cat risk\u201d amounts", "content": content, "open": True}]))

    risk = snapshot.get("risk_categories") or {}
    pending_days = (risk.get("pending_parent_confirmations") or {}).get("days", 0) or 0
    absence_children = ((risk.get("approaching_absence_limits") or {}).get("children", 0) or 0) + ((risk.get("crossed_absence_limits") or {}).get("children", 0) or 0)
    incomplete_days = (risk.get("incomplete_attendance") or {}).get("days", 0) or 0
    summary_rows = []
    if pending_days:
        summary_rows.append({"area": "Pending confirmations", "status": f"{pending_days} day(s) need parent sign-off"})
    if absence_children:
        summary_rows.append({"area": "Absence limits", "status": f"{absence_children} child(ren) near or over the monthly limit"})
    if incomplete_days:
        summary_rows.append({"area": "Incomplete attendance", "status": f"{incomplete_days} day(s) missing check-in or check-out"})
    if summary_rows:
        tbl = _table("Current items requiring attention", [("area", "Area"), ("status", "Status")], summary_rows)
        if tbl:
            blocks.append(tbl)
    elif len(blocks) == 1:
        blocks.append(_accordion([{"title": "Current status", "content": "There are no outstanding items to flag for the current period."}]))
    return blocks


# ==============================================================================
# SECTION 6 -- BLOCK VALIDATION (unchanged from the previous version)
# ==============================================================================

_RICH_TYPES = {"table", "buttons", "accordion"}
_KEY_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def _scalar(v):
    return v is None or isinstance(v, (str, int, float, bool))


def _valid_table(b):
    cols, rows = b.get("columns"), b.get("rows")
    if not isinstance(cols, list) or not 1 <= len(cols) <= 12 or not isinstance(rows, list) or len(rows) > 100:
        return False
    keys = []
    for c in cols:
        if not isinstance(c, dict):
            return False
        k = c.get("key")
        if not isinstance(k, str) or not _KEY_RE.fullmatch(k) or k in keys or not isinstance(c.get("label"), str):
            return False
        if c.get("align") not in (None, "left", "center", "right"):
            return False
        keys.append(k)
    return all(isinstance(r, dict) and not any(k not in keys for k in r) and all(_scalar(r.get(k)) for k in keys) for r in rows)


def _valid_buttons(b):
    items = b.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8:
        return False
    for i in items:
        if not isinstance(i, dict) or not isinstance(i.get("label"), str):
            return False
        if "value" in i and not isinstance(i["value"], str):
            return False
        if i.get("variant") not in (None, "primary", "secondary"):
            return False
    return True


def _valid_accordion(b):
    items = b.get("items")
    if not isinstance(items, list) or not 1 <= len(items) <= 8:
        return False
    for i in items:
        if not isinstance(i, dict) or not isinstance(i.get("title"), str) or not isinstance(i.get("content"), str):
            return False
        if "```chat-ui" in i["content"] or ("open" in i and not isinstance(i["open"], bool)):
            return False
    return True


def _valid_block(b):
    if not isinstance(b, dict) or b.get("version") != 1:
        return False
    t = b.get("type")
    if t == "text":
        return isinstance(b.get("content"), str) and ("italic" not in b or isinstance(b.get("italic"), bool))
    return {"table": _valid_table, "buttons": _valid_buttons, "accordion": _valid_accordion}.get(t, lambda _b: False)(b)


# ==============================================================================
# SECTION 7 -- ENTRY POINT
# ==============================================================================

_turn_request = _ctx("turnRequest") or {}
_action = _turn_request.get("action")
_sub_filter = _turn_request.get("subFilter")
_provider_status = (_ctx("ccare_provider_data_py") or {}).get("status")
_provider_reason = (_ctx("ccare_provider_data_py") or {}).get("reason")
_payment_result = _ctx("paymentResult") or {}

_recommended = recommend()
write_context("recommendedActions", _recommended)

if _provider_status == "failed" and _provider_reason == "CONNECTION_FAILED":
    _blocks = build_connection_error()
elif _provider_status == "failed":
    _blocks = build_unauthorized()
elif _action == "STARTER":
    _blocks = build_greeting()
elif _provider_status == "needs_clarification" or _action == "CLARIFY":
    _blocks = build_clarify()
elif _action == "END":
    _blocks = build_end()
elif _action == "EXPLAIN":
    _blocks = build_explain()
elif _action == "PAYMENT":
    _child_names = [c for c in (_turn_request.get("childNames") or []) if c]
    _county_names = [c for c in (_turn_request.get("countyNames") or []) if c]
    if _payment_result.get("mode") == "multi_period":
        _blocks = build_payment_multi_period()
    elif _payment_result.get("status") == "needs_period_selection":
        _blocks = build_payment_needs_period_selection()
    elif _sub_filter == "FULL_BREAKDOWN":
        _blocks = build_payment_full_breakdown()
    elif _child_names:
        _blocks = build_payment_child_detail(_child_names[0])
    elif _county_names:
        _blocks = build_payment_county_detail(_county_names[0])
    else:
        _blocks = build_payment()
elif _action == "ATTENDANCE":
    _blocks = {
        "PENDING_CONFIRMATIONS": build_pending_confirmations,
        "ABSENCE_LIMITS": build_absence_limits,
        "INCOMPLETE_ATTENDANCE": build_incomplete_attendance,
        "PAYOUT_IMPACT": build_payout_impact,
    }.get(_sub_filter, build_attendance_all)()
else:
    _blocks = build_fallback()

# Inject the shared estimate disclaimer once, before the buttons, if any
# block on the page carries a dollar amount and it isn't already present.
_has_dollar = any(
    (b.get("type") == "text" and "$" in (b.get("content") or ""))
    or (b.get("type") == "table" and any("$" in str(v) for row in (b.get("rows") or []) for v in row.values() if v is not None))
    for b in _blocks
)
_has_disclaimer = any(b.get("type") == "text" and b.get("content") == DISCLAIMER_TEXT for b in _blocks)
if _has_dollar and not _has_disclaimer:
    _blocks.append(_text(DISCLAIMER_TEXT, italic=True))

# (fix, previous pass) Only mark the greeting as delivered when a
# greeting-eligible response actually went out -- not on failed validation.
if _provider_status != "failed":
    write_context("greetingDone", True)

_buttons_block = _buttons(_recommended)
_final_blocks = _blocks + ([_buttons_block] if _buttons_block else [])
_final_blocks = [b for b in _final_blocks if _valid_block(b)]

_formatted_markdown = blocks_to_markdown(_blocks, _recommended)
write_context("formattedBlocks", _final_blocks)
write_context("formattedResponse", _formatted_markdown)

_parts = []
for _b in _final_blocks:
    if _b.get("type") == "text":
        _c = _b.get("content", "")
        _parts.append(f"*{_c}*" if _b.get("italic") else _c)
    else:
        _parts.append("```chat-ui\n" + json.dumps(_b, ensure_ascii=False, separators=(",", ":")) + "\n```")

respond(
    "\n\n".join(_parts) if _parts else "I was unable to retrieve your account details at this time. This is typically "
                                        "temporary — please try again shortly, and contact your system administrator if the issue persists.",
    confidence=1.0,
)