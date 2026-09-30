"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_scope_cache_gate_py, v1.0.0. Single shared Phase 0 cache-validity check
for both PAYMENT and ATTENDANCE -- one normalization pass over turnRequest/
dataSnapshotVersion so the two domains can never disagree about "has scope
changed" (they read the same shared context, so they must use the same
comparison). Writes both paymentCacheValid and attendanceCacheValid; the
downstream decision gates just branch on whichever flag their action needs.

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


def _normalized(names):
    return sorted({str(n).strip().lower() for n in (names or []) if n})


def _cache_check(fingerprint, current_child_filter, current_county_filter, current_snapshot_version, current_service_period_id=None):
    if not isinstance(fingerprint, dict):
        return "NO", "no_cached_result"
    same_scope = (
        _normalized(fingerprint.get("child_filter")) == current_child_filter
        and _normalized(fingerprint.get("county_filter")) == current_county_filter
        and fingerprint.get("dataSnapshotVersion") == current_snapshot_version
    )
    period_ok = (
        not current_service_period_id
        or str(current_service_period_id) in (fingerprint.get("resolved_service_period_ids") or [])
    )
    if same_scope and period_ok:
        return "YES", "scope_unchanged"
    return "NO", "scope_changed"


_turn_request = read_context("turnRequest") or {}
if not isinstance(_turn_request, dict):
    _turn_request = {}

_child_filter = _normalized(_turn_request.get("childNames"))
_county_filter = _normalized(_turn_request.get("countyNames"))
_snapshot_version = read_context("dataManifest.fetchedAtEpoch")
_service_period_id = _turn_request.get("servicePeriodId")

_payment_result = read_context("paymentResult") or {}
_payment_valid, _payment_reason = _cache_check(
    _payment_result.get("scopeFingerprint") if isinstance(_payment_result, dict) else None,
    _child_filter, _county_filter, _snapshot_version, _service_period_id,
)

_analyzer_result = read_context("attendance_risks_analyzer_py") or read_context("result") or {}
_attendance_valid, _attendance_reason = _cache_check(
    _analyzer_result.get("scopeFingerprint") if isinstance(_analyzer_result, dict) else None,
    _child_filter, _county_filter, _snapshot_version,
)

write_context("turnRequest", dict(_turn_request, paymentCacheValid=_payment_valid, attendanceCacheValid=_attendance_valid))
log(f"scope cache gate: payment={_payment_valid} ({_payment_reason}) attendance={_attendance_valid} ({_attendance_reason})")
respond({"paymentCacheValid": _payment_valid, "attendanceCacheValid": _attendance_valid}, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________