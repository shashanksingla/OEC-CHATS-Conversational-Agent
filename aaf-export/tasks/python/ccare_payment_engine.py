"""_______________Restructured by ai-firstify re-engineer pass_______________

Consolidated payment + attendance-risk + payout-impact calculation engine.

WHY THIS IS STRUCTURED DIFFERENTLY FROM THE PREVIOUS VERSION
--------------------------------------------------------------------------
The previous version computed day-level classification and rate resolution
THREE separate times: once with `date` objects for the payment view, once
with a parallel set of string-date helpers for the attendance-risk view
(`_is_provider_closure_str`, `_months_of_age_str`, ...), and a third time by
re-joining schedules back to rows for the payout-impact view
(`_rated_amount_for_schedule`, `_schedule_indices`) -- even on turns where the
payment view had already resolved those exact rates moments earlier.

All three views are really aggregations of the same underlying fact: for a
given scheduled care day, what's its classification, payable hours, resolved
rate, and risk flags. This version computes that ONCE per turn (the "day
ledger") and expresses payment / attendance-risk / payout-impact as three
small, pure summarizer functions that read off the same ledger. A change to
a classification or rate-resolution rule now only has to happen in one
place.

PUBLIC CONTRACT (unchanged from the previous version, so no other task needs
to change): writes the same context keys (`paymentResult`,
`attendance_risks_analyzer_py`, `payoutImpactResult`, `snapshot`,
`data_collection_result`) with the same field names, except one ADDITIVE
field: `attendance_risks_analyzer_py.incomplete_attendance_records` is new
(previously "incomplete attendance" was only derivable as a side effect of
`payoutImpactResult`, which meant it silently went stale on any turn where
payout-impact hadn't run -- see summarize_attendance_risk()).

Runtime affordances: read_context, write_context, respond.
"""

from datetime import date, timedelta
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from typing import Any, Optional

if "read_context" not in globals():
    def read_context(key):
        return None

if "respond" not in globals():
    def respond(result, **kw):
        return result

if "write_context" not in globals():
    def write_context(key, value):
        return value

log = print

# ==============================================================================
# SECTION 1 -- CONSTANTS
# ==============================================================================

# The previous version declared this same value twice under two different
# names (CONFIRMATION_WINDOW_DAYS for the payment view, lookback_days=9 for
# the attendance-risk view). It is one concept: how many days back a day is
# still "tentative" rather than "confirmed" for both limit-counting and
# confirmation-risk purposes.
RISK_WINDOW_DAYS = 9
NEAR_LIMIT_THRESHOLD = 1

MONEY_QUANTUM = Decimal("0.01")
PAID_TIERS = (
    (Decimal("0"), "NO_PAYMENT"),
    (Decimal("5"), "PART_TIME"),
    (Decimal("12"), "FULL_TIME"),
    (Decimal("17"), "FULL_TIME_PLUS_PART_TIME"),
)
CARE_UNIT_TO_TIER = {
    "1": "NO_PAYMENT", "2": "PART_TIME", "3": "FULL_TIME",
    "4": "FULL_TIME_PLUS_PART_TIME", "5": "FULL_TIME_PLUS_FULL_TIME",
}
TIER_TO_CARE_UNIT = {tier: code for code, tier in CARE_UNIT_TO_TIER.items()}
AGE_GROUP_MONTH_BOUNDS = ((6, "1"), (12, "2"), (18, "3"), (24, "4"), (30, "5"), (36, "6"), (60, "7"))

RATE_TYPE_LABELS = {
    "1": "Regular", "2": "Regular Tier 1", "3": "Regular Tier 2", "4": "Regular Tier 3",
    "5": "Regular Tier 4", "6": "Regular Tier 5", "8": "School Age Tier 1", "9": "School Age Tier 2",
    "10": "School Age Tier 3", "13": "Before School", "14": "Before School Tier 1",
    "15": "Before School Tier 2", "16": "Before School Tier 3", "17": "Before School Tier 4",
    "18": "Before School Tier 5", "19": "After School", "20": "After School Tier 1",
    "21": "After School Tier 2", "22": "After School Tier 3", "23": "After School Tier 4",
    "24": "After School Tier 5", "25": "B and A School", "26": "B and A School Tier 1",
    "27": "B and A School Tier 2", "28": "B and A School Tier 3", "29": "B and A School Tier 4",
    "30": "B and A School Tier 5", "31": "Overnight", "32": "Overnight Tier 1",
    "33": "Overnight Tier 2", "37": "Weekend", "38": "Weekend Tier 1", "39": "Weekend Tier 2",
    "40": "Weekend Tier 3", "41": "Weekend Tier 4", "42": "Weekend Tier 5", "43": "Evening",
    "44": "Evening Tier 1", "45": "Evening Tier 2", "46": "Evening Tier 3", "47": "Evening Tier 4",
    "48": "Evening Tier 5", "49": "Alternate", "50": "Alternate Tier 1", "51": "Alternate Tier 2",
    "52": "Alternate Tier 3", "53": "Alternate Tier 4", "55": "Disability", "56": "Disability Tier 1",
    "57": "Disability Tier 2", "58": "Disability Tier 3", "59": "Disability Tier 4",
    "60": "Disability Tier 5", "61": "Disability Alternative", "62": "Disability Alternative Tier 1",
    "63": "Disability Alternative Tier 2", "64": "Disability Alternative Tier 3", "67": "At-Risk",
    "73": "Sick Care", "74": "Sick Care Tier 1", "75": "Sick Care Tier 2", "79": "Wraparound",
    "80": "Wraparound Tier 1", "81": "Wraparound Tier 2", "82": "Wraparound Tier 3",
    "83": "Wraparound Tier 4", "84": "Wraparound Tier 5", "85": "Experience FCCH",
    "86": "Experience FCCH Tier 1", "88": "Experience FCCH Tier 3", "91": "Out-of-County",
    "92": "Out-of-County Tier 1", "93": "Out-of-County Tier 2", "100": "Care Not Offered",
}
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
PARENT_PENDING = "PARENT_PENDING"


# ==============================================================================
# SECTION 2 -- LOW-LEVEL FIELD HELPERS (unchanged from the previous version --
# these were already single, non-duplicated utilities)
# ==============================================================================

def _text(row, *keys):
    if not isinstance(row, dict):
        return None
    for key in keys:
        value = row.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return None


def _number(row, *keys):
    if not isinstance(row, dict):
        return None
    for key in keys:
        value = _decimal(row.get(key))
        if value is not None and value >= 0:
            return value
    return None


