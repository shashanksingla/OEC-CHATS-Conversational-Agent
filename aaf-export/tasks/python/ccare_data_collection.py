"""_______________Scoping/caching fixes by ai-firstify audit pass_______________

Fetches provider source data in parallel and builds the provider snapshot.
Runtime affordances: _context, call_endpoint(), write_context(), respond().

AUDIT FIXES (each was a way a view could be silently skipped or wrong):
  1. Any PAYMENT turn fetches payment sources (previously only listed
     subFilters did -- a period picked from the disambiguation list has
     subFilter=None and got zero payment data).
  2. Authorizations are never narrowed by child name here (the real
     getAuthData payload has no child name on IDN_CLIENT__r, so narrowing
     dropped everything). Child/county scoping is applied downstream on the
     computed ledger, so cached raw data is always complete.
  3. getProviderInfo is date-windowed; if the requested window isn't covered
     by the bundle already in context, it's re-fetched for that window.
  4. CURRENT_MONTH / ALL / SPECIFIC_PERIOD fetch schedules across the full
     span of the periods involved (periods straddle month edges), and ALL
     fetches periods for previous+current month (was previous month only).
  5. EXPLAIN reuses fresh data instead of refetching.
  6. Engine result-cache validity requires EXACT filter equality (a cached
     unfiltered result must not be shown for a scoped question) and does not
     key attendance results on subFilter.
"""

import json
import time
from datetime import date, timedelta
from concurrent.futures import ThreadPoolExecutor

log = print


def _respond_failure(reason):
    respond({"status": "DATA_COLLECTION_FAILED", "reason": reason}, confidence=1.0)


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


