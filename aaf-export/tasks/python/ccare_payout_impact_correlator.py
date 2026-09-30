"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_payout_impact_correlator, v1.0.0. Resolves $/hours at risk for each
attendance-risk row (absence-limit, unconfirmed attendance) against fiscal
rates already collected in context.paymentData.

Runtime affordances: read_context, write_context, respond().
"""

from datetime import date
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP

if "read_context" not in globals():
    def read_context(key):
        return None

if "write_context" not in globals():

    def write_context(key, value):
        return value

if "respond" not in globals():

    def respond(payload, **kw):
        return payload

log = print

MONEY_QUANTUM = Decimal("0.01")
PAID_TIERS = (
    (Decimal("0"), "NO_PAYMENT"),
    (Decimal("5"), "PART_TIME"),
    (Decimal("12"), "FULL_TIME"),
    (Decimal("17"), "FULL_TIME_PLUS_PART_TIME"),
)
CARE_UNIT_TO_TIER = {
    "1": "NO_PAYMENT",
    "2": "PART_TIME",
    "3": "FULL_TIME",
    "4": "FULL_TIME_PLUS_PART_TIME",
    "5": "FULL_TIME_PLUS_FULL_TIME",
}
TIER_TO_CARE_UNIT = {tier: code for code, tier in CARE_UNIT_TO_TIER.items()}
AGE_GROUP_MONTH_BOUNDS = ((6, "1"), (12, "2"), (18, "3"), (24, "4"), (30, "5"), (36, "6"), (60, "7"))
RATE_TYPE_BASE_CODES = {
    **{str(code): "1" for code in range(2, 7)},
    **{str(code): "13" for code in range(14, 19)},
    **{str(code): "19" for code in range(20, 25)},
    **{str(code): "25" for code in range(26, 31)},
    **{str(code): "31" for code in range(32, 37)},
    **{str(code): "37" for code in range(38, 43)},
    **{str(code): "43" for code in range(44, 49)},
    **{str(code): "49" for code in range(50, 54)},
    **{str(code): "55" for code in range(56, 61)},
    **{str(code): "61" for code in range(62, 65)},
    **{str(code): "73" for code in range(74, 76)},
    **{str(code): "79" for code in range(80, 85)},
    **{str(code): "85" for code in range(86, 89)},
    **{str(code): "91" for code in range(92, 94)},
}


def _text(row, *keys):
    if not isinstance(row, dict):
        return None
    for key in keys:
        value = row.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return None


def _decimal(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return parsed if parsed.is_finite() else None


def _number(row, *keys):
    if not isinstance(row, dict):
        return None
    for key in keys:
        value = _decimal(row.get(key))
        if value is not None and value >= 0:
            return value
    return None


def _count_value(row, *keys):
    value = _number(row, *keys)
    return int(value) if value is not None else 0


def _money(value):
    if value is None:
        return None
    return format(value.quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


def _fiscal_rate_type(value):
    code = str(value or "").strip()
    return RATE_TYPE_BASE_CODES.get(code, code)


def paid_tier_for_hours(hours):
    value = _decimal(hours)
    if value is None or value <= 0:
        return "NO_PAYMENT"
    for boundary, tier in PAID_TIERS[1:]:
        if value <= boundary:
            return tier
    return "FULL_TIME_PLUS_FULL_TIME"


def _as_list(value):
    if isinstance(value, list):
        return [item for item in value if isinstance(item, dict)]
    if isinstance(value, dict):
        for key in ("records", "items", "results", "data"):
            nested = value.get(key)
            if isinstance(nested, list):
                return [item for item in nested if isinstance(item, dict)]
    return []


def _extract_ids(items, *fields):
    ids = []
    for item in items:
        if not isinstance(item, dict):
            continue
        for field in fields:
            value = (item.get(field) or "").strip() if item.get(field) else ""
            if value and value not in ids:
                ids.append(value)
                break
    return ids


def _fiscal_schedule_index(fiscal_agreements, fiscal_schedules):
    """{(provider_id, county_id): [{ext_id, rate_types, quality_tier}, ...]} --
    same join ccare_payment_engine uses."""
    agreement_scope = {}
    for agreement in fiscal_agreements:
        if not isinstance(agreement, dict):
            continue
        agreement_id = _text(agreement, "Id", "IDN_EXTNL__c")
        provider_id = _text(agreement, "ID_SERVICE__c", "provider_id")
        county_id = _text(agreement, "CDE_COUNTY__c", "county_id")
        if agreement_id and provider_id and county_id:
            agreement_scope[agreement_id] = (provider_id, county_id)

    index = {}

    def _add_schedule(rs, provider_id, county_id):
        if not isinstance(rs, dict) or not provider_id or not county_id:
            return
        ext_id = _text(rs, "IDN_EXTNL__c", "Id")
        if not ext_id:
            return
        rate_type_raw = _text(rs, "CDE_RATE_TYPE__c") or ""
        rate_types = {token.strip() for token in rate_type_raw.split(";") if token.strip()}
        quality_tier = _text(rs, "TXT_CHATS_RATING__c")
        index.setdefault((provider_id, county_id), []).append(
            {"ext_id": ext_id, "rate_types": rate_types, "quality_tier": quality_tier}
        )

    for agreement in fiscal_agreements:
        if not isinstance(agreement, dict):
            continue
        provider_id = _text(agreement, "ID_SERVICE__c", "provider_id")
        county_id = _text(agreement, "CDE_COUNTY__c", "county_id")
        for rs in _as_list(agreement.get("Rate_Schedules__r")):
            _add_schedule(rs, provider_id, county_id)

    for rs in fiscal_schedules:
        if not isinstance(rs, dict):
            continue
        agreement_id = _text(rs, "IDN_AGRMT_FISCAL__c")
        scope = agreement_scope.get(agreement_id or "")
        if scope:
            _add_schedule(rs, scope[0], scope[1])

    return index


def _rate_lookup(fiscal_rates):
    """Phase 4: key by the SAME normalized rate type _resolve_rate_for_schedule
    queries with (_fiscal_rate_type()) -- storing the raw code here while the
    query side normalizes meant an alias code (e.g. 2-6 -> 1) could never
    match, surfacing as a false "fiscal_rate" blocker."""
    lookup = {}
    for rate in fiscal_rates:
        if not isinstance(rate, dict):
            continue
        ext_id = _text(rate, "idn_fiscal_sch__c")
        rate_type = _fiscal_rate_type(_text(rate, "cde_rate_type__c"))
        age_group = _text(rate, "cde_age_group__c") or ""
        care_unit = _text(rate, "cde_care_unit__c")
        amount = _number(rate, "amt_fa__c", "amount")
        if not ext_id or not rate_type or not care_unit or amount is None:
            continue
        lookup.setdefault((ext_id, rate_type, age_group, care_unit), amount)
    return lookup


def _date_value(value):
    try:
        return date.fromisoformat(str(value)[:10])
    except (TypeError, ValueError):
        return None


def _age_group_code(authorization, service_date):
    client = authorization.get("IDN_CLIENT__r") if isinstance(authorization, dict) else None
    dob = _date_value(_text(client, "DTE_DOB__c", "dob"))
    target = _date_value(service_date)
    if not dob or not target:
        return None
    months = (target.year - dob.year) * 12 + target.month - dob.month
    if target.day < dob.day:
        months -= 1
    for bound, code in AGE_GROUP_MONTH_BOUNDS:
        if max(months, 0) < bound:
            return code
    return "8"


def _resolve_rate_for_schedule(schedule, authorization, county_id, provider_id, schedule_index, rate_lookup, hours, service_date):
    schedule_rate_type_code = _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c") \
        or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
    rate_type_code = _fiscal_rate_type(schedule_rate_type_code)
    age_group_code = _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code") \
        or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c") \
        or _age_group_code(authorization, service_date)
    if not age_group_code:
        return None, "age_group_code_unresolved"
    care_unit = TIER_TO_CARE_UNIT.get(paid_tier_for_hours(hours))
    if care_unit is None:
        return None, "care_unit_mapping_unconfirmed"
    provider_id = provider_id or _text(authorization, "IDN_PROVR__c", "provider_id")
    county_id = county_id or _text(authorization, "CDE_COUNTY__c", "county_id")
    candidates = schedule_index.get((provider_id or "", county_id or ""), [])
    if not candidates:
        return None, "fiscal_schedule"
    no_payment_unit = TIER_TO_CARE_UNIT["NO_PAYMENT"]
    for candidate in candidates:
        candidate_rate_types = {_fiscal_rate_type(value) for value in candidate["rate_types"]}
        if rate_type_code and candidate_rate_types and rate_type_code not in candidate_rate_types:
            continue
        amount = rate_lookup.get((candidate["ext_id"], rate_type_code or "", age_group_code, care_unit))
        if amount is not None:
            return amount, None
        fallback = rate_lookup.get((candidate["ext_id"], rate_type_code or "", age_group_code, no_payment_unit))
        if fallback is not None:
            return Decimal("0"), None
    return None, "fiscal_rate"


def _rate_debug(schedule, authorization, county_id, provider_id, schedule_index, fiscal_rates, hours, service_date):
    schedule_rate_type_code = _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c") \
        or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
    rate_type_code = _fiscal_rate_type(schedule_rate_type_code)
    age_group_code = _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code") \
        or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c") \
        or _age_group_code(authorization, service_date)
    paid_tier = paid_tier_for_hours(hours)
    care_unit = TIER_TO_CARE_UNIT.get(paid_tier)
    candidates = schedule_index.get((provider_id or "", county_id or ""), [])
    candidate_ids = {candidate["ext_id"] for candidate in candidates}
    nearby_rates = []
    for rate in fiscal_rates:
        if _text(rate, "idn_fiscal_sch__c") not in candidate_ids:
            continue
        rate_type = _text(rate, "cde_rate_type__c")
        fiscal_rate_type = _fiscal_rate_type(rate_type)
        age_group = _text(rate, "cde_age_group__c") or ""
        rate_care_unit = _text(rate, "cde_care_unit__c")
        score = sum(
            [
                fiscal_rate_type == rate_type_code,
                age_group == age_group_code,
                rate_care_unit == care_unit,
            ]
        )
        nearby_rates.append({
            "schedule_ext_id": _text(rate, "idn_fiscal_sch__c"),
            "rate_type": rate_type,
            "fiscal_rate_type": fiscal_rate_type,
            "age_group": age_group,
            "care_unit": rate_care_unit,
            "amount": _text(rate, "amt_fa__c", "amount"),
            "match_score": score,
        })
    nearby_rates.sort(key=lambda row: row["match_score"], reverse=True)
    return {
        "schedule": {
            "authorization_id": _text(schedule, "CI_Authorization_Id__c", "authorization_id"),
            "authorized_hours": float(hours),
            "schedule_rate_type": schedule_rate_type_code,
            "fiscal_rate_type": rate_type_code,
            "age_group": age_group_code,
            "computed_paid_tier": paid_tier,
            "computed_care_unit": care_unit,
            "service_date": service_date,
            "provider_id": provider_id,
            "county_id": county_id,
        },
        "fiscal_schedule_candidates": [
            {
                "ext_id": candidate.get("ext_id"),
                "rate_types": sorted(candidate.get("rate_types") or []),
                "quality_tier": candidate.get("quality_tier"),
            }
            for candidate in candidates
        ],
        "nearby_fiscal_rates": nearby_rates[:20],
    }


def _ctx(key, default=None):
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


def _schedule_indices(raw_bundle):
    """{(child_id, date): schedule}, {(authorization, date): schedule}, and
    {schedule_id: schedule} -- built from
    the same raw schedulesData.schedules ccare_data_collection already
    fetched, so this task never re-fetches schedules itself."""
    schedules = _as_list((raw_bundle.get("schedulesData") or {}).get("schedules"))
    by_child_date = {}
    by_auth_date = {}
    by_id = {}
    for schedule in schedules:
        child_id = _text(schedule, "CI_Client_Id__c", "child_id")
        schedule_date = _text(schedule, "CI_Authorization_Date__c", "date")
        if schedule_date:
            schedule_date = schedule_date[:10]
        by_child_date.setdefault((str(child_id), schedule_date), schedule)
        auth_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id")
        if auth_ref:
            by_auth_date.setdefault((auth_ref, schedule_date), schedule)
        schedule_id = _text(schedule, "Id", "id")
        if schedule_id:
            by_id[schedule_id] = schedule
    return by_child_date, by_auth_date, by_id


def _correlate():
    analyzer = _ctx("attendance_risks_analyzer_py") or {}
    approaching = analyzer.get("approaching_absence_limits") or []
    unconfirmed = analyzer.get("pending_confirmation_records") or []

    # Phase 0c: zero-risk short-circuit -- STARTER turns always run this
    # correlator (payout_impact_gate's "starter" branch) even when there is
    # nothing to correlate. Skip the fiscal-rate lookup/index build entirely
    # rather than paying for it with an empty result.
    if not approaching and not unconfirmed:
        return {
            "status": "ok", "rows": [], "total_hours_at_risk": 0.0, "total_dollar_at_risk": "0.00",
            "absence_risk_hours": 0.0, "absence_risk_amount": "0.00",
            "unconfirmed_risk_hours": 0.0, "unconfirmed_risk_amount": "0.00",
            "incomplete_risk_hours": 0.0, "incomplete_risk_amount": "0.00",
            "unconfirmed_count": 0, "unconfirmed_children": 0,
        }

    _ref_date = (analyzer.get("reference_date") or "")[:10]
    _lookback = int(analyzer.get("lookback_days") or 9)
    _win_start = None
    try:
        from datetime import date as _ddate, timedelta as _dtd
        _win_start = str(_ddate.fromisoformat(_ref_date) - _dtd(days=_lookback))
    except Exception:
        pass
    if _win_start:
        unconfirmed = [r for r in unconfirmed if (r.get("date") or "") >= _win_start]

    turn_request = _ctx("turnRequest") or {}
    child_filter = {c.lower() for c in (turn_request.get("childNames") or []) if c}
    county_filter = {c.lower() for c in (turn_request.get("countyNames") or []) if c}

    raw_bundle = _ctx("raw_provider_data") or {}
    provider_data = raw_bundle.get("providerData") or {}
    fiscal_agreements = _as_list(_ctx("ccare_provider_data_py.providerDataRaw.fiscalAgreements"))
    authorizations = _as_list((raw_bundle.get("authData") or {}).get("authorizations"))
    auth_by_id = {_text(row, "Id", "id", "ID_AUTH__c", "authorization_id"): row for row in authorizations if _text(row, "Id", "id", "ID_AUTH__c", "authorization_id")}
    auth_by_name = {_text(row, "Name", "name", "NAM_AUTH__c"): row for row in authorizations if _text(row, "Name", "name", "NAM_AUTH__c")}
    by_child_date, by_auth_date, by_id = _schedule_indices(raw_bundle)
    county_rate_plans = _as_list((raw_bundle.get("countyData") or {}).get("countyRatePlans"))
    county_name_by_id = {
        _text(plan, "countyId", "county_id", "CDE_COUNTY__c"): _text(plan, "countyName", "county_name")
        for plan in county_rate_plans
        if _text(plan, "countyId", "county_id", "CDE_COUNTY__c")
    }

    provider_ids = _extract_ids(_as_list(provider_data.get("providers")), "Id", "id")
    fiscal_schedule_ids = []
    for agreement in fiscal_agreements:
        for rs in _as_list(agreement.get("Rate_Schedules__r")):
            fsid = _text(rs, "Id", "id")
            if fsid and fsid not in fiscal_schedule_ids:
                fiscal_schedule_ids.append(fsid)

    payment_data = _ctx("paymentData") or {}
    fiscal_rates = _as_list(payment_data.get("fiscalRates"))
    fiscal_schedules_raw = _as_list(payment_data.get("fiscalSchedules"))

    schedule_index = _fiscal_schedule_index(fiscal_agreements, fiscal_schedules_raw)
    rate_lookup = _rate_lookup(fiscal_rates)

    rows = []
    total_hours = Decimal("0")
    total_dollar = Decimal("0")
    absence_unresolved = False
    unconfirmed_unresolved = False
    schedules = _as_list((raw_bundle.get("schedulesData") or {}).get("schedules"))
    absence_identities = {}
    unconfirmed_identities = {}
    # Phase 4: join instrumentation -- ratio (not just a raw count) shows
    # whether the analyzer/correlator child-id join is actually failing in
    # production, without guessing at a key-normalization "fix" first.
    _join_attempts = 0
    _join_unmatched = 0

    def _skip(child_name, county_name):
        if child_filter and (child_name or "").lower() not in child_filter:
            return True
        if county_filter and county_name and (county_name or "").lower() not in county_filter:
            return True
        return False

    def _risk_identity(schedule, fallback_auth=None, fallback_date=None, fallback_child=None):
        schedule_id = _text(schedule, "Id", "id", "schedule_id")
        if schedule_id:
            return ("schedule", schedule_id)
        auth_id = _text(schedule, "CI_Authorization_Id__c", "authorization_id", "auth_id") or fallback_auth
        service_date = _text(schedule, "CI_Authorization_Date__c", "date") or fallback_date
        child_id = _text(schedule, "IDN_CLIENT__c", "child_id", "childId") or fallback_child
        return ("day", auth_id or child_id or "unknown", service_date or "unknown")

    def _record(child_name, authorization_id, county_name, hours, rate, blocker, reason, category=None, debug=None):
        nonlocal total_hours, total_dollar
        if rate is None:
            rows.append(
                {
                    "child_name": child_name,
                    "authorization_id": authorization_id,
                    "county_name": county_name,
                    "care_hours": float(hours) if hours is not None else None,
                    "amount": None,
                    "amount_type": None,
                    "reason": blocker,
                    "risk_category": category,
                    "rate_debug": debug,
                }
            )
            return
        amount = rate
        total_hours += hours
        total_dollar += amount
        rows.append(
            {
                "child_name": child_name,
                "authorization_id": authorization_id,
                "county_name": county_name,
                "care_hours": float(hours),
                "amount": _money(amount),
                "amount_type": "At-risk",
                "reason": reason,
                "risk_category": category,
                "rate_debug": debug,
            }
        )

    for group in approaching:
        if not isinstance(group, dict):
            continue
        if _skip(group.get("child_name"), group.get("county_name")):
            continue
        limit = int(group.get("absence_limit") or 0)
        confirmed_dates = sorted(group.get("confirmed_absence_dates") or [])
        probable_dates = sorted(group.get("probable_absence_dates") or [])
        # Only dates that exceed the allowed limit carry payment risk.
        # First `limit` confirmed absences are within the paid allowance.
        over_confirmed = confirmed_dates[limit:] if limit > 0 else confirmed_dates
        remaining_capacity = max(0, limit - len(confirmed_dates))
        over_probable = probable_dates[remaining_capacity:]
        dates = over_confirmed + over_probable
        if _win_start:
            dates = [d for d in dates if d and d >= _win_start]
        for absence_date in dates:
            _absence_key = (str(group.get("authorization_id") or group.get("child_id") or ""), absence_date)
            if _absence_key in absence_identities:
                continue
            absence_identities[_absence_key] = 1
            _join_attempts += 1
            schedule = by_auth_date.get((str(group.get("authorization_id")), absence_date))
            if not schedule:
                schedule = by_child_date.get((str(group.get("child_id")), absence_date))
            if not schedule:
                # A missing schedule is not a valid absence or payment day.
                absence_unresolved = True
                _join_unmatched += 1
                continue
            hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours") or Decimal("0")
            authorization = auth_by_id.get(group.get("authorization_id")) or auth_by_name.get(
                _text(schedule, "CI_Authorization_Id__c", "authorization_id")
            ) or {}
            rate, blocker = _resolve_rate_for_schedule(
                schedule, authorization, group.get("county_id"), group.get("provider_id"),
                schedule_index, rate_lookup, hours, absence_date,
            )
            authorization_id = _text(schedule, "CI_Authorization_Id__c", "authorization_id")
            _record(
                group.get("child_name"),
                authorization_id,
                group.get("county_name"),
                hours,
                rate,
                blocker,
                "Absence beyond the confirmed limit is at risk of exclusion from payment",
                "absence",
            )

    for item in unconfirmed:
        if not isinstance(item, dict):
            continue
        if _skip(item.get("child_name"), None):
            continue
        _join_attempts += 1
        schedule = by_id.get(str(item.get("schedule_id")))
        if not schedule:
            # Analyzer records are only actionable when their source schedule
            # still exists in the collected data.
            unconfirmed_unresolved = True
            _join_unmatched += 1
            continue
        identity = _risk_identity(
            schedule,
            fallback_auth=item.get("auth_id"),
            fallback_date=item.get("date"),
            fallback_child=item.get("child_id"),
        )
        if identity in unconfirmed_identities:
            continue
        unconfirmed_identities[identity] = 1
        hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours") or Decimal("0")
        county_id = item.get("county_id") or _text(schedule, "CDE_COUNTY__c")
        provider_id = _text(schedule, "IDN_PROVIDER__c")
        authorization = auth_by_id.get(item.get("auth_id")) or auth_by_name.get(
            _text(schedule, "CI_Authorization_Id__c", "authorization_id")
        ) or {}
        rate, blocker = _resolve_rate_for_schedule(
            schedule, authorization, county_id, provider_id, schedule_index, rate_lookup, hours, item.get("date")
        )
        _record(
            item.get("child_name"),
            item.get("auth_id"),
            county_name_by_id.get(county_id),
            hours,
            rate,
            blocker,
            "Pending parent confirmation -- payment not yet finalized",
            "unconfirmed",
        )

    for schedule in schedules:
        check_in_count = _count_value(schedule, "Check_In_Count__c", "check_in_count", "checkInCount")
        check_out_count = _count_value(schedule, "Check_Out_Count__c", "check_out_count", "checkOutCount")
        if not ((check_in_count > 0 and check_out_count == 0) or (check_out_count > 0 and check_in_count == 0)):
            continue
        service_date = _text(schedule, "CI_Authorization_Date__c", "date")
        if _win_start and service_date and service_date < _win_start:
            continue
        hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours") or Decimal("0")
        authorization_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id")
        authorization = auth_by_name.get(authorization_ref) or auth_by_id.get(authorization_ref) or {}
        child_name = _text(
            authorization.get("IDN_CLIENT__r") if isinstance(authorization, dict) else None,
            "Name", "name", "NAM_FIRST__c",
        ) or _text(schedule, "child_name", "childName")
        # Phase 3 filter-leak fix: this was the only risk-category loop that
        # skipped _skip() entirely -- a scoped request could still aggregate
        # out-of-scope incomplete-attendance rows into the totals.
        _county_name_for_skip = _text(
            authorization.get("CDE_COUNTY__r") if isinstance(authorization, dict) else None, "Name", "name",
        )
        if _skip(child_name, _county_name_for_skip):
            continue
        _join_attempts += 1
        if _risk_identity(
            schedule,
            fallback_auth=authorization_ref,
            fallback_date=service_date,
            fallback_child=_text(schedule, "IDN_CLIENT__c", "child_id", "childId"),
        ) in unconfirmed_identities:
            continue
        county_id = _text(authorization, "CDE_COUNTY__c", "county_id")
        provider_id = _text(schedule, "IDN_PROVIDER__c", "provider_id") or _text(
            authorization, "IDN_PROVR__c", "provider_id"
        )
        rate, blocker = _resolve_rate_for_schedule(
            schedule,
            authorization,
            county_id,
            provider_id,
            schedule_index,
            rate_lookup,
            hours,
            service_date,
        )
        debug = _rate_debug(
            schedule, authorization, county_id, provider_id, schedule_index, fiscal_rates, hours, service_date
        ) if blocker == "fiscal_rate" else None
        _record(
            child_name,
            authorization_ref,
            _text(authorization.get("CDE_COUNTY__r") if isinstance(authorization, dict) else None, "Name", "name"),
            hours,
            rate,
            blocker,
            "Incomplete check-in or check-out -- payment may be withheld",
            "incomplete",
            debug,
        )
        if rows:
            rows[-1]["schedule_id"] = _text(schedule, "Id", "id")
            rows[-1]["date"] = service_date

    absence_hours = Decimal("0")
    absence_dollar = Decimal("0")
    unconfirmed_hours = Decimal("0")
    unconfirmed_dollar = Decimal("0")
    incomplete_hours = Decimal("0")
    incomplete_dollar = Decimal("0")
    incomplete_unresolved = False
    for row in rows:
        hours = _decimal(row.get("care_hours")) or Decimal("0")
        amount = _decimal(row.get("amount")) or Decimal("0")
        if row.get("risk_category") == "absence":
            absence_hours += hours
            absence_dollar += amount
            if row.get("amount") is None:
                absence_unresolved = True
        elif row.get("risk_category") == "unconfirmed":
            unconfirmed_hours += hours
            unconfirmed_dollar += amount
            if row.get("amount") is None and float(row.get("care_hours") or 0) > 0:
                unconfirmed_unresolved = True
        elif row.get("risk_category") == "incomplete":
            incomplete_hours += hours
            incomplete_dollar += amount
            if row.get("amount") is None:
                incomplete_unresolved = True

    return {
        "status": "ok",
        "rows": rows,
        "total_hours_at_risk": float(total_hours),
        "total_dollar_at_risk": _money(total_dollar) if total_dollar else "0.00",
        "absence_risk_hours": None if absence_unresolved else float(absence_hours),
        "absence_risk_amount": None if absence_unresolved else (_money(absence_dollar) if absence_dollar else "0.00"),
        "unconfirmed_risk_hours": None if unconfirmed_unresolved else float(unconfirmed_hours),
        "unconfirmed_risk_amount": None if unconfirmed_unresolved else (_money(unconfirmed_dollar) if unconfirmed_dollar else "0.00"),
        "incomplete_risk_hours": float(incomplete_hours),
        "incomplete_risk_amount": None if incomplete_unresolved else (_money(incomplete_dollar) if incomplete_dollar else "0.00"),
        "unconfirmed_count": len(unconfirmed),
        "unconfirmed_children": len({r.get("child_name") or r.get("child_id") for r in unconfirmed if r.get("child_name") or r.get("child_id")}),
        "diagnostics": {
            "join_attempts": _join_attempts,
            "join_unmatched": _join_unmatched,
            "join_unmatched_ratio": round(_join_unmatched / _join_attempts, 3) if _join_attempts else 0.0,
        },
    }


_impact = _correlate()

_data_result = _ctx("data_collection_result") or {}
_snapshot = (_data_result.get("snapshot") if isinstance(_data_result, dict) else None) or {}
if True:
    _risk_categories = _snapshot.setdefault("risk_categories", {})
    _absence_category = _risk_categories.setdefault("approaching_absence_limits", {})
    _pending_category = _risk_categories.setdefault("pending_parent_confirmations", {})
    _absence_category["potential_loss_hours"] = _impact["absence_risk_hours"]
    _absence_category["potential_loss_amount"] = _impact["absence_risk_amount"]
    _pending_category["potential_loss_hours"] = _impact["unconfirmed_risk_hours"]
    _pending_category["potential_loss_amount"] = _impact["unconfirmed_risk_amount"]
    _pending_category["days"] = _impact.get("unconfirmed_count", 0)
    _pending_category["children"] = _impact.get("unconfirmed_children", 0)
    _incomplete_category = _risk_categories.setdefault("incomplete_attendance", {})
    _incomplete_category["potential_loss_hours"] = _impact["incomplete_risk_hours"]
    _incomplete_category["potential_loss_amount"] = _impact["incomplete_risk_amount"]
    write_context("snapshot", _snapshot)
    _data_result["snapshot"] = _snapshot
    write_context("data_collection_result", _data_result)

write_context("payoutImpactResult", _impact)
respond(_impact, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________