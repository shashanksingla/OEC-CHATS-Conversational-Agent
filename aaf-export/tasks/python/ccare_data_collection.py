"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

Fetches provider source data in parallel and builds the provider snapshot.
Runtime affordances: _context, call_endpoint(), write_context(), respond().
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
    return {
        "dateFilter": "DATE_RANGE",
        "dateFrom": start.isoformat(),
        "dateTo": end.isoformat(),
    }


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
        (_period_date(period, "serviceBeginDate", "DTE_BEGIN_EFFV__c", "Start_Date__c"),
         _period_date(period, "serviceEndDate", "DTE_END_EFFV__c", "End_Date__c"))
        for period in periods if isinstance(period, dict)
    ]
    bounds = [(start, end) for start, end in bounds if start is not None and end is not None]
    if not bounds:
        return None, None
    return min(start for start, _ in bounds), max(end for _, end in bounds)


def _service_period_support_params(sub_filter, turn_request, initial_params, periods):
    periods = periods if isinstance(periods, list) else []
    selected_periods = periods
    selected_id = turn_request.get("servicePeriodId") if isinstance(turn_request, dict) else None
    if selected_id:
        matching = [
            period for period in periods
            if str(_record_value(period, "servicePeriodId", "IDN_EXTNL__c", "id")) == str(selected_id)
        ]
        if matching:
            selected_periods = matching

    # Use full calendar months because absence limits are monthly.
    if sub_filter == "LAST_PAYOUT" and selected_periods:
        start, end = _period_bounds(selected_periods[:1])
        if start is not None and end is not None:
            month_start, _ = _month_bounds(start)
            _, month_end = _month_bounds(end)
            return _date_range_params(month_start, month_end)
    if sub_filter in ("NEXT_PAYOUT", "CURRENT_PERIOD_FORECAST", "FULL_BREAKDOWN") and selected_periods:
        start, end = _period_bounds(selected_periods[:1])
        if start is not None and end is not None:
            month_start, _ = _month_bounds(start)
            _, month_end = _month_bounds(end)
            return _date_range_params(month_start, month_end)
    if sub_filter == "SPECIFIC_PERIOD" and periods:
        start, end = _period_bounds(periods)
        if start is not None and end is not None:
            month_start, _ = _month_bounds(start)
            _, month_end = _month_bounds(end)
            return _date_range_params(month_start, month_end)
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
        first, last = _month_bounds(today)
        return _date_range_params(first, last)
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
    if sub_filter in ("CURRENT_MONTH", "ALL"):
        first, last = _month_bounds(today, 1 if sub_filter == "ALL" else 0)
        if sub_filter == "CURRENT_MONTH":
            return _date_range_params(*_month_bounds(today))
        return _date_range_params(first, last)
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


def _number_value(value):
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _child_id(record):
    value = _record_value(
        record,
        "child_id", "childId", "ChildId", "ContactId",
        "ContactId__c", "IDN_CLIENT__c", "CI_Client_Id__c",
        "clientId", "Contact_Name__c", "child_name",
    )
    return str(value) if value is not None else None


def _child_name(record):
    value = _record_value(
        record, "child_name", "childName", "ChildName",
        "Contact_Name__c", "Contact.Name", "IDN_CLIENT__r.Name",
    )
    return str(value) if value is not None else None


def _schedule_date(record):
    value = _record_value(
        record, "date", "service_date", "ServiceDate",
        "Service_Date__c", "Schedule_Date__c",
        "CI_Authorization_Date__c",
    )
    return str(value)[:10] if value is not None else None


def _is_checked_in(record):
    attended = _record_value(record, "attended", "isAttended")
    if isinstance(attended, bool):
        return attended
    if isinstance(attended, str) and attended.strip().lower() in ("true", "yes", "1"):
        return True
    check_in = _record_value(record, "Check_In_Count__c", "check_in_count", "checkInCount")
    number = _number_value(check_in)
    return number is not None and number > 0


def _pending_transactions(record):
    return _record_list(_record_value(record, "Attendance__r.records", "attendance.records", "transactions"))


def _is_pending(record):
    status = _record_value(record, "Status__c", "status", "Status", "parent_confirmation")
    return str(status or "").strip().upper() in ("PARENT_PENDING", "PENDING", "PENDING_PROVIDER")