def _as_object(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
        except (TypeError, ValueError):
            return None
        return parsed if isinstance(parsed, dict) else None
    return None


def _provider_bundle(value):
    value = _as_object(value)
    if value is None:
        return None, None
    nested = _as_object(value.get("providerDataRaw"))
    if nested is not None:
        return nested, value.get("resolvedFilters")
    return value, None


def _project_providers(providers, agreements):
    result = []
    provider_records = providers if isinstance(providers, list) else []
    agreement_records = agreements if isinstance(agreements, list) else []
    for provider in provider_records:
        if not isinstance(provider, dict):
            continue
        provider_id = provider.get("Id")
        agreement = next(
            (item for item in agreement_records
             if isinstance(item, dict) and item.get("ID_SERVICE__c") == provider_id),
            {},
        )
        rate_schedules = agreement.get("Rate_Schedules__r", {}).get("records", [])
        rating = rate_schedules[0].get("TXT_CHATS_RATING__c", "") if rate_schedules else ""
        result.append({
            "Id": provider_id,
            "Name": provider.get("Name"),
            "NAM_FACILITY__c": provider.get("NAM_FACILITY__c", ""),
            "CDE_STATUS_PROVR__c": provider.get("CDE_STATUS_PROVR__c", ""),
            "TXT_CHATS_RATING__c": provider.get("TXT_CHATS_RATING__c") or rating,
        })
    return [item for item in result if item.get("Id")]


def _unique_values(records, field):
    values = []
    for record in records if isinstance(records, list) else []:
        value = record.get(field) if isinstance(record, dict) else None
        if value and value not in values:
            values.append(value)
    return values


def _record_value(record, *paths):
    for path in paths:
        value = record
        for part in path.split("."):
            if not isinstance(value, dict):
                value = None
                break
            value = value.get(part)
        if value is not None and value != "":
            return value
    return None


def _record_list(value):
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        for key in ("records", "items", "results", "value"):
            if isinstance(value.get(key), list):
                return value[key]
    return []


def _extract_fiscal_schedule_ids(agreements):
    ids = []
    for agreement in agreements if isinstance(agreements, list) else []:
        if not isinstance(agreement, dict):
            continue
        for schedule in _record_list(agreement.get("Rate_Schedules__r")):
            value = _record_value(schedule, "IDN_EXTNL__c", "Id", "id")
            if value is not None and str(value) not in ids:
                ids.append(str(value))
    return ids


def _month_bounds(base, months_back=0):
    year, month = base.year, base.month
    for _ in range(months_back):
        month -= 1
        if month < 1:
            month = 12
            year -= 1
    first = date(year, month, 1)
    last = date(year + 1, 1, 1) - timedelta(days=1) if month == 12 else date(year, month + 1, 1) - timedelta(days=1)
    return first, last


def _date_range_params(start, end):
    if start is None or end is None:
        return {"dateFilter": "THIS_MONTH"}
    return {"dateFilter": "DATE_RANGE", "dateFrom": start.isoformat(), "dateTo": end.isoformat()}


def _period_date(period, *keys):
    value = _record_value(period, *keys)
    if value is None:
        return None
    try:
        return date.fromisoformat(str(value)[:10])
    except (TypeError, ValueError):
        return None


def _period_bounds(periods):
    bounds = [
        (_period_date(p, "serviceBeginDate", "DTE_BEGIN_EFFV__c", "Start_Date__c"),
         _period_date(p, "serviceEndDate", "DTE_END_EFFV__c", "End_Date__c"))
        for p in periods if isinstance(p, dict)
    ]
    bounds = [(s, e) for s, e in bounds if s is not None and e is not None]
    if not bounds:
        return None, None
    return min(s for s, _ in bounds), max(e for _, e in bounds)


def _full_months_params(periods):
    """Full calendar months spanning the periods -- absence limits are monthly
    and periods straddle month edges, so partial months undercount."""
    start, end = _period_bounds(periods)
    if start is None or end is None:
        return None
    month_start, _ = _month_bounds(start)
    _, month_end = _month_bounds(end)
    return _date_range_params(month_start, month_end)


def _service_period_support_params(sub_filter, turn_request, initial_params, periods):
    periods = periods if isinstance(periods, list) else []
    selected_id = turn_request.get("servicePeriodId") if isinstance(turn_request, dict) else None
    selected = periods
    if selected_id:
        matching = [p for p in periods if str(_record_value(p, "servicePeriodId", "IDN_EXTNL__c", "id")) == str(selected_id)]
        if matching:
            selected = matching

    if sub_filter in ("LAST_PAYOUT", "NEXT_PAYOUT", "CURRENT_PERIOD_FORECAST", "FULL_BREAKDOWN") and selected:
        params = _full_months_params(selected[:1])
        if params:
            return params
    # A service period picked from the disambiguation list arrives with no
    # subFilter -- scope to that period's months too.
    if selected_id and sub_filter is None and selected:
        params = _full_months_params(selected[:1])
        if params:
            return params
    # Multi-period / explicit-period views: cover EVERY period involved.
    # "ALL" is shared by ATTENDANCE and PAYMENT -- only PAYMENT spans periods.
    is_payment = isinstance(turn_request, dict) and turn_request.get("action") == "PAYMENT"
    if sub_filter in ("SPECIFIC_PERIOD", "CURRENT_MONTH", "ALL") and periods and (is_payment or sub_filter != "ALL"):
        params = _full_months_params(periods)
        if params:
            return params
    return initial_params


def _source_date_params(resolved_filters):
    if not isinstance(resolved_filters, dict):
        return {"dateFilter": "THIS_MONTH"}
    date_filter = resolved_filters.get("dateFilter", "THIS_MONTH")
    if date_filter in ("THIS_WEEK", "LAST_WEEK", "NEXT_WEEK", "TODAY"):
        date_filter = "THIS_MONTH"
    if date_filter == "THIS_MONTH":
        first, last = _month_bounds(date.today())
        return _date_range_params(first, last)
    params = {"dateFilter": date_filter}
    if date_filter == "DATE_RANGE":
        if resolved_filters.get("dateFrom"):
            params["dateFrom"] = resolved_filters["dateFrom"]
        if resolved_filters.get("dateTo"):
            params["dateTo"] = resolved_filters["dateTo"]
    elif date_filter in ("LAST_N_MONTHS", "LAST_N_DAYS") and resolved_filters.get("periodCount"):
        params["periodCount"] = resolved_filters["periodCount"]
    return params


def _payment_date_params(sub_filter, turn_request, resolved_filters):
    fetch_params = turn_request.get("fetchParams") if isinstance(turn_request, dict) else {}
    fetch_params = fetch_params if isinstance(fetch_params, dict) else {}
    today = date.today()
    if sub_filter == "LAST_PAYOUT":
        return {"dateFilter": "LAST_N_MONTHS", "periodCount": 2}
    if sub_filter == "CURRENT_PERIOD_FORECAST":
        return {"dateFilter": "TODAY"}
    if sub_filter == "CURRENT_MONTH":
        return _date_range_params(*_month_bounds(today))
    if sub_filter == "ALL":
        first, _ = _month_bounds(today, 1)
        _, last = _month_bounds(today)
        return {"dateFilter": "DATE_RANGE", "dateFrom": (first - timedelta(days=7)).isoformat(), "dateTo": (last + timedelta(days=7)).isoformat()}
    if sub_filter == "SPECIFIC_PERIOD" and fetch_params.get("dateFrom") and fetch_params.get("dateTo"):
        return {"dateFilter": "DATE_RANGE", "dateFrom": fetch_params["dateFrom"], "dateTo": fetch_params["dateTo"]}
    return _source_date_params(resolved_filters)


def _service_period_params(sub_filter, turn_request, resolved_filters):
    fetch_params = turn_request.get("fetchParams") if isinstance(turn_request, dict) else {}
    fetch_params = fetch_params if isinstance(fetch_params, dict) else {}
    today = date.today()
    if sub_filter == "NEXT_PAYOUT":
        return {"paymentAfter": "TODAY", "limitOne": True}
    if sub_filter == "CURRENT_PERIOD_FORECAST":
        return {"dateOn": "TODAY", "limitOne": True}
    if sub_filter == "LAST_PAYOUT":
        return {"paymentBefore": "TODAY", "limitOne": True}
    if sub_filter is None and isinstance(turn_request, dict) and turn_request.get("servicePeriodId"):
        # Child/county drill-down on a specific period (subFilter omitted by the button).
        # Cover last month + this month so the target period resolves whether its
        # payout date is upcoming or already released.
        first, _ = _month_bounds(today, 1)
        _, last = _month_bounds(today)
        return _date_range_params(first, last)
    if sub_filter == "FULL_BREAKDOWN":
        # Drill-down onto a specific servicePeriodId. Cover last month + this month
        # so the target period resolves whether its payout date is upcoming (next
        # payout) or already released (last payout).
        first, _ = _month_bounds(today, 1)
        _, last = _month_bounds(today)
        return _date_range_params(first, last)
    if sub_filter == "CURRENT_MONTH":
        return _date_range_params(*_month_bounds(today))
    if sub_filter == "ALL" and isinstance(turn_request, dict) and turn_request.get("action") == "PAYMENT":
        # previous + current month (was previous month only)
        return _date_range_params(_month_bounds(today, 1)[0], _month_bounds(today)[1])
    if sub_filter == "SPECIFIC_PERIOD" and fetch_params.get("dateFrom") and fetch_params.get("dateTo"):
        return {"dateFilter": "DATE_RANGE", "dateFrom": fetch_params["dateFrom"], "dateTo": fetch_params["dateTo"]}
    return _source_date_params(resolved_filters)


def _first_available(*keys):
    for key in keys:
        value = _safe_get(key)
        if value is not None:
            return value
    return None


def _first_available_entry(*keys):
    for key in keys:
        value = _safe_get(key)
        if value is not None:
            return key, value
    return None, None


def _number_value(value):
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _child_id(record):
    value = _record_value(record, "child_id", "childId", "ChildId", "ContactId", "ContactId__c", "IDN_CLIENT__c",
                          "CI_Client_Id__c", "clientId", "Contact_Name__c", "child_name")
    return str(value) if value is not None else None


def _child_name(record):
    value = _record_value(record, "child_name", "childName", "ChildName", "Contact_Name__c", "Contact.Name", "IDN_CLIENT__r.Name")
    return str(value) if value is not None else None


def _schedule_date(record):
    value = _record_value(record, "date", "service_date", "ServiceDate", "Service_Date__c", "Schedule_Date__c", "CI_Authorization_Date__c")
    return str(value)[:10] if value is not None else None


def _is_checked_in(record):
    attended = _record_value(record, "attended", "isAttended")
    if isinstance(attended, bool):
        return attended
    if isinstance(attended, str) and attended.strip().lower() in ("true", "yes", "1"):
        return True
    number = _number_value(_record_value(record, "Check_In_Count__c", "check_in_count", "checkInCount"))
    return number is not None and number > 0


def _is_pending(record):
    status = _record_value(record, "Status__c", "status", "Status", "parent_confirmation")
    return str(status or "").strip().upper() in ("PARENT_PENDING", "PENDING", "PENDING_PROVIDER")


def _build_snapshot(providers, resolved_filters, county_data, holiday_data, authorizations, schedules):
    """Lightweight dashboard snapshot. Risk categories (pending / absence /
    incomplete) are filled in by the calc engine from its ledger -- the
    schedule-level counts here are only the pre-engine baseline."""
    today = date.today().isoformat()
    confirmation_window_days = 9
    provider_record = providers[0] if providers else {}
    children, today_children, today_checked = {}, {}, {}
    pending_days, pending_children, incomplete_days, incomplete_children = {}, {}, {}, {}
    pending_rows, pending_hours, incomplete_hours = [], {}, {}

    def _hours(record):
        number = _number_value(_record_value(record, "authorized_hours", "authorizedHours", "CI_Authorization_Hours__c", "hours", "Hours__c"))
        return number if number is not None and number >= 0 else 0.0

    def _count(record, *paths):
        number = _number_value(_record_value(record, *paths))
        return int(number) if number is not None else 0

    for schedule in schedules if isinstance(schedules, list) else []:
        if not isinstance(schedule, dict):
            continue
        child_key = _child_id(schedule) or _child_name(schedule)
        schedule_date = _schedule_date(schedule)
        checked_in = _is_checked_in(schedule)
        hours = _hours(schedule)
        if child_key is not None:
            child = children.setdefault(child_key, {"child_name": _child_name(schedule), "scheduled_records": 0,
                                                     "checked_in_records": 0, "pending_confirmation_days": 0,
                                                     "incomplete_attendance_days": 0})
            child["scheduled_records"] += 1
            child["checked_in_records"] += 1 if checked_in else 0
            if schedule_date == today:
                today_children[child_key] = True
                if checked_in:
                    today_checked[child_key] = True

        transactions = _record_list(_record_value(schedule, "Attendance__r.records", "attendance.records", "transactions"))
        if _is_pending(schedule) or any(_is_pending(t) for t in transactions if isinstance(t, dict)):
            key = (child_key or "unknown", schedule_date or "unknown")
            if key not in pending_days:
                pending_days[key] = True
                pending_hours[key] = hours
                if child_key is not None:
                    pending_children[child_key] = True
                    if child_key in children:
                        children[child_key]["pending_confirmation_days"] += 1
                pending_rows.append({"child_name": _child_name(schedule),
                                     "authorization_id": _record_value(schedule, "CI_Authorization_Id__c", "authorization_id", "auth_id"),
                                     "service_date": schedule_date, "status": "PARENT_PENDING"})

        ci = _count(schedule, "Check_In_Count__c", "check_in_count", "checkInCount")
        co = _count(schedule, "Check_Out_Count__c", "check_out_count", "checkOutCount")
        if (ci > 0 and co == 0) or (co > 0 and ci == 0):
            key = (child_key or "unknown", schedule_date or "unknown")
            if key not in incomplete_days:
                incomplete_days[key] = True
                incomplete_hours[key] = hours
                if child_key is not None:
                    incomplete_children[child_key] = True
                    if child_key in children:
                        children[child_key]["incomplete_attendance_days"] += 1

    deadlines = []
    for row in pending_rows:
        try:
            deadlines.append((date.fromisoformat(row["service_date"]) + timedelta(days=confirmation_window_days)).isoformat())
        except (TypeError, ValueError):
            continue
    earliest = min(deadlines) if deadlines else None

    holiday_dates = []
    if isinstance(holiday_data, dict):
        for h in holiday_data.get("holidayList", []):
            if isinstance(h, dict):
                v = _record_value(h, "DTE_OBSERVED_HOL__c", "DTE_HOL__c", "date")
                if v is not None:
                    holiday_dates.append(str(v)[:10])

    scheduled_children, checked_children = len(today_children), len(today_checked)
    next_actions = []
    if pending_days:
        next_actions.append("Review pending confirmations - %d days" % len(pending_days))
    if incomplete_days:
        next_actions.append("Review incomplete attendance - %d days" % len(incomplete_days))
    return {
        "as_of_date": today,
        "confirmation_window_days": confirmation_window_days,
        "confirmation_cutoff_date": (date.today() - timedelta(days=confirmation_window_days)).isoformat(),
        "user_name": _first_available("ccare_provider_data_py.providerName", "providerName") or provider_record.get("Name"),
        "facility_name": provider_record.get("NAM_FACILITY__c"),
        "date_filter": resolved_filters.get("dateFilter") if isinstance(resolved_filters, dict) else None,
        "today": {"scheduled_children": scheduled_children, "checked_in_children": checked_children},
        "children_scheduled_count": scheduled_children,
        "checked_in_count": checked_children,
        "pending_confirmation_days": len(pending_days),
        "pending_confirmation_children_count": len(pending_children),
        "pending_confirmations": pending_rows,
        "absence_risk_children_count": 0,
        "absence_risks": [],
        "risk_categories": {
            "pending_parent_confirmations": {"days": len(pending_days), "children": len(pending_children),
                                              "potential_loss_hours": round(sum(pending_hours.values()), 2)},
            "approaching_absence_limits": {"children": 0, "counties": 0},
            "crossed_absence_limits": {"children": 0, "counties": 0, "potential_loss_hours": None},
            "incomplete_attendance": {"days": len(incomplete_days), "children": len(incomplete_children),
                                       "potential_loss_hours": round(sum(incomplete_hours.values()), 2)},
        },
        "payment_summary": {"status": "AVAILABLE_ON_REQUEST", "view": "NEXT_PAYOUT", "amount_status": "UNAVAILABLE",
                            "missing_sources": ["fiscal rates", "payment history"]},
        "children": list(children.values()),
        "earliest_confirmation_deadline": earliest,
        "earliest_confirmation_days_remaining": (date.fromisoformat(earliest) - date.today()).days if earliest else None,
        "holiday_dates": sorted(set(holiday_dates)),
        "next_actions": next_actions[:4],
        "source_counts": {
            "providers": len(providers) if isinstance(providers, list) else 0,
            "authorizations": len(authorizations) if isinstance(authorizations, list) else 0,
            "schedules": len(schedules) if isinstance(schedules, list) else 0,
            "county_rate_plans": len(county_data.get("countyRatePlans", [])) if isinstance(county_data, dict) else 0,
            "holidays": len(holiday_data.get("holidayList", [])) if isinstance(holiday_data, dict) else 0,
        },
    }


# ------------------------------------------------------------------------------
# Scope / cache helpers
# ------------------------------------------------------------------------------

def _materialize_bounds(resolved_f, df):
    if isinstance(resolved_f, dict) and resolved_f.get("dateFrom") and resolved_f.get("dateTo"):
        return resolved_f["dateFrom"], resolved_f["dateTo"]
    today = date.today()
    df = (df or "THIS_MONTH").upper()
    if df == "THIS_MONTH":
        first, last = _month_bounds(today)
        return first.isoformat(), last.isoformat()
    if df == "LAST_MONTH":
        first, last = _month_bounds(today, 1)
        return first.isoformat(), last.isoformat()
    return None, None


_COMMON_SOURCES = {"servicePeriods", "county", "holidays", "authorizations", "schedules"}
_PAYMENT_SOURCES = {"fiscalRates", "paymentHistory", "vacantSlots"}
_COMMON_CACHE_TTL_SECONDS = 300
_PAYMENT_CACHE_TTL_SECONDS = 900


def _manifest_sources(manifest):
    sources = manifest.get("sources", []) if isinstance(manifest, dict) else []
    return sources if isinstance(sources, list) else []


def _manifest_is_fresh(manifest, requires_payment_sources):
    if not isinstance(manifest, dict) or not manifest.get("fetchedAt"):
        return False
    fetched_epoch = manifest.get("fetchedAtEpoch")
    if fetched_epoch is None:
        return manifest.get("fetchedAt") == date.today().isoformat()
    try:
        ttl = _PAYMENT_CACHE_TTL_SECONDS if requires_payment_sources else _COMMON_CACHE_TTL_SECONDS
        return time.time() - float(fetched_epoch) <= ttl
    except (TypeError, ValueError):
        return False


def _scope_matches_manifest(manifest, source_params):
    if not isinstance(manifest, dict) or not isinstance(source_params, dict):
        return False
    return manifest.get("dateFrom") == source_params.get("dateFrom") and manifest.get("dateTo") == source_params.get("dateTo")


def _date_window_within_manifest(manifest, source_params):
    if not isinstance(manifest, dict):
        return False
    m_from, m_to = manifest.get("dateFrom"), manifest.get("dateTo")
    if not m_from or not m_to:
        return False
    c_from, c_to = _materialize_bounds(source_params, source_params.get("dateFilter") if isinstance(source_params, dict) else None)
    if not c_from or not c_to:
        return False
    return m_from <= c_from and c_to <= m_to


def _filters_covered(current_child, current_county, cached_child, cached_county):
    """Raw-DATA coverage: cached data fetched for a scope covers a narrower
    request (the engine re-applies child/county scoping on the ledger)."""
    def _covered(current, cached):
        if not cached:
            return True
        return bool(current) and current.issubset(cached)
    return _covered(current_child, cached_child) and _covered(current_county, cached_county)


def _drill_down_reuse(turn_request, manifest, payment_result, attendance_result, source_params):
    if not isinstance(manifest, dict) or not manifest.get("fetchedAtEpoch"):
        return False
    snapshot_version = manifest.get("fetchedAtEpoch")
    service_period_id = turn_request.get("servicePeriodId") if isinstance(turn_request, dict) else None
    current_sub_filter = turn_request.get("subFilter") if isinstance(turn_request, dict) else None

    if service_period_id:
        fp = payment_result.get("scopeFingerprint") if isinstance(payment_result, dict) else None
        if not isinstance(fp, dict) or fp.get("dataSnapshotVersion") != snapshot_version:
            return False
        if str(service_period_id) not in (fp.get("resolved_service_period_ids") or []):
            return False
        if fp.get("subFilter") != current_sub_filter:
            # Child/county drill-down (subFilter=None) on an already-resolved period:
            # the engine result already has the rows; formatter re-filters by child/county.
            # Skip the date-window check -- no new fetch is needed.
            if current_sub_filter is not None:
                return False
            return True
    else:
        fp = None
        for candidate in (payment_result, attendance_result):
            cfp = candidate.get("scopeFingerprint") if isinstance(candidate, dict) else None
            if isinstance(cfp, dict) and cfp.get("dataSnapshotVersion") == snapshot_version \
                    and cfp.get("subFilter") == current_sub_filter:
                fp = cfp
                break
        # Fallback for attendance child/county drill-downs: the engine computes all
        # attendance records in one pass; subFilter only selects the formatter view.
        # An unfiltered prior attendance result covers any scoped request.
        if fp is None and isinstance(turn_request, dict) and turn_request.get("action") == "ATTENDANCE":
            _child_req = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
            _county_req = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}
            if _child_req or _county_req:
                cfp = attendance_result.get("scopeFingerprint") if isinstance(attendance_result, dict) else None
                if (isinstance(cfp, dict)
                        and cfp.get("dataSnapshotVersion") == snapshot_version
                        and not (cfp.get("child_filter") or [])
                        and not (cfp.get("county_filter") or [])):
                    fp = cfp
        if fp is None:
            return False

    current_child = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
    current_county = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}
    if not _filters_covered(current_child, current_county, set(fp.get("child_filter") or []), set(fp.get("county_filter") or [])):
        return False
    return _date_window_within_manifest(manifest, source_params)