def _decimal(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return parsed if parsed.is_finite() else None


def _date(row, *keys):
    value = _text(row, *keys)
    if not value:
        return None
    try:
        return date.fromisoformat(value[:10])
    except ValueError:
        return None


def _truthy(row, *keys):
    value = _text(row, *keys)
    return value is not None and value.lower() in {"true", "1", "yes", "y"}


def _int_or_none(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _money(value):
    if value is None:
        value = Decimal("0")
    return format(value.quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


def _records(value):
    if isinstance(value, list):
        return [r for r in value if isinstance(r, dict)]
    if not isinstance(value, dict):
        return []
    for key in ("records", "data", "results", "items", "servicePeriods", "authorizations",
                "schedules", "fiscalRates", "paymentHistory", "countyRatePlans"):
        nested = value.get(key)
        if isinstance(nested, list):
            return [r for r in nested if isinstance(r, dict)]
    return [value] if any(k in value for k in ("Id", "id", "Name", "name")) else []


def _first(mapping, *keys):
    for key in keys:
        if key in mapping and mapping[key] is not None:
            return mapping[key]
    return None


def _unique_index(records, *keys):
    grouped: dict[str, list] = {}
    for row in records:
        k = _text(row, *keys)
        if k:
            grouped.setdefault(k, []).append(row)
    return {k: rows[0] for k, rows in grouped.items() if len(rows) == 1}


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


def paid_tier_for_hours(hours) -> str:
    value = _decimal(hours)
    if value is None or value <= 0:
        return "NO_PAYMENT"
    for boundary, tier in PAID_TIERS[1:]:
        if value <= boundary:
            return tier
    return "FULL_TIME_PLUS_FULL_TIME"


def _fiscal_rate_type(value):
    code = str(value or "").strip()
    return RATE_TYPE_BASE_CODES.get(code, code)


def _normalize_tier(value) -> str:
    """Normalize schedule/provider tier values for shared limit calculations.

    NOTE (flagged, not changed): live sample data confirms providers carry
    values like "Level 2" here, and this function maps "LEVEL n" -> tier
    str(n+1) while "TIER n" maps to tier str(n) with no shift. That asymmetry
    is preserved exactly from the previous version since it may encode an
    intentional mapping between two rating conventions -- confirm with
    whoever owns the county rate-plan mapping before changing it, since it
    changes which absence-day limit applies.
    """
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


# ==============================================================================
# SECTION 3 -- INDICES (built once per turn from the raw fetched data)
# ==============================================================================

def build_county_policy_index(county_rate_plans):
    """Index county rate plans by county ID for absence/drop-in limit enforcement."""
    index = {}
    for plan in county_rate_plans:
        if not isinstance(plan, dict):
            continue
        county_id = _text(plan, "countyId", "county_id", "IDN_COUNTY__c")
        if not county_id:
            continue
        index[county_id] = {
            "county_name": _text(plan, "countyName", "county_name", "Name"),
            "absence_limits": {
                "1": _int_or_none(plan.get("absenceDaysTier1")),
                "2": _int_or_none(plan.get("absenceDaysTier2")),
                "3": _int_or_none(plan.get("absenceDaysTier3")),
                "4": _int_or_none(plan.get("absenceDaysTier4")),
                "5": _int_or_none(plan.get("absenceDaysTier5")),
            },
            "allow_drop_in_days": plan.get("allowDropInDays"),
            "max_drop_in_days_per_month": _int_or_none(plan.get("maxDropInDaysPerMonth")),
            # Live getCountyData samples show this as semicolon-separated
            # numeric codes (e.g. "1;4;5;6;9;10"), not names -- named
            # `holiday_codes` (not `holiday_names` as before) for honesty.
            # Matching logic is unchanged: compared against holiday records'
            # CDE_HOL__c, which appears to use the same code convention.
            "holiday_codes": {
                n.strip().upper() for n in (plan.get("countyholidayList") or "").split(";") if n.strip()
            },
        }
    return index


def build_fiscal_schedule_index(fiscal_agreements, fiscal_schedules):
    """Index fiscal schedules by provider, county, rate types, and quality tier."""
    agreement_scope = {}
    for agreement in fiscal_agreements:
        if not isinstance(agreement, dict):
            continue
        agreement_id = _text(agreement, "Id", "IDN_EXTNL__c")
        provider_id = _text(agreement, "ID_SERVICE__c", "provider_id")
        county_id = _text(agreement, "CDE_COUNTY__c", "county_id")
        if agreement_id and provider_id and county_id:
            agreement_scope[agreement_id] = (provider_id, county_id)

    index: dict[tuple, list] = {}

    def _add_schedule(rs, provider_id, county_id):
        if not isinstance(rs, dict) or not provider_id or not county_id:
            return
        ext_id = _text(rs, "IDN_EXTNL__c", "Id")
        if not ext_id:
            return
        rate_type_raw = _text(rs, "CDE_RATE_TYPE__c") or ""
        rate_types = {token.strip() for token in rate_type_raw.split(";") if token.strip()}
        quality_tier = _text(rs, "TXT_CHATS_RATING__c")
        index.setdefault((provider_id, county_id), []).append({
            "ext_id": ext_id, "rate_types": rate_types, "quality_tier": quality_tier,
        })

    for agreement in fiscal_agreements:
        if not isinstance(agreement, dict):
            continue
        provider_id = _text(agreement, "ID_SERVICE__c", "provider_id")
        county_id = _text(agreement, "CDE_COUNTY__c", "county_id")
        for rs in _records(agreement.get("Rate_Schedules__r")):
            _add_schedule(rs, provider_id, county_id)

    for rs in fiscal_schedules:
        if not isinstance(rs, dict):
            continue
        agreement_id = _text(rs, "IDN_AGRMT_FISCAL__c")
        scope = agreement_scope.get(agreement_id or "")
        if scope:
            _add_schedule(rs, scope[0], scope[1])

    return index


def build_rate_lookup(fiscal_rates):
    """Index raw fiscal-rate rows by schedule, type, age group, and care unit."""
    lookup = {}
    for rate in fiscal_rates:
        if not isinstance(rate, dict):
            continue
        ext_id = _text(rate, "idn_fiscal_sch__c")
        rate_type = _text(rate, "cde_rate_type__c")
        age_group = _text(rate, "cde_age_group__c") or ""
        care_unit = _text(rate, "cde_care_unit__c")
        amount = _number(rate, "amt_fa__c", "amount")
        if not ext_id or not rate_type or not care_unit or amount is None:
            continue
        lookup.setdefault((ext_id, rate_type, age_group, care_unit), amount)
    return lookup


def build_auth_indices(authorizations):
    return (
        _unique_index(authorizations, "Name", "name", "NAM_AUTH__c", "authorization_name"),
        _unique_index(authorizations, "Id", "id", "ID_AUTH__c", "authorization_id"),
    )


# ==============================================================================
# SECTION 4 -- SHARED DAY-LEVEL RULES
# One date-based implementation each (the previous version duplicated these
# with a parallel string-date variant for the attendance-risk view).
# ==============================================================================

def is_provider_closure(closures, provider_id, county_id, service_date):
    for closure in closures:
        if not isinstance(closure, dict) or not _truthy(closure, "IND_ACTIVE__c", "active"):
            continue
        closure_provider = _text(closure, "IDN_PROVIDER__c", "provider_id")
        closure_county = _text(closure, "CDE_COUNTY__c", "county_id")
        if provider_id and closure_provider and closure_provider != provider_id:
            continue
        if county_id and closure_county and closure_county != county_id:
            continue
        if _date(closure, "DTE_BEGIN_CLOSURE__c", "closure_date") == service_date:
            return True
    return False


def is_county_holiday(holidays, service_date, county_holiday_codes):
    if not county_holiday_codes:
        return False
    for h in holidays:
        if _date(h, "DTE_HOL__c", "DTE_OBSERVED_HOL__c", "holiday_date", "date") != service_date:
            continue
        h_code = _text(h, "CDE_HOL__c")
        if h_code and h_code.strip().upper() in county_holiday_codes:
            return True
    return False


def months_of_age(dob: Optional[date], on_date: Optional[date]) -> Optional[int]:
    if not dob or not on_date:
        return None
    months = (on_date.year - dob.year) * 12 + (on_date.month - dob.month)
    if on_date.day < dob.day:
        months -= 1
    return max(months, 0)


def age_group_code_for(dob, service_date):
    months = months_of_age(dob, service_date)
    if months is None:
        return None
    for bound, code in AGE_GROUP_MONTH_BOUNDS:
        if months < bound:
            return code
    return "8"


def classify_day(closures, provider_id, county_id, service_date, authorized_hours, attended_hours,
                  holidays, as_of_date, county_holiday_codes):
    if is_provider_closure(closures, provider_id, county_id, service_date):
        return "CARE_NOT_OFFERED"
    if authorized_hours == 0:
        return "DROP_IN" if attended_hours > 0 else "NO_CARE"
    if attended_hours > 0:
        return "REGULAR"
    if is_county_holiday(holidays, service_date, county_holiday_codes or set()):
        return "HOLIDAY"
    if as_of_date is not None and service_date > as_of_date:
        return "FORECAST"
    return "ABSENCE"


def payable_hours_for(classification, authorized, attended):
    if classification in {"HOLIDAY", "ABSENCE", "ENROLLMENT_ABSENCE", "FORECAST"}:
        return authorized
    if classification == "DROP_IN":
        return attended
    return min(authorized, attended)


def attended_hours_from(schedule):
    """Treat paired zero check-in/out counts as confirmed zero attendance."""
    direct = _number(schedule, "attended_hours", "Hours__c", "unit_hours")
    if direct is not None:
        return direct
    check_in = _number(schedule, "Check_In_Count__c", "check_in")
    check_out = _number(schedule, "Check_Out_Count__c", "check_out")
    if check_in is None or check_out is None or check_out < check_in:
        return None
    return check_out - check_in


def child_dob_of(authorization):
    client = authorization.get("IDN_CLIENT__r") if isinstance(authorization, dict) else None
    return _date(client, "DTE_DOB__c", "dob") if isinstance(client, dict) else None


def quality_tier_for(authorization, rate_type_code, fiscal_schedule_index):
    provider_id = _text(authorization, "IDN_PROVR__c")
    county_id = _text(authorization, "CDE_COUNTY__c")
    fiscal_rate_type = _fiscal_rate_type(rate_type_code)
    for candidate in fiscal_schedule_index.get((provider_id or "", county_id or ""), []):
        candidate_types = {_fiscal_rate_type(v) for v in candidate["rate_types"]}
        if not candidate_types or (fiscal_rate_type and fiscal_rate_type in candidate_types):
            if candidate.get("quality_tier"):
                return candidate["quality_tier"]
    return None


def resolve_attended_rate(authorization, rate_type_code, age_group_code, payable_hours,
                           fiscal_schedule_index, rate_lookup):
    if not age_group_code:
        return None, "age_group_code_unresolved"
    fiscal_rate_type = _fiscal_rate_type(rate_type_code)
    care_unit = TIER_TO_CARE_UNIT.get(paid_tier_for_hours(payable_hours))
    if care_unit is None:
        return None, "care_unit_mapping_unconfirmed"
    provider_id = _text(authorization, "IDN_PROVR__c")
    county_id = _text(authorization, "CDE_COUNTY__c")
    candidates = fiscal_schedule_index.get((provider_id or "", county_id or ""), [])
    if not candidates:
        return None, "fiscal_schedule"
    no_payment_unit = TIER_TO_CARE_UNIT["NO_PAYMENT"]
    for candidate in candidates:
        candidate_types = {_fiscal_rate_type(v) for v in candidate["rate_types"]}
        if fiscal_rate_type and candidate_types and fiscal_rate_type not in candidate_types:
            continue
        amount = rate_lookup.get((candidate["ext_id"], fiscal_rate_type, age_group_code, care_unit))
        if amount is not None:
            return amount, None
        if rate_lookup.get((candidate["ext_id"], fiscal_rate_type, age_group_code, no_payment_unit)) is not None:
            return Decimal("0"), None
    return None, "fiscal_rate"


def _existing_payment_amount(records, period_id):
    total = None
    for record in records:
        record_period = _text(record, "idn_period_serv__c", "service_period_id", "ServicePeriodId", "ID_SERVICE_PERIOD__c")
        status = _text(record, "cde_status_pmt_sub__c", "status", "Status__c")
        if record_period != period_id or status not in {"PAID", "REQUESTED"}:
            continue
        amount = _number(record, "amt_total_pmt_sub__c", "amount", "Amount__c", "AMT_PMT__c", "paid_amount")
        if amount is not None:
            total = (total or Decimal("0")) + amount
    return total


def _select_period_or_candidates(records, requested_id):
    if requested_id is not None:
        requested = str(requested_id)
        matches = [r for r in records if _text(r, "servicePeriodId", "Id", "id", "service_period_id") == requested]
    else:
        matches = list(records)
    if len(matches) == 1:
        return matches[0], None
    if len(matches) >= 2:
        candidates = []
        for row in matches:
            period_id = _text(row, "servicePeriodId", "Id", "id", "service_period_id")
            start = _date(row, "serviceBeginDate", "Start_Date__c", "DTE_START__c", "start_date", "startDate")
            end = _date(row, "serviceEndDate", "End_Date__c", "DTE_END__c", "end_date", "endDate")
            label = f"{start.isoformat()} to {end.isoformat()}" if start and end else (period_id or "unknown period")
            candidates.append({"id": period_id, "label": label})
        return None, candidates
    return None, None


def _select_last_released_period(periods):
    today = date.today()
    released = [(r, p) for p in periods if (r := _date(p, "paymentReleaseDate", "DTE_BATCH_FILE_PMT__c", "release_date")) and r <= today]
    if not released:
        return None
    released.sort(key=lambda pair: pair[0], reverse=True)
    return released[0][1]


def _select_next_upcoming_period(periods):
    today = date.today()
    upcoming = [(r, p) for p in periods if (r := _date(p, "paymentReleaseDate", "DTE_BATCH_FILE_PMT__c", "release_date")) and r >= today]
    if not upcoming:
        return None
    upcoming.sort(key=lambda pair: pair[0])
    return upcoming[0][1]


def _periods_overlapping(periods, window_start, window_end):
    result = []
    for period in periods:
        begin = _date(period, "serviceBeginDate", "DTE_BEGIN_EFFV__c", "Start_Date__c")
        end = _date(period, "serviceEndDate", "DTE_END_EFFV__c", "End_Date__c")
        if begin is not None and end is not None and begin <= window_end and end >= window_start:
            result.append(period)
    return result


def _status_from_remaining(confirmed_remaining, potential_remaining, tentative_used, threshold):
    if confirmed_remaining < 0:
        return "OVER_LIMIT"
    if potential_remaining < 0:
        return "POTENTIAL_OVER_LIMIT"
    if tentative_used > 0 and potential_remaining <= threshold and confirmed_remaining > threshold:
        return "POTENTIAL_APPROACHING_LIMIT"
    return "APPROACHING_LIMIT"


def _blocked(blockers):
    return {
        "status": "blocked", "rows": [], "total_amount": "0.00", "attended_care_amount": "0.00",
        "vacant_slot_amount": "0.00", "amount_at_risk": "0.00", "at_risk_day_count": 0,
        "potential_total_amount": "0.00", "service_period_start": None, "service_period_end": None,
        "payment_release_date": None, "blockers": blockers,
    }


# ==============================================================================
# SECTION 5 -- THE DAY LEDGER (the core reusability win)
# One pass over schedules -> one record per scheduled care day, carrying
# classification, resolved rate, and every risk flag every downstream view
# needs. Absence/drop-in monthly grouping is a second (still single) pass.
# ==============================================================================

def build_day_ledger(schedules, auth_by_name, auth_by_id, closures, holidays,
                      county_policy_by_id, fiscal_schedule_index, rate_lookup, as_of_date):
    records = []
    for schedule in schedules:
        if not isinstance(schedule, dict):
            continue
        service_date = _date(schedule, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c",
                              "service_date", "schedule_date", "date")
        if not service_date:
            continue

        auth_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id", "AuthorizationId", "IDN_AUTH__c", "auth_id")
        authorization = (auth_by_name.get(auth_ref) if auth_ref else None) or (auth_by_id.get(auth_ref) if auth_ref else None)
        auth_id = _text(authorization, "Id", "id", "ID_AUTH__c", "authorization_id") if authorization else None

        rec = {
            "schedule_id": _text(schedule, "Id", "id"),
            "service_date": service_date,
            "auth_id": auth_id,
            # Salesforce object ID (used for lookups/joins only). The
            # human-facing reference shown in attendance-risk/payout-impact
            # tables is `auth_ref` below -- the schedule's own
            # CI_Authorization_Id__c (e.g. "963383"), which is what
            # providers actually recognize. Conflating the two was a
            # regression: it showed the opaque Salesforce ID instead.
            "auth_ref": auth_ref or auth_id,
            "status_ok": True,
            "blocker": None,
            "limit_blocker": None,
            "rate_blocker": None,
            "is_pending_confirmation": False,
            "is_incomplete_checkinout": False,
            "confirmation_risk": None,
        }

        if authorization is None or not auth_id:
            rec.update(status_ok=False, blocker="authorization_relationship", classification=None,
                       child_name=None, county_id=None, county_name=None, payable_hours=Decimal("0"), rate=None)
            records.append(rec)
            continue

        authorized_hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours", "authorization_hours", "hours")
        attended_hours = attended_hours_from(schedule)
        if attended_hours is None and service_date > as_of_date:
            attended_hours = Decimal("0")

        rec.update({
            "auth_name": _text(authorization, "Name"),
            "child_id": _text(authorization, "IDN_CLIENT__c"),
            "child_name": (
                _text(authorization.get("IDN_CLIENT__r") or {}, "Name", "NAM_FIRST__c")
                # Live getAuthData samples only return Id + DTE_DOB__c on
                # IDN_CLIENT__r -- Contact_Name__c on the schedule itself is
                # the field that actually carries the human-readable name.
                or _text(schedule, "Contact_Name__c", "childName", "child_name", "clientName", "client_name")
            ),
            "county_id": _text(authorization, "county_id", "CDE_COUNTY__c", "countyId"),
            "provider_id": _text(authorization, "IDN_PROVR__c", "provider_id"),
        })
        rec["county_name"] = (county_policy_by_id.get(rec["county_id"] or "", {}) or {}).get("county_name")

        if authorized_hours is None or attended_hours is None:
            rec.update(status_ok=False, blocker="attendance_hours", classification=None,
                       payable_hours=Decimal("0"), rate=None)
            records.append(rec)
            continue

        county_holiday_codes = (county_policy_by_id.get(rec["county_id"] or "", {}) or {}).get("holiday_codes") or set()
        classification = classify_day(closures, rec["provider_id"], rec["county_id"], service_date,
                                       authorized_hours, attended_hours, holidays, as_of_date, county_holiday_codes)

        age_months = months_of_age(child_dob_of(authorization), service_date)
        if classification == "ABSENCE" and age_months is not None and age_months <= 36:
            classification = "ENROLLMENT_ABSENCE"

        rate_type_code = (
            _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
            or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
        )
        age_group_code = (
            _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code")
            or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c")
            or age_group_code_for(child_dob_of(authorization), service_date)
        )
        quality_tier_raw = (
            quality_tier_for(authorization, rate_type_code, fiscal_schedule_index)
            or _text(schedule, "quality_tier", "TXT_CHATS_RATING__c")
            or _text(authorization, "quality_tier", "TXT_CHATS_RATING__c")
        )
        payable_hours = payable_hours_for(classification, authorized_hours, attended_hours)

        attendance = schedule.get("Attendance__r") if isinstance(schedule, dict) else None
        att_records = (attendance.get("records") if isinstance(attendance, dict) else None) or []
        is_pending = any(_text(r, "Status__c") == PARENT_PENDING for r in att_records if isinstance(r, dict))
        check_in_count = int(_number(schedule, "Check_In_Count__c", "check_in_count", "checkInCount") or 0)
        check_out_count = int(_number(schedule, "Check_Out_Count__c", "check_out_count", "checkOutCount") or 0)
        is_incomplete = (check_in_count > 0 and check_out_count == 0) or (check_out_count > 0 and check_in_count == 0)

        confirmation_risk = None
        if classification not in {"HOLIDAY", "ENROLLMENT_ABSENCE"} and service_date <= as_of_date \
                and 0 <= (as_of_date - service_date).days <= RISK_WINDOW_DAYS:
            if is_pending:
                confirmation_risk = "PENDING_CONFIRMATION"
            elif not att_records:
                confirmation_risk = "MISSING_ATTENDANCE"

        rec.update({
            "classification": classification,
            "rate_type_code": rate_type_code,
            "age_group_code": age_group_code,
            "quality_tier": _normalize_tier(quality_tier_raw),
            "payable_hours": payable_hours,
            "is_pending_confirmation": is_pending,
            "is_incomplete_checkinout": is_incomplete,
            "confirmation_risk": confirmation_risk,
            "is_tentative": service_date <= as_of_date and 0 <= (as_of_date - service_date).days <= RISK_WINDOW_DAYS,
        })

        if classification in {"CARE_NOT_OFFERED", "NO_CARE"} or payable_hours <= 0:
            rec.update(rate=None)
        else:
            rate, rate_blocker = resolve_attended_rate(authorization, rate_type_code, age_group_code,
                                                        payable_hours, fiscal_schedule_index, rate_lookup)
            rec.update(rate=rate, rate_blocker=rate_blocker)

        records.append(rec)

    absence_groups = _group_absence_and_drop_in(records, county_policy_by_id)
    return {"records": records, "absence_groups": absence_groups}


def _group_absence_and_drop_in(records, county_policy_by_id):
    """Single pass that both (a) groups absence days per auth+month into
    confirmed/probable buckets (feeds the attendance-risk view) and (b)
    annotates each record with the limit blocker payment needs.

    PRODUCT DECISION (confirmed from the previous version, not changed here):
    once an auth+month's TOTAL non-exempt absence-day count exceeds the
    county's tier limit, EVERY absence day that auth/month is blocked from
    payment -- not just the days past the threshold. Drop-in follows the
    same "total count vs max" rule with no confirmed/tentative split.
    """
    groups: dict[tuple, dict] = {}
    for rec in records:
        if rec.get("classification") not in {"ABSENCE", "DROP_IN"} or not rec.get("auth_id") or rec.get("is_pending_confirmation"):
            continue
        key = (rec.get("auth_ref") or rec["auth_id"], rec["service_date"].strftime("%Y-%m"))
        group = groups.setdefault(key, {
            "confirmed": [], "probable": [], "drop_in": [],
            "county_id": rec.get("county_id"), "tier": rec.get("quality_tier"),
        })
        if rec["classification"] == "ABSENCE":
            (group["probable"] if rec.get("is_tentative") else group["confirmed"]).append(rec)
        else:
            group["drop_in"].append(rec)

    for group in groups.values():
        policy = county_policy_by_id.get(group["county_id"] or "", {}) or {}
        absence_limit = (policy.get("absence_limits") or {}).get(group["tier"])
        total_absence = len(group["confirmed"]) + len(group["probable"])
        for rec in group["confirmed"] + group["probable"]:
            if not isinstance(absence_limit, int):
                rec["limit_blocker"] = "absence_limit_unavailable"
            elif total_absence > absence_limit:
                rec["limit_blocker"] = "absence_limit_exceeded"

        max_drop_in = policy.get("max_drop_in_days_per_month")
        allow_drop_in = policy.get("allow_drop_in_days")
        for rec in group["drop_in"]:
            # Live getCountyData returns "Y"/"N" strings here, never a
            # Python bool -- comparing against the string is what actually
            # lets this guardrail fire (the previous version's `is False`
            # check could never match a string and never blocked anything).
            if isinstance(allow_drop_in, str) and allow_drop_in.strip().upper() == "N":
                rec["limit_blocker"] = "drop_in_not_allowed"
            elif isinstance(max_drop_in, int) and len(group["drop_in"]) > max_drop_in:
                rec["limit_blocker"] = "drop_in_limit_exceeded"

    return groups


# ==============================================================================
# SECTION 6 -- PAYMENT VIEW (period-scoped aggregation over the ledger)
# ==============================================================================

def _payment_row_from_ledger_record(rec):
    if not rec.get("status_ok", True):
        return {"kind": "ATTENDED_CARE", "service_date": rec["service_date"].isoformat(),
                "status": "blocked", "blocker": rec.get("blocker"), "amount": "0.00"}

    classification = rec.get("classification")
    if classification == "NO_CARE":
        return None  # No care, no row -- matches the previous version's `continue`.

    base = {
        "kind": "ATTENDED_CARE", "service_date": rec["service_date"].isoformat(),
        "authorization_id": rec.get("auth_id"), "authorization_name": rec.get("auth_name"),
        "child_name": rec.get("child_name"), "county_id": rec.get("county_id"),
        "county_name": rec.get("county_name"), "classification": classification,
    }
    if rec.get("limit_blocker"):
        return {**base, "payable_hours": _money(Decimal("0")), "amount": "0.00",
                "status": "not_payable", "blocker": rec["limit_blocker"]}
    if classification == "CARE_NOT_OFFERED" or (rec.get("payable_hours") or Decimal("0")) <= 0:
        return {**base, "payable_hours": _money(Decimal("0")), "amount": "0.00", "status": "not_payable"}
    if rec.get("rate") is None:
        return {**base, "status": "blocked", "blocker": rec.get("rate_blocker"), "amount": "0.00",
                "paid_tier": paid_tier_for_hours(rec.get("payable_hours")),
                "rate_type_label": RATE_TYPE_LABELS.get(rec.get("rate_type_code") or "", rec.get("rate_type_code"))}

    basis = "scheduled" if classification in {"HOLIDAY", "FORECAST"} else "attended"
    row = {
        **base,
        "rate_type_label": RATE_TYPE_LABELS.get(rec.get("rate_type_code") or "", rec.get("rate_type_code")),
        "payment_basis": basis, "paid_tier": paid_tier_for_hours(rec["payable_hours"]),
        "payable_hours": _money(rec["payable_hours"]), "rate": _money(rec["rate"]), "amount": _money(rec["rate"]),
        "status": "at_risk" if rec.get("confirmation_risk") else "calculated",
    }
    if rec.get("confirmation_risk"):
        row["confirmation_risk"] = rec["confirmation_risk"]
    return row


def _vacant_slot_rows(vacant_slots, period_start, period_end, holidays, closures, county_policy_by_id,
                       fiscal_schedule_index, rate_lookup):
    rows, blockers = [], []
    for slot in vacant_slots:
        if not isinstance(slot, dict):
            continue
        slot_county_id = _text(slot, "CDE_COUNTY__c")
        county_holiday_codes = (county_policy_by_id.get(slot_county_id or "", {}) or {}).get("holiday_codes") or set()
        allowed_weekdays = {t.strip().upper() for t in (_text(slot, "CNT_DAYS_OF_WEEK__c") or "").split(";") if t.strip()}
        monthly_limit = _int_or_none(slot.get("CNT_DAYS_OF_MONTH__c"))
        provider_id = _text(slot, "IDN_PROVIDER__c")
        begin = _date(slot, "DTE_BEGIN_SLOT__c")
        end = _date(slot, "DTE_END_SLOT__c")
        if not begin or not end:
            continue

        def _eligible(d):
            if allowed_weekdays and d.strftime("%A").upper() not in allowed_weekdays:
                return False
            if is_provider_closure(closures, provider_id, slot_county_id, d):
                return False
            if is_county_holiday(holidays, d, county_holiday_codes):
                return False
            return True

        segment_start = max(begin, period_start)
        payable, excluded = [], []
        while segment_start <= min(end, period_end):
            month_start, month_end = _month_bounds(segment_start, 0)
            segment_end = min(period_end, end, month_end)
            days = []
            d = segment_start
            while d <= segment_end:
                if _eligible(d):
                    days.append(d)
                d += timedelta(days=1)
            if monthly_limit is None:
                payable.extend(days)
            else:
                prior_end = segment_start - timedelta(days=1)
                prior_count = 0
                if prior_end >= month_start:
                    pd = month_start
                    while pd <= prior_end:
                        if _eligible(pd):
                            prior_count += 1
                        pd += timedelta(days=1)
                remaining = max(monthly_limit - prior_count, 0)
                payable.extend(days[:remaining])
                excluded.extend(days[remaining:])
            segment_start = month_end + timedelta(days=1)

        # County name: prefer the county rate-plan index, but fall back to the
        # slot's own embedded CDE_COUNTY__r.Name -- vacant slots can exist for
        # a county the provider has no active fiscal AGREEMENT in (getCountyData
        # is scoped off agreements), which otherwise left this blank even
        # though the slot record itself carries the name.
        slot_county_name = ((county_policy_by_id.get(slot_county_id or "", {}) or {}).get("county_name")
                             or _text(slot.get("CDE_COUNTY__r") or {}, "Name", "name"))
        for d in excluded:
            rows.append({"kind": "VACANT_SLOT", "service_date": d.isoformat(), "status": "blocked",
                         "blocker": "vacant_slot_monthly_cap_exceeded", "amount": "0.00",
                         "county_id": slot_county_id, "county_name": slot_county_name})
            blockers.append("vacant_slot_monthly_cap_exceeded")
        rate_type = _text(slot, "CDE_RATE_TYPE__c")
        care_unit = _text(slot, "CDE_CARE_UNIT__c")
        care_level = _text(slot, "CDE_CARE_LEVEL__c")
        for d in payable:
            amount, blocker = None, "vacant_slot_rate_fields"
            if rate_type and care_unit and care_level:
                for candidate in fiscal_schedule_index.get((provider_id or "", slot_county_id or ""), []):
                    if candidate["rate_types"] and rate_type not in candidate["rate_types"]:
                        continue
                    amount = rate_lookup.get((candidate["ext_id"], rate_type, care_level, care_unit))
                    if amount is not None:
                        blocker = None
                        break
            if amount is None:
                rows.append({"kind": "VACANT_SLOT", "service_date": d.isoformat(), "status": "blocked",
                             "blocker": blocker, "amount": "0.00", "county_id": slot_county_id, "county_name": slot_county_name})
                blockers.append(blocker)
            else:
                rows.append({"kind": "VACANT_SLOT", "service_date": d.isoformat(), "amount": _money(amount),
                             "status": "calculated", "county_id": slot_county_id, "county_name": slot_county_name})
    return rows, blockers


def summarize_period(ledger, period, payment_history, vacant_slots, holidays, closures, county_policy_by_id,
                      fiscal_schedule_index, rate_lookup):
    period_id = _text(period, "servicePeriodId", "Id", "id", "ID_SERVICE_PERIOD__c", "service_period_id")
    start = _date(period, "serviceBeginDate", "Start_Date__c", "DTE_START__c", "start_date", "startDate", "period_start")
    end = _date(period, "serviceEndDate", "End_Date__c", "DTE_END__c", "end_date", "endDate", "period_end")
    if not period_id or not start or not end or end < start:
        return _blocked(["service_period_dates"])

    existing_amount = _existing_payment_amount(payment_history, period_id)
    if existing_amount is not None:
        return {
            "status": "ok", "service_period_id": period_id, "service_period_start": start.isoformat(),
            "service_period_end": end.isoformat(), "payment_release_date": _text(period, "paymentReleaseDate"),
            "payment_history_found": True, "rows": [], "total_amount": _money(existing_amount),
            "attended_care_amount": _money(existing_amount), "vacant_slot_amount": "0.00",
            "amount_at_risk": "0.00", "at_risk_day_count": 0, "potential_total_amount": _money(existing_amount),
            "blockers": [], "settlement_source": "ACTUAL_PAYMENT_RECORD", "settlement_scope": "PERIOD_WIDE",
        }

    rows, blockers = [], []
    for rec in sorted(ledger["records"], key=lambda r: r["service_date"]):
        if not (start <= rec["service_date"] <= end):
            continue
        row = _payment_row_from_ledger_record(rec)
        if row is None:
            continue
        rows.append(row)
        if row["status"] == "blocked":
            blockers.append(row["blocker"])

    vacant_rows, vacant_blockers = _vacant_slot_rows(vacant_slots, start, end, holidays, closures,
                                                      county_policy_by_id, fiscal_schedule_index, rate_lookup)
    rows.extend(vacant_rows)
    blockers.extend(vacant_blockers)

    calculated_rows = [r for r in rows if r.get("status") == "calculated"]
    at_risk_rows = [r for r in rows if r.get("status") == "at_risk"]
    total = sum((Decimal(r["amount"]) for r in calculated_rows), Decimal("0"))
    amount_at_risk = sum((Decimal(r["amount"]) for r in at_risk_rows), Decimal("0"))
    attended_rows = [r for r in calculated_rows if r.get("kind") == "ATTENDED_CARE" and r.get("classification") != "FORECAST"]
    forecast_rows = [r for r in calculated_rows if r.get("kind") == "ATTENDED_CARE" and r.get("classification") == "FORECAST"]
    unique_blockers = sorted(frozenset(blockers))
    return {
        "status": "blocked" if unique_blockers else "ok",
        "service_period_id": period_id, "service_period_start": start.isoformat(), "service_period_end": end.isoformat(),
        "payment_release_date": _text(period, "paymentReleaseDate"), "payment_history_found": False, "rows": rows,
        "total_amount": _money(total),
        "attended_care_amount": _money(sum((Decimal(r["amount"]) for r in attended_rows), Decimal("0"))),
        "attended_care_hours": _money(sum((Decimal(str(r.get("payable_hours") or "0")) for r in attended_rows), Decimal("0"))),
        "forecast_amount": _money(sum((Decimal(r["amount"]) for r in forecast_rows), Decimal("0"))),
        "forecast_hours": _money(sum((Decimal(str(r.get("payable_hours") or "0")) for r in forecast_rows), Decimal("0"))),
        "vacant_slot_amount": _money(sum((Decimal(r["amount"]) for r in calculated_rows if r["kind"] == "VACANT_SLOT"), Decimal("0"))),
        "amount_at_risk": _money(amount_at_risk), "at_risk_day_count": len(at_risk_rows),
        "potential_total_amount": _money(total + amount_at_risk), "blockers": unique_blockers,
    }


def summarize_multi_period(ledger, periods, payment_history, vacant_slots, holidays, closures,
                            county_policy_by_id, fiscal_schedule_index, rate_lookup):
    periods_result = [
        summarize_period(ledger, p, payment_history, vacant_slots, holidays, closures,
                          county_policy_by_id, fiscal_schedule_index, rate_lookup)
        for p in sorted(periods, key=lambda p: _date(p, "serviceBeginDate", "Start_Date__c", "DTE_START__c") or date.min)
    ]
    total = sum((Decimal(p["total_amount"]) for p in periods_result), Decimal("0"))
    all_blockers = sorted(frozenset(b for p in periods_result for b in (p.get("blockers") or [])))
    return {"status": "ok", "mode": "multi_period", "periods": periods_result, "total_amount": _money(total), "blockers": all_blockers}


def calculate_payment(raw_bundle, ledger):
    """Top-level payment dispatcher -- period selection / candidates / multi-period
    modes, unchanged in spirit from the previous version, now delegating the
    actual per-period math to summarize_period()/summarize_multi_period()."""
    service_periods = _records(_first(raw_bundle, "service_periods", "servicePeriods", "getServicePeriods"))
    payment_history = _records(_first(raw_bundle, "payment_history", "paymentHistory", "subPayments"))
    holidays = _records(_first(raw_bundle, "holidays", "holidayList", "getHolidayList"))
    vacant_slots = _records(_first(raw_bundle, "vacant_slots", "vacantSlots", "getVacantSlots"))
    county_rate_plans = _records(_first(raw_bundle, "county_rate_plans", "countyRatePlans", "CountyInformation"))
    provider_closures = _records(_first(raw_bundle, "provider_closures", "providerClosures", "getProviderClosures"))
    fiscal_agreements = _records(_first(raw_bundle, "fiscal_agreements", "fiscalAgreements"))
    fiscal_schedules = _records(_first(raw_bundle, "fiscal_schedules", "fiscalSchedules"))
    fiscal_rates = _records(_first(raw_bundle, "fiscal_rates", "fiscalRates", "getFiscalRates"))
    county_policy_by_id = build_county_policy_index(county_rate_plans)
    fiscal_schedule_index = build_fiscal_schedule_index(fiscal_agreements, fiscal_schedules)
    rate_lookup = build_rate_lookup(fiscal_rates)
    shared = (holidays, provider_closures, county_policy_by_id, fiscal_schedule_index, rate_lookup)

    multi_period_window = raw_bundle.get("multi_period_window")
    if multi_period_window:
        window_start, window_end = (
            date.fromisoformat(str(v)[:10]) if not isinstance(v, date) else v for v in multi_period_window
        )
        matching = _periods_overlapping(service_periods, window_start, window_end)
        if not matching:
            return _blocked(["service_period"])
        return summarize_multi_period(ledger, matching, payment_history, vacant_slots, *shared)

    if raw_bundle.get("select_last_released"):
        period = _select_last_released_period(service_periods)
        return summarize_period(ledger, period, payment_history, vacant_slots, *shared) if period else _blocked(["no_released_period"])

    if raw_bundle.get("select_next_upcoming"):
        period = _select_next_upcoming_period(service_periods)
        return summarize_period(ledger, period, payment_history, vacant_slots, *shared) if period else _blocked(["no_upcoming_period"])

    period, candidates = _select_period_or_candidates(service_periods, raw_bundle.get("service_period_id"))
    if candidates is not None:
        return {"status": "needs_period_selection", "candidates": candidates, "rows": [],
                "total_amount": "0.00", "attended_care_amount": "0.00", "vacant_slot_amount": "0.00", "blockers": []}
    if period is None:
        return _blocked(["service_period"])
    return summarize_period(ledger, period, payment_history, vacant_slots, *shared)


# ==============================================================================
# SECTION 7 -- ATTENDANCE-RISK VIEW (aggregation over the same ledger)
# ==============================================================================

def summarize_attendance_risk(ledger, county_policy_by_id, child_filter, county_filter, provider_id,
                               reference_date, data_snapshot_version):
    records, groups = ledger["records"], ledger["absence_groups"]

    def _passes(name, county):
        if child_filter and not _name_matches(name, child_filter):
            return False
        if county_filter and (county or "").strip().lower() not in county_filter:
            return False
        return True

    approaching = []
    for (auth_id, year_month), group in groups.items():
        confirmed, probable = group["confirmed"], group["probable"]
        if not confirmed and not probable:
            continue
        sample = (confirmed + probable)[0]
        if not _passes(sample.get("child_name"), sample.get("county_name")):
            continue
        policy = county_policy_by_id.get(group["county_id"] or "", {}) or {}
        limit = int((policy.get("absence_limits") or {}).get(group["tier"]) or 0)
        confirmed_used, tentative_used = len(confirmed), len(probable)
        confirmed_remaining = limit - confirmed_used
        potential_remaining = limit - confirmed_used - tentative_used
        if limit > 0 and (confirmed_remaining <= NEAR_LIMIT_THRESHOLD or potential_remaining <= NEAR_LIMIT_THRESHOLD):
            approaching.append({
                "child_id": sample.get("child_id"), "child_name": sample.get("child_name"),
                "authorization_id": auth_id, "provider_id": sample.get("provider_id"),
                "county_id": group["county_id"], "county_name": sample.get("county_name"),
                "quality_tier": group["tier"], "absence_limit": limit,
                "confirmed_absence_count": confirmed_used, "probable_absence_count": tentative_used,
                "confirmed_absence_remaining": confirmed_remaining, "potential_absence_remaining": potential_remaining,
                "status": _status_from_remaining(confirmed_remaining, potential_remaining, tentative_used, NEAR_LIMIT_THRESHOLD),
                "year_month": year_month,
                "confirmed_absence_dates": sorted(r["service_date"].isoformat() for r in confirmed),
                "probable_absence_dates": sorted(r["service_date"].isoformat() for r in probable),
            })

    pending = [
        {"schedule_id": r.get("schedule_id"), "auth_id": r.get("auth_ref") or r.get("auth_id"), "child_id": r.get("child_id"),
         "child_name": r.get("child_name"), "county_name": r.get("county_name"), "provider_id": r.get("provider_id"),
         "county_id": r.get("county_id"), "date": r["service_date"].isoformat(), "status": PARENT_PENDING}
        for r in records if r.get("is_pending_confirmation") and _passes(r.get("child_name"), r.get("county_name"))
    ]

    # Decoupled from payoutImpactResult (restructuring fix): incomplete
    # check-in/out is now a direct ledger field, so it no longer silently
    # depends on payout-impact having run earlier in the same turn.
    incomplete = [
        {"child_name": r.get("child_name"), "authorization_id": r.get("auth_ref") or r.get("auth_id"), "county_name": r.get("county_name"),
         "date": r["service_date"].isoformat(), "reason": "A check-in or check-out was not logged for this day"}
        for r in records if r.get("is_incomplete_checkinout") and _passes(r.get("child_name"), r.get("county_name"))
    ]

    return {
        "provider_id": provider_id, "reference_date": reference_date,
        "approaching_absence_limits": sorted(approaching, key=lambda r: (r["county_id"] or "", r["child_id"] or "")),
        "pending_confirmation_records": sorted(pending, key=lambda r: (r["date"], r.get("child_id") or "")),
        "incomplete_attendance_records": sorted(incomplete, key=lambda r: r["date"]),
        "lookback_days": RISK_WINDOW_DAYS,
        "scopeFingerprint": {"child_filter": sorted(child_filter), "county_filter": sorted(county_filter),
                             "as_of_date": reference_date, "dataSnapshotVersion": data_snapshot_version},
    }


# ==============================================================================
# SECTION 8 -- PAYOUT-IMPACT VIEW
# No re-join needed: every day's rate was already resolved once, while
# building the ledger. This eliminates ~150 lines of schedule re-indexing
# and rate re-resolution that the previous version ran a second time here.
# ==============================================================================

def summarize_payout_impact(ledger, risk_result, child_filter, county_filter):
    records = ledger["records"]

    def _skip(child_name, county_name):
        if child_filter and not _name_matches(child_name, child_filter):
            return True
        if county_filter and county_name and (county_name or "").lower() not in county_filter:
            return True
        return False

    total_hours, total_dollar = Decimal("0"), Decimal("0")

    def _row(rec, reason, category):
        nonlocal total_hours, total_dollar
        hours = rec.get("payable_hours") or Decimal("0")
        amount = rec.get("rate")
        out = {"child_name": rec.get("child_name"), "authorization_id": rec.get("auth_ref") or rec.get("auth_id"),
               "county_name": rec.get("county_name"), "risk_category": category}
        if amount is None:
            out.update(care_hours=float(hours) if hours else None, amount=None, amount_type=None, reason=rec.get("rate_blocker"))
        else:
            total_hours += hours
            total_dollar += amount
            out.update(care_hours=float(hours), amount=_money(amount), amount_type="At-risk", reason=reason)
        return out

    reference_date = (risk_result.get("reference_date") or date.today().isoformat())[:10]
    try:
        win_start = (date.fromisoformat(reference_date) - timedelta(days=RISK_WINDOW_DAYS)).isoformat()
    except ValueError:
        win_start = None

    rows = []
    for rec in records:
        if rec.get("classification") != "ABSENCE" or _skip(rec.get("child_name"), rec.get("county_name")):
            continue
        # Days 9+ days old are outside the actionable/confirmation window --
        # the payment cycle has already processed them one way or the other,
        # so they're no longer a "risk," just a settled fact (see the
        # payment view's own blocker for what actually happened to them).
        if not rec.get("is_tentative"):
            continue
        # A day whose group has ALREADY crossed the county's absence limit
        # is a certainty, not a risk -- it will not be paid, full stop.
        # Only days still within the limit (or where the limit itself is
        # unknown) have a payment outcome that's still genuinely open.
        if rec.get("limit_blocker") == "absence_limit_exceeded":
            continue
        rows.append(_row(rec, "Recent, unconfirmed absence within the county limit -- still pending, payment could change", "absence"))

    for rec in records:
        if rec.get("is_pending_confirmation") and (not win_start or rec["service_date"].isoformat() >= win_start) \
                and not _skip(rec.get("child_name"), rec.get("county_name")):
            rows.append(_row(rec, "Pending parent confirmation -- payment not yet finalized", "unconfirmed"))

    for rec in records:
        if rec.get("is_incomplete_checkinout") and (not win_start or rec["service_date"].isoformat() >= win_start) \
                and not _skip(rec.get("child_name"), rec.get("county_name")):
            row = _row(rec, "Incomplete check-in or check-out -- payment may be withheld", "incomplete")
            row["date"] = rec["service_date"].isoformat()
            rows.append(row)

    totals = {"absence": [Decimal("0"), Decimal("0"), False], "unconfirmed": [Decimal("0"), Decimal("0"), False],
              "incomplete": [Decimal("0"), Decimal("0"), False]}
    for row in rows:
        cat = row.get("risk_category")
        if cat not in totals:
            continue
        hours = Decimal(str(row.get("care_hours") or 0))
        amount = Decimal(row["amount"]) if row.get("amount") is not None else Decimal("0")
        totals[cat][0] += hours
        totals[cat][1] += amount
        if row.get("amount") is None and (cat != "unconfirmed" or float(row.get("care_hours") or 0) > 0):
            totals[cat][2] = True

    unconfirmed_recs = [r for r in records if r.get("is_pending_confirmation")]
    return {
        "status": "ok", "rows": rows,
        "total_hours_at_risk": float(total_hours),
        "total_dollar_at_risk": _money(total_dollar) if total_dollar else "0.00",
        "absence_risk_hours": None if totals["absence"][2] else float(totals["absence"][0]),
        "absence_risk_amount": None if totals["absence"][2] else (_money(totals["absence"][1]) if totals["absence"][1] else "0.00"),
        "unconfirmed_risk_hours": None if totals["unconfirmed"][2] else float(totals["unconfirmed"][0]),
        "unconfirmed_risk_amount": None if totals["unconfirmed"][2] else (_money(totals["unconfirmed"][1]) if totals["unconfirmed"][1] else "0.00"),
        "incomplete_risk_hours": float(totals["incomplete"][0]),
        "incomplete_risk_amount": None if totals["incomplete"][2] else (_money(totals["incomplete"][1]) if totals["incomplete"][1] else "0.00"),
        "unconfirmed_count": len(unconfirmed_recs),
        "unconfirmed_children": len({r.get("child_name") or r.get("child_id") for r in unconfirmed_recs if r.get("child_name") or r.get("child_id")}),
    }


def _name_matches(name, filters):
    """Tolerant child-name match: exact, substring, or all filter tokens present
    ('murti' matches 'MURTI SB')."""
    n = (name or "").strip().lower()
    if not n:
        return False
    tokens = n.split()
    return any(f == n or f in n or all(t in tokens for t in f.split()) for f in filters)


def filter_ledger(ledger, child_filter, county_filter):
    """Scope the computed ledger by child/county. Whole authorizations are kept
    or dropped (an authorization has one child and one county), so monthly
    absence/drop-in grouping stays correct. Raw fetched data is never narrowed."""
    if not child_filter and not county_filter:
        return ledger

    def keep(rec):
        if child_filter and not _name_matches(rec.get("child_name"), child_filter):
            return False
        if county_filter and (rec.get("county_name") or "").strip().lower() not in county_filter:
            return False
        return True

    records = [r for r in ledger["records"] if keep(r)]
    groups = {k: g for k, g in ledger["absence_groups"].items()
              if any(keep(r) for r in g["confirmed"] + g["probable"] + g["drop_in"])}
    return {"records": records, "absence_groups": groups}


# ==============================================================================
# SECTION 9 -- ENTRY POINT (thin dispatch; the previous version's ~230-line
# entry point shrinks because index-building and ledger-building are now
# each a single reusable call instead of being re-derived per branch)
# ==============================================================================

def _ctx(key, default=None):
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


_providers = _ctx("provider", [])
_county_info = _ctx("CountyInformation", [])
_authorizations_all = _ctx("AuthInformation", [])
_schedules_all = _ctx("ScheduleInformation", [])
_holidays = _ctx("orgHolidays", [])
_turn_request = _ctx("turnRequest", {}) or {}
_payment_bundle = _ctx("paymentData") or {}
_action = _turn_request.get("action") if isinstance(_turn_request, dict) else None
_sub_filter = _turn_request.get("subFilter") if isinstance(_turn_request, dict) else None
_as_of_date = date.today()
_data_snapshot_version = _ctx("dataManifest.fetchedAtEpoch")

_child_filter = {c.strip().lower() for c in (_turn_request.get("childNames") or []) if c}
_county_name_filter = {c.strip().lower() for c in (_turn_request.get("countyNames") or []) if c}

_authorizations = _authorizations_all
_schedules = _schedules_all
if _county_name_filter:
    _name_to_id = {}
    for row in _county_info if isinstance(_county_info, list) else []:
        name = _text(row, "countyName", "county_name", "NAM_COUNTY__c", "Name")
        cid = _text(row, "countyId", "county_id", "CDE_COUNTY__c", "Id", "id")
        if name and cid:
            _name_to_id.setdefault(name.strip().lower(), cid)
    _allowed_county_ids = {_name_to_id[n] for n in _county_name_filter if n in _name_to_id}
    _vslots = _payment_bundle.get("vacantSlots") if isinstance(_payment_bundle, dict) else None
    if isinstance(_vslots, list):
        _payment_bundle["vacantSlots"] = [s for s in _vslots if isinstance(s, dict) and _text(s, "CDE_COUNTY__c") in _allowed_county_ids]

_provider_closures = _records(_first(_payment_bundle, "provider_closures", "providerClosures", "getProviderClosures")) if isinstance(_payment_bundle, dict) else []
_county_policy_by_id = build_county_policy_index(_county_info)
_fiscal_agreements = _records(_first(_payment_bundle, "fiscal_agreements", "fiscalAgreements")) if isinstance(_payment_bundle, dict) else []
_fiscal_schedules = _records(_first(_payment_bundle, "fiscal_schedules", "fiscalSchedules")) if isinstance(_payment_bundle, dict) else []
_fiscal_rates = _records(_first(_payment_bundle, "fiscal_rates", "fiscalRates", "getFiscalRates")) if isinstance(_payment_bundle, dict) else []
_fiscal_schedule_index = build_fiscal_schedule_index(_fiscal_agreements, _fiscal_schedules)
_rate_lookup = build_rate_lookup(_fiscal_rates)
_auth_by_name, _auth_by_id = build_auth_indices(_authorizations)

_payment_result = None
_attendance_result = None
_impact_result = None

_needs_ledger = _action in ("PAYMENT", "ATTENDANCE", "STARTER")
_ledger = (
    build_day_ledger(_schedules, _auth_by_name, _auth_by_id, _provider_closures, _holidays,
                      _county_policy_by_id, _fiscal_schedule_index, _rate_lookup, _as_of_date)
    if _needs_ledger else {"records": [], "absence_groups": {}}
)
_ledger = filter_ledger(_ledger, _child_filter, _county_name_filter)

if _action == "PAYMENT":
    if not isinstance(_payment_bundle, dict) or not _payment_bundle:
        _payment_result = _blocked(["payment_data_collection"])
    else:
        _raw_bundle = {**_payment_bundle}
        _payment_result = calculate_payment(_raw_bundle, _ledger)

    _resolved_period_ids = (
        [p.get("service_period_id") for p in (_payment_result.get("periods") or [])]
        if _payment_result.get("mode") == "multi_period"
        else [_payment_result.get("service_period_id")]
    )
    _payment_result["scopeFingerprint"] = {
        "resolved_service_period_ids": sorted(str(p) for p in _resolved_period_ids if p),
        "child_filter": sorted(_child_filter), "county_filter": sorted(_county_name_filter),
        "as_of_date": _as_of_date.isoformat(), "dataSnapshotVersion": _data_snapshot_version,
        "subFilter": _sub_filter,
    }
    write_context("paymentResult", _payment_result)

if _action in ("ATTENDANCE", "STARTER"):
    _attendance_cache_valid = _turn_request.get("attendanceCacheValid") == "YES"
    _cached_attendance = _ctx("attendance_risks_analyzer_py")
    if not _providers or not _county_info or not _schedules:
        _attendance_result = {
            "status": "FAILED_BAD_INPUT",
            "error": "; ".join(filter(None, [
                "provider record is missing" if not _providers else None,
                "county rate plans are missing" if not _county_info else None,
                "schedules must be a non-empty array" if not _schedules else None,
            ])),
            "provider_id": _text(_providers[0], "Id", "id") if _providers else None,
        }
    elif _attendance_cache_valid and isinstance(_cached_attendance, dict) and _cached_attendance.get("status") != "FAILED_BAD_INPUT":
        _attendance_result = _cached_attendance
    else:
        _attendance_result = summarize_attendance_risk(
            _ledger, _county_policy_by_id, _child_filter, _county_name_filter,
            _text(_providers[0], "Id", "id") if _providers else None,
            _as_of_date.isoformat(), _data_snapshot_version,
        )
        write_context("input.provider_id", _attendance_result.get("provider_id"))
        write_context("input.schedules_count", len(_schedules))

    if _attendance_result.get("status") == "FAILED_BAD_INPUT":
        write_context("result.error", _attendance_result)
    else:
        write_context("attendance_risks_analyzer_py", _attendance_result)
        write_context("result.approaching_absence_limits", _attendance_result["approaching_absence_limits"])
        write_context("result.pending_confirmation_records", _attendance_result["pending_confirmation_records"])
        write_context("result.scopeFingerprint", _attendance_result["scopeFingerprint"])

        if _attendance_result is not None:  # always fresh with the attendance scan -- no stale impact rows
            _impact_result = summarize_payout_impact(_ledger, _attendance_result, _child_filter, _county_name_filter)
            _data_result = _ctx("data_collection_result") or {}
            _snapshot = (_data_result.get("snapshot") if isinstance(_data_result, dict) else None) or {}
            _risk_categories = _snapshot.setdefault("risk_categories", {})
            _risk_categories.setdefault("approaching_absence_limits", {}).update(
                potential_loss_hours=_impact_result["absence_risk_hours"], potential_loss_amount=_impact_result["absence_risk_amount"])
            _pending_category = _risk_categories.setdefault("pending_parent_confirmations", {})
            _pending_category.update(
                potential_loss_hours=_impact_result["unconfirmed_risk_hours"], potential_loss_amount=_impact_result["unconfirmed_risk_amount"],
                days=_impact_result.get("unconfirmed_count", 0), children=_impact_result.get("unconfirmed_children", 0))
            _risk_categories.setdefault("incomplete_attendance", {}).update(
                potential_loss_hours=_impact_result["incomplete_risk_hours"], potential_loss_amount=_impact_result["incomplete_risk_amount"])
            _data_result["snapshot"] = _snapshot
            write_context("snapshot", _snapshot)
            write_context("data_collection_result", _data_result)
            write_context("payoutImpactResult", _impact_result)

_final_result = _payment_result if _payment_result is not None else (_impact_result if _impact_result is not None else (_attendance_result or {}))
respond(_final_result, confidence=1.0)