def _build_snapshot(providers, resolved_filters, county_data, holiday_data, authorizations, schedules):
    today = date.today().isoformat()
    confirmation_window_days = 9
    provider_record = providers[0] if providers else {}
    children = {}
    today_children = {}
    today_checked_children = {}
    pending_rows = []
    pending_children = {}
    pending_days = {}
    pending_hours_by_day = {}
    incomplete_days = {}
    incomplete_children = {}
    incomplete_hours_by_day = {}
    absence_risks = []
    approaching_children = {}
    crossed_children = {}
    approaching_counties = {}
    crossed_counties = {}

    def _hours(record):
        value = _record_value(
            record,
            "authorized_hours",
            "authorizedHours",
            "CI_Authorization_Hours__c",
            "hours",
            "Hours__c",
        )
        number = _number_value(value)
        return number if number is not None and number >= 0 else 0.0

    def _count_value(record, *paths):
        number = _number_value(_record_value(record, *paths))
        return int(number) if number is not None else 0

    def _display_number(number):
        if number is None:
            return None
        return int(number) if float(number).is_integer() else number

    for schedule in schedules if isinstance(schedules, list) else []:
        if not isinstance(schedule, dict):
            continue
        child_id = _child_id(schedule)
        child_name = _child_name(schedule)
        child_key = child_id or child_name
        schedule_date = _schedule_date(schedule)
        checked_in = _is_checked_in(schedule)
        schedule_hours = _hours(schedule)
        if child_key is not None:
            child = children.setdefault(child_key, {
                "child_name": child_name,
                "scheduled_records": 0,
                "checked_in_records": 0,
                "pending_confirmation_days": 0,
                "incomplete_attendance_days": 0,
            })
            child["scheduled_records"] += 1
            if checked_in:
                child["checked_in_records"] += 1
            if schedule_date == today:
                today_children[child_key] = True
                if checked_in:
                    today_checked_children[child_key] = True

        transactions = _pending_transactions(schedule)
        pending = _is_pending(schedule) or any(
            _is_pending(item) for item in transactions if isinstance(item, dict)
        )
        if pending:
            pending_key = (child_key or "unknown", schedule_date or "unknown")
            if pending_key not in pending_days:
                pending_days[pending_key] = True
                pending_hours_by_day[pending_key] = schedule_hours
                if child_key is not None:
                    pending_children[child_key] = True
                    if child_key in children:
                        children[child_key]["pending_confirmation_days"] += 1
                pending_rows.append({
                    "child_name": child_name,
                    "authorization_id": _record_value(schedule, "CI_Authorization_Id__c", "authorization_id", "auth_id"),
                    "service_date": schedule_date,
                    "status": "PARENT_PENDING",
                })

        check_in_count = _count_value(
            schedule,
            "Check_In_Count__c",
            "check_in_count",
            "checkInCount",
        )
        check_out_count = _count_value(
            schedule,
            "Check_Out_Count__c",
            "check_out_count",
            "checkOutCount",
        )
        incomplete = (
            (check_in_count > 0 and check_out_count == 0)
            or (check_out_count > 0 and check_in_count == 0)
        )
        if incomplete:
            incomplete_key = (child_key or "unknown", schedule_date or "unknown")
            if incomplete_key not in incomplete_days:
                incomplete_days[incomplete_key] = True
                incomplete_hours_by_day[incomplete_key] = schedule_hours
                if child_key is not None:
                    incomplete_children[child_key] = True
                    if child_key in children:
                        children[child_key]["incomplete_attendance_days"] += 1

    def _sum_hours(values):
        return round(sum(values), 2)

    pending_loss_hours = _sum_hours(pending_hours_by_day.values())
    incomplete_loss_hours = _sum_hours(incomplete_hours_by_day.values())
    pending_deadlines = []
    for row in pending_rows:
        service_date = row.get("service_date")
        try:
            deadline = date.fromisoformat(service_date) + timedelta(days=confirmation_window_days)
            pending_deadlines.append(deadline.isoformat())
        except (TypeError, ValueError):
            continue
    earliest_deadline = min(pending_deadlines) if pending_deadlines else None
    deadline_days_remaining = None
    if earliest_deadline:
        deadline_days_remaining = (date.fromisoformat(earliest_deadline) - date.today()).days

    holiday_dates = []
    if isinstance(holiday_data, dict):
        for holiday in holiday_data.get("holidayList", []):
            if isinstance(holiday, dict):
                value = _record_value(holiday, "DTE_OBSERVED_HOL__c", "DTE_HOL__c", "date")
                if value is not None:
                    holiday_dates.append(str(value)[:10])

    children_list = []
    for child in children.values():
        children_list.append(child)

    pending_category = {
        "days": len(pending_days),
        "children": len(pending_children),
        "potential_loss_hours": pending_loss_hours,
    }
    approaching_category = {
        "children": len(approaching_children),
        "counties": len(approaching_counties),
    }
    crossed_category = {
        "children": len(crossed_children),
        "counties": len(crossed_counties),
        "potential_loss_hours": None,
    }
    incomplete_category = {
        "days": len(incomplete_days),
        "children": len(incomplete_children),
        "potential_loss_hours": incomplete_loss_hours,
    }

    next_actions = []
    if pending_category["days"]:
        next_actions.append("Review pending confirmations - %d days" % pending_category["days"])
    absence_count = approaching_category["children"] + crossed_category["children"]
    if absence_count:
        next_actions.append("Review absence-limit risk - %d children" % absence_count)
    if incomplete_category["days"]:
        next_actions.append("Review incomplete attendance - %d days" % incomplete_category["days"])
    scheduled_children = len(today_children)
    checked_in_children = len(today_checked_children)
    return {
        "as_of_date": today,
        "confirmation_window_days": confirmation_window_days,
        "confirmation_cutoff_date": (date.today() - timedelta(days=confirmation_window_days)).isoformat(),
        "user_name": _first_available("ccare_provider_data_py.providerName", "providerName") or provider_record.get("Name"),
        "facility_name": provider_record.get("NAM_FACILITY__c"),
        "date_filter": resolved_filters.get("dateFilter") if isinstance(resolved_filters, dict) else None,
        "today": {
            "scheduled_children": scheduled_children,
            "checked_in_children": checked_in_children,
        },
        "children_scheduled_count": scheduled_children,
        "checked_in_count": checked_in_children,
        "pending_confirmation_days": len(pending_days),
        "pending_confirmation_children_count": len(pending_children),
        "pending_confirmations": pending_rows,
        "absence_risk_children_count": absence_count,
        "absence_risks": absence_risks,
        "risk_categories": {
            "pending_parent_confirmations": pending_category,
            "approaching_absence_limits": approaching_category,
            "crossed_absence_limits": crossed_category,
            "incomplete_attendance": incomplete_category,
        },
        "payment_summary": {
            "status": "AVAILABLE_ON_REQUEST",
            "view": "NEXT_PAYOUT",
            "amount_status": "UNAVAILABLE",
            "missing_sources": ["fiscal rates", "payment history"],
        },
        "children": children_list,
        "earliest_confirmation_deadline": earliest_deadline,
        "earliest_confirmation_days_remaining": deadline_days_remaining,
        "holiday_dates": sorted({value for value in holiday_dates}),
        "next_actions": next_actions[:4],
        "source_counts": {
            "providers": len(providers) if isinstance(providers, list) else 0,
            "authorizations": len(authorizations) if isinstance(authorizations, list) else 0,
            "schedules": len(schedules) if isinstance(schedules, list) else 0,
            "county_rate_plans": len(county_data.get("countyRatePlans", [])) if isinstance(county_data, dict) and isinstance(county_data.get("countyRatePlans", []), list) else 0,
            "holidays": len(holiday_data.get("holidayList", [])) if isinstance(holiday_data, dict) and isinstance(holiday_data.get("holidayList", []), list) else 0,
        },
    }