def _engine_cache_status(turn_request, manifest, payment_result, attendance_result):
    """Cache validity for COMPUTED RESULTS. Stricter than raw-data coverage:
    a result is only reusable when its child/county scope EQUALS the current
    one (a cached unfiltered result must never be shown for a scoped
    question, and vice versa -- the formatter doesn't re-filter)."""
    turn_request = turn_request if isinstance(turn_request, dict) else {}
    snapshot_version = manifest.get("fetchedAtEpoch") if isinstance(manifest, dict) else None
    current_child = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
    current_county = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}
    current_period = turn_request.get("servicePeriodId")
    current_sub_filter = turn_request.get("subFilter")

    def _valid(result, check_sub_filter):
        fp = result.get("scopeFingerprint") if isinstance(result, dict) else None
        if not isinstance(fp, dict) or fp.get("dataSnapshotVersion") != snapshot_version:
            return "NO"
        # Payment results depend on subFilter; the attendance scan does not.
        if check_sub_filter and fp.get("subFilter") != current_sub_filter:
            # Allow reuse for child/county drill-downs (subFilter=None) on a period
            # already computed. build_payment_child_detail filters rows itself via
            # _child_rows(), so re-running the engine is wasteful and error-prone.
            if current_sub_filter is not None:
                return "NO"
            if not current_period or str(current_period) not in (fp.get("resolved_service_period_ids") or []):
                return "NO"
        # A prior unfiltered result (empty fp_child/fp_county) covers any child/county
        # drill-down because the formatter re-filters via _child_rows()/_all_engine_rows().
        # A prior filtered result only covers the same or broader scope.
        fp_child = set(fp.get("child_filter") or [])
        fp_county = set(fp.get("county_filter") or [])
        if fp_child and not fp_child.issuperset(current_child):
            return "NO"
        if fp_county and not fp_county.issuperset(current_county):
            return "NO"
        if current_period and str(current_period) not in (fp.get("resolved_service_period_ids") or []):
            return "NO"
        return "YES"

    payment_valid = _valid(payment_result, True)
    attendance_valid = _valid(attendance_result, False)
    action = turn_request.get("action")
    sub_filter = turn_request.get("subFilter")
    if action == "PAYMENT":
        engine_valid = payment_valid
    elif action in ("ATTENDANCE", "STARTER"):
        engine_valid = "NO" if (sub_filter == "PAYOUT_IMPACT" or action == "STARTER") else attendance_valid
    else:
        engine_valid = "NO"
    return {"paymentCacheValid": payment_valid, "attendanceCacheValid": attendance_valid, "engineCacheValid": engine_valid}


