"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

attendance_risks_analyzer_py, v2.0.0. Analyzes absence-limit risk and
unconfirmed attendance directly from raw Salesforce fields -- no canonical-
mapping/guessing layer. Uses the same confirmed schedule/authorization join
as ccare_payment_engine.py: schedule.CI_Authorization_Id__c -> authorization.Name,
child_id = authorization.IDN_CLIENT__c, county_id = authorization.CDE_COUNTY__c.

Child name: IDN_CLIENT__r.Name is selected by getAuthData and is used directly.
child_id remains as the fallback when the related record or Name is absent.

Runtime affordances: read_context, write_context, respond().
"""

from datetime import date

if "read_context" not in globals():
    def read_context(key):
        return None

if "write_context" not in globals():
    _WCTX: dict = {}

    def write_context(key, value):
        _WCTX[key] = value
        return value

if "respond" not in globals():

    def respond(payload):
        return payload

log = print

PARENT_PENDING = "PARENT_PENDING"


def _text(row, *keys):
    if not isinstance(row, dict):
        return None
    for key in keys:
        value = row.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return None


def _number(row, *keys, default=0):
    if not isinstance(row, dict):
        return default
    for key in keys:
        value = row.get(key)
        if value is None or value == "":
            continue
        try:
            return float(value)
        except (TypeError, ValueError):
            continue
    return default


def _date_key(value):
    text = str(value or "")[:10]
    try:
        date.fromisoformat(text)
        return text
    except ValueError:
        return None


def _days_from(reference_date, target_date):
    try:
        return (date.fromisoformat(reference_date) - date.fromisoformat(target_date)).days
    except (TypeError, ValueError):
        return None


def _normalize_tier(value):
    text = str(value or "1").strip().upper()
    if text == "EXEMPT PROVIDER":
        return "1"
    if text.startswith("LEVEL"):
        text = text.replace("LEVEL", "").strip()
        if text in {"1", "2", "3", "4", "5"}:
            mapped = int(text) + 1
            return str(mapped) if mapped <= 5 else "5"
    if text.startswith("TIER"):
        text = text.replace("TIER", "").strip()
    return text if text in {"1", "2", "3", "4", "5"} else "1"


def _tier_limit(rate_plan, tier):
    if not isinstance(rate_plan, dict):
        return 0
    key = "absenceDaysTier" + _normalize_tier(tier)
    try:
        return int(rate_plan.get(key) or 0)
    except (TypeError, ValueError):
        return 0


def _status_from_remaining(confirmed_remaining, potential_remaining, tentative_used, threshold):
    if confirmed_remaining < 0:
        return "OVER_LIMIT"
    if potential_remaining < 0:
        return "POTENTIAL_OVER_LIMIT"
    if tentative_used > 0 and potential_remaining <= threshold and confirmed_remaining > threshold:
        return "POTENTIAL_APPROACHING_LIMIT"
    return "APPROACHING_LIMIT"


def _as_list(value):
    if isinstance(value, list):
        return [item for item in value if isinstance(item, dict)]
    if isinstance(value, dict):
        for key in ("records", "items", "results", "data"):
            nested = value.get(key)
            if isinstance(nested, list):
                return [item for item in nested if isinstance(item, dict)]
    return []


def _attended_hours(schedule):
    """Same fallback ccare_payment_engine.py's _attended_hours uses."""
    direct = _number(schedule, "attended_hours", "Hours__c", "unit_hours", default=None)
    if direct is not None:
        return direct
    check_in = _number(schedule, "Check_In_Count__c", default=None)
    check_out = _number(schedule, "Check_Out_Count__c", default=None)
    if check_in is not None and check_out is not None and check_in > 0 and check_out >= check_in:
        return check_out - check_in
    return None


