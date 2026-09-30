"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_action_shortcut_gate_py (deployed under the retired ccare_scope_cache_gate_py
task slot -- the AAF portal has no API to create a brand-new task, so an
existing unbound slot is repurposed; see tools/aaf_admin/README.md). Runs
FIRST in the process graph, before the LLM intent classifier. Resolves a
clicked recommended-action button (exact id match) or a bare positional
reply ("3" / "first" / "last") deterministically -- neither needs language
understanding, so a match here lets the graph skip the LLM call entirely.
Relocated (not duplicated) from ccare_turn_request_finalizer_py.py, which
previously computed this same match AFTER an LLM call whose classification
was then discarded every time the match won -- confirmed live: a clicked
"view_full_breakdown" button still paid for a full Bedrock round-trip whose
output was thrown away by the finalizer's own keyword match.

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
    """A message that is ONLY a number/ordinal/"last" (optionally with
    light punctuation) is unambiguous regardless of what an LLM would
    decide -- confirmed live the router does not always reliably set
    positionalRef for a bare number, so this never depends on model
    behavior in the first place."""
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
    """A clicked recommended-action button's value is the candidate's own
    meaningful id (e.g. "upcoming_payment") -- a direct, exact,
    order-independent id match resolves it without any language
    understanding. Returns (resolved_fields_dict, matched)."""
    text = (user_message or "").strip().lower()
    if not text:
        return {}, False
    for candidate in (payment_candidates if isinstance(payment_candidates, list) else []):
        if isinstance(candidate, dict) and str(candidate.get("id") or "").strip().lower() == text:
            return {
                "action": candidate.get("action") or "PAYMENT",
                "subFilter": candidate.get("subFilter"),
                "servicePeriodId": candidate.get("id"),
            }, True
    for item in (recommended_actions if isinstance(recommended_actions, list) else []):
        if isinstance(item, dict) and str(item.get("id") or "").strip().lower() == text:
            return {
                "action": item.get("action"),
                "subFilter": item.get("subFilter"),
                "servicePeriodId": None,
            }, True
    return {}, False


def _resolve_positional(ref, recommended_actions, payment_candidates):
    """Walks a detected positional reference against the actual structured
    list. Returns (resolved_fields_dict, ok) -- ok=False means no list to
    resolve against, or the index is out of range."""
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
        }, True

    if isinstance(recommended_actions, list) and recommended_actions:
        if idx >= len(recommended_actions):
            return {}, False
        item = recommended_actions[idx]
        if not isinstance(item, dict):
            return {}, False
        # A recommendedActions item's "id" is the recommendation's own label
        # (e.g. "view_full_breakdown"), never a real service period ID.
        return {
            "action": item.get("action"),
            "subFilter": item.get("subFilter"),
            "servicePeriodId": None,
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
    })
    log(f"action shortcut: matched action={_resolved.get('action')} subFilter={_resolved.get('subFilter')} -- skipping LLM router")
    respond({"matched": "YES"}, confidence=1.0)
else:
    write_context("shortcutResolution", {"matched": "NO"})
    log("action shortcut: no match -- routing to LLM router")
    respond({"matched": "NO"}, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________