def _provider_window_key(params):
    return json.dumps({k: params.get(k) for k in ("dateFilter", "dateFrom", "dateTo", "periodCount")}, sort_keys=True)


def _initial_provider_window():
    """Window of the provider bundle already in context, if we can tell."""
    stored = _safe_get("providerBundleWindow")
    if isinstance(stored, dict):
        return stored
    rf = _safe_get("ccare_provider_data_py.resolvedFilters")
    if isinstance(rf, dict):
        f, t = _materialize_bounds(rf, rf.get("dateFilter"))
        if f and t:
            return {"from": f, "to": t, "key": None}
    return None


def _provider_window_covers(need_params):
    have = _initial_provider_window()
    need_from, need_to = _materialize_bounds(need_params, need_params.get("dateFilter"))
    if need_from and need_to:
        return bool(have and have.get("from") and have.get("to") and have["from"] <= need_from and need_to <= have["to"])
    # Unknown-bounds filters (LAST_N_*): only reuse when fetched with the same params.
    return bool(have and have.get("key") == _provider_window_key(need_params))


def _main():
    raw_provider_path, raw_provider_data = _first_available_entry("ccare_provider_data_py.providerDataRaw", "providerDataRaw")
    provider_bundle, bundle_filters = _provider_bundle(raw_provider_data)

    _fetch_params = _as_object(_safe_get("turnRequest.fetchParams")) or {}
    _refresh_filters = None
    if _fetch_params:
        rf_filter, rf_from, rf_to = _fetch_params.get("dateFilter"), _fetch_params.get("dateFrom"), _fetch_params.get("dateTo")
        if rf_filter or rf_from:
            _refresh_filters = {"dateFilter": rf_filter or "DATE_RANGE"}
            if rf_from:
                _refresh_filters["dateFrom"] = rf_from
            if rf_to:
                _refresh_filters["dateTo"] = rf_to

    resolved_filters = (
        _refresh_filters
        or _first_available("ccare_provider_data_py.resolvedFilters", "resolvedFilters")
        or bundle_filters
        or {"dateFilter": "THIS_MONTH"}
    )
    date_filter = resolved_filters.get("dateFilter", "THIS_MONTH") if isinstance(resolved_filters, dict) else "THIS_MONTH"

    if date_filter in ("THIS_WEEK", "LAST_WEEK", "NEXT_WEEK"):
        today = date.today()
        offset = {"LAST_WEEK": -7, "THIS_WEEK": 0, "NEXT_WEEK": 7}[date_filter]
        week_start = today - timedelta(days=today.weekday()) + timedelta(days=offset)
        resolved_filters = {"dateFilter": "DATE_RANGE", "dateFrom": week_start.isoformat(),
                            "dateTo": (week_start + timedelta(days=6)).isoformat()}
        date_filter = "DATE_RANGE"

    turn_request = _safe_get("turnRequest") or {}
    turn_request = turn_request if isinstance(turn_request, dict) else {}
    routing_class = (turn_request.get("routingClass") or "").strip().upper()
    action = turn_request.get("action")
    sub_filter = turn_request.get("subFilter")

    # FIX 1: any PAYMENT turn needs payment sources (subFilter may be None
    # after a period is chosen from the disambiguation list).
    is_payment_request = action == "PAYMENT"
    needs_payment_sources = is_payment_request or sub_filter == "PAYOUT_IMPACT"
    needs_risk_rate_sources = needs_payment_sources or action in {"STARTER", "ATTENDANCE"}
    required_sources = list(_COMMON_SOURCES)
    if needs_risk_rate_sources:
        required_sources.append("fiscalRates")
    if needs_payment_sources:
        required_sources.extend(s for s in _PAYMENT_SOURCES if s not in required_sources)

    initial_source_params = (
        _payment_date_params(sub_filter, turn_request, resolved_filters) if is_payment_request
        else _source_date_params(resolved_filters)
    )
    child_names = sorted({str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c})
    county_names = sorted({str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c})
    requested_scope_key = json.dumps({
        "action": action, "subFilter": sub_filter, "asOfDate": date.today().isoformat(),
        "servicePeriodId": turn_request.get("servicePeriodId"),
        "source": initial_source_params,
        "servicePeriod": _service_period_params(sub_filter, turn_request, resolved_filters),
        "childNames": child_names, "countyNames": county_names,
    }, sort_keys=True)

    manifest = _safe_get("dataManifest")
    manifest = manifest if isinstance(manifest, dict) else {}
    payment_result = _safe_get("paymentResult")
    payment_result = payment_result if isinstance(payment_result, dict) else {}
    attendance_result = _safe_get("attendance_risks_analyzer_py") or _safe_get("result")
    attendance_result = attendance_result if isinstance(attendance_result, dict) else {}
    drill_down_reusable = _drill_down_reuse(turn_request, manifest, payment_result, attendance_result, initial_source_params)

    data_sufficient = (
        _manifest_is_fresh(manifest, needs_payment_sources)
        and all(s in _manifest_sources(manifest) for s in required_sources)
        and (manifest.get("requestKey") == requested_scope_key or drill_down_reusable)
    )
    # FIX 5: EXPLAIN renders from data already in context.
    explain_reuse = (
        action == "EXPLAIN" and _manifest_is_fresh(manifest, False)
        and all(s in _manifest_sources(manifest) for s in _COMMON_SOURCES)
    )
    if routing_class in ("CLARIFY", "END") or data_sufficient or explain_reuse:
        reason = (f"no data needed for {routing_class}" if routing_class in ("CLARIFY", "END")
                  else f"existing data covers {date_filter}/{sub_filter}")
        log(f"data-guard: {reason}")
        cache_status = _engine_cache_status(turn_request, manifest, payment_result, attendance_result)
        write_context("turnRequest", dict(turn_request, **cache_status))
        log(f"engine cache: {cache_status}")
        respond({"status": "DATA_COLLECTION_COMPLETE" if (data_sufficient or explain_reuse) else "DATA_NOT_REQUIRED",
                 "reason": reason}, confidence=1.0)
        return

    if provider_bundle is None:
        return _respond_failure("providerDataRaw must be an object")

    def _unpack_provider(bundle):
        providers, agreements = bundle.get("providers"), bundle.get("fiscalAgreements")
        if not isinstance(providers, list) or not isinstance(agreements, list):
            return None
        closures = bundle.get("providerClosures") or []
        provider_ids = _unique_values(agreements, "ID_SERVICE__c")
        provider_ids.extend(v for v in _unique_values(providers, "Id") if v not in provider_ids)
        return {
            "providers": providers, "agreements": agreements, "closures": closures,
            "provider_ids": provider_ids, "county_ids": _unique_values(agreements, "CDE_COUNTY__c"),
            "projected": _project_providers(providers, agreements),
        }

    prov = _unpack_provider(provider_bundle)
    if prov is None:
        return _respond_failure("providerDataRaw requires providers and fiscalAgreements arrays")
    write_context("provider", prov["projected"])
    write_context("resolvedFilters", resolved_filters)

    log("calling getServicePeriods before date-aware supporting sources")
    sp_response = call_endpoint("getServicePeriods", _service_period_params(sub_filter, turn_request, resolved_filters))
    if not sp_response or not sp_response.get("isSuccess"):
        return _respond_failure("getServicePeriods failed")
    sp_data = sp_response.get("data") or {}
    service_periods = sp_data.get("servicePeriods") or sp_data.get("records") or (sp_data if isinstance(sp_data, list) else [])
    if not isinstance(service_periods, list):
        return _respond_failure("getServicePeriods.servicePeriods must be an array")

    shared_params = _service_period_support_params(sub_filter, turn_request, initial_source_params, service_periods)

    # FIX 3: getProviderInfo is date-windowed -- re-fetch when the window we
    # now need isn't covered by the bundle already in context.
    if not _provider_window_covers(shared_params):
        user_id = _safe_get("external_id")
        if not user_id:
            return _respond_failure("IDENTITY_MISSING")
        log(f"refreshing getProviderInfo for window {shared_params}")
        refreshed = call_endpoint("getProviderInfo", dict({"userId": user_id}, **shared_params))
        if not refreshed or not refreshed.get("isSuccess"):
            return _respond_failure("getProviderInfo refresh failed")
        new_bundle = refreshed.get("data") or {}
        new_prov = _unpack_provider(new_bundle)
        if new_prov is None:
            return _respond_failure("getProviderInfo refresh returned no providers/fiscalAgreements")
        prov = new_prov
        cpd = dict(_safe_get("ccare_provider_data_py") or {})
        cpd["providerDataRaw"] = new_bundle
        write_context("ccare_provider_data_py", cpd)
        write_context("provider", prov["projected"])
        f, t = _materialize_bounds(shared_params, shared_params.get("dateFilter"))
        write_context("providerBundleWindow", {"from": f, "to": t, "key": _provider_window_key(shared_params)})

    provider_ids, county_ids, agreements, provider_closures = prov["provider_ids"], prov["county_ids"], prov["agreements"], prov["closures"]
    projected_provider = prov["projected"]

    effective_scope_key = json.dumps({"action": action, "subFilter": sub_filter, "source": shared_params,
                                      "servicePeriod": _service_period_params(sub_filter, turn_request, resolved_filters)}, sort_keys=True)
    common_cache_reusable = (
        _manifest_is_fresh(manifest, False)
        and all(s in _manifest_sources(manifest) for s in _COMMON_SOURCES)
        and _scope_matches_manifest(manifest, shared_params)
    )

    t0 = time.time()
    if common_cache_reusable:
        county_response = {"isSuccess": True, "data": {"countyRatePlans": _safe_get("CountyInformation") or []}}
        holiday_response = {"isSuccess": True, "data": {"holidayList": _safe_get("orgHolidays") or []}}
        auth_response = {"isSuccess": True, "data": {"authorizations": _safe_get("AuthInformation") or []}}
        log("reusing cached county, holiday and authorization data")
    else:
        with ThreadPoolExecutor(max_workers=3) as pool:
            cf = pool.submit(call_endpoint, "getCountyData", dict({"countyIds": county_ids}, **shared_params))
            hf = pool.submit(call_endpoint, "getHolidayList", shared_params)
            af = pool.submit(call_endpoint, "getAuthData", dict({"countyIds": county_ids, "providerIds": provider_ids}, **shared_params))
            county_response, holiday_response, auth_response = cf.result(), hf.result(), af.result()
    log(f"getCountyData + getHolidayList + getAuthData done in {time.time() - t0:.1f}s")

    if not county_response or not county_response.get("isSuccess"):
        return _respond_failure("getCountyData failed")
    if not holiday_response or not holiday_response.get("isSuccess"):
        return _respond_failure("getHolidayList failed")
    if not auth_response or not auth_response.get("isSuccess"):
        return _respond_failure("getAuthData failed")

    county_data = county_response.get("data") or {}
    county_information = county_data.get("countyRatePlans", [])
    write_context("CountyInformation", county_information)
    holiday_data = holiday_response.get("data") or {}
    holiday_list = holiday_data.get("holidayList", [])
    write_context("orgHolidays", holiday_list)

    # FIX 2: never narrow authorizations by child name here -- the real
    # payload has no child name on IDN_CLIENT__r, and cached raw data must
    # stay complete. Child/county scoping happens on the engine's ledger.
    authorizations = (auth_response.get("data") or {}).get("authorizations", [])
    write_context("AuthInformation", authorizations)
    auth_names = _unique_values(authorizations, "Name")
    if not auth_names:
        return _respond_failure("NO_AUTH_NAMES_FOR_SCHEDULES")

    t2 = time.time()
    if common_cache_reusable:
        schedule_response = {"isSuccess": True, "data": {"schedules": _safe_get("ScheduleInformation") or []}}
        log("reusing cached schedule data")
    else:
        schedule_response = call_endpoint("getSchedules", dict({"authNames": auth_names, "providerIds": provider_ids}, **shared_params))
    log(f"getSchedules done in {time.time() - t2:.1f}s")
    if not schedule_response or not schedule_response.get("isSuccess"):
        return _respond_failure("getSchedules failed")
    schedules = (schedule_response.get("data") or {}).get("schedules", [])
    if not isinstance(schedules, list):
        return _respond_failure("getSchedules.schedules must be an array")
    write_context("ScheduleInformation", schedules)

    payment_bundle = {
        "servicePeriods": service_periods, "fiscalRates": [], "fiscalSchedules": [], "fiscalAgreements": agreements,
        "paymentHistory": [], "vacantSlots": [], "providerClosures": provider_closures,
    }
    if needs_risk_rate_sources:
        fiscal_params = dict({"providerIds": provider_ids, "fiscalScheduleIds": _extract_fiscal_schedule_ids(agreements)}, **shared_params)
        history_response = {"isSuccess": True, "data": {"subPayments": []}}
        slots_response = {"isSuccess": True, "data": {"vacantSlots": []}}
        with ThreadPoolExecutor(max_workers=3 if needs_payment_sources else 1) as pool:
            fiscal_future = pool.submit(call_endpoint, "getFiscalRates", fiscal_params)
            history_future = slots_future = None
            if needs_payment_sources:
                history_future = pool.submit(call_endpoint, "getPaymentHistory", dict({"providerIds": provider_ids}, **shared_params))
                if county_ids:
                    slots_future = pool.submit(call_endpoint, "getVacantSlots", dict({"providerIds": provider_ids, "countyIds": county_ids}, **shared_params))
            fiscal_response = fiscal_future.result()
            if history_future:
                history_response = history_future.result()
            if slots_future:
                slots_response = slots_future.result()
        responses = {"getFiscalRates": fiscal_response}
        if needs_payment_sources:
            responses.update({"getPaymentHistory": history_response, "getVacantSlots": slots_response})
        failures = [n for n, r in responses.items() if not isinstance(r, dict) or not r.get("isSuccess")]
        if failures:
            return _respond_failure("payment source failure: " + ", ".join(failures))
        fiscal_data = fiscal_response.get("data") or {}
        payment_bundle.update({
            "fiscalRates": fiscal_data.get("fiscalRates") or [],
            "fiscalSchedules": fiscal_data.get("fiscalSchedules") or [],
            "paymentHistory": (history_response.get("data") or {}).get("subPayments") or [],
            "vacantSlots": (slots_response.get("data") or {}).get("vacantSlots") or (slots_response.get("data") or {}).get("records") or [],
        })

    if turn_request.get("servicePeriodId"):
        payment_bundle["service_period_id"] = turn_request["servicePeriodId"]
    if action == "STARTER":
        payment_bundle["multi_period_window"] = [d.isoformat() for d in _month_bounds(date.today())]
    elif sub_filter == "CURRENT_MONTH":
        payment_bundle["multi_period_window"] = [d.isoformat() for d in _month_bounds(date.today())]
    elif sub_filter == "ALL":
        payment_bundle["multi_period_window"] = [_month_bounds(date.today(), 1)[0].isoformat(), _month_bounds(date.today())[1].isoformat()]
    elif sub_filter == "LAST_PAYOUT":
        payment_bundle["select_last_released"] = True
    elif sub_filter == "NEXT_PAYOUT":
        payment_bundle["select_next_upcoming"] = True
    write_context("paymentData", payment_bundle)

    snapshot = _build_snapshot(projected_provider, resolved_filters, county_data, holiday_data, authorizations, schedules)
    result = {"status": "DATA_COLLECTION_COMPLETE", "snapshot": snapshot, "providerDisplayName": snapshot.get("user_name"),
              "facilityName": snapshot.get("facility_name"), "resolvedFilters": resolved_filters}
    write_context("raw_provider_data", {
        "providerData": {"providers": projected_provider, "providerClosures": provider_closures},
        "countyData": {"countyRatePlans": county_information}, "authData": {"authorizations": authorizations},
        "schedulesData": {"schedules": schedules}, "holidayData": {"holidayList": holiday_list},
    })
    write_context("data_collection_result", result)
    write_context("snapshot", snapshot)

    mf, mt = _materialize_bounds(shared_params, shared_params.get("dateFilter", date_filter))
    new_manifest = {
        "fetchedAt": date.today().isoformat(), "fetchedAtEpoch": time.time(), "requestKey": requested_scope_key,
        "dateFilter": shared_params.get("dateFilter", date_filter), "dateFrom": mf, "dateTo": mt,
        "scopeKey": effective_scope_key, "sources": sorted(required_sources),
        "providerIds": provider_ids, "countyIds": county_ids,
        "recordCounts": {
            "schedules": len(schedules), "authorizations": len(authorizations),
            "servicePeriods": len(service_periods), "fiscalRates": len(payment_bundle["fiscalRates"]),
            "paymentHistory": len(payment_bundle["paymentHistory"]), "vacantSlots": len(payment_bundle["vacantSlots"]),
        },
    }
    write_context("dataManifest", new_manifest)
    cache_status = _engine_cache_status(turn_request, new_manifest, payment_result, attendance_result)
    write_context("turnRequest", dict(turn_request, **cache_status))
    log(f"engine cache: {cache_status}")
    respond({"status": result["status"]}, confidence=1.0)


_main()