def _materialize_bounds(resolved_f, df):
    """Resolve filters to concrete date bounds."""
    if isinstance(resolved_f, dict):
        if resolved_f.get("dateFrom") and resolved_f.get("dateTo"):
            return resolved_f["dateFrom"], resolved_f["dateTo"]
    today = date.today()
    df = (df or "THIS_MONTH").upper()
    if df == "THIS_MONTH":
        first = today.replace(day=1)
        last = (date(today.year, today.month + 1, 1) - timedelta(days=1)) if today.month < 12 else date(today.year, 12, 31)
        return first.isoformat(), last.isoformat()
    if df == "LAST_MONTH":
        first_this = today.replace(day=1)
        last_prev = first_this - timedelta(days=1)
        return last_prev.replace(day=1).isoformat(), last_prev.isoformat()
    return None, None


_COMMON_SOURCES = {
    "servicePeriods", "county", "holidays", "authorizations", "schedules",
}
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
    return (
        manifest.get("dateFrom") == source_params.get("dateFrom")
        and manifest.get("dateTo") == source_params.get("dateTo")
    )


def _date_window_within_manifest(manifest, source_params):
    """Return whether the request window is covered by the manifest."""
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
    """Return whether current filters are covered by cached filters."""
    def _covered(current, cached):
        if not cached:
            return True
        return bool(current) and current.issubset(cached)
    return _covered(current_child, cached_child) and _covered(current_county, cached_county)


