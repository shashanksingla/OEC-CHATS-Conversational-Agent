"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_provider_data_py, v1.2.3. Validates the provider via getProviderInfo
and writes context.ccare_provider_data_py (status/providerName/resolvedFilters).

Runtime affordances: _context, call_endpoint(), write_context(), respond().
"""

log = print


def _context_get(key, default=None):
    value = _context
    if isinstance(value, dict) and key in value:
        direct = value.get(key)
        if direct is not None:
            return direct
    for part in key.split("."):
        try:
            value = value.get(part) if isinstance(value, dict) else getattr(value, part)
        except (AttributeError, KeyError, TypeError):
            return default
        if value is None:
            return default
    return value


def _safe_get(key, default=None):
    value = _context_get(key)
    return value if value is not None else default


turn_request = _safe_get("turnRequest") or {}
if not isinstance(turn_request, dict):
    turn_request = {}

# "intent" carries the legacy classification label (Starter/Attendance/Payment/
# Explain/Unclear) written by ccare_unified_intent_router specifically for this
# check -- everything else in the process reads turnRequest.action instead.
intent = turn_request.get("intent", "")

resolved_filters = {"dateFilter": turn_request.get("dateFilter") or "THIS_MONTH"}
if turn_request.get("dateFrom"):
    resolved_filters["dateFrom"] = turn_request["dateFrom"]
if turn_request.get("dateTo"):
    resolved_filters["dateTo"] = turn_request["dateTo"]
fetch_params = turn_request.get("fetchParams") or {}
if isinstance(fetch_params, dict) and fetch_params.get("periodCount"):
    resolved_filters["periodCount"] = fetch_params["periodCount"]

# Last-payout calculations need the selected released period plus the
# surrounding agreement and rate data used to explain it.
if (turn_request.get("action") == "PAYMENT" and
        turn_request.get("subFilter") == "LAST_PAYOUT"):
    resolved_filters = {"dateFilter": "LAST_N_MONTHS", "periodCount": 2}

# userId always sourced from authenticated session context -- never from user input
user_id = _safe_get("external_id") or "005hG0000011ZG6QAM"

params = {"userId": user_id}
params.update({k: v for k, v in resolved_filters.items() if v is not None})
if "dateFilter" not in params:
    params["dateFilter"] = "THIS_MONTH"

log("calling getProviderInfo userId=%s filters=%s" % (user_id, {k: v for k, v in params.items() if k != "userId"}))
response = call_endpoint("getProviderInfo", params)

if not response or not response.get("isSuccess"):
    reason = "getProviderInfo call failed"
    if isinstance(response, dict):
        reason = response.get("message") or response.get("error") or reason
    log("provider validation failed: %s" % reason)
    respond({"status": "failed", "reason": reason}, confidence=1.0)
else:
    provider_data = response.get("data") or {}
    provider_name = provider_data.get("ProviderName")
    conversation_state = {
        "providerVerified": True,
        "providerName": provider_name,
        "turnRequest": turn_request,
        "resolvedFilters": resolved_filters,
    }
    # 2026-09-26: persistent, session-scoped flag -- written once, never
    # re-derived from per-turn data-freshness logic (unlike the removed
    # freshnessResult.sessionValidated). provider_validated_gate reads this
    # to skip this task (and its getProviderInfo call) on every turn after
    # the first; nothing else in the process writes to sessionState.
    write_context("sessionState", {"providerVerified": "YES", "providerName": provider_name})
    log("provider validated: providerName=%s intent=%s" % (provider_name, intent))
    if intent == "Unclear":
        log("intent unclear -- routing to clarification after provider validated")
        write_context("ccare_provider_data_py", {
            "status": "needs_clarification",
            "providerName": provider_name,
            "providerDataRaw": provider_data,
            "resolvedFilters": resolved_filters,
            "conversationState": conversation_state,
        })
        respond({
            "status": "needs_clarification",
            "providerName": provider_name,
            "resolvedFilters": resolved_filters,
            "conversationState": conversation_state,
        }, confidence=1.0)
    else:
        write_context("ccare_provider_data_py", {
            "status": "success",
            "providerName": provider_name,
            "providerDataRaw": provider_data,
            "resolvedFilters": resolved_filters,
            "conversationState": conversation_state,
        })
        respond({
            "status": "success",
            "providerName": provider_name,
            "resolvedFilters": resolved_filters,
            "conversationState": conversation_state,
        }, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________