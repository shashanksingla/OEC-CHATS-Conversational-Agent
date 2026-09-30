"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________
Builds the deterministic turnRequest from router output and session context.
Runtime affordances: read_context, write_context, respond().
"""

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

ACTION_META = {
    "STARTER": ("DATA_ACTION", "Starter"),
    "ATTENDANCE": ("DATA_ACTION", "Attendance"),
    "PAYMENT": ("DATA_ACTION", "Payment"),
    "EXPLAIN": ("DATA_ACTION", "Explain"),
    "CLARIFY": ("CLARIFY", "Unclear"),
    "END": ("END", "End"),
}


def _resolve_positional(classification, recommended_actions, payment_candidates):
    """Resolves router positional references to an action or clarification."""
    ref = classification.get("positionalRef")
    if not ref or not isinstance(ref, dict):
        return {}, True

    ref_type = ref.get("type")
    value = ref.get("value")
    # Coerce quoted integer values.
    if isinstance(value, str) and value.strip().lstrip("-").isdigit():
        value = int(value.strip())

    list_len = len(payment_candidates) if isinstance(payment_candidates, list) and payment_candidates \
        else (len(recommended_actions) if isinstance(recommended_actions, list) else 0)
    if list_len == 0:
        return {}, False

    # "last" resolves to the final item when value is null.
    if ref_type == "last" and value is None:
        idx = list_len - 1
    elif isinstance(value, int) and value >= 1:
        idx = value - 1
    else:
        return {}, False

    if isinstance(payment_candidates, list) and payment_candidates:
        if idx >= len(payment_candidates):
            return {}, False
        candidate = payment_candidates[idx]
        if not isinstance(candidate, dict):
            return {}, False
        return {
            "action": candidate.get("action") or "PAYMENT",
            "subFilter": candidate.get("subFilter"),
            "servicePeriodId": candidate.get("id"),
            "actionId": candidate.get("id"),
        }, True

    if isinstance(recommended_actions, list) and recommended_actions:
        if idx >= len(recommended_actions):
            return {}, False
        item = recommended_actions[idx]
        if not isinstance(item, dict):
            return {}, False
        # Recommendation IDs are labels, not service-period IDs.
        return {
            "action": item.get("action"),
            "subFilter": item.get("subFilter"),
            "servicePeriodId": None,
            "actionId": item.get("id"),
        }, True

    return {}, False


def _resolve_date_filter(action, date_filter):
    if action in ("CLARIFY", "END"):
        return None
    return date_filter or "THIS_MONTH"


def _build_fetch_params(sub_filter, date_filter, date_from, date_to, period_count):
    if sub_filter == "LAST_PAYOUT":
        return {"paymentBefore": "TODAY", "limitOne": True}
    if date_filter in ("THIS_WEEK", "LAST_WEEK", "NEXT_WEEK"):
        return {"dateFilter": date_filter}
    if sub_filter == "SPECIFIC_PERIOD" and date_from and date_to:
        return {"dateFilter": "DATE_RANGE", "dateFrom": date_from, "dateTo": date_to}
    if date_filter in ("LAST_N_MONTHS", "LAST_N_DAYS") and period_count:
        return {"dateFilter": date_filter, "periodCount": period_count}
    return {}


def _scope_ref(child_names, county_names):
    if child_names:
        return " for " + ", ".join(child_names)
    if county_names:
        return " in " + ", ".join(county_names)
    return ""


def _period_ref(date_filter, service_period_id):
    if service_period_id:
        return "the period you just selected"
    labels = {
        "TODAY": "today", "THIS_WEEK": "this week", "LAST_WEEK": "last week",
        "NEXT_WEEK": "next week", "THIS_MONTH": "this month", "LAST_MONTH": "last month",
        "LAST_N_MONTHS": "the recent months you asked about",
        "LAST_N_DAYS": "the recent days you asked about",
        "DATE_RANGE": "the date range you specified",
    }
    return labels.get(date_filter, "the current period")


def _progress_message(action, sub_filter, first_turn, mention_name, provider_name, child_names, county_names, date_filter, service_period_id, variant):
    # CLARIFY already asks for details in its final response.
    if action in ("END", "CLARIFY"):
        return ""

    # Mention the provider name only on first turns, topic changes, or milestones.
    name_clause = f", {provider_name}" if mention_name and provider_name else ""
    scope = _scope_ref(child_names, county_names)
    period = _period_ref(date_filter, service_period_id)
    # Alternate phrasing to avoid repetitive consecutive messages.
    v = variant % 2

    if action == "STARTER":
        if first_turn:
            return "Hello — one moment while I verify your account details before we get started."
        return (
            f"One moment{name_clause} — I am compiling your attendance and payment overview now."
            if v == 0 else
            f"Refreshing your attendance and payment overview{name_clause}."
        )

    if action == "ATTENDANCE" and sub_filter == "PAYOUT_IMPACT":
        return (
            f"One moment{name_clause} — I am calculating how your attendance risk{scope} could affect your payout for {period}."
            if v == 0 else
            f"Assessing the payout impact of your current attendance risk{scope} for {period}{name_clause}."
        )

    if action == "ATTENDANCE":
        return (
            f"One moment{name_clause} — I am retrieving your attendance records{scope} and reviewing parent confirmations for {period}."
            if v == 0 else
            f"Checking attendance and confirmation status{scope} for {period}{name_clause}."
        )

    if action == "PAYMENT":
        return (
            f"One moment{name_clause} — I am retrieving your payment records{scope} and calculating the figures for {period}."
            if v == 0 else
            f"Reviewing your payment details{scope} for {period}{name_clause}."
        )

    if action == "EXPLAIN":
        return (
            f"One moment{name_clause} — I will verify the details before providing an explanation."
            if v == 0 else
            f"Reviewing the relevant details{name_clause} before explaining this."
        )

    if action == "CLARIFY":
        if first_turn:
            return "I would be glad to help — could you share more detail about what you'd like to look into?"
        return f"I would be glad to help{name_clause} — could you share more detail about what you would like to look into?"

    return (
        f"One moment{name_clause} — I am looking into that now."
        if v == 0 else
        f"Reviewing your request{name_clause} now."
    )


_classification = read_context("routerClassification") or {}
if not isinstance(_classification, dict):
    _classification = {}

_shortcut = read_context("shortcutResolution") or {}
_shortcut_matched = isinstance(_shortcut, dict) and _shortcut.get("matched") == "YES"

_recommended_actions = read_context("recommendedActions") or []
_payment_result = read_context("paymentResult") or {}
_payment_candidates = _payment_result.get("candidates") if isinstance(_payment_result, dict) else None
_user_message = read_context("user_message") or ""
_external_id = read_context("external_id") or ""
_session_state = read_context("sessionState") or {}
_greeting_done = bool(read_context("greetingDone"))
_provider_name = _session_state.get("providerName") if isinstance(_session_state, dict) else None
_first_turn = not _greeting_done

# Revalidate providers after the session turn bound.
_REVALIDATION_TURN_BOUND = 20
_session_updates = {}
if isinstance(_session_state, dict) and _session_state.get("providerVerified") == "YES":
    _turn_count = int(_session_state.get("validatedTurnCount") or 0) + 1
    if _turn_count > _REVALIDATION_TURN_BOUND:
        _session_updates.update(providerVerified="NO", validatedTurnCount=0)
    else:
        _session_updates.update(validatedTurnCount=_turn_count)

_action = _classification.get("action") or "CLARIFY"
_sub_filter = _classification.get("subFilter")
_clarify_reason = _classification.get("clarifyReason")
_child_names = _classification.get("childNames") or []
_county_names = _classification.get("countyNames") or []
_date_filter = _classification.get("dateFilter")
_date_from = _classification.get("dateFrom")
_date_to = _classification.get("dateTo")
_period_count = _classification.get("periodCount")
_confidence = _classification.get("confidence", 1.0)
_service_period_id = None
_action_id = None

# Use shortcut resolution directly; its classification may be stale.
if _shortcut_matched:
    _action = _shortcut.get("action") or "CLARIFY"
    _sub_filter = _shortcut.get("subFilter")
    _service_period_id = _shortcut.get("servicePeriodId")
    _action_id = _shortcut.get("actionId")
    _clarify_reason = None
    _child_names = []
    _county_names = []
    _date_filter = None
    _date_from = None
    _date_to = None
    _period_count = None
    _confidence = 1.0
else:
    # Resolve the router's positional reference when present.
    _positional_fields, _positional_ok = _resolve_positional(_classification, _recommended_actions, _payment_candidates)
    if _classification.get("positionalRef"):
        if not _positional_ok:
            _action, _sub_filter, _clarify_reason = "CLARIFY", None, "vague"
        else:
            _action = _positional_fields.get("action") or _action
            _sub_filter = _positional_fields.get("subFilter")
            _service_period_id = _positional_fields.get("servicePeriodId")
            _action_id = _positional_fields.get("actionId")

# Require explicit dates for SPECIFIC_PERIOD.
if _sub_filter == "SPECIFIC_PERIOD" and not (_date_from and _date_to):
    _action, _sub_filter, _clarify_reason = "CLARIFY", None, "vague"

_date_filter = _resolve_date_filter(_action, _date_filter)
_fetch_params = _build_fetch_params(_sub_filter, _date_filter, _date_from, _date_to, _period_count)
_routing_class, _intent = ACTION_META.get(_action, ("CLARIFY", "Unclear"))

# Mention names on first turn, topic changes, and END milestones.
_last_action_category = _session_state.get("lastActionCategory") if isinstance(_session_state, dict) else None
_topic_changed = _last_action_category is not None and _last_action_category != _action
_mention_name = _first_turn or _action == "END" or _topic_changed
_turn_seq = int(_session_state.get("turnSeq") or 0) + 1 if isinstance(_session_state, dict) else 1
_session_updates["lastActionCategory"] = _action
_session_updates["turnSeq"] = _turn_seq
if isinstance(_session_state, dict):
    write_context("sessionState", dict(_session_state, **_session_updates))

_progress = _progress_message(
    _action, _sub_filter, _first_turn, _mention_name, _provider_name, _child_names, _county_names, _date_filter, _service_period_id, _turn_seq,
)
write_context("progressMessage", _progress)
# NOTE (ai-firstify re-engineer pass): `progressMessage` is NOT a separate
# turn shown to the provider -- no node in the live graph emits it
# independently. It exists only so the formatter can decide whether to
# still show its own opening line. Do not repurpose this as if it were
# delivered; see ccare_response_formatter.py's `_progress_sent` handling.
if _action != "END":
    write_context("greetingDone", True)

_turn_request = {
    "action": _action,
    "actionId": _action_id,
    "routingClass": _routing_class,
    "intent": _intent,
    "subFilter": _sub_filter,
    "query": _user_message,
    "user_id": _external_id,
    "dateFilter": _date_filter,
    "dateFrom": _date_from,
    "dateTo": _date_to,
    "servicePeriodId": _service_period_id,
    "childNames": _child_names,
    "countyNames": _county_names,
    "fetchParams": _fetch_params,
    "clarifyReason": _clarify_reason,
    "confidence": _confidence,
}
write_context("turnRequest", _turn_request)
log(f"turnRequest finalized: action={_action} subFilter={_sub_filter} dateFilter={_date_filter} actionId={_action_id}")
respond(_turn_request, confidence=_confidence)

# __________________________GenAI: Generated code ends here______________________________