def _drill_down_reuse(turn_request, manifest, payment_result, attendance_result, source_params):
    """Return whether cached data can satisfy the current drill-down."""
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
        # Require matching subFilter; views may use different scopes.
        if fp.get("subFilter") != current_sub_filter:
            return False
    else:
        fp = None
        for candidate in (payment_result, attendance_result):
            candidate_fp = candidate.get("scopeFingerprint") if isinstance(candidate, dict) else None
            if (
                isinstance(candidate_fp, dict)
                and candidate_fp.get("dataSnapshotVersion") == snapshot_version
                # Require matching subFilter to prevent unrelated cache reuse.
                and candidate_fp.get("subFilter") == current_sub_filter
            ):
                fp = candidate_fp
                break
        if fp is None:
            return False

    current_child = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c} if isinstance(turn_request, dict) else set()
    current_county = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c} if isinstance(turn_request, dict) else set()
    cached_child = set(fp.get("child_filter") or [])
    cached_county = set(fp.get("county_filter") or [])
    if not _filters_covered(current_child, current_county, cached_child, cached_county):
        return False

    return _date_window_within_manifest(manifest, source_params)


def _engine_cache_status(turn_request, manifest, payment_result, attendance_result):
    """Compute cache-validity flags for payment, attendance, and engine reuse."""
    turn_request = turn_request if isinstance(turn_request, dict) else {}
    snapshot_version = manifest.get("fetchedAtEpoch") if isinstance(manifest, dict) else None
    current_child = {str(c).strip().lower() for c in (turn_request.get("childNames") or []) if c}
    current_county = {str(c).strip().lower() for c in (turn_request.get("countyNames") or []) if c}
    current_period = turn_request.get("servicePeriodId")
    current_sub_filter = turn_request.get("subFilter")

    def _valid(result):
        fp = result.get("scopeFingerprint") if isinstance(result, dict) else None
        if not isinstance(fp, dict) or fp.get("dataSnapshotVersion") != snapshot_version:
            return "NO"
        # Require matching subFilter before accepting cached results.
        if fp.get("subFilter") != current_sub_filter:
            return "NO"
        cached_child = set(fp.get("child_filter") or [])
        cached_county = set(fp.get("county_filter") or [])
        if not _filters_covered(current_child, current_county, cached_child, cached_county):
            return "NO"
        if current_period and str(current_period) not in (fp.get("resolved_service_period_ids") or []):
            return "NO"
        return "YES"

    payment_valid = _valid(payment_result)
    attendance_valid = _valid(attendance_result)

    action = turn_request.get("action")
    sub_filter = turn_request.get("subFilter")
    if action == "PAYMENT":
        engine_valid = payment_valid
    elif action in ("ATTENDANCE", "STARTER"):
        # PAYOUT_IMPACT/STARTER always force a fresh engine run.
        engine_valid = "NO" if (sub_filter == "PAYOUT_IMPACT" or action == "STARTER") else attendance_valid
    else:
        engine_valid = "NO"

    return {
        "paymentCacheValid": payment_valid,
        "attendanceCacheValid": attendance_valid,
        "engineCacheValid": engine_valid,
    }


raw_provider_path, raw_provider_data = _first_available_entry(
    "ccare_provider_data_py.providerDataRaw",
    "providerDataRaw",
)
provider_bundle, bundle_filters = _provider_bundle(raw_provider_data)
# Refresh fetchParams override the session date scope.
_fetch_params = _as_object(_safe_get("turnRequest.fetchParams")) or {}
_refresh_filters = None
if _fetch_params:
    _rf_date_filter = _fetch_params.get("dateFilter")
    _rf_date_from = _fetch_params.get("dateFrom")
    _rf_date_to = _fetch_params.get("dateTo")
    if _rf_date_filter or _rf_date_from:
        _refresh_filters = {"dateFilter": _rf_date_filter or "DATE_RANGE"}
        if _rf_date_from:
            _refresh_filters["dateFrom"] = _rf_date_from
        if _rf_date_to:
            _refresh_filters["dateTo"] = _rf_date_to

