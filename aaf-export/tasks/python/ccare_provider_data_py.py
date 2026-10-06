"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________
Validates provider identity and writes provider context.
Runtime affordances: read_context, write_context, respond().
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

# Legacy router classification used for this check.
intent = turn_request.get("intent", "")

resolved_filters = {"dateFilter": turn_request.get("dateFilter") or "THIS_MONTH"}
if turn_request.get("dateFrom"):
    resolved_filters["dateFrom"] = turn_request["dateFrom"]
if turn_request.get("dateTo"):
    resolved_filters["dateTo"] = turn_request["dateTo"]
fetch_params = turn_request.get("fetchParams") or {}
if isinstance(fetch_params, dict) and fetch_params.get("periodCount"):
    resolved_filters["periodCount"] = fetch_params["periodCount"]

# Include surrounding agreement and rate data for last payout.
if (turn_request.get("action") == "PAYMENT" and
        turn_request.get("subFilter") == "LAST_PAYOUT"):
    resolved_filters = {"dateFilter": "LAST_N_MONTHS", "periodCount": 2}

# Use authenticated session identity; fail closed if missing.
user_id = _safe_get("external_id")

if not user_id:
    log("provider validation failed: missing external_id in session context")
    write_context("sessionState", {"providerVerified": "NO"})
    respond({"status": "failed", "reason": "IDENTITY_MISSING"}, confidence=1.0)
    _skip_rest = True
else:
    _skip_rest = False

if not _skip_rest:
    params = {"userId": user_id}
    params.update({k: v for k, v in resolved_filters.items() if v is not None})
    if "dateFilter" not in params:
        params["dateFilter"] = "THIS_MONTH"

    log("calling getProviderInfo userId=%s filters=%s" % (user_id, {k: v for k, v in params.items() if k != "userId"}))
    _connection_failed = False
    _validation_failed = False
    try:
        response = call_endpoint("getProviderInfo", params)
    except RuntimeError as _exc:
        _msg = str(_exc)
        if "401" in _msg or "INVALID_SESSION_ID" in _msg or "Session expired" in _msg:
            log("connection error calling getProviderInfo: %s" % _msg)
            write_context("sessionState", {"providerVerified": "NO"})
            write_context("ccare_provider_data_py", {"status": "failed", "reason": "CONNECTION_FAILED"})
            _tr_end = dict(turn_request)
            _tr_end["action"] = "END"
            write_context("turnRequest", _tr_end)
            respond({"status": "failed", "reason": "CONNECTION_FAILED"}, confidence=1.0)
            _connection_failed = True
        else:
            raise

    if not _connection_failed:
        if not response or not response.get("isSuccess"):
            reason = "getProviderInfo call failed"
            if isinstance(response, dict):
                reason = response.get("message") or response.get("error") or reason
            log("provider validation failed: %s" % reason)
            # Clear stale trust after failed re-check.
            write_context("sessionState", {"providerVerified": "NO"})
            _validation_failed = True
            respond({"status": "failed", "reason": reason}, confidence=1.0)
        elif not _validation_failed:
            provider_data = response.get("data") or {}
            provider_name = provider_data.get("ProviderName")
            conversation_state = {
                "providerVerified": True,
                "providerName": provider_name,
                "turnRequest": turn_request,
                "resolvedFilters": resolved_filters,
            }
            # Persist validation state and reset the revalidation counter.
            write_context("sessionState", {"providerVerified": "YES", "providerName": provider_name, "validatedTurnCount": 0})
            log("provider validated: providerName=%s intent=%s" % (provider_name, intent))
        if not _validation_failed and intent == "Unclear":
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
        elif not _validation_failed:
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