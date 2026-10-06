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
from datetime import date, timedelta
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

def _candidate(id_, label, action, sub_filter, severity, service_period_id=None, child_names=None, county_names=None):
    out = {"id": id_, "label": label, "action": action, "subFilter": sub_filter, "severity": severity}
    if service_period_id:
        out["servicePeriodId"] = service_period_id
    if child_names:
        out["childNames"] = child_names
    if county_names:
        out["countyNames"] = county_names
    return out


def _highest_value_child(rows, amount_key="amount", name_key="child_name", hours_key="care_hours"):
    """Picks the child with the largest resolved dollar amount across rows
    (falling back to hours when no row has a resolved amount yet). Returns
    None when fewer than 2 distinct children are present -- drilling into
    "the highest" of one isn't a useful action."""
    dollars, hours = {}, {}
    for r in rows or []:
        name = r.get(name_key)
        if not name:
            continue
        if r.get(amount_key) is not None:
            dollars[name] = dollars.get(name, 0.0) + float(_safe_decimal(r.get(amount_key)))
        hours[name] = hours.get(name, 0.0) + float(r.get(hours_key) or 0)
    pool = dollars if dollars else hours
    if len(pool) < 2:
        return None
    name, value = max(pool.items(), key=lambda kv: kv[1])
    return name, value, bool(dollars)