resolved_filters = (
    _refresh_filters
    or _first_available(
        "ccare_provider_data_py.resolvedFilters",
        "resolvedFilters",
    )
    or bundle_filters
    or {"dateFilter": "THIS_MONTH"}
)
date_filter = resolved_filters.get("dateFilter", "THIS_MONTH") if isinstance(resolved_filters, dict) else "THIS_MONTH"

# Resolve weekly filters to explicit date ranges.
_WEEKLY_FILTERS = {"THIS_WEEK", "LAST_WEEK", "NEXT_WEEK"}
if date_filter in _WEEKLY_FILTERS:
    _today = date.today()
    _week_offset = {"LAST_WEEK": -7, "THIS_WEEK": 0, "NEXT_WEEK": 7}[date_filter]
    _this_monday = _today - timedelta(days=_today.weekday())
    _week_start = _this_monday + timedelta(days=_week_offset)
    _week_end = _week_start + timedelta(days=6)
    resolved_filters = {
        "dateFilter": "DATE_RANGE",
        "dateFrom": _week_start.isoformat(),
        "dateTo": _week_end.isoformat(),
    }
    date_filter = "DATE_RANGE"

# Skip fetch when existing data covers the request.
_rc_value = _safe_get('turnRequest.routingClass')
_rc = _rc_value.strip().upper() if isinstance(_rc_value, str) else ''
_turn_request = _safe_get("turnRequest") or {}
_sub_filter = _turn_request.get("subFilter") if isinstance(_turn_request, dict) else None
_payment_sub_filters = {
    "NEXT_PAYOUT", "LAST_PAYOUT", "CURRENT_PERIOD_FORECAST",
    "CURRENT_MONTH", "SPECIFIC_PERIOD", "FULL_BREAKDOWN",
}
_is_payment_request = (
    isinstance(_turn_request, dict)
    and _turn_request.get("action") == "PAYMENT"
    and (_sub_filter in _payment_sub_filters or _sub_filter == "ALL")
)
_needs_payment_sources = (
    _is_payment_request
    or (isinstance(_turn_request, dict) and _sub_filter == "PAYOUT_IMPACT")
)
_needs_risk_rate_sources = _needs_payment_sources or (
    isinstance(_turn_request, dict)
    and _turn_request.get("action") in {"STARTER", "ATTENDANCE"}
)
_required_sources = list(_COMMON_SOURCES)
if _needs_risk_rate_sources and "fiscalRates" not in _required_sources:
    _required_sources.append("fiscalRates")
if _needs_payment_sources:
    _required_sources.extend(source for source in _PAYMENT_SOURCES if source not in _required_sources)
_initial_source_params = (
    _payment_date_params(_sub_filter, _turn_request, resolved_filters)
    if _is_payment_request
    else _source_date_params(resolved_filters)
)
_requested_scope_key = json.dumps({
    "action": _turn_request.get("action") if isinstance(_turn_request, dict) else None,
    "subFilter": _sub_filter,
    "asOfDate": date.today().isoformat(),
    "servicePeriodId": _turn_request.get("servicePeriodId") if isinstance(_turn_request, dict) else None,
    "source": _initial_source_params,
    "servicePeriod": _service_period_params(_sub_filter, _turn_request, resolved_filters),
    # Scope cache keys by child and county filters.
    "childNames": sorted({str(c).strip().lower() for c in (_turn_request.get("childNames") or []) if c}) if isinstance(_turn_request, dict) else [],
    "countyNames": sorted({str(c).strip().lower() for c in (_turn_request.get("countyNames") or []) if c}) if isinstance(_turn_request, dict) else [],
}, sort_keys=True)
_manifest = _safe_get('dataManifest')
_manifest = _manifest if isinstance(_manifest, dict) else {}
_r_sf_value = _safe_get('turnRequest.subFilter')
_r_sf = _r_sf_value.strip().upper() if isinstance(_r_sf_value, str) else ''
_payment_result = _safe_get("paymentResult")
_payment_result = _payment_result if isinstance(_payment_result, dict) else {}
_attendance_result = _safe_get("attendance_risks_analyzer_py") or _safe_get("result")
_attendance_result = _attendance_result if isinstance(_attendance_result, dict) else {}
_drill_down_reusable = _drill_down_reuse(
    _turn_request, _manifest, _payment_result, _attendance_result, _initial_source_params,
)