def _bundle():
    raw = read_context("raw_provider_data") or {}
    return {
        "providers": _as_list((raw.get("providerData") or {}).get("providers")),
        "county_rate_plans": _as_list((raw.get("countyData") or {}).get("countyRatePlans")),
        "authorizations": _as_list((raw.get("authData") or {}).get("authorizations")),
        "schedules": _as_list((raw.get("schedulesData") or {}).get("schedules")),
        "org_holidays": _as_list((raw.get("holidayData") or {}).get("holidayList")),
        "provider_closures": _as_list((raw.get("providerData") or {}).get("providerClosures")),
    }


def _is_provider_closure(closures, provider_id, county_id, schedule_date):
    """Same closure rule ccare_payment_engine.py uses -- checked before a
    zero-attendance day counts as an absence."""
    for closure in closures:
        if not isinstance(closure, dict):
            continue
        active_val = _text(closure, "IND_ACTIVE__c", "active")
        if not (active_val and active_val.lower() in {"true", "1", "yes", "y"}):
            continue
        closure_provider = _text(closure, "IDN_PROVIDER__c", "provider_id")
        closure_county = _text(closure, "CDE_COUNTY__c", "county_id")
        if provider_id and closure_provider and closure_provider != provider_id:
            continue
        if county_id and closure_county and closure_county != county_id:
            continue
        if _date_key(_text(closure, "DTE_BEGIN_CLOSURE__c", "closure_date")) == schedule_date:
            return True
    return False


def _months_of_age(dob_key, on_date_key):
    """Child's age in whole months on a given date -- enrollment-absence
    (<=36 months) carve-out, same rule ccare_payment_engine.py applies."""
    dob = _date_key(dob_key)
    on_date = on_date_key
    if not dob or not on_date:
        return None
    dob_d, on_d = date.fromisoformat(dob), date.fromisoformat(on_date)
    months = (on_d.year - dob_d.year) * 12 + (on_d.month - dob_d.month)
    if on_d.day < dob_d.day:
        months -= 1
    return max(months, 0)


bundle = _bundle()
providers = bundle["providers"]
rate_plans = bundle["county_rate_plans"]
authorizations = bundle["authorizations"]
schedules = bundle["schedules"]
org_holiday_records = bundle["org_holidays"]
provider_closures = bundle["provider_closures"]

input_errors = []
if not providers:
    input_errors.append("provider record is missing")
if not rate_plans:
    input_errors.append("county rate plans are missing")
if not schedules:
    input_errors.append("schedules must be a non-empty array")

provider_id = _text(providers[0], "Id", "id") if providers else None
provider_tier = _normalize_tier(_text(providers[0], "TXT_CHATS_RATING__c") if providers else None)
reference_date = date.today().isoformat()
lookback_days = 9
near_limit_threshold = 1

rate_plan_by_county = {}
for plan in rate_plans:
    county_id = _text(plan, "countyId", "county_id", "CDE_COUNTY__c")
    if county_id:
        rate_plan_by_county[county_id] = plan

# Phase 3 filter-leak fix: read scope filters before the aggregation loop so
# an out-of-scope child/county is skipped at the source, not after grouping.
turn_request = read_context("turnRequest") or {}
child_filter = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
county_filter = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}

# Confirmed join (same as ccare_payment_engine.py):
# schedule.CI_Authorization_Id__c -> authorization.Name.
auth_by_name = {}
auth_by_id = {}
for auth in authorizations:
    name = _text(auth, "Name")
    if name:
        auth_by_name[name] = auth
    aid = _text(auth, "Id", "id")
    if aid:
        auth_by_id[aid] = auth

org_holidays = {_date_key(_text(h, "DTE_HOL__c", "DTE_OBSERVED_HOL__c")) for h in org_holiday_records}
org_holidays.discard(None)

write_context("input.provider_id", provider_id)
write_context("input.schedules_count", len(schedules))

absence_groups = {}
pending_confirmation_records = []

