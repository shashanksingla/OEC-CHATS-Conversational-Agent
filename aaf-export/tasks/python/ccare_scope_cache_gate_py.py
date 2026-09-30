"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Runs deterministic action shortcut matching before LLM routing.
Resolves exact action IDs and positional replies.
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

_ORDINAL_WORDS = {
    "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5,
    "1st": 1, "2nd": 2, "3rd": 3, "4th": 4, "5th": 5,
}


def _detect_positional_ref(user_message):
    """Returns an unambiguous positional reference from a bare reply."""
    text = (user_message or "").strip().strip(".!?").lower()
    if not text:
        return None
    if text.isdigit():
        return {"type": "number", "value": int(text)}
    if text in _ORDINAL_WORDS:
        return {"type": "ordinal", "value": _ORDINAL_WORDS[text]}
    if text in ("last", "the last one", "last one"):
        return {"type": "last", "value": None}
    return None


def _resolve_by_keyword(user_message, recommended_actions, payment_candidates):
    """Resolves exact action IDs without language understanding."""
    text = (user_message or "").strip().lower()
    if not text:
        return {}, False
    for candidate in (payment_candidates if isinstance(payment_candidates, list) else []):
        if isinstance(candidate, dict) and str(candidate.get("id") or "").strip().lower() == text:
            return {
                "action": candidate.get("action") or "PAYMENT",
                "subFilter": candidate.get("subFilter"),
                "servicePeriodId": candidate.get("id"),
                # Carried through so downstream drill-down views (e.g. the three
                # PAYOUT_IMPACT variants, which share one subFilter) can tell
                # which specific recommended action was clicked.
                "actionId": candidate.get("id"),
            }, True
    for item in (recommended_actions if isinstance(recommended_actions, list) else []):
        if isinstance(item, dict) and str(item.get("id") or "").strip().lower() == text:
            return {
                "action": item.get("action"),
                "subFilter": item.get("subFilter"),
                "servicePeriodId": None,
                "actionId": item.get("id"),
            }, True
    return {}, False


def _resolve_positional(ref, recommended_actions, payment_candidates):
    """Resolves a positional reference against available candidates."""
    if not ref or not isinstance(ref, dict):
        return {}, False

    ref_type = ref.get("type")
    value = ref.get("value")
    if isinstance(value, str) and value.strip().lstrip("-").isdigit():
        value = int(value.strip())

    list_len = len(payment_candidates) if isinstance(payment_candidates, list) and payment_candidates \
        else (len(recommended_actions) if isinstance(recommended_actions, list) else 0)
    if list_len == 0:
        return {}, False

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
        # Recommended-action IDs are labels, not service-period IDs.
        return {
            "action": item.get("action"),
            "subFilter": item.get("subFilter"),
            "servicePeriodId": None,
            "actionId": item.get("id"),
        }, True

    return {}, False


_user_message = read_context("user_message") or ""
_recommended_actions = read_context("recommendedActions") or []
_payment_result = read_context("paymentResult") or {}
_payment_candidates = _payment_result.get("candidates") if isinstance(_payment_result, dict) else None

_resolved, _matched = _resolve_by_keyword(_user_message, _recommended_actions, _payment_candidates)
if not _matched:
    _ref = _detect_positional_ref(_user_message)
    if _ref:
        _resolved, _matched = _resolve_positional(_ref, _recommended_actions, _payment_candidates)

if _matched:
    write_context("shortcutResolution", {
        "matched": "YES",
        "action": _resolved.get("action"),
        "subFilter": _resolved.get("subFilter"),
        "servicePeriodId": _resolved.get("servicePeriodId"),
        "actionId": _resolved.get("actionId"),
    })
    log(f"action shortcut: matched action={_resolved.get('action')} subFilter={_resolved.get('subFilter')} actionId={_resolved.get('actionId')} -- skipping LLM router")
    respond({"matched": "YES"}, confidence=1.0)
else:
    write_context("shortcutResolution", {"matched": "NO"})
    log("action shortcut: no match -- routing to LLM router")
    respond({"matched": "NO"}, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________