_data_sufficient = (
    _manifest_is_fresh(_manifest, _needs_payment_sources)
    and all(source in _manifest_sources(_manifest) for source in _required_sources)
    and (
        _manifest.get('requestKey') == _requested_scope_key
        or _drill_down_reusable
    )
)
_skip_fetch = _rc in ('CLARIFY', 'END') or _data_sufficient
if _skip_fetch:
    _skip_reason = (
        f'no data needed for {_rc}' if _rc in ('CLARIFY', 'END')
        else f'existing data covers {date_filter}/{_r_sf}'
    )
    log(f'data-guard: {_skip_reason}')
    # Compute cache validity from the available request and results.
    _cache_status = _engine_cache_status(_turn_request, _manifest, _payment_result, _attendance_result)
    write_context("turnRequest", dict(_turn_request, **_cache_status))
    log(f"engine cache: payment={_cache_status['paymentCacheValid']} attendance={_cache_status['attendanceCacheValid']} engine={_cache_status['engineCacheValid']}")
    respond(
        {'status': 'DATA_COLLECTION_COMPLETE' if _data_sufficient else 'DATA_NOT_REQUIRED', 'reason': _skip_reason},
        confidence=1.0,
    )
elif provider_bundle is None:
    _respond_failure("providerDataRaw must be an object")