for schedule in schedules:
    schedule_id = _text(schedule, "Id", "id")
    schedule_date = _date_key(_text(schedule, "CI_Authorization_Date__c"))
    if not schedule_id or not schedule_date:
        continue

    auth_ref = _text(schedule, "CI_Authorization_Id__c")
    auth = auth_by_name.get(auth_ref, {}) if auth_ref else {}
    if not auth and auth_ref:
        auth = auth_by_id.get(auth_ref, {})
    auth_sfid = _text(auth, "Id", "id") if auth else None
    child_id = _text(auth, "IDN_CLIENT__c")
    child_name = _text(auth.get("IDN_CLIENT__r") if isinstance(auth, dict) else None, "NAM_FIRST__c") or child_id
    county_id = _text(auth, "CDE_COUNTY__c")
    linked_provider_id = _text(auth, "IDN_PROVR__c") or provider_id
    tier = provider_tier

    # Phase 3 filter-leak fix: skip out-of-scope schedules before any
    # aggregation/grouping, not just at the very end on the finished lists.
    if child_filter and (child_name or "").strip().lower() not in child_filter:
        continue
    county_name_for_filter = _text(rate_plan_by_county.get(county_id, {}), "countyName", "county_name") if county_id else None
    if county_filter and (county_name_for_filter or "").strip().lower() not in county_filter:
        continue

    # 2026-09-26 (confirmed, was previously guessed): Status__c does not
    # exist as a top-level Schedule__c field -- it lives on the child
    # Attendance__r.records[] (Transaction__c rows). Same fix applied in
    # ccare_payment_engine.py's confirmation-risk check.
    attendance_records = (schedule.get("Attendance__r") or {}).get("records") or []
    is_pending = any(
        _text(r, "Status__c") == PARENT_PENDING for r in attendance_records if isinstance(r, dict)
    )
    if is_pending:
        # Phase 6: carry county_name (not just county_id) so a county-name
        # filter downstream doesn't silently drop in-scope pending rows.
        pending_confirmation_records.append({
            "schedule_id": schedule_id,
            "auth_id": auth_ref,
            "child_id": child_id,
            "child_name": child_name,
            "county_name": _text(rate_plan_by_county.get(county_id, {}), "countyName", "county_name") if county_id else None,
            "provider_id": linked_provider_id,
            "county_id": county_id,
            "date": schedule_date,
            "status": PARENT_PENDING,
        })
        continue  # PARENT_PENDING: excluded from absence counting

    authorized_hours = _number(schedule, "CI_Authorization_Hours__c")
    attended_hours = _attended_hours(schedule) or 0

    if authorized_hours <= 0 or attended_hours != 0:
        continue
    if not child_id or not county_id or not linked_provider_id:
        continue
    if schedule_date in org_holidays:
        continue
    if _is_provider_closure(provider_closures, linked_provider_id, county_id, schedule_date):
        continue

    # Future scheduled dates are not absences yet.
    if schedule_date > reference_date:
        continue

    # Enrollment-absence carve-out: <=36 months old on this date is exempt
    # from the county absence limit, so it should not count toward the
    # near-limit alert either.
    client = auth.get("IDN_CLIENT__r") if isinstance(auth, dict) else None
    child_dob = _text(client, "DTE_DOB__c") if isinstance(client, dict) else None
    age_months = _months_of_age(child_dob, schedule_date)
    if age_months is not None and age_months <= 36:
        continue

    days_ago = _days_from(reference_date, schedule_date)
    is_tentative_absence = days_ago is not None and 0 <= days_ago <= lookback_days and not is_pending

    year_month = schedule_date[:7]
    key = ((auth_ref + "|" + year_month) if auth_ref else (child_id + "|" + county_id + "|" + year_month))
    if key not in absence_groups:
        absence_groups[key] = {
            "child_id": child_id,
            "child_name": child_name,
            "authorization_id": auth_ref or auth_sfid,
            "provider_id": linked_provider_id,
            "county_id": county_id,
            "quality_tier": tier,
            "year_month": year_month,
            "confirmed_absence_dates": [],
            "probable_absence_dates": [],
        }
    target = "probable_absence_dates" if is_tentative_absence else "confirmed_absence_dates"
    if schedule_date not in absence_groups[key][target]:
        absence_groups[key][target].append(schedule_date)