def _multi_child_hint(counties_too=False):
    if counties_too:
        return _text("Tip: ask about a specific child (by name or authorization ID) or a specific county to see "
                     "just their payments or attendance for the period you're viewing.", italic=True)
    return _text("Tip: ask about a specific child by name or authorization ID to see just their payments or "
                 "attendance for the period you're viewing.", italic=True)


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

    turn_request = _ctx("turnRequest") or {}
    active_children = {str(n).strip().upper() for n in (turn_request.get("childNames") or [])}
    active_counties = {str(n).strip().upper() for n in (turn_request.get("countyNames") or [])}

    def _filter_by_active(rows, name_key="child_name"):
        result = rows
        if active_children:
            result = [r for r in result if str(r.get(name_key) or "").strip().upper() in active_children]
        if active_counties:
            result = [r for r in result if str(r.get("county_name") or "").strip().upper() in active_counties]
        return result

    _fwd_filters = {}
    if active_children:
        _fwd_filters["child_names"] = list(turn_request.get("childNames") or [])
    if active_counties:
        _fwd_filters["county_names"] = list(turn_request.get("countyNames") or [])

    pending_all = analyzer.get("pending_confirmation_records") or []
    pending = _filter_by_active([r for r in pending_all if not win_start or (r.get("date") or "") >= win_start])
    overview_scope = current_action == "STARTER" or (current_action == "ATTENDANCE" and current_sub_filter == "ALL")

    # "Check your upcoming payout" / "this week's forecast" are standing
    # nudges across EVERY attendance-related view (not just the overview),
    # so a provider deep in absence-limit review still gets pointed at
    # payment info. Each stops appearing once the provider has actually
    # visited that specific payment view -- tracked in sessionState, not in
    # the per-turn shown-candidate log (which no longer suppresses anything,
    # see recommend()). "This month's payouts" stays overview-only; it's a
    # drill-down summary, not a standing nudge.
    visited_payment_views = set(_ctx("sessionState.visitedPaymentViews") or [])
    if attendance_scope:
        if "NEXT_PAYOUT" not in visited_payment_views:
            candidates.append(_candidate("upcoming_payment", "Check your upcoming payout", "PAYMENT", "NEXT_PAYOUT", "INFO"))
        if "CURRENT_PERIOD_FORECAST" not in visited_payment_views:
            candidates.append(_candidate("current_week_forecast", "See this week's payment forecast", "PAYMENT", "CURRENT_PERIOD_FORECAST", "INFO"))
    if overview_scope:
        candidates.append(_candidate("current_month_payouts", "See this month's payouts by service period", "PAYMENT", "CURRENT_MONTH", "INFO"))
    if overview_scope and pending:
        label = f"Review {len(pending)} pending parent confirmation day(s)"
        at_risk = (_ctx("payoutImpactResult") or {}).get("unconfirmed_risk_amount")
        try:
            if at_risk and float(at_risk) > 0:
                label += f" — {_fmt_money(at_risk)} at risk"
        except (TypeError, ValueError):
            pass
        candidates.append(_candidate("pending_confirmations", label, "ATTENDANCE", "PENDING_CONFIRMATIONS", "URGENT", **_fwd_filters))
    elif attendance_scope and current_sub_filter == "PENDING_CONFIRMATIONS":
        if any(r.get("risk_category") == "unconfirmed" and r.get("amount") is not None
               for r in (_ctx("payoutImpactResult") or {}).get("rows") or []):
            candidates.append(_candidate("payout_impact_pending", "See estimated payout impact of these pending days", "ATTENDANCE", "PAYOUT_IMPACT", "REVIEW"))

    approaching = _filter_by_active(_absence_rows_for_summary(analyzer.get("approaching_absence_limits") or [], win_start)) if attendance_scope else []
    if approaching and overview_scope:
        exceeded = [r for r in approaching if (r.get("status") or "") in ("OVER_LIMIT", "POTENTIAL_OVER_LIMIT")]
        near = [r for r in approaching if (r.get("status") or "") == "APPROACHING_LIMIT"]
        parts = []
        if exceeded:
            parts.append(f"{_distinct_child_count(exceeded)} exceeded")
        if near:
            parts.append(f"{_distinct_child_count(near)} approaching")
        candidates.append(_candidate(
            "absence_limits", "Review absence risk",
            "ATTENDANCE", "ABSENCE_LIMITS", "URGENT" if exceeded else "REVIEW",
            **_fwd_filters,
        ))
    # Reads directly off the engine's ledger-derived field -- no longer
    # depends on payoutImpactResult having run this turn (see module docstring).
    _incomplete_cio_all = analyzer.get("incomplete_checkinout_records") or [] if attendance_scope else []
    _incomplete_cio = _filter_by_active([r for r in _incomplete_cio_all if not win_start or (r.get("date") or "") >= win_start])
    if _incomplete_cio and overview_scope:
        candidates.append(_candidate("incomplete_attendance", f"Review incomplete check-in/check-out -- {len(_incomplete_cio)} day(s)",
                                      "ATTENDANCE", "INCOMPLETE_ATTENDANCE", "REVIEW", **_fwd_filters))
    if _incomplete_cio and current_sub_filter == "INCOMPLETE_ATTENDANCE":
        if any(r.get("risk_category") == "incomplete_cio" and r.get("amount") is not None
               for r in (_ctx("payoutImpactResult") or {}).get("rows") or []):
            candidates.append(_candidate("payout_impact_incomplete", "See estimated payout impact of these incomplete records", "ATTENDANCE", "PAYOUT_IMPACT", "REVIEW"))

    already_child_scoped = bool(active_children)
    if attendance_scope and not already_child_scoped:
        top = _highest_value_child((_ctx("payoutImpactResult") or {}).get("rows") or [])
        if top:
            name, value, is_dollar = top
            detail = f"{_fmt_money(value)} at risk" if is_dollar else f"{_fmt_hours(value)} care hrs at risk"
            candidates.append(_candidate(
                "highest_impact_child", f"See most at-risk child — {_safe_display_value(name)} ({detail})",
                "ATTENDANCE", current_sub_filter, "REVIEW", child_names=[name],
            ))

    is_payment_summary = not (active_children or active_counties)
    if (payment_result.get("mode") != "multi_period" and payment_result.get("status") != "needs_period_selection"
            and current_sub_filter != "FULL_BREAKDOWN" and is_payment_summary):
        settled = payment_result.get("payment_history_found") is True
        payable_rows = [r for r in payment_result.get("rows") or [] if isinstance(r, dict) and r.get("status") in ("calculated", "at_risk")]
        at_risk_count = payment_result.get("at_risk_day_count", 0) or 0
        current_period_id = payment_result.get("service_period_id")
        if settled and payable_rows:
            candidates.append(_candidate(FULL_BREAKDOWN_ID, "View breakdown of this settled amount", "PAYMENT", "FULL_BREAKDOWN", "INFO", current_period_id))
        elif payable_rows:
            label = (f"Review full breakdown — {at_risk_count} at-risk entr{'y' if at_risk_count == 1 else 'ies'}"
                     if at_risk_count > 0 else "View full payment breakdown for this period")
            candidates.append(_candidate(FULL_BREAKDOWN_ID, label, "PAYMENT", "FULL_BREAKDOWN", "INFO", current_period_id))
        # Key by authorization_name (the auth number) for unambiguous matching;
        # two children sharing a display name won't be merged into one button.
        top_paid = _highest_value_child(payable_rows, name_key="authorization_name") if payable_rows else None
        if top_paid and current_sub_filter != "FULL_BREAKDOWN":
            auth_name, value, _ = top_paid
            display_name = next(
                (r.get("child_name") for r in payable_rows
                 if r.get("authorization_name") == auth_name and r.get("child_name")),
                auth_name,
            )
            # Store display_name (child_name) so the engine can filter by it;
            # auth_name was only used to find the unambiguous top earner.
            candidates.append(_candidate(
                "highest_paid_child",
                f"See payments for {_safe_display_value(display_name)} (highest this period — {_fmt_money(value)})",
                "PAYMENT", None, "INFO", current_period_id, child_names=[display_name],
            ))
        top_county = _highest_value_child(payable_rows, name_key="county_name") if payable_rows else None
        if top_county and current_sub_filter != "FULL_BREAKDOWN":
            cname, cvalue, _ = top_county
            candidates.append(_candidate(
                "highest_paid_county", f"See payment detail for {cname} County (highest this period — {_fmt_money(cvalue)})",
                "PAYMENT", None, "INFO", current_period_id, county_names=[cname],
            ))

    # When inside a child or county drill-down, the top-level summary buttons
    # are gone. Offer a navigation back so the provider can reach other views
    # (e.g. county after child, or child after county) without typing.
    # Pass servicePeriodId explicitly so the back button returns to the same
    # period -- without it the router defaults to NEXT_PAYOUT which may differ.
    if current_action == "PAYMENT" and not is_payment_summary:
        _back_period_id = payment_result.get("service_period_id")
        candidates.append(_candidate(
            "payment_summary", "Back to payment overview for this period",
            "PAYMENT", None, "INFO", _back_period_id,
        ))

    # On a child-scoped attendance view, offer a direct jump to that child's
    # payment detail so the provider doesn't have to navigate back to the
    # payment summary first.
    if attendance_scope and already_child_scoped:
        for _att_child in (turn_request.get("childNames") or [])[:1]:
            candidates.append(_candidate(
                "view_payment_child", f"See payment detail for {_safe_display_value(_att_child)}",
                "PAYMENT", None, "INFO", child_names=[_att_child],
            ))

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

    remaining = [c for c in unique if not (
        c.get("action") == current_action and c.get("subFilter") == current_sub_filter
        and current_action is not None and not c.get("childNames") and not c.get("countyNames")
    )]
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

    blocks = [_text(f"## {user_name}, here's where things stand today at {facility_name}.")]
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
    incomplete_cio = [r for r in analyzer.get("incomplete_checkinout_records") or [] if not win_start or (r.get("date") or "") >= win_start]

    risk = snapshot.get("risk_categories") or {}

    def _loss(cat):
        val, amount = (cat or {}).get("potential_loss_hours"), (cat or {}).get("potential_loss_amount")
        if isinstance(val, (int, float)):
            return f"{_fmt_money(amount)} ({val:.1f} care hrs)" if amount is not None else "Unavailable"
        return "Unavailable" if cat else "No calculated impact"

    exc_dates = [dd for r in exceeded for dd in _over_limit_dates(r) if not win_start or dd >= win_start]
    app_dates = [dd for r in approaching for dd in (list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])) if not win_start or dd >= win_start]
    all_absence_dates = sorted(set(exc_dates + app_dates))
    _absence_child_count = len({
        str(r.get("child_name") or r.get("child_id") or "").strip()
        for rows in (exceeded, approaching) for r in rows
        if r.get("child_name") or r.get("child_id")
    })
    if exceeded or approaching:
        finding_parts = []
        if exceeded:
            finding_parts.append(f"{len(exc_dates)} day(s) over limit")
        if approaching:
            finding_parts.append(f"{len(app_dates)} day(s) approaching limit")
        impact_parts = []
        if approaching:
            loss_str = _loss(risk.get("approaching_absence_limits"))
            if loss_str and loss_str not in ("Unavailable", "No calculated impact"):
                impact_parts.append(loss_str)
        absence_row = {
            "area": "Absence-limit risk",
            "finding": f"{_absence_child_count} child(ren) · " + " · ".join(finding_parts),
            "period": _date_range_for_dates(all_absence_dates) or "--",
            "impact": "  ·  ".join(impact_parts) or "No actionable impact",
        }
    else:
        absence_row = {
            "area": "Absence-limit risk",
            "finding": "No children near or over county absence limits",
            "period": "--",
            "impact": "No actionable impact",
        }

    issues_tbl = _table(
        f"Attendance and payment issues — {_period_label()}",
        [("area", "Risk area"), ("finding", "Verified finding"), ("period", "Period"), ("impact", "Potential payment impact")],
        [
            {"area": "Pending parent confirmations",
             "finding": f"{len(pending)} day(s), {len({r.get('child_id') for r in pending if r.get('child_id')})} child(ren)" if pending else "No pending parent confirmations",
             "period": _date_range_for_dates(r.get("date") for r in pending) or "--",
             "impact": _loss(risk.get("pending_parent_confirmations")) if pending else "No actionable impact"},
            absence_row,
            {"area": "Incomplete check-ins/check-outs",
             "finding": f"{len(incomplete_cio)} day(s)" if incomplete_cio else "No incomplete check-in/out found",
             "period": _date_range_for_dates(r.get("date") for r in incomplete_cio) or "--",
             "impact": _loss(risk.get("incomplete_checkinout")) if incomplete_cio else "No actionable impact"},
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

    impact_rows = (_ctx("payoutImpactResult") or {}).get("rows") or []
    impact_by_day = {
        (str(r.get("child_name") or "").strip().lower(), r.get("date")): r
        for r in impact_rows if r.get("risk_category") in ("unconfirmed", "incomplete")
    }
    today = date.today()
    display_rows = []
    for row in rows:
        service_date = row.get("date")
        deadline, time_remaining = "--", "Review"
        try:
            due = date.fromisoformat(str(service_date)[:10]) + timedelta(days=9)
            remaining = (due - today).days
            deadline = _fmt_date(due.isoformat())
            time_remaining = "Due today" if remaining == 0 else (f"{remaining} days left" if remaining > 1 else "1 day left")
        except (TypeError, ValueError):
            pass
        impact = impact_by_day.get((str(row.get("child_name") or "").strip().lower(), service_date))
        display_rows.append({
            "child": _safe_display_value(row.get("child_name") or ""),
            "authorization": row.get("auth_id") or "--",
            "service_date": _fmt_date(service_date),
            "status": "Parent confirmation pending" if row.get("status") == "PARENT_PENDING" else "Provider attendance entry missing",
            "deadline": deadline,
            "time_remaining": time_remaining,
            "amount_at_risk": _fmt_money(impact.get("amount")) if impact and impact.get("amount") is not None else "--",
        })
    tbl = _table("Attendance confirmation and entry", [("child", "Child"), ("authorization", "Authorization"),
                 ("service_date", "Service date"), ("status", "Status"), ("deadline", "9-day deadline"),
                 ("time_remaining", "Time remaining"), ("amount_at_risk", "Estimated impact", "right")], display_rows)
    blocks = [tbl] if tbl else []
    blocks.append(_text("Recommended action: follow up with the parent outside the system when confirmation is pending, then verify or complete the attendance record in the source system."))
    if len({r.get("child_name") for r in rows if r.get("child_name")}) > 1 and not (_ctx("turnRequest") or {}).get("childNames"):
        blocks.append(_multi_child_hint())
    return blocks


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
            # Exceeded days are a certainty, not a risk -- no dollar amount
            # is calculated for them (see the engine). Report the count instead.
            impact = f"{len(od_all)} day(s) beyond limit — not payable" if od_all else "Beyond limit — not payable"
        else:
            period_range = _date_range_for_dates(list(r.get("confirmed_absence_dates") or []) + list(r.get("probable_absence_dates") or [])) or "--"
            imp = impact_by_auth.get(auth_key)
            impact = f"${imp['amount']:.2f} at risk ({imp['hours']:.1f} care hrs)" if imp and imp["amount"] > 0 else "Within county limit"
        confirmed_ct = r.get("confirmed_absence_count", len(r.get("confirmed_absence_dates") or []))
        probable_ct = r.get("probable_absence_count", len(r.get("probable_absence_dates") or []))
        used = f"{confirmed_ct + probable_ct} ({probable_ct} not confirmed yet)" if probable_ct else str(confirmed_ct + probable_ct)
        table_rows.append({
            "risk_type": "Limit exceeded" if is_exceeded else "Approaching limit",
            "child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("authorization_id") or "--",
            "county": r.get("county_name") or "--", "absences_used": used, "absence_limit": r.get("absence_limit", "--"),
            "at_risk_period": period_range, "payment_impact": impact,
        })
    tbl = _table("Absence-limit risk",
                 [("risk_type", "Risk type"), ("child", "Child"), ("authorization", "Authorization"), ("county", "County"),
                  ("absences_used", "Absences used", "right"), ("absence_limit", "County limit", "right"),
                  ("at_risk_period", "At-risk period"), ("payment_impact", "Payment impact")], table_rows)
    if tbl:
        blocks.append(tbl)
    if len({r.get("child_name") for r in rows if r.get("child_name")}) > 1 and not (_ctx("turnRequest") or {}).get("childNames"):
        blocks.append(_multi_child_hint())
    return blocks


def build_incomplete_attendance():
    win_start = _risk_window_start()
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    rows = [r for r in analyzer.get("incomplete_checkinout_records") or []
            if not win_start or (r.get("date") or "") >= win_start]
    if not rows:
        return [_accordion([{"title": "Incomplete check-ins/check-outs", "content": "No incomplete check-ins or check-outs were found in this window."}])]
    tbl = _table("Incomplete check-ins/check-outs",
                 [("child", "Child"), ("authorization", "Authorization"), ("service_date", "Service date"),
                  ("reason", "Reason")],
                 [{"child": _safe_display_value(r.get("child_name") or ""), "authorization": r.get("authorization_id") or "--",
                   "service_date": _fmt_date(r.get("date")),
                   "reason": r.get("reason") or "A check-in or check-out was not logged for this day"} for r in rows])
    blocks = [tbl] if tbl else []
    if len({r.get("child_name") for r in rows if r.get("child_name")}) > 1 and not (_ctx("turnRequest") or {}).get("childNames"):
        blocks.append(_multi_child_hint())
    return blocks


def _all_engine_rows():
    result = _ctx("paymentResult") or {}
    if result.get("mode") == "multi_period":
        return [r for period in (result.get("periods") or []) for r in (period.get("rows") or [])]
    return result.get("rows") or []


def build_attendance_child_detail(child_name):
    all_rows = _all_engine_rows()
    rows = _child_rows(all_rows, child_name)
    care_rows = [r for r in rows if r.get("kind") == "ATTENDED_CARE"]

    if not care_rows:
        known = sorted({
            str(r.get("child_name") or "").strip()
            for r in all_rows if r.get("kind") == "ATTENDED_CARE" and r.get("child_name")
        })
        if known:
            return [_text(
                f"No records found for **{child_name}**. "
                f"Children on record this period: {', '.join(known)}. "
                "Please check the spelling and try again."
            )]
        return [_text(f"No attendance records found for **{child_name}** this period.")]

    _CLASS_LABELS = {
        "ABSENCE": "Absence",
        "ENROLLMENT_ABSENCE": "Enrollment absence",
        "FORECAST": "Forecast",
        "ATTENDED": "Attended",
    }
    _STATUS_LABELS = {
        "calculated": "Calculated",
        "at_risk": "At risk",
        "not_payable": "Not payable",
    }

    display_rows = []
    for row in sorted(care_rows, key=lambda r: (r.get("service_date") or "")):
        status = row.get("status") or ""
        note = ""
        if row.get("confirmation_risk") == "MISSING_ATTENDANCE":
            note = " — missing attendance"
        elif row.get("blocker") == "absence_limit_exceeded":
            note = " — absence limit exceeded"
        classification = row.get("classification") or ""
        hrs = row.get("payable_hours")
        display_rows.append({
            "date": _fmt_date(row.get("service_date")),
            "type": _CLASS_LABELS.get(classification, classification.replace("_", " ").title()),
            "rate_type": row.get("rate_type_label") or "--",
            "hours": _fmt_hours(hrs) if hrs not in (None, "0.00", 0, "0") else "--",
            "amount": _fmt_money(row.get("amount")),
            "status": (_STATUS_LABELS.get(status, status.replace("_", " ").title()) or "--") + note,
        })

    child_display = care_rows[0].get("child_name") or child_name
    auth_display = care_rows[0].get("authorization_name") or ""
    caption = f"Attendance — {_safe_display_value(child_display)}"
    if auth_display:
        caption += f" (auth {auth_display})"
    caption += f" — {_period_label()}"

    tbl = _table(
        caption,
        [
            ("date", "Date"),
            ("type", "Type"),
            ("rate_type", "Rate type"),
            ("hours", "Hours", "right"),
            ("amount", "Amount", "right"),
            ("status", "Status"),
        ],
        display_rows,
    )
    return [tbl] if tbl else [_text(f"No attendance rows found for {child_name}.")]


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
    _scope_map = {"payout_impact_absence": {"absence"}, "payout_impact_pending": {"unconfirmed"},
                  "payout_impact_incomplete": {"incomplete_cio"}}
    scope_cats = _scope_map.get(scope)
    if scope_cats:
        rows = [r for r in rows if (r.get("risk_category") or "") in scope_cats]
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
    if len(agg) > 1 and not (_ctx("turnRequest") or {}).get("childNames"):
        blocks.append(_multi_child_hint())
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
        headline += f"\n\n{at_risk_days} day{'s' if at_risk_days != 1 else ''} flagged at risk, so the final amount may differ at county processing."
    blocks = [_text(headline)]
    tbl = _table("Payment summary", [("field", "Field"), ("value", "Value")], rows_out, no_limit=True)
    if tbl:
        blocks.append(tbl)
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def _period_display(p, today):
    """Release status + amount text for one service period.

    Amount label rules:
      - released AND settled (actual payment record)  -> Confirmed
      - days already worked (attended/at-risk/vacant) -> Calculated
      - future/forecast days                          -> Scheduled
    A period that straddles today is a MIX, shown as "$A calculated + $B scheduled".
    """
    def _d(v):
        try:
            return date.fromisoformat(str(v)[:10])
        except (TypeError, ValueError):
            return None

    start, end, release = _d(p.get("service_period_start")), _d(p.get("service_period_end")), _d(p.get("payment_release_date"))
    if release and release <= today:
        release_status = "Released"
    elif end and end < today:
        release_status = "Awaiting release"
    elif start and start <= today:
        release_status = "In progress"
    else:
        release_status = "Upcoming"

    potential = _safe_decimal(p.get("potential_total_amount") or p.get("total_amount") or "0")
    risk = _safe_decimal(p.get("amount_at_risk") or "0")
    if p.get("payment_history_found"):
        amount = f"{_fmt_money(potential)} (Confirmed)"
    else:
        forecast = _safe_decimal(p.get("forecast_amount") or "0")
        calculated = potential - forecast
        if forecast > 0 and calculated > 0:
            amount = f"{_fmt_money(calculated)} calculated + {_fmt_money(forecast)} scheduled"
        elif forecast > 0:
            amount = f"{_fmt_money(forecast)} (Scheduled)"
        else:
            amount = f"{_fmt_money(calculated)} (Calculated)"
        if risk > 0:
            amount += f" · incl. {_fmt_money(risk)} at risk"
    return release_status, amount


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
    today = date.today()
    all_rows = []
    for p in periods:
        release_status, amount = _period_display(p, today)
        all_rows.append({
            "service_period": _fmt_date_range(p.get("service_period_start"), p.get("service_period_end")) or (p.get("service_period_id") or "--"),
            "payout_date": _fmt_date(p.get("payment_release_date")) if p.get("payment_release_date") else "--",
            "amount": amount, "release_status": release_status,
        })
    start_idx = page * MULTI_PERIOD_PAGE_SIZE
    page_rows = all_rows[start_idx:start_idx + MULTI_PERIOD_PAGE_SIZE]
    grand_total = sum((_safe_decimal(p.get("potential_total_amount") or p.get("total_amount") or "0.00") for p in periods), Decimal("0"))
    _mp_tr = _ctx("turnRequest") or {}
    _mp_children = [c for c in (_mp_tr.get("childNames") or []) if c]
    _mp_counties = [c for c in (_mp_tr.get("countyNames") or []) if c]
    _scope_parts = []
    if _mp_children:
        _scope_parts.append("child: " + ", ".join(_mp_children))
    if _mp_counties:
        _scope_parts.append("county: " + ", ".join(_mp_counties))
    caption = f"Payouts by service period · Total: {_fmt_money(grand_total)}"
    if _scope_parts:
        caption += " · Filtered to: " + " · ".join(_scope_parts)
    if len(all_rows) > MULTI_PERIOD_PAGE_SIZE:
        caption += f" · Showing {start_idx + 1}–{min(start_idx + MULTI_PERIOD_PAGE_SIZE, len(all_rows))} of {len(all_rows)} periods"
    if _mp_children:
        _mp_heading = "## Payments for " + ", ".join(_mp_children)
    elif _mp_counties:
        _mp_heading = "## Payments for " + ", ".join(_mp_counties) + (" County" if len(_mp_counties) == 1 else " Counties")
    else:
        _mp_heading = "## Payment history"
    blocks = [_text(_mp_heading)]
    tbl = _table(caption, [("service_period", "Service period"), ("payout_date", "Payout date"),
                 ("amount", "Amount"), ("release_status", "Release status")], page_rows, no_limit=True)
    if tbl:
        blocks.append(tbl)
    blocks.append(_text("Confirmed = settled by the county · Calculated = worked days, based on attendance on file · "
                        "Scheduled = upcoming days, based on authorized hours.", italic=True))
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
    _tr_now = _ctx("turnRequest") or {}
    if len({r.get("child_name") for r in calculated if r.get("child_name")}) > 1 and not _tr_now.get("childNames"):
        has_multi_county = len({r.get("county_name") for r in calculated if r.get("county_name")}) > 1 and not _tr_now.get("countyNames")
        blocks.append(_multi_child_hint(counties_too=has_multi_county))
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def _child_rows(rows, child_key):
    key = str(child_key or "").strip().lower()
    def _cn_match(r):
        cn = str(r.get("child_name") or "").strip().lower()
        return bool(key and (key in cn or cn in key))
    return [r for r in rows if r.get("kind") == "ATTENDED_CARE"
            and (key in {str(r.get("authorization_name") or "").strip().lower(), str(r.get("authorization_id") or "").strip().lower()}
                 or _cn_match(r))]


def build_payment_child_detail(child_key):
    rows = _child_rows(_all_engine_rows(), child_key)
    if not rows:
        return [_text(f"I couldn't find any attendance records for \"{child_key}\" in this service period. "
                      "Please verify the spelling, or ask me to list your children.")]

    # Multiple distinct authorizations match the same name — show a
    # disambiguation table so the provider can pick by auth number.
    auth_ids = {r.get("authorization_id") for r in rows
                if r.get("kind") == "ATTENDED_CARE" and r.get("authorization_id")}
    if len(auth_ids) > 1:
        seen = {}
        for r in rows:
            if r.get("kind") != "ATTENDED_CARE":
                continue
            aid = r.get("authorization_id") or ""
            if aid not in seen:
                seen[aid] = {"auth": r.get("authorization_name") or aid,
                             "child": r.get("child_name") or "--",
                             "county": r.get("county_name") or "--",
                             "total": Decimal("0")}
            seen[aid]["total"] += _safe_decimal(r.get("amount"))
        dis_rows = [{"auth": d["auth"], "child": d["child"], "county": d["county"],
                     "amount": _fmt_money(d["total"])} for d in seen.values()]
        tbl = _table(
            f"Multiple authorizations match \"{child_key}\" — ask by authorization number for detail",
            [("auth", "Authorization"), ("child", "Child"), ("county", "County"), ("amount", "Amount", "right")],
            dis_rows,
        )
        return ([_text(f"## Multiple children — \"{child_key}\""), tbl]
                if tbl else [_text(f"Multiple authorizations match \"{child_key}\". "
                                   "Please specify an authorization number to see the detail.")])

    auth_name, county_name = rows[0].get("authorization_name") or child_key, rows[0].get("county_name") or "--"
    child_display = rows[0].get("child_name")
    heading_subject = f"{child_display} ({auth_name})" if child_display else auth_name
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
    blocks = [_text(f"## Payment detail — {heading_subject}")]
    tbl = _table(f"Authorization: {auth_name} · County: {county_name}",
                 [("category", "Category"), ("days", "Days", "right"), ("hours", "Hours", "right"), ("amount", "Amount", "right")], category_rows)
    if tbl:
        blocks.append(tbl)
    return blocks


def build_payment_county_detail(county_key):
    key = str(county_key or "").strip().lower()
    matching = [r for r in _all_engine_rows() if str(r.get("county_name") or "").strip().lower() == key]
    if not matching:
        return [_accordion([{"title": f"County detail — {county_key}",
                             "content": f"I don't have payment data for \"{county_key}\" in this service period. Please verify the "
                                        "county name, or request your full breakdown."}])]

    attended_care = [r for r in matching if r.get("kind") == "ATTENDED_CARE"]
    payable = [r for r in attended_care if r.get("status") in ("calculated", "at_risk")]
    vacant = [r for r in matching if r.get("kind") == "VACANT_SLOT" and r.get("status") == "calculated"]
    county_name = matching[0].get("county_name") or county_key

    # "Care hours" = hours of care actually delivered (regular attendance and
    # drop-in) -- absence/holiday/forecast are paid categories but not hours
    # of care given, so they're reported as separate counts below instead.
    care_rows = [r for r in payable if r.get("classification") in ("REGULAR", "DROP_IN")]
    care_hours = sum((_safe_decimal(r.get("payable_hours")) for r in care_rows), Decimal("0"))
    children_served = {r.get("child_name") for r in care_rows if r.get("child_name")}
    # "Logged" counts every day of that classification on file for this
    # county, regardless of whether it ended up payable -- an absence that
    # hit the county limit was still logged, it just isn't being paid.
    absences_logged = sum(1 for r in attended_care if r.get("classification") in ("ABSENCE", "ENROLLMENT_ABSENCE"))
    drop_ins_logged = sum(1 for r in attended_care if r.get("classification") == "DROP_IN")

    attended_amount = sum((_safe_decimal(r.get("amount")) for r in payable), Decimal("0"))
    vacant_amount = sum((_safe_decimal(r.get("amount")) for r in vacant), Decimal("0"))
    at_risk_amount = sum((_safe_decimal(r.get("amount")) for r in payable if r.get("status") == "at_risk"), Decimal("0"))
    total_amount = attended_amount + vacant_amount
    _pr = _ctx("paymentResult") or {}
    period_label = _fmt_date_range(_pr.get("service_period_start"), _pr.get("service_period_end")) or (_pr.get("service_period_id") or "--")

    blocks = [_text(f"## Payment detail — {county_name} County")]
    summary_rows = [
        {"field": "Service period", "value": period_label},
        {"field": "Children served", "value": len(children_served)},
        {"field": "Care hours", "value": _fmt_hours(float(care_hours))},
        {"field": "Absences logged", "value": absences_logged},
        {"field": "Drop-ins logged", "value": drop_ins_logged},
        {"field": "Attendance-based payment", "value": _fmt_money(attended_amount)},
        {"field": "Vacant slot payment", "value": _fmt_money(vacant_amount)},
    ]
    if at_risk_amount > 0:
        summary_rows.append({"field": "Included at risk", "value": _fmt_money(at_risk_amount)})
    summary_rows.append({"field": "Amount overall", "value": f"**{_fmt_money(total_amount)}**"})
    tbl = _table(f"County: {county_name}", [("field", "Field"), ("value", "Value")], summary_rows, no_limit=True)
    if tbl:
        blocks.append(tbl)
    if len(children_served) > 1 and not (_ctx("turnRequest") or {}).get("childNames"):
        blocks.append(_multi_child_hint())
    blocks.append(_text(DISCLAIMER_TEXT, italic=True))
    return blocks


def _explain_payment_calculation():
    """PAYMENT_CALCULATION: invariant rule, so it's a template -- but it uses a
    real row from the current period when one is available, instead of only
    speaking in the abstract."""
    payment_result = _ctx("paymentResult") or {}
    rows = payment_result.get("rows") or []
    worked_example = next((r for r in rows if r.get("kind") == "ATTENDED_CARE" and r.get("status") == "calculated"), None)
    content = (
        "Each scheduled care day is calculated in four steps:\n\n"
        "1. **Classify the day** — regular attendance, absence, holiday, drop-in, or forecast (a future day not yet worked), "
        "based on authorized hours vs. attended hours and provider closures.\n"
        "2. **Determine payable hours** — attended days are paid for attended hours; absence, holiday, and forecast days "
        "are paid for authorized hours; drop-in days are paid for attended hours only.\n"
        "3. **Resolve the rate** — payable hours map to a care-hours tier (e.g. part-time, full-time), which combines with the "
        "child's age band, the authorization's rate type, and your county's rate schedule to look up a dollar rate per day.\n"
        "4. **Apply confirmation risk** — if the day is within the last 9 days and parent confirmation is still pending or missing, "
        "the amount shows as *at risk* rather than *calculated* until it's confirmed."
    )
    if worked_example:
        content += (
            f"\n\nFor example, {_fmt_date(worked_example.get('service_date'))} for "
            f"{_safe_display_value(worked_example.get('child_name') or '')}: classified as "
            f"**{(worked_example.get('classification') or '').replace('_', ' ').title()}**, "
            f"{_fmt_hours(worked_example.get('payable_hours'))} payable hours at the "
            f"{worked_example.get('rate_type_label') or 'applicable'} rate, for **{_fmt_money(worked_example.get('amount'))}**."
        )
    return [_text("## How payment is calculated"), _accordion([{"title": "The four-step calculation", "content": content, "open": True}])]


def _explain_absence_limit_rule():
    """ABSENCE_LIMIT_RULE: cite the provider's own current limit/count when
    we have one on file; otherwise explain the rule in general terms."""
    groups = (_ctx("attendance_risks_analyzer_py") or {}).get("approaching_absence_limits") or []
    content = (
        "Each county sets a maximum number of paid absence days per month, based on your provider quality tier. "
        "Absences within that limit are paid the same as an attended day. Once the total confirmed and recent "
        "absences for a child's authorization in a calendar month **exceed** that limit, every absence day for that "
        "authorization that month — not just the days past the threshold — is excluded from payment.\n\n"
        "Children 36 months or younger are exempt from absence-limit counting entirely."
    )
    if groups:
        g = groups[0]
        content += (
            f"\n\nFor example, {_safe_display_value(g.get('child_name') or '')} in {g.get('county_name') or 'your county'} "
            f"has a limit of **{g.get('absence_limit')}** absence day(s) this month, with "
            f"**{g.get('confirmed_absence_count', 0)}** confirmed and **{g.get('probable_absence_count', 0)}** from the last 9 days."
        )
    return [_text("## How absence limits work"), _accordion([{"title": "The monthly limit rule", "content": content, "open": True}])]


def _explain_confirmation_window():
    content = (
        "Any care day within the **last 9 days** is still considered open for parent confirmation. If a day in that "
        "window has a pending confirmation, or no attendance record logged at all, its payment shows as *at risk* "
        "rather than *calculated* — the amount is what you'd expect to be paid, but it isn't finalized yet.\n\n"
        "Once a day passes the 9-day window, it's treated as settled one way or the other and no longer shows as "
        "at risk — whatever the county's records reflect at that point is what carries into the payment cycle."
    )
    return [_text("## The confirmation window"), _accordion([{"title": "Why some days show as \u201cat risk\u201d", "content": content, "open": True}])]


def _explain_rate_or_tier():
    payment_result = _ctx("paymentResult") or {}
    rows = [r for r in payment_result.get("rows") or [] if r.get("kind") == "ATTENDED_CARE" and r.get("rate_type_label")]
    content = (
        "Your rate for a given day depends on three things: the **child's age band**, the **care-hours tier** "
        "(based on how many hours were authorized/attended that day — part-time, full-time, etc.), and your "
        "**provider quality rating**, which sets which fiscal rate schedule applies. The same child can be billed "
        "at different rates on different days if their authorized hours change, or across a birthday that moves "
        "them into a new age band."
    )
    if rows:
        labels = sorted({r["rate_type_label"] for r in rows})
        content += f"\n\nRate type(s) on file for this period: {', '.join(labels)}."
    return [_text("## Why your rate is what it is"), _accordion([{"title": "How a rate is chosen", "content": content, "open": True}])]


def _explain_at_risk_reason():
    payment_result = _ctx("paymentResult") or {}
    at_risk_amt = payment_result.get("amount_at_risk")
    at_risk_days = payment_result.get("at_risk_day_count") or 0
    try:
        at_risk_float = float(at_risk_amt) if at_risk_amt else 0
    except (TypeError, ValueError):
        at_risk_float = 0
    blocks = [_text("## About \u201cat risk\u201d amounts")]
    if at_risk_float > 0:
        detail = _at_risk_reason(payment_result)
        content = ("A day is marked **at risk** when care was provided but parent confirmation is still pending or "
                   "missing, within the last 9 days. The county holds payment on those days until they're confirmed "
                   "or the window closes.\n\n"
                   f"Your current at-risk amount: **{_fmt_money(at_risk_amt)}** ({at_risk_days} day(s) — {detail or 'awaiting confirmation'})")
        blocks.append(_accordion([{"title": "What's at risk right now", "content": content, "open": True}]))
    else:
        blocks.append(_accordion([{"title": "Nothing currently at risk",
                                   "content": "There's no at-risk amount on the payment view you were looking at. A day shows "
                                              "as at risk only when it's within the last 9 days and still pending or missing "
                                              "confirmation."}]))
    return blocks


def build_explain():
    topic = (_ctx("turnRequest") or {}).get("explainTopic")
    if topic == "PAYMENT_CALCULATION":
        return _explain_payment_calculation()
    if topic == "ABSENCE_LIMIT_RULE":
        return _explain_absence_limit_rule()
    if topic == "CONFIRMATION_WINDOW":
        return _explain_confirmation_window()
    if topic == "RATE_OR_TIER":
        return _explain_rate_or_tier()
    if topic == "AT_RISK_REASON":
        return _explain_at_risk_reason()

    # OTHER (or unrecognized): a prior LLM synthesis step (ccare_explain_synthesizer,
    # only invoked for this path -- see the process graph) reasoned over the
    # data already computed this turn and wrote its answer here. It is
    # instructed to answer strictly from provided facts and to say so
    # plainly when it can't -- so a missing/empty value below means that
    # step genuinely couldn't answer, not a formatting bug.
    synthesis = _ctx("explainSynthesis") or {}
    if synthesis.get("text"):
        return [_text("## Explanation"), _text(synthesis["text"])]
    return [_accordion([{"title": "I need a bit more to go on",
                         "content": "I couldn't match that to something specific I can explain from what's on screen. "
                                    "Try asking about a payment or attendance view first, then ask me to explain it -- "
                                    "or rephrase what you'd like explained."}])]


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
_child_names = [c for c in (_turn_request.get("childNames") or []) if c]
_county_names = [c for c in (_turn_request.get("countyNames") or []) if c]
_provider_status = (_ctx("ccare_provider_data_py") or {}).get("status")
_provider_reason = (_ctx("ccare_provider_data_py") or {}).get("reason")
_payment_result = _ctx("paymentResult") or {}

_recommended = recommend()

_PAYMENT_NUDGE_VIEWS = {"NEXT_PAYOUT", "CURRENT_PERIOD_FORECAST"}
if _action == "PAYMENT" and _sub_filter in _PAYMENT_NUDGE_VIEWS:
    _session_state_now = _ctx("sessionState") or {}
    _visited_now = set(_session_state_now.get("visitedPaymentViews") or [])
    if _sub_filter not in _visited_now:
        _visited_now.add(_sub_filter)
        write_context("sessionState", dict(_session_state_now, visitedPaymentViews=sorted(_visited_now)))

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
    if _child_names:
        _blocks = build_attendance_child_detail(_child_names[0])
    else:
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