else:
    providers = provider_bundle.get("providers")
    agreements = provider_bundle.get("fiscalAgreements")
    # Preserve closures returned with fiscal agreements.
    provider_closures = provider_bundle.get("providerClosures") or []
    if not isinstance(providers, list) or not isinstance(agreements, list):
        _respond_failure("providerDataRaw requires providers and fiscalAgreements arrays")
    else:
        provider_ids = _unique_values(agreements, "ID_SERVICE__c")
        provider_ids.extend(
            value for value in _unique_values(providers, "Id") if value not in provider_ids
        )
        county_ids = _unique_values(agreements, "CDE_COUNTY__c")
        projected_provider = _project_providers(providers, agreements)
        # Persist provider data for downstream tasks.
        write_context("provider", projected_provider)
        write_context("resolvedFilters", resolved_filters)

        log("calling getServicePeriods before date-aware supporting sources")
        _service_period_response = call_endpoint(
            "getServicePeriods",
            _service_period_params(_sub_filter, _turn_request, resolved_filters),
        )
        if not _service_period_response or not _service_period_response.get("isSuccess"):
            _respond_failure("getServicePeriods failed")
            raise SystemExit(1)
        else:
            _service_period_data = _service_period_response.get("data") or {}
            _service_periods = (
                _service_period_data.get("servicePeriods")
                or _service_period_data.get("records")
                or (_service_period_data if isinstance(_service_period_data, list) else [])
            )
            if not isinstance(_service_periods, list):
                _respond_failure("getServicePeriods.servicePeriods must be an array")
                raise SystemExit(1)
            _shared_source_params = _service_period_support_params(
                _sub_filter,
                _turn_request,
                _initial_source_params,
                _service_periods,
            )
            _effective_scope_key = json.dumps({
                "action": _turn_request.get("action") if isinstance(_turn_request, dict) else None,
                "subFilter": _sub_filter,
                "source": _shared_source_params,
                "servicePeriod": _service_period_params(_sub_filter, _turn_request, resolved_filters),
            }, sort_keys=True)
            _common_cache_reusable = (
                _manifest_is_fresh(_manifest, False)
                and all(source in _manifest_sources(_manifest) for source in _COMMON_SOURCES)
                and _scope_matches_manifest(_manifest, _shared_source_params)
            )
            log("parallel: getCountyData + getHolidayList + getAuthData")
        t0 = time.time()
        if _common_cache_reusable:
            county_response = {"isSuccess": True, "data": {"countyRatePlans": _safe_get("CountyInformation") or []}}
            holiday_response = {"isSuccess": True, "data": {"holidayList": _safe_get("orgHolidays") or []}}
            auth_response = {"isSuccess": True, "data": {"authorizations": _safe_get("AuthInformation") or []}}
            log("reusing cached county and holiday data")
        else:
            with ThreadPoolExecutor(max_workers=3) as pool:
                county_future = pool.submit(call_endpoint, "getCountyData", {
                    "countyIds": county_ids,
                    **_shared_source_params,
                })
                holiday_future = pool.submit(call_endpoint, "getHolidayList", _shared_source_params)
                auth_future = pool.submit(call_endpoint, "getAuthData", {
                    "countyIds": county_ids,
                    "providerIds": provider_ids,
                    **_shared_source_params,
                })
                county_response = county_future.result()
                holiday_response = holiday_future.result()
                auth_response = auth_future.result()
        log(f"getCountyData + getHolidayList done in {time.time() - t0:.1f}s")

        if not county_response or not county_response.get("isSuccess"):
            _respond_failure("getCountyData failed")
        elif not holiday_response or not holiday_response.get("isSuccess"):
            _respond_failure("getHolidayList failed")
        else:
            county_data = county_response.get("data") or {}
            county_information = county_data.get("countyRatePlans", [])
            write_context("CountyInformation", county_information)
            holiday_data = holiday_response.get("data") or {}
            holiday_list = holiday_data.get("holidayList", [])
            write_context("orgHolidays", holiday_list)

            if not auth_response or not auth_response.get("isSuccess"):
                _respond_failure("getAuthData failed")
            else:
                auth_data = auth_response.get("data") or {}
                authorizations = auth_data.get("authorizations", [])
                # Narrow authorizations locally for scoped child requests.
                _req_child_names = {str(c).strip().lower() for c in (_turn_request.get("childNames") or []) if c} if isinstance(_turn_request, dict) else set()
                if _req_child_names:
                    authorizations = [
                        a for a in authorizations
                        if str((a.get("IDN_CLIENT__r") or {}).get("Name") or "").strip().lower() in _req_child_names
                    ]
                write_context("AuthInformation", authorizations)
                auth_names = _unique_values(authorizations, "Name")
                if not auth_names:
                    _respond_failure("NO_AUTH_NAMES_FOR_SCHEDULES")
                else:
                    log("calling getSchedules")
                    t2 = time.time()
                    if _common_cache_reusable:
                        schedule_response = {"isSuccess": True, "data": {"schedules": _safe_get("ScheduleInformation") or []}}
                        log("reusing cached schedule data")
                    else:
                        _schedule_params = {
                            "authNames": auth_names,
                            "providerIds": provider_ids,
                            **_shared_source_params,
                        }
                        schedule_response = call_endpoint("getSchedules", _schedule_params)
                    log(f"getSchedules done in {time.time() - t2:.1f}s")

                    if not schedule_response or not schedule_response.get("isSuccess"):
                        _respond_failure("getSchedules failed")
                    else:
                        schedule_data = schedule_response.get("data") or {}
                        schedules = schedule_data.get("schedules", [])
                        if not isinstance(schedules, list):
                            _respond_failure("getSchedules.schedules must be an array")
                        else:
                            write_context("ScheduleInformation", schedules)
                            _payment_bundle: dict = {
                                "servicePeriods": _service_periods,
                                "fiscalRates": [],
                                "fiscalSchedules": [],
                                "fiscalAgreements": agreements,
                                "paymentHistory": [],
                                "vacantSlots": [],
                                "providerClosures": provider_closures,
                            }
                            if _needs_risk_rate_sources:
                                _payment_date_params_value = _shared_source_params
                                _fiscal_schedule_ids = _extract_fiscal_schedule_ids(agreements)
                                _fiscal_rate_params = {
                                    "providerIds": provider_ids,
                                    "fiscalScheduleIds": _fiscal_schedule_ids,
                                    **_payment_date_params_value,
                                }
                                _payment_history_response = {"isSuccess": True, "data": {"subPayments": []}}
                                _vacant_slot_response = {"isSuccess": True, "data": {"vacantSlots": []}}
                                with ThreadPoolExecutor(max_workers=3 if _needs_payment_sources else 1) as pool:
                                    _fiscal_rate_future = pool.submit(call_endpoint, "getFiscalRates", _fiscal_rate_params)
                                    if _needs_payment_sources:
                                        _payment_history_future = pool.submit(call_endpoint, "getPaymentHistory", {
                                            "providerIds": provider_ids,
                                            **_payment_date_params_value,
                                        })
                                        _vacant_slot_future = pool.submit(call_endpoint, "getVacantSlots", {
                                            "providerIds": provider_ids,
                                            "countyIds": county_ids,
                                            **_payment_date_params_value,
                                        }) if county_ids else None
                                    _fiscal_rate_response = _fiscal_rate_future.result()
                                    if _needs_payment_sources:
                                        _payment_history_response = _payment_history_future.result()
                                        _vacant_slot_response = _vacant_slot_future.result() if _vacant_slot_future else _vacant_slot_response
                                _payment_responses = {
                                    "getFiscalRates": _fiscal_rate_response,
                                }
                                if _needs_payment_sources:
                                    _payment_responses.update({
                                        "getPaymentHistory": _payment_history_response,
                                        "getVacantSlots": _vacant_slot_response,
                                    })
                                _payment_failures = [name for name, response in _payment_responses.items() if not isinstance(response, dict) or not response.get("isSuccess")]
                                if _payment_failures:
                                    _respond_failure("payment source failure: " + ", ".join(_payment_failures))
                                    raise SystemExit(1)
                                _fiscal_rate_data = _fiscal_rate_response.get("data") or {}
                                _payment_history_data = _payment_history_response.get("data") or {}
                                _vacant_slot_data = _vacant_slot_response.get("data") or {}
                                _payment_bundle.update({
                                    "fiscalRates": _fiscal_rate_data.get("fiscalRates") or [],
                                    "fiscalSchedules": _fiscal_rate_data.get("fiscalSchedules") or [],
                                    # fiscalRateFees is unused downstream.
                                    "paymentHistory": _payment_history_data.get("subPayments") or [],
                                    "vacantSlots": _vacant_slot_data.get("vacantSlots") or _vacant_slot_data.get("records") or [],
                                })
                            if isinstance(_turn_request, dict) and _turn_request.get("servicePeriodId"):
                                _payment_bundle["service_period_id"] = _turn_request["servicePeriodId"]
                            if _sub_filter == "CURRENT_MONTH":
                                _payment_bundle["multi_period_window"] = [d.isoformat() for d in _month_bounds(date.today())]
                            elif _sub_filter == "ALL":
                                _payment_bundle["multi_period_window"] = [_month_bounds(date.today(), 1)[0].isoformat(), _month_bounds(date.today())[1].isoformat()]
                            elif _sub_filter == "LAST_PAYOUT":
                                _payment_bundle["select_last_released"] = True
                            elif _sub_filter == "NEXT_PAYOUT":
                                # Select the soonest upcoming period client-side.
                                _payment_bundle["select_next_upcoming"] = True
                            write_context("paymentData", _payment_bundle)
                            snapshot = _build_snapshot(
                                projected_provider,
                                resolved_filters,
                                county_data,
                                holiday_data,
                                authorizations,
                                schedules,
                            )
                            result = {
                                "status": "DATA_COLLECTION_COMPLETE",
                                "snapshot": snapshot,
                                "providerDisplayName": snapshot.get("user_name"),
                                "facilityName": snapshot.get("facility_name"),
                                "resolvedFilters": resolved_filters,
                            }
                            write_context("raw_provider_data", {
                                "providerData": {"providers": projected_provider, "providerClosures": provider_closures},
                                "countyData": {"countyRatePlans": county_information},
                                "authData": {"authorizations": authorizations},
                                "schedulesData": {"schedules": schedules},
                                "holidayData": {"holidayList": holiday_list},
                            })
                            write_context("data_collection_result", result)
                            write_context("snapshot", snapshot)
                            _mf, _mt = _materialize_bounds(
                                _shared_source_params,
                                _shared_source_params.get("dateFilter", date_filter),
                            )
                            _new_manifest = {
                                "fetchedAt": date.today().isoformat(),
                                "fetchedAtEpoch": time.time(),
                                "requestKey": _requested_scope_key,
                                "dateFilter": _shared_source_params.get("dateFilter", date_filter),
                                "dateFrom": _mf,
                                "dateTo": _mt,
                                "scopeKey": _effective_scope_key,
                                "sources": sorted(_required_sources),
                                "providerIds": provider_ids,
                                "countyIds": county_ids,
                                "recordCounts": {
                                    "schedules": len(schedules),
                                    "authorizations": len(authorizations),
                                    "servicePeriods": len(_payment_bundle["servicePeriods"]) if isinstance(_payment_bundle["servicePeriods"], list) else 0,
                                    "fiscalRates": len(_payment_bundle["fiscalRates"]),
                                    "paymentHistory": len(_payment_bundle["paymentHistory"]),
                                    "vacantSlots": len(_payment_bundle["vacantSlots"]),
                                },
                            }
                            write_context("dataManifest", _new_manifest)
                            # Fresh snapshots invalidate older cache fingerprints.
                            _cache_status = _engine_cache_status(_turn_request, _new_manifest, _payment_result, _attendance_result)
                            write_context("turnRequest", dict(_turn_request, **_cache_status))
                            log(f"engine cache: payment={_cache_status['paymentCacheValid']} attendance={_cache_status['attendanceCacheValid']} engine={_cache_status['engineCacheValid']}")
                            respond({"status": result["status"]}, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________