approaching_absence_limits = []
for group in absence_groups.values():
    limit = _tier_limit(rate_plan_by_county.get(group["county_id"]), group["quality_tier"])
    confirmed_used = len(group["confirmed_absence_dates"])
    tentative_used = len(group["probable_absence_dates"])
    confirmed_remaining = limit - confirmed_used
    potential_remaining = limit - confirmed_used - tentative_used
    if limit > 0 and (confirmed_remaining <= near_limit_threshold or potential_remaining <= near_limit_threshold):
        approaching_absence_limits.append({
            "child_id": group["child_id"],
            "child_name": group["child_name"],
            "authorization_id": group["authorization_id"],
            "provider_id": group["provider_id"],
            "county_id": group["county_id"],
            "county_name": _text(rate_plan_by_county.get(group["county_id"], {}), "countyName", "county_name"),
            "quality_tier": group["quality_tier"],
            "absence_limit": limit,
            "confirmed_absence_count": confirmed_used,
            "probable_absence_count": tentative_used,
            # Phase 6: preserve the signed value -- clamping to zero hid how
            # far over the limit a child actually was (exact-limit and
            # exceeded-by-N looked identical to a consumer reading this field).
            "confirmed_absence_remaining": confirmed_remaining,
            "potential_absence_remaining": potential_remaining,
            "status": _status_from_remaining(confirmed_remaining, potential_remaining, tentative_used, near_limit_threshold),
            "year_month": group["year_month"],
            "confirmed_absence_dates": sorted(group["confirmed_absence_dates"]),
            "probable_absence_dates": sorted(group["probable_absence_dates"]),
        })

turn_request = read_context("turnRequest") or {}
child_filter = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
county_filter = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}


def _passes(row):
    if child_filter and str(row.get("child_name") or "").strip().lower() not in child_filter:
        return False
    if county_filter and str(row.get("county_name") or "").strip().lower() not in county_filter:
        return False
    return True


if child_filter or county_filter:
    approaching_absence_limits = [r for r in approaching_absence_limits if _passes(r)]
    pending_confirmation_records = [r for r in pending_confirmation_records if _passes(r)]

result = {
    "provider_id": provider_id,
    "reference_date": reference_date,
    "approaching_absence_limits": sorted(approaching_absence_limits, key=lambda r: (r["county_id"] or "", r["child_id"] or "")),
    "pending_confirmation_records": sorted(pending_confirmation_records, key=lambda r: (r["date"], r.get("child_id") or "")),
    "lookback_days": lookback_days,
}

if input_errors:
    error_response = {"status": "FAILED_BAD_INPUT", "error": "; ".join(input_errors), "provider_id": provider_id}
    write_context("result.error", error_response)
    respond(error_response)
else:
    # Phase 0 caching: scope fingerprint so a same-scope subFilter switch
    # (e.g. ABSENCE_LIMITS -> INCOMPLETE_ATTENDANCE) can skip recalculation.
    result["scopeFingerprint"] = {
        "child_filter": sorted(child_filter),
        "county_filter": sorted(county_filter),
        "as_of_date": reference_date,
        "dataSnapshotVersion": read_context("dataManifest.fetchedAtEpoch"),
    }
    write_context("result.approaching_absence_limits", result["approaching_absence_limits"])
    write_context("result.pending_confirmation_records", result["pending_confirmation_records"])
    write_context("result.scopeFingerprint", result["scopeFingerprint"])
    respond(result)

# __________________________GenAI: Generated code ends here______________________________