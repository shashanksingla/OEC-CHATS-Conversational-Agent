"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_calc_engine_py, v1.0.0. Consolidated payment + attendance-risk +
payout-impact calculation engine. Replaces ccare_payment_engine.py,
attendance_risks_analyzer_py.py, and ccare_payout_impact_correlator.py with
ONE task -- eliminating the duplicated fiscal-rate/classification core those
three files previously carried independently, and the resulting calculation
drift (the old correlator rated risk on authorized_hours; payment rated the
same day on payable_hours post-classification -- same day, two different
numbers were possible). Every business rule below is ported verbatim from
those three files, not redesigned; only the duplication and the correlator's
independent rate-lookup are removed.

Shared classification/fiscal core (this section) is used by BOTH the
payment aggregation (period-scoped) and the payout-impact aggregation
(lookback-window-scoped, over the SAME classification functions) -- the two
aggregation scopes remain intentionally distinct (they answer different
business questions) but now share one source of truth for "what is this day
worth."

Runtime affordances: read_context, write_context, respond.
"""

import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from typing import Any, Set

# -- AAF runtime stubs (unit-test shim) --------------------------------------
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
# SHARED CALCULATION CORE (pure functions -- no AAF context access)
# ==============================================================================

# Same lookback window the attendance-risk view uses for unconfirmed-
# attendance detection -- a calculated day inside this window is "at risk"
# (not yet guaranteed), not a settled amount.
CONFIRMATION_WINDOW_DAYS = 9

MONEY_QUANTUM = Decimal("0.01")
PAID_TIERS = (
    (Decimal("0"), "NO_PAYMENT"),
    (Decimal("5"), "PART_TIME"),
    (Decimal("12"), "FULL_TIME"),
    (Decimal("17"), "FULL_TIME_PLUS_PART_TIME"),
)

# Confirmed picklist code tables (cde_care_unit__c, cde_age_group__c,
# cde_rate_type__c) -- source of truth for all fiscal-rate joins below.
CARE_UNIT_TO_TIER = {
    "1": "NO_PAYMENT",
    "2": "PART_TIME",
    "3": "FULL_TIME",
    "4": "FULL_TIME_PLUS_PART_TIME",
    "5": "FULL_TIME_PLUS_FULL_TIME",
}
TIER_TO_CARE_UNIT = {tier: code for code, tier in CARE_UNIT_TO_TIER.items()}

# cde_age_group__c: 6-month bands from birth through 36 months, then
# 36-School-Age and School-Age. Upper bound is in months of age; code "8"
# (School Age) is the open-ended final band.
AGE_GROUP_MONTH_BOUNDS = ((6, "1"), (12, "2"), (18, "3"), (24, "4"), (30, "5"), (36, "6"), (60, "7"))

# cde_rate_type__c labels, for diagnostics only (joins always use the code).
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


def _fiscal_rate_type(value: str | None) -> str:
    code = str(value or "").strip()
    return RATE_TYPE_BASE_CODES.get(code, code)


def _normalize_tier(value: Any) -> str:
    """Shared normalization -- payment and attendance-risk aggregation agree
    on which absence_limits.tier_N / absenceDaysTierN a schedule maps to."""
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


def _county_policy_index(county_rate_plans: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """Index getCountyData's countyRatePlans by county_id -> policy fields
    calculate_payment needs for limit enforcement."""
    index: dict[str, dict[str, Any]] = {}
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
            # countyholidayList is semicolon-separated holiday NAMES, matched
            # against getHolidayList's CDE_HOL__c.
            "holiday_names": {
                n.strip().upper() for n in (plan.get("countyholidayList") or "").split(";") if n.strip()
            },
        }
    return index


def _int_or_none(value: Any) -> int | None:
    if isinstance(value, bool) or value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _fiscal_schedule_index(
    fiscal_agreements: list[dict[str, Any]],
    fiscal_schedules: list[dict[str, Any]],
) -> dict[tuple[str, str], list[dict[str, Any]]]:
    """Build {(provider_id, county_id): [{ext_id, rate_types, quality_tier}, ...]}.

    Two real sources feed this: fiscal_agreements (from the provider-data
    bundle) carries nested Rate_Schedules__r records directly under each
    agreement; fiscal_schedules (the flat list from getFiscalRates) links
    back to its agreement via IDN_AGRMT_FISCAL__c, so the agreement's
    provider/county scope is resolved from fiscal_agreements first."""
    agreement_scope: dict[str, tuple[str, str]] = {}
    for agreement in fiscal_agreements:
        if not isinstance(agreement, dict):
            continue
        agreement_id = _text(agreement, "Id", "IDN_EXTNL__c")
        provider_id = _text(agreement, "ID_SERVICE__c", "provider_id")
        county_id = _text(agreement, "CDE_COUNTY__c", "county_id")
        if agreement_id and provider_id and county_id:
            agreement_scope[agreement_id] = (provider_id, county_id)

    index: dict[tuple[str, str], list[dict[str, Any]]] = {}

    def _add_schedule(rs: Any, provider_id: str | None, county_id: str | None) -> None:
        if not isinstance(rs, dict) or not provider_id or not county_id:
            return
        ext_id = _text(rs, "IDN_EXTNL__c", "Id")
        if not ext_id:
            return
        rate_type_raw = _text(rs, "CDE_RATE_TYPE__c") or ""
        rate_types = {token.strip() for token in rate_type_raw.split(";") if token.strip()}
        quality_tier = _text(rs, "TXT_CHATS_RATING__c")
        index.setdefault((provider_id, county_id), []).append({
            "ext_id": ext_id,
            "rate_types": rate_types,
            "quality_tier": quality_tier,
        })

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


def _rate_lookup(fiscal_rates: list[dict[str, Any]]) -> dict[tuple[str, str, str, str], Decimal]:
    """{(fiscal_schedule_ext_id, rate_type, age_group, care_unit): amount},
    built directly from raw batchsit_t_fiscal_rate__x rows -- confirmed field
    names: idn_fiscal_sch__c, cde_rate_type__c, cde_age_group__c,
    cde_care_unit__c, amt_fa__c."""
    lookup: dict[tuple[str, str, str, str], Decimal] = {}
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


def _quality_tier_for(
    authorization: dict[str, Any],
    rate_type_code: str | None,
    schedule_index: dict[tuple[str, str], list[dict[str, Any]]],
) -> str | None:
    """Provider quality tier lives on the resolved fiscal schedule
    (TXT_CHATS_RATING__c), not on schedule or authorization records."""
    provider_id = _text(authorization, "IDN_PROVR__c")
    county_id = _text(authorization, "CDE_COUNTY__c")
    fiscal_rate_type = _fiscal_rate_type(rate_type_code)
    for candidate in schedule_index.get((provider_id or "", county_id or ""), []):
        candidate_rate_types = {_fiscal_rate_type(value) for value in candidate["rate_types"]}
        if not candidate_rate_types or (fiscal_rate_type and fiscal_rate_type in candidate_rate_types):
            if candidate.get("quality_tier"):
                return candidate["quality_tier"]
    return None


def _months_of_age(dob: date | None, on_date: date | None) -> int | None:
    """Child's age in whole months on a given date -- shared by age-group
    banding and the enrollment-absence (<=36 months) rule."""
    if not dob or not on_date:
        return None
    months = (on_date.year - dob.year) * 12 + (on_date.month - dob.month)
    if on_date.day < dob.day:
        months -= 1
    return max(months, 0)


def _is_provider_closure(closures: list[dict[str, Any]], provider_id: str | None, county_id: str | None, service_date: date) -> bool:
    """Checked BEFORE holiday/absence when a scheduled day has zero
    attendance. Closures come from getProviderData's providerClosures
    (T_PROVR_CLOSURE__c: IDN_PROVIDER__c, CDE_COUNTY__c, DTE_BEGIN_CLOSURE__c,
    IND_ACTIVE__c) -- single-day closures (no end-date field confirmed),
    matched by exact date."""
    for closure in closures:
        if not isinstance(closure, dict):
            continue
        if not _truthy(closure, "IND_ACTIVE__c", "active"):
            continue
        closure_provider = _text(closure, "IDN_PROVIDER__c", "provider_id")
        closure_county = _text(closure, "CDE_COUNTY__c", "county_id")
        if provider_id and closure_provider and closure_provider != provider_id:
            continue
        if county_id and closure_county and closure_county != county_id:
            continue
        closure_date = _date(closure, "DTE_BEGIN_CLOSURE__c", "closure_date")
        if closure_date == service_date:
            return True
    return False


def _child_dob(authorization: dict[str, Any]) -> date | None:
    """Child DOB for age-band derivation -- lives on the nested client
    relationship, IDN_CLIENT__r.DTE_DOB__c."""
    client = authorization.get("IDN_CLIENT__r") if isinstance(authorization, dict) else None
    return _date(client, "DTE_DOB__c", "dob") if isinstance(client, dict) else None


def _age_group_code(dob: date | None, service_date: date | None) -> str | None:
    """Maps child age on service_date to the confirmed AGE_GROUP_MONTH_BOUNDS
    band. Code "8" (School Age) is the open-ended final band."""
    if not dob or not service_date:
        return None
    months = (service_date.year - dob.year) * 12 + (service_date.month - dob.month)
    if service_date.day < dob.day:
        months -= 1
    months = max(months, 0)
    for bound, code in AGE_GROUP_MONTH_BOUNDS:
        if months < bound:
            return code
    return "8"


def _resolve_attended_rate(
    authorization: dict[str, Any],
    rate_type_code: str | None,
    age_group_code: str | None,
    payable_hours: Decimal,
    schedule_index: dict[tuple[str, str], list[dict[str, Any]]],
    rate_lookup: dict[tuple[str, str, str, str], Decimal],
) -> tuple[Decimal | None, str | None]:
    """Joins authorization -> fiscal schedule -> fiscal rate row keyed by
    (schedule_ext_id, rate_type, age_group, care_unit). care_unit comes from
    payable hours via CARE_UNIT_TO_TIER. Falls back to the schedule's
    NO_PAYMENT row (a real $0 rate) before giving up. Never guesses.

    Used by BOTH the payment aggregation and the payout-impact aggregation --
    the single source of "what is this day worth," rated on payable_hours
    (post-classification), never on raw authorized_hours."""
    if not age_group_code:
        return None, "age_group_code_unresolved"
    fiscal_rate_type = _fiscal_rate_type(rate_type_code)
    care_unit = TIER_TO_CARE_UNIT.get(paid_tier_for_hours(payable_hours))
    if care_unit is None:
        return None, "care_unit_mapping_unconfirmed"
    provider_id = _text(authorization, "IDN_PROVR__c")
    county_id = _text(authorization, "CDE_COUNTY__c")
    candidates = schedule_index.get((provider_id or "", county_id or ""), [])
    if not candidates:
        return None, "fiscal_schedule"
    no_payment_unit = TIER_TO_CARE_UNIT["NO_PAYMENT"]
    for candidate in candidates:
        candidate_rate_types = {_fiscal_rate_type(value) for value in candidate["rate_types"]}
        if fiscal_rate_type and candidate_rate_types and fiscal_rate_type not in candidate_rate_types:
            continue
        amount = rate_lookup.get((candidate["ext_id"], fiscal_rate_type, age_group_code, care_unit))
        if amount is not None:
            return amount, None
        fallback = rate_lookup.get((candidate["ext_id"], fiscal_rate_type, age_group_code, no_payment_unit))
        if fallback is not None:
            return Decimal("0"), None
    return None, "fiscal_rate"


def _vacant_slot_weekday_set(slot: dict[str, Any]) -> Set[str]:
    weekday_raw = _text(slot, "CNT_DAYS_OF_WEEK__c")
    return {token.strip().upper() for token in (weekday_raw or "").split(";") if token.strip()}


def _is_county_holiday(holidays: list[dict[str, Any]], service_date: date, county_holiday_names: Set[str]) -> bool:
    """countyholidayList is semicolon-separated holiday NAMES;
    getHolidayList's CDE_HOL__c carries the matching name. A county with no
    configured holiday list has no county-specific holidays applied (fails
    closed -- never falls back to a global match)."""
    if not county_holiday_names:
        return False
    for h in holidays:
        h_date = _date(h, "DTE_HOL__c", "DTE_OBSERVED_HOL__c", "holiday_date", "date")
        if h_date != service_date:
            continue
        h_name = _text(h, "CDE_HOL__c")
        if h_name and h_name.strip().upper() in county_holiday_names:
            return True
    return False


def _vacant_slot_eligible_day(
    slot: dict[str, Any], service_date: date, holidays: list[dict[str, Any]],
    closures: list[dict[str, Any]], allowed_weekdays: Set[str], county_holiday_names: Set[str],
) -> bool:
    """Single-day eligibility only: weekday pattern, provider closure,
    county-specific holiday -- independent of every other day, no monthly
    cap applied here."""
    if allowed_weekdays and service_date.strftime("%A").upper() not in allowed_weekdays:
        return False
    provider_id = _text(slot, "IDN_PROVIDER__c")
    county_id = _text(slot, "CDE_COUNTY__c")
    if _is_provider_closure(closures, provider_id, county_id, service_date):
        return False
    if _is_county_holiday(holidays, service_date, county_holiday_names):
        return False
    return True


def _vacant_slot_eligible_days_in_range(
    slot: dict[str, Any], range_start: date, range_end: date,
    holidays: list[dict[str, Any]], closures: list[dict[str, Any]], county_holiday_names: Set[str],
) -> list[date]:
    """Every eligible day (weekday+closure+holiday, no cap) between
    range_start/range_end inclusive, clipped to the slot's own
    DTE_BEGIN_SLOT__c/DTE_END_SLOT__c. Sorted ascending. Used both for the
    week actually being processed and for the stateless month-to-date
    recompute in _vacant_slot_payable_days()."""
    begin = _date(slot, "DTE_BEGIN_SLOT__c")
    end = _date(slot, "DTE_END_SLOT__c")
    if not begin or not end or range_end < range_start:
        return []
    start = max(begin, range_start)
    stop = min(end, range_end)
    if stop < start:
        return []
    allowed_weekdays = _vacant_slot_weekday_set(slot)
    days: list[date] = []
    current = start
    while current <= stop:
        if _vacant_slot_eligible_day(slot, current, holidays, closures, allowed_weekdays, county_holiday_names):
            days.append(current)
        current = date.fromordinal(current.toordinal() + 1)
    return days


def _vacant_slot_payable_days(
    slot: dict[str, Any], period_start: date, period_end: date,
    holidays: list[dict[str, Any]], closures: list[dict[str, Any]], county_holiday_names: Set[str],
) -> tuple[list[date], list[date]]:
    """Weekly service period, monthly cap recomputed fresh every call from
    config alone -- never from stored history or a running total. A period
    straddling a month boundary is split into per-month segments; each
    segment's remaining cap room = CNT_DAYS_OF_MONTH__c minus the eligible
    days that fall between that month's 1st and the day before this segment
    starts (recomputed the same way, not fetched). Returns (payable_days,
    excluded_days) -- excluded_days are eligible but beyond the month's
    remaining cap room this week."""
    monthly_limit = _int_or_none(slot.get("CNT_DAYS_OF_MONTH__c"))
    payable_days: list[date] = []
    excluded_days: list[date] = []
    segment_start = period_start
    while segment_start <= period_end:
        month_start, month_end = _month_bounds(segment_start, 0)
        segment_end = min(period_end, month_end)
        segment_days = _vacant_slot_eligible_days_in_range(slot, segment_start, segment_end, holidays, closures, county_holiday_names)
        if monthly_limit is None:
            payable_days.extend(segment_days)
        else:
            prior_end = segment_start - timedelta(days=1)
            prior_count = (
                len(_vacant_slot_eligible_days_in_range(slot, month_start, prior_end, holidays, closures, county_holiday_names))
                if prior_end >= month_start else 0
            )
            remaining = max(monthly_limit - prior_count, 0)
            payable_days.extend(segment_days[:remaining])
            excluded_days.extend(segment_days[remaining:])
        segment_start = month_end + timedelta(days=1)
    return payable_days, excluded_days


def _vacant_slot_rate(
    slot: dict[str, Any],
    schedule_index: dict[tuple[str, str], list[dict[str, Any]]],
    rate_lookup: dict[tuple[str, str, str, str], Decimal],
) -> tuple[Decimal | None, str | None]:
    """There is no cde_care_level__c field on batchsit_t_fiscal_rate__x; the
    only differentiator per rate_type+care_unit is cde_age_group__c. A vacant
    slot has no child, so its CDE_CARE_LEVEL__c fills the age_group slot in
    the SAME rate_lookup attended-care rows use: (ext_id, rate_type,
    age_group, care_unit)."""
    rate_type = _text(slot, "CDE_RATE_TYPE__c")
    care_unit = _text(slot, "CDE_CARE_UNIT__c")
    care_level = _text(slot, "CDE_CARE_LEVEL__c")
    provider_id = _text(slot, "IDN_PROVIDER__c")
    county_id = _text(slot, "CDE_COUNTY__c")
    if not rate_type or not care_unit or not care_level:
        return None, "vacant_slot_rate_fields"
    candidates = schedule_index.get((provider_id or "", county_id or ""), [])
    for candidate in candidates:
        if candidate["rate_types"] and rate_type not in candidate["rate_types"]:
            continue
        amount = rate_lookup.get((candidate["ext_id"], rate_type, care_level, care_unit))
        if amount is not None:
            return amount, None
    return None, "fiscal_rate"


def paid_tier_for_hours(hours) -> str:
    value = _decimal(hours)
    if value is None or value <= 0:
        return "NO_PAYMENT"
    for boundary, tier in PAID_TIERS[1:]:
        if value <= boundary:
            return tier
    return "FULL_TIME_PLUS_FULL_TIME"


def _payable_hours(classification, authorized, attended, schedule):
    """Reverted per confirmed CCCAP policy: an ABSENCE/ENROLLMENT_ABSENCE day
    WITHIN the county's monthly limit is paid on authorized/scheduled hours
    (the original, correct policy) -- absences beyond the limit are excluded
    from payment entirely via limit_exceeded_blocker BEFORE this function is
    even reached (see _calculate_for_period), so this function never needs
    to distinguish within-limit vs over-limit itself."""
    if classification in {"HOLIDAY", "ABSENCE", "ENROLLMENT_ABSENCE"}:
        return authorized
    if classification == "DROP_IN":
        return attended
    if classification == "FORECAST":
        return authorized
    return min(authorized, attended)


def _classification(closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays, as_of_date=None, county_holiday_names=None):
    """Derived purely from hours + closure + holiday + status semantics
    (CCCAP_AUTHORIZED/CCCAP_NOT_AUTHORIZED/CARE_NOT_OFFERED are states, not
    booleans) -- closure checked first, then hours decide authorized vs.
    drop-in vs. no-care, then holiday/absence for a scheduled day with zero
    attendance. Holiday check uses the same county-specific
    _is_county_holiday() the vacant-slot path uses -- a date is only HOLIDAY
    when it's on THIS authorization's county's configured list."""
    if _is_provider_closure(closures, provider_id, county_id, service_date):
        return "CARE_NOT_OFFERED"
    if authorized_hours == 0:
        return "DROP_IN" if attended_hours > 0 else "NO_CARE"
    if attended_hours > 0:
        return "REGULAR"
    if _is_county_holiday(holidays, service_date, county_holiday_names or set()):
        return "HOLIDAY"
    if as_of_date is not None and service_date > as_of_date:
        return "FORECAST"
    return "ABSENCE"


def _attended_hours(schedule):
    """A day with Check_In_Count__c=0 and Check_Out_Count__c=0 is a genuine,
    confirmed zero-attendance day (e.g. the child never checked in) -- that
    is real data, not missing data, and must resolve to 0 hours so
    classification can correctly call it ABSENCE/HOLIDAY/etc. The previous
    `check_in > 0` requirement treated every such day as unresolvable,
    blocking the whole day with an "hours" blocker before classification
    ever ran -- confirmed live: every schedule with both counts at 0 was
    blocked instead of classified, including plain absence days.
    Only a genuinely missing/null count (field absent from the record) is
    unresolvable; a negative count-difference from bad data still blocks."""
    direct = _number(schedule, "attended_hours", "Hours__c", "unit_hours")
    if direct is not None:
        return direct
    check_in = _number(schedule, "Check_In_Count__c", "check_in")
    check_out = _number(schedule, "Check_Out_Count__c", "check_out")
    if check_in is None or check_out is None or check_out < check_in:
        return None
    return check_out - check_in


def _attendance_confirmation_risk(schedule, service_date, as_of_date, classification=None):
    """Within the 9-day confirmation window, a day is 'at risk' (not yet
    guaranteed) if its attendance transaction is still PARENT_PENDING, or if
    no attendance transaction was logged at all -- confirmed field location:
    Attendance__r.records[].Status__c (a child Transaction__c record, NOT a
    top-level Schedule__c field). HOLIDAY and ENROLLMENT_ABSENCE are payable
    without parent confirmation -- no attendance records are expected, so
    MISSING_ATTENDANCE never applies."""
    if classification in {"HOLIDAY", "ENROLLMENT_ABSENCE"}:
        return None
    if as_of_date is None or service_date > as_of_date:
        return None
    if not (0 <= (as_of_date - service_date).days <= CONFIRMATION_WINDOW_DAYS):
        return None
    attendance = schedule.get("Attendance__r") if isinstance(schedule, dict) else None
    records = attendance.get("records") if isinstance(attendance, dict) else None
    records = records if isinstance(records, list) else []
    if any(_text(r, "Status__c") == "PARENT_PENDING" for r in records if isinstance(r, dict)):
        return "PENDING_CONFIRMATION"
    if not records:
        return "MISSING_ATTENDANCE"
    return None


def _existing_payment_amount(records, period_id):
    """Real settlement records are subPayments rows
    (idn_period_serv__c/cde_status_pmt_sub__c/amt_total_pmt_sub__c), and a
    period can have more than one sub-payment (one per authorization) -- sum
    every matching PAID/REQUESTED row instead of returning the first."""
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
    """Distinguishes "no match" from "2+ matches" instead of collapsing both
    into a bare blocked result. Returns (period, None) on an exact single
    match, or (None, candidates) when disambiguation is needed -- candidates
    is None when there is truly nothing to disambiguate."""
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


def _records(value):
    if isinstance(value, list):
        return [r for r in value if isinstance(r, dict)]
    if not isinstance(value, dict):
        return []
    for key in ("records", "data", "results", "items", "servicePeriods", "authorizations", "schedules", "fiscalRates", "paymentHistory", "countyRatePlans"):
        nested = value.get(key)
        if isinstance(nested, list):
            return [r for r in nested if isinstance(r, dict)]
    return [value] if any(k in value for k in ("Id", "id", "Name", "name")) else []


def _unique_index(records, *keys):
    grouped = {}
    for row in records:
        k = _text(row, *keys)
        if k:
            grouped.setdefault(k, []).append(row)
    return {k: rows[0] for k, rows in grouped.items() if len(rows) == 1}


def _first(mapping, *keys):
    for key in keys:
        if key in mapping and mapping[key] is not None:
            return mapping[key]
    return None


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


def _money(value):
    return format(value.quantize(MONEY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


def _blocked(blockers):
    return {
        "status": "blocked", "rows": [], "total_amount": "0.00", "attended_care_amount": "0.00",
        "vacant_slot_amount": "0.00", "amount_at_risk": "0.00", "at_risk_day_count": 0,
        "potential_total_amount": "0.00", "service_period_start": None, "service_period_end": None,
        "payment_release_date": None, "blockers": blockers,
    }


def _blocked_row(kind, service_date, blocker, **values):
    return {"kind": kind, "service_date": service_date.isoformat(), **values, "status": "blocked", "blocker": blocker, "amount": "0.00"}


def _month_bounds(base, months_back=0):
    """First/last calendar day of the month `months_back` months before
    `base` (0 = base's own month)."""
    year, month = base.year, base.month
    for _ in range(months_back):
        month -= 1
        if month < 1:
            month = 12
            year -= 1
    first = date(year, month, 1)
    last = date(year + 1, 1, 1) - timedelta(days=1) if month == 12 else date(year, month + 1, 1) - timedelta(days=1)
    return first, last


def _periods_overlapping(periods, window_start, window_end):
    """Real overlap filter (begin <= window_end AND end >= window_start) --
    replaces reliance on strict-containment dateFrom/dateTo semantics, which
    silently drops a period straddling window_start/window_end."""
    result = []
    for period in periods:
        begin = _date(period, "serviceBeginDate", "DTE_BEGIN_EFFV__c", "Start_Date__c")
        end = _date(period, "serviceEndDate", "DTE_END_EFFV__c", "End_Date__c")
        if begin is None or end is None:
            continue
        if begin <= window_end and end >= window_start:
            result.append(period)
    return result


def _select_last_released_period(periods):
    """Client-side equivalent of a 'paymentBefore' filter: most recent period
    whose release date is <= today, by release date descending. Returns None
    if nothing has released yet (a real, distinct blocked state -- never
    guesses)."""
    today = date.today()
    released = []
    for period in periods:
        release = _date(period, "paymentReleaseDate", "DTE_BATCH_FILE_PMT__c", "release_date")
        if release is not None and release <= today:
            released.append((release, period))
    if not released:
        return None
    released.sort(key=lambda pair: pair[0], reverse=True)
    return released[0][1]


def _select_next_upcoming_period(periods):
    """Client-side counterpart to _select_last_released_period: soonest
    period whose release date is >= today, ascending by release date.
    Deterministic regardless of how many periods are in the list (fresh
    fetch or a reused wider one) -- never a count-based disambiguation.
    Returns None if nothing is scheduled to release yet."""
    today = date.today()
    upcoming = []
    for period in periods:
        release = _date(period, "paymentReleaseDate", "DTE_BATCH_FILE_PMT__c", "release_date")
        if release is not None and release >= today:
            upcoming.append((release, period))
    if not upcoming:
        return None
    upcoming.sort(key=lambda pair: pair[0])
    return upcoming[0][1]


# ==============================================================================
# PAYMENT VIEW (period-scoped) -- ported verbatim from ccare_payment_engine.py
# ==============================================================================

def calculate_payment(raw_bundle: dict[str, Any]) -> dict[str, Any]:
    """Calculate CCCAP payment from a bundle of raw endpoint responses.

    A thin dispatcher over three modes, all sharing the same already-fetched
    authorizations/schedules/rates -- no extra endpoint calls per mode:
    - multi_period (raw_bundle["multi_period_window"] = (start, end)):
      CURRENT_MONTH/ALL -- runs _calculate_for_period once per period that
      genuinely overlaps the window (via _periods_overlapping, not strict
      containment), returns a periods[] list instead of forcing a
      single-period pick.
    - select_last_released (raw_bundle["select_last_released"] = True):
      LAST_PAYOUT -- picks the most recently RELEASED period client-side.
    - default: existing single-period selection (_select_period_or_candidates),
      unchanged for NEXT_PAYOUT/CURRENT_PERIOD_FORECAST/SPECIFIC_PERIOD.
    """
    if not isinstance(raw_bundle, dict):
        return _blocked(["raw_bundle"])

    service_periods = _records(_first(raw_bundle, "service_periods", "servicePeriods", "getServicePeriods"))
    authorizations = _records(_first(raw_bundle, "authorizations", "authData", "getAuthData"))
    schedules = _records(_first(raw_bundle, "schedules", "getSchedules"))
    fiscal_rates = _records(_first(raw_bundle, "fiscal_rates", "fiscalRates", "getFiscalRates"))
    fiscal_agreements = _records(_first(raw_bundle, "fiscal_agreements", "fiscalAgreements"))
    fiscal_schedules = _records(_first(raw_bundle, "fiscal_schedules", "fiscalSchedules"))
    payment_history = _records(_first(raw_bundle, "payment_history", "paymentHistory", "subPayments"))
    holidays = _records(_first(raw_bundle, "holidays", "holidayList", "getHolidayList"))
    vacant_slots = _records(_first(raw_bundle, "vacant_slots", "vacantSlots", "getVacantSlots"))
    county_rate_plans = _records(_first(raw_bundle, "county_rate_plans", "countyRatePlans", "CountyInformation"))
    provider_closures = _records(_first(raw_bundle, "provider_closures", "providerClosures", "getProviderClosures"))
    county_policy_by_id = _county_policy_index(county_rate_plans)
    shared_inputs = (
        authorizations, schedules, fiscal_rates, fiscal_agreements, fiscal_schedules,
        payment_history, holidays, vacant_slots, county_policy_by_id, provider_closures,
    )

    multi_period_window = raw_bundle.get("multi_period_window")
    if multi_period_window:
        window_start, window_end = multi_period_window
        matching_periods = _periods_overlapping(service_periods, window_start, window_end)
        if not matching_periods:
            return _blocked(["service_period"])
        periods_result = [
            _calculate_for_period(period, *shared_inputs)
            for period in sorted(
                matching_periods,
                key=lambda p: _date(p, "serviceBeginDate", "Start_Date__c", "DTE_START__c") or date.min,
            )
        ]
        total = sum((Decimal(p["total_amount"]) for p in periods_result), Decimal("0"))
        all_blockers = sorted(frozenset(b for p in periods_result for b in (p.get("blockers") or [])))
        return {
            "status": "ok",
            "mode": "multi_period",
            "periods": periods_result,
            "total_amount": _money(total),
            "blockers": all_blockers,
        }

    if raw_bundle.get("select_last_released"):
        period = _select_last_released_period(service_periods)
        if period is None:
            # A real, distinct blocked state -- nothing has released yet,
            # never the same as "no service period found."
            return _blocked(["no_released_period"])
        return _calculate_for_period(period, *shared_inputs)

    if raw_bundle.get("select_next_upcoming"):
        # Mirrors select_last_released above: deterministic single-period
        # pick for NEXT_PAYOUT instead of count-based disambiguation, so a
        # stale/wide servicePeriods list never surfaces a false
        # "multiple service periods found" prompt.
        period = _select_next_upcoming_period(service_periods)
        if period is None:
            return _blocked(["no_upcoming_period"])
        return _calculate_for_period(period, *shared_inputs)

    period, candidates = _select_period_or_candidates(service_periods, raw_bundle.get("service_period_id"))
    if candidates is not None:
        # Service-period disambiguation -- 2+ matches surfaces the candidate
        # list so the formatter can ask the provider which one they meant,
        # and positional resolution can resolve a follow-up against this
        # same list.
        return {
            "status": "needs_period_selection",
            "candidates": candidates,
            "rows": [],
            "total_amount": "0.00",
            "attended_care_amount": "0.00",
            "vacant_slot_amount": "0.00",
            "blockers": [],
        }
    if period is None:
        return _blocked(["service_period"])
    return _calculate_for_period(period, *shared_inputs)


def _monthly_limit_counts(schedules, auth_by_name, auth_by_id, holidays, provider_closures, county_policy_by_id, as_of_date):
    """Pass 1: scans ALL fetched schedules -- not date-range-filtered to a
    single service period -- to build the TRUE monthly absence/drop-in day
    count per (auth_id, year-month). County absence/drop-in limits are
    monthly, but a service period can be a sub-range (e.g. weekly) within
    that month; counting only the schedules inside one period's own
    [start, end] undercounts the true monthly total whenever a sibling
    period in the same month also has absences/drop-ins. A PARENT_PENDING
    day is excluded from the count entirely -- it is not yet a confirmed
    absence, matching analyze_attendance_risks()'s own exclusion -- so a
    still-pending day never itself pushes the count over the limit."""
    absence_day_counts: dict[tuple[str, str], int] = {}
    drop_in_day_counts: dict[tuple[str, str], int] = {}
    for schedule in schedules:
        service_date = _date(schedule, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c", "service_date", "schedule_date", "date")
        if not service_date:
            continue
        schedule_auth_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id", "AuthorizationId", "IDN_AUTH__c", "auth_id")
        authorization = auth_by_name.get(schedule_auth_ref) if schedule_auth_ref else None
        if authorization is None and schedule_auth_ref:
            authorization = auth_by_id.get(schedule_auth_ref)
        auth_id = _text(authorization, "Id", "id", "ID_AUTH__c", "authorization_id") if authorization else None
        if authorization is None or not auth_id:
            continue
        authorized_hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours", "authorization_hours", "hours")
        attended_hours = _attended_hours(schedule)
        if attended_hours is None and service_date > as_of_date:
            attended_hours = Decimal("0")
        if authorized_hours is None or attended_hours is None:
            continue
        provider_id = _text(authorization, "IDN_PROVR__c", "provider_id")
        county_id = _text(authorization, "county_id", "CDE_COUNTY__c", "countyId")
        _county_holiday_names = (county_policy_by_id.get(county_id or "", {}) or {}).get("holiday_names") or set()
        classification = _classification(
            provider_closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays, as_of_date,
            _county_holiday_names,
        )
        if classification not in ("ABSENCE", "DROP_IN"):
            continue
        attendance = schedule.get("Attendance__r") if isinstance(schedule, dict) else None
        records = attendance.get("records") if isinstance(attendance, dict) else None
        records = records if isinstance(records, list) else []
        if any(_text(r, "Status__c") == "PARENT_PENDING" for r in records if isinstance(r, dict)):
            continue
        key = (auth_id, service_date.strftime("%Y-%m"))
        if classification == "ABSENCE":
            age_months = _months_of_age(_child_dob(authorization), service_date)
            if age_months is not None and age_months <= 36:
                continue  # enrollment carve-out -- never counted against the limit
            absence_day_counts[key] = absence_day_counts.get(key, 0) + 1
        else:
            drop_in_day_counts[key] = drop_in_day_counts.get(key, 0) + 1
    return absence_day_counts, drop_in_day_counts


def _calculate_for_period(
    period: dict[str, Any],
    authorizations: list[dict[str, Any]],
    schedules: list[dict[str, Any]],
    fiscal_rates: list[dict[str, Any]],
    fiscal_agreements: list[dict[str, Any]],
    fiscal_schedules: list[dict[str, Any]],
    payment_history: list[dict[str, Any]],
    holidays: list[dict[str, Any]],
    vacant_slots: list[dict[str, Any]],
    county_policy_by_id: dict[str, dict[str, Any]],
    provider_closures: list[dict[str, Any]],
) -> dict[str, Any]:
    """The per-day calculation core, shared by both the single-period and
    multi-period dispatch paths in calculate_payment()."""
    period_id = _text(period, "servicePeriodId", "Id", "id", "ID_SERVICE_PERIOD__c", "service_period_id")
    start = _date(period, "serviceBeginDate", "Start_Date__c", "DTE_START__c", "start_date", "startDate", "period_start")
    end = _date(period, "serviceEndDate", "End_Date__c", "DTE_END__c", "end_date", "endDate", "period_end")
    if not period_id or not start or not end or end < start:
        return _blocked(["service_period_dates"])

    # ---- settlement short-circuit ------------------------------------------
    # Once an actual PAID/REQUESTED record is on file for this period, that
    # record is authoritative -- return it directly and skip all per-day
    # computation (no recalculation, ever, for a settled period). subPayment/
    # payment_history rows carry no confirmed authorization-linking field, so
    # this total cannot be scoped to a requested child/county -- settlement
    # amounts are period-wide by definition.
    existing_amount = _existing_payment_amount(payment_history, period_id)
    if existing_amount is not None:
        return {
            "status": "ok",
            "service_period_id": period_id,
            "service_period_start": start.isoformat(),
            "service_period_end": end.isoformat(),
            "payment_release_date": _text(period, "paymentReleaseDate"),
            "payment_history_found": True,
            "rows": [],
            "total_amount": _money(existing_amount),
            "attended_care_amount": _money(existing_amount),
            "vacant_slot_amount": "0.00",
            "amount_at_risk": "0.00",
            "at_risk_day_count": 0,
            "potential_total_amount": _money(existing_amount),
            "blockers": [],
            "settlement_source": "ACTUAL_PAYMENT_RECORD",
            "settlement_scope": "PERIOD_WIDE",
        }

    auth_by_id = _unique_index(authorizations, "Id", "id", "ID_AUTH__c", "authorization_id")
    auth_by_name = _unique_index(authorizations, "Name", "name", "NAM_AUTH__c", "authorization_name")
    fiscal_schedule_index = _fiscal_schedule_index(fiscal_agreements, fiscal_schedules)
    rate_lookup = _rate_lookup(fiscal_rates)
    as_of_date = date.today()

    # ---- per-authorization absence-day and drop-in-day counters -----------
    # Pre-computed against ALL fetched schedules (not just this period's own
    # [start, end]) -- county absence/drop-in limits are monthly, and a
    # service period can be a sub-range (e.g. weekly) within that month, so
    # the count must span the whole month regardless of which period is
    # being rendered. See _monthly_limit_counts().
    absence_day_counts, drop_in_day_counts = _monthly_limit_counts(
        schedules, auth_by_name, auth_by_id, holidays, provider_closures, county_policy_by_id, as_of_date,
    )

    rows: list[dict[str, Any]] = []
    blockers: list[str] = []
    for schedule in sorted(
        schedules,
        key=lambda row: _text(row, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c", "service_date", "schedule_date", "date") or "",
    ):
        service_date = _date(schedule, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c", "service_date", "schedule_date", "date")
        if not service_date or not start <= service_date <= end:
            continue

        # schedule.CI_Authorization_Id__c (bare number) matches
        # authorization.Name -- schedule.Authorization__c/IDN_AUTH__c point
        # to an unrelated DECL-side object and are kept only as a fallback.
        schedule_auth_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id", "AuthorizationId", "IDN_AUTH__c", "auth_id")
        authorization = auth_by_name.get(schedule_auth_ref) if schedule_auth_ref else None
        if authorization is None and schedule_auth_ref:
            authorization = auth_by_id.get(schedule_auth_ref)
        auth_id = _text(authorization, "Id", "id", "ID_AUTH__c", "authorization_id") if authorization else None
        if authorization is None or not auth_id:
            rows.append(_blocked_row("ATTENDED_CARE", service_date, "authorization"))
            blockers.append("authorization_relationship")
            continue

        # authorized_hours lives on the schedule row, not on the
        # authorization record.
        authorized_hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours", "authorization_hours", "hours")
        attended_hours = _attended_hours(schedule)
        if attended_hours is None and service_date > as_of_date:
            # Forecast day -- attendance can't exist yet for a future service
            # date; treat as zero attended hours instead of a data blocker.
            attended_hours = Decimal("0")
        if authorized_hours is None or attended_hours is None:
            rows.append(_blocked_row("ATTENDED_CARE", service_date, "hours"))
            blockers.append("attendance_hours")
            continue

        provider_id = _text(authorization, "IDN_PROVR__c", "provider_id")
        county_id = _text(authorization, "county_id", "CDE_COUNTY__c", "countyId")
        _county_holiday_names = (county_policy_by_id.get(county_id or "", {}) or {}).get("holiday_names") or set()
        classification = _classification(
            provider_closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays, as_of_date,
            _county_holiday_names,
        )
        # Closure-first precedence is unchanged, but positive attendance on a
        # closure date was previously silent -- surface it as an explicit
        # flag for audit visibility without changing the payable outcome.
        _closure_with_attendance = classification == "CARE_NOT_OFFERED" and attended_hours > 0
        rate_type_code = _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c") \
            or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
        age_group_code = _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code") \
            or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c") \
            or _age_group_code(_child_dob(authorization), service_date)

        policy = county_policy_by_id.get(county_id or "", {})
        # Quality tier lives on the resolved fiscal schedule
        # (TXT_CHATS_RATING__c), not on schedule or authorization.
        quality_tier_raw = _quality_tier_for(authorization, rate_type_code, fiscal_schedule_index) \
            or _text(schedule, "quality_tier", "TXT_CHATS_RATING__c") \
            or _text(authorization, "quality_tier", "TXT_CHATS_RATING__c")
        tier = _normalize_tier(quality_tier_raw)

        limit_exceeded_blocker = None
        if classification == "ABSENCE":  # HOLIDAY does not count against absence limit
            # Enrollment carve-out first: <=36 months old, always payable, never
            # counted against the county absence limit.
            age_months = _months_of_age(_child_dob(authorization), service_date)
            if age_months is not None and age_months <= 36:
                classification = "ENROLLMENT_ABSENCE"
            else:
                absence_limit = (policy.get("absence_limits") or {}).get(tier)
                # Count is pre-computed against the WHOLE month by
                # _monthly_limit_counts() -- read only here, never increment,
                # so multiple periods within the same month agree on one
                # true monthly total instead of each counting independently.
                _abs_key = (auth_id, service_date.strftime("%Y-%m"))
                _abs_month_count = absence_day_counts.get(_abs_key, 0)
                if not isinstance(absence_limit, int):
                    limit_exceeded_blocker = "absence_limit_unavailable"
                elif _abs_month_count > absence_limit:
                    limit_exceeded_blocker = "absence_limit_exceeded"
        elif classification == "DROP_IN":
            max_drop_in = policy.get("max_drop_in_days_per_month")
            allow_drop_in = policy.get("allow_drop_in_days")
            if allow_drop_in is False:
                limit_exceeded_blocker = "drop_in_not_allowed"
            elif isinstance(max_drop_in, int):
                _di_key = (auth_id, service_date.strftime("%Y-%m"))
                _di_month_count = drop_in_day_counts.get(_di_key, 0)
                if _di_month_count > max_drop_in:
                    limit_exceeded_blocker = "drop_in_limit_exceeded"

        auth_name = _text(authorization, "Name")
        county_name = (county_policy_by_id.get(county_id or "", {}) or {}).get("county_name")
        child_name = _text((authorization.get("IDN_CLIENT__r") or {}) if isinstance(authorization, dict) else {}, "Name") \
            or _text(authorization, "childName", "child_name", "clientName", "client_name") \
            or _text(schedule, "childName", "child_name", "Contact_Name__c", "clientName", "client_name")

        if limit_exceeded_blocker:
            rows.append({
                "kind": "ATTENDED_CARE",
                "service_date": service_date.isoformat(),
                "authorization_id": auth_id,
                "authorization_name": auth_name,
                "child_name": child_name,
                "county_id": county_id,
                "county_name": county_name,
                "classification": classification,
                "payable_hours": _money(Decimal("0")),
                "amount": _money(Decimal("0")),
                "status": "not_payable",
                "blocker": limit_exceeded_blocker,
            })
            continue

        payable_hours = _payable_hours(classification, authorized_hours, attended_hours, schedule)
        if classification == "NO_CARE":
            continue  # no scheduled care and no attendance -- not a payment event, not a blocker
        if classification == "CARE_NOT_OFFERED" or payable_hours <= 0:
            rows.append({
                "kind": "ATTENDED_CARE",
                "service_date": service_date.isoformat(),
                "authorization_id": auth_id,
                "authorization_name": auth_name,
                "child_name": child_name,
                "county_id": county_id,
                "county_name": county_name,
                "classification": classification,
                "payable_hours": _money(Decimal("0")),
                "amount": _money(Decimal("0")),
                "status": "not_payable",
            })
            continue

        # Joins authorization -> fiscal schedule -> fiscal rate row.
        rate, rate_blocker = _resolve_attended_rate(
            authorization, rate_type_code, age_group_code, payable_hours, fiscal_schedule_index, rate_lookup,
        )
        if rate is None:
            paid_tier = paid_tier_for_hours(payable_hours)
            rows.append(_blocked_row(
                "ATTENDED_CARE", service_date, rate_blocker, auth_id=auth_id, paid_tier=paid_tier,
                rate_type_label=RATE_TYPE_LABELS.get(rate_type_code or "", rate_type_code),
            ))
            blockers.append(rate_blocker)
            continue
        paid_tier = paid_tier_for_hours(payable_hours)
        amount = rate
        confirmation_risk = _attendance_confirmation_risk(schedule, service_date, as_of_date, classification)
        # Basis tells the provider whether this amount is grounded in actual
        # recorded attendance or in scheduled/authorized hours. Only HOLIDAY
        # (a deliberate closure policy) and FORECAST (a genuinely future date
        # -- attendance can't exist yet) are paid on authorized hours.
        # ABSENCE/ENROLLMENT_ABSENCE are excluded here entirely: they now pay
        # 0 (actual attendance), so they never reach this row shape -- see
        # _payable_hours().
        _basis = "scheduled" if classification in {"HOLIDAY", "FORECAST"} else "attended"
        row = {
            "kind": "ATTENDED_CARE",
            "service_date": service_date.isoformat(),
            "authorization_id": auth_id,
            "authorization_name": auth_name,
            "child_name": child_name,
            "county_id": county_id,
            "county_name": county_name,
            "classification": classification,
            "rate_type_label": RATE_TYPE_LABELS.get(rate_type_code or "", rate_type_code),
            "payment_basis": _basis,
            "paid_tier": paid_tier,
            "payable_hours": _money(payable_hours),
            "rate": _money(rate),
            "amount": _money(amount),
            "status": "at_risk" if confirmation_risk else "calculated",
        }
        if confirmation_risk:
            row["confirmation_risk"] = confirmation_risk
        rows.append(row)

    # ---- vacant slots are contract ranges, monthly cap recomputed
    # stateless per week (see _vacant_slot_payable_days) --------------------
    for slot in vacant_slots:
        if not isinstance(slot, dict):
            continue
        slot_county_id = _text(slot, "CDE_COUNTY__c")
        slot_county_holiday_names = (county_policy_by_id.get(slot_county_id or "", {}) or {}).get("holiday_names") or []
        payable_days, excluded_days = _vacant_slot_payable_days(
            slot, start, end, holidays, provider_closures, slot_county_holiday_names,
        )
        for slot_date in excluded_days:
            rows.append(_blocked_row("VACANT_SLOT", slot_date, "vacant_slot_monthly_cap_exceeded"))
            blockers.append("vacant_slot_monthly_cap_exceeded")
        for slot_date in payable_days:
            amount, slot_blocker = _vacant_slot_rate(slot, fiscal_schedule_index, rate_lookup)
            if amount is None:
                rows.append(_blocked_row("VACANT_SLOT", slot_date, slot_blocker))
                blockers.append(slot_blocker)
                continue
            rows.append({
                "kind": "VACANT_SLOT", "service_date": slot_date.isoformat(), "amount": _money(amount),
                "status": "calculated", "county_id": slot_county_id,
                "county_name": (county_policy_by_id.get(slot_county_id or "", {}) or {}).get("county_name"),
            })

    calculated_rows = [r for r in rows if r.get("status") == "calculated"]
    at_risk_rows = [r for r in rows if r.get("status") == "at_risk"]
    total = sum((Decimal(r["amount"]) for r in calculated_rows), Decimal("0"))
    amount_at_risk = sum((Decimal(r["amount"]) for r in at_risk_rows), Decimal("0"))
    _attended_rows = [r for r in calculated_rows if r.get("kind") == "ATTENDED_CARE" and r.get("classification") != "FORECAST"]
    _forecast_rows = [r for r in calculated_rows if r.get("kind") == "ATTENDED_CARE" and r.get("classification") == "FORECAST"]
    unique_blockers = sorted(frozenset(blockers))
    return {
        "status": "blocked" if unique_blockers else "ok",
        "service_period_id": period_id,
        "service_period_start": start.isoformat(),
        "service_period_end": end.isoformat(),
        "payment_release_date": _text(period, "paymentReleaseDate"),
        "payment_history_found": False,
        "rows": rows,
        "total_amount": _money(total),
        "attended_care_amount": _money(sum((Decimal(r["amount"]) for r in _attended_rows), Decimal("0"))),
        "attended_care_hours": _money(sum((Decimal(str(r.get("payable_hours") or "0")) for r in _attended_rows), Decimal("0"))),
        "forecast_amount": _money(sum((Decimal(r["amount"]) for r in _forecast_rows), Decimal("0"))),
        "forecast_hours": _money(sum((Decimal(str(r.get("payable_hours") or "0")) for r in _forecast_rows), Decimal("0"))),
        "vacant_slot_amount": _money(sum((Decimal(r["amount"]) for r in calculated_rows if r["kind"] == "VACANT_SLOT"), Decimal("0"))),
        "amount_at_risk": _money(amount_at_risk),
        "at_risk_day_count": len(at_risk_rows),
        "potential_total_amount": _money(total + amount_at_risk),
        "blockers": unique_blockers,
    }


# ==============================================================================
# ATTENDANCE-RISK VIEW (rolling lookback window, period-agnostic) -- ported
# near-verbatim from attendance_risks_analyzer_py.py. Deliberately keeps its
# own small string-date helpers (below) rather than forcing the payment
# view's date-object helpers on it -- the two views operate over genuinely
# different scopes (one resolved period vs. a rolling lookback window), and
# only the closure/carve-out RULES need to agree, not their date type.
# ==============================================================================

PARENT_PENDING = "PARENT_PENDING"


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


def _is_provider_closure_str(closures, provider_id, county_id, schedule_date):
    """Same closure rule _is_provider_closure() enforces, but against a
    string-keyed schedule_date (this view's native date representation)
    instead of a date object."""
    for closure in closures:
        if not isinstance(closure, dict):
            continue
        if not _truthy(closure, "IND_ACTIVE__c", "active"):
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


def _months_of_age_str(dob_key, on_date_key):
    """Same enrollment-absence (<=36 months) carve-out rule _months_of_age()
    enforces, against string-keyed dates."""
    dob = _date_key(dob_key)
    on_date_str = on_date_key
    if not dob or not on_date_str:
        return None
    dob_d, on_d = date.fromisoformat(dob), date.fromisoformat(on_date_str)
    months = (on_d.year - dob_d.year) * 12 + (on_d.month - dob_d.month)
    if on_d.day < dob_d.day:
        months -= 1
    return max(months, 0)


def analyze_attendance_risks(providers, rate_plans, authorizations, schedules, org_holiday_records, provider_closures, child_filter, county_filter, data_snapshot_version):
    """Absence-limit risk and unconfirmed-attendance analysis, over ALL
    fetched schedules regardless of service period -- a rolling lookback
    window from today, independent of any resolved payment period. Returns
    the same shape attendance_risks_analyzer_py.py wrote to context."""
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

    if input_errors:
        return {"status": "FAILED_BAD_INPUT", "error": "; ".join(input_errors), "provider_id": provider_id}

    rate_plan_by_county = {}
    for plan in rate_plans:
        county_id = _text(plan, "countyId", "county_id", "CDE_COUNTY__c")
        if county_id:
            rate_plan_by_county[county_id] = plan

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

        if child_filter and (child_name or "").strip().lower() not in child_filter:
            continue
        county_name_for_filter = _text(rate_plan_by_county.get(county_id, {}), "countyName", "county_name") if county_id else None
        if county_filter and (county_name_for_filter or "").strip().lower() not in county_filter:
            continue

        attendance_records = (schedule.get("Attendance__r") or {}).get("records") or []
        is_pending = any(
            _text(r, "Status__c") == PARENT_PENDING for r in attendance_records if isinstance(r, dict)
        )
        if is_pending:
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

        authorized_hours = float((_number(schedule, "CI_Authorization_Hours__c") or Decimal("0")))
        # Only a real, confirmed 0 (both counts present, post the payment
        # engine's _attended_hours() fix) counts as absence -- a genuinely
        # missing value (None: check-in/check-out fields absent from the
        # record entirely) must NOT be guessed as absence. Matches the
        # payment engine's "block, don't guess" principle instead of
        # silently treating missing data as a confirmed zero-attendance day.
        _attended_raw = _attended_hours(schedule)
        if _attended_raw is None:
            continue
        attended_hours = float(_attended_raw)

        if authorized_hours <= 0 or attended_hours != 0:
            continue
        if not child_id or not county_id or not linked_provider_id:
            continue
        if schedule_date in org_holidays:
            continue
        if _is_provider_closure_str(provider_closures, linked_provider_id, county_id, schedule_date):
            continue

        # Future scheduled dates are not absences yet.
        if schedule_date > reference_date:
            continue

        # Enrollment-absence carve-out: <=36 months old on this date is exempt
        # from the county absence limit, so it should not count toward the
        # near-limit alert either.
        client = auth.get("IDN_CLIENT__r") if isinstance(auth, dict) else None
        child_dob = _text(client, "DTE_DOB__c") if isinstance(client, dict) else None
        age_months = _months_of_age_str(child_dob, schedule_date)
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
                # Signed value preserved -- clamping to zero hides how far
                # over the limit a child actually was.
                "confirmed_absence_remaining": confirmed_remaining,
                "potential_absence_remaining": potential_remaining,
                "status": _status_from_remaining(confirmed_remaining, potential_remaining, tentative_used, near_limit_threshold),
                "year_month": group["year_month"],
                "confirmed_absence_dates": sorted(group["confirmed_absence_dates"]),
                "probable_absence_dates": sorted(group["probable_absence_dates"]),
            })

    def _passes(row):
        if child_filter and str(row.get("child_name") or "").strip().lower() not in child_filter:
            return False
        if county_filter and str(row.get("county_name") or "").strip().lower() not in county_filter:
            return False
        return True

    if child_filter or county_filter:
        approaching_absence_limits = [r for r in approaching_absence_limits if _passes(r)]
        pending_confirmation_records = [r for r in pending_confirmation_records if _passes(r)]

    return {
        "provider_id": provider_id,
        "reference_date": reference_date,
        "approaching_absence_limits": sorted(approaching_absence_limits, key=lambda r: (r["county_id"] or "", r["child_id"] or "")),
        "pending_confirmation_records": sorted(pending_confirmation_records, key=lambda r: (r["date"], r.get("child_id") or "")),
        "lookback_days": lookback_days,
        "scopeFingerprint": {
            "child_filter": sorted(child_filter),
            "county_filter": sorted(county_filter),
            "as_of_date": reference_date,
            "dataSnapshotVersion": data_snapshot_version,
        },
    }


# ==============================================================================
# PAYOUT-IMPACT VIEW -- ported from ccare_payout_impact_correlator.py, but its
# entire duplicate rate-lookup/classification core is REMOVED. Every row's
# dollar amount is now resolved via the SAME _classification()/_payable_hours()
# /_resolve_attended_rate() the payment view uses, rated on payable_hours
# post-classification -- never on raw authorized_hours. This is the fix for
# the calculation-drift bug: one amount per day, shared by both views.
# ==============================================================================

def _count_value(row, *keys):
    value = _number(row, *keys)
    return int(value) if value is not None else 0


def _risk_identity(schedule, fallback_auth=None, fallback_date=None, fallback_child=None):
    schedule_id = _text(schedule, "Id", "id", "schedule_id")
    if schedule_id:
        return ("schedule", schedule_id)
    auth_id = _text(schedule, "CI_Authorization_Id__c", "authorization_id", "auth_id") or fallback_auth
    service_date = _text(schedule, "CI_Authorization_Date__c", "date") or fallback_date
    child_id = _text(schedule, "IDN_CLIENT__c", "child_id", "childId") or fallback_child
    return ("day", auth_id or child_id or "unknown", service_date or "unknown")


def _schedule_indices(all_schedules):
    """{(child_id, date): schedule}, {(auth_ref, date): schedule}, and
    {schedule_id: schedule} -- built from the SAME already-fetched/filtered
    ScheduleInformation the payment view iterates, so this view never
    re-fetches or re-filters schedules itself."""
    by_child_date = {}
    by_auth_date = {}
    by_id = {}
    for schedule in all_schedules:
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


def _rated_amount_for_schedule(schedule, authorization, county_id, provider_id, schedule_index, rate_lookup, holidays, provider_closures, county_holiday_names, as_of_date, authorized_hours_override=None):
    """The single shared path from a schedule row to a rated dollar amount --
    classification -> payable_hours -> fiscal rate. authorized_hours_override
    lets a caller supply the hours it already resolved (e.g. from the
    analyzer's absence-day grouping) instead of re-reading the schedule."""
    service_date = _date(schedule, "CI_Authorization_Date__c", "Service_Date__c", "date")
    authorized_hours = authorized_hours_override if authorized_hours_override is not None else _number(schedule, "CI_Authorization_Hours__c", "authorized_hours")
    if authorized_hours is None:
        return None, None, "attendance_hours"
    attended_hours = _attended_hours(schedule)
    if attended_hours is None:
        attended_hours = Decimal("0")
    if service_date is None:
        return None, None, "service_period_dates"
    classification = _classification(
        provider_closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays, as_of_date,
        county_holiday_names,
    )
    payable_hours = _payable_hours(classification, authorized_hours, attended_hours, schedule)
    rate_type_code = _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c") \
        or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
    age_group_code = _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code") \
        or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c") \
        or _age_group_code(_child_dob(authorization), service_date)
    rate, blocker = _resolve_attended_rate(authorization, rate_type_code, age_group_code, payable_hours, schedule_index, rate_lookup)
    return rate, payable_hours, blocker


def correlate_payout_impact(analyzer_result, all_authorizations, all_schedules, fiscal_agreements, fiscal_schedules, fiscal_rates, county_rate_plans, holidays, provider_closures, county_policy_by_id, child_filter, county_filter, as_of_date):
    """Resolves $/hours at risk for each attendance-risk row (absence-limit,
    unconfirmed attendance, incomplete check-in/out) against the SAME fiscal
    core the payment view uses."""
    approaching = analyzer_result.get("approaching_absence_limits") or []
    unconfirmed = analyzer_result.get("pending_confirmation_records") or []

    # Zero-risk short-circuit -- skip the fiscal-rate index build entirely
    # when there is nothing to correlate (e.g. a STARTER turn with no risk).
    if not approaching and not unconfirmed:
        return {
            "status": "ok", "rows": [], "total_hours_at_risk": 0.0, "total_dollar_at_risk": "0.00",
            "absence_risk_hours": 0.0, "absence_risk_amount": "0.00",
            "unconfirmed_risk_hours": 0.0, "unconfirmed_risk_amount": "0.00",
            "incomplete_risk_hours": 0.0, "incomplete_risk_amount": "0.00",
            "unconfirmed_count": 0, "unconfirmed_children": 0,
        }

    _ref_date = (analyzer_result.get("reference_date") or "")[:10]
    _lookback = int(analyzer_result.get("lookback_days") or 9)
    _win_start = None
    try:
        _win_start = str(date.fromisoformat(_ref_date) - timedelta(days=_lookback))
    except Exception:
        pass
    if _win_start:
        unconfirmed = [r for r in unconfirmed if (r.get("date") or "") >= _win_start]

    auth_by_id = {_text(row, "Id", "id", "ID_AUTH__c", "authorization_id"): row for row in all_authorizations if _text(row, "Id", "id", "ID_AUTH__c", "authorization_id")}
    auth_by_name = {_text(row, "Name", "name", "NAM_AUTH__c"): row for row in all_authorizations if _text(row, "Name", "name", "NAM_AUTH__c")}
    by_child_date, by_auth_date, by_id = _schedule_indices(all_schedules)
    county_name_by_id = {
        _text(plan, "countyId", "county_id", "CDE_COUNTY__c"): _text(plan, "countyName", "county_name")
        for plan in county_rate_plans
        if _text(plan, "countyId", "county_id", "CDE_COUNTY__c")
    }

    schedule_index = _fiscal_schedule_index(fiscal_agreements, fiscal_schedules)
    rate_lookup = _rate_lookup(fiscal_rates)

    rows = []
    total_hours = Decimal("0")
    total_dollar = Decimal("0")
    absence_unresolved = False
    unconfirmed_unresolved = False
    absence_identities = {}
    unconfirmed_identities = {}
    _join_attempts = 0
    _join_unmatched = 0

    def _skip(child_name, county_name):
        if child_filter and (child_name or "").lower() not in child_filter:
            return True
        if county_filter and county_name and (county_name or "").lower() not in county_filter:
            return True
        return False

    def _record(child_name, authorization_id, county_name, hours, rate, blocker, reason, category=None):
        nonlocal total_hours, total_dollar
        if rate is None:
            rows.append({
                "child_name": child_name, "authorization_id": authorization_id, "county_name": county_name,
                "care_hours": float(hours) if hours is not None else None, "amount": None, "amount_type": None,
                "reason": blocker, "risk_category": category,
            })
            return
        total_hours += hours
        total_dollar += rate
        rows.append({
            "child_name": child_name, "authorization_id": authorization_id, "county_name": county_name,
            "care_hours": float(hours), "amount": _money(rate), "amount_type": "At-risk",
            "reason": reason, "risk_category": category,
        })

    for group in approaching:
        if not isinstance(group, dict):
            continue
        if _skip(group.get("child_name"), group.get("county_name")):
            continue
        limit = int(group.get("absence_limit") or 0)
        confirmed_dates = sorted(group.get("confirmed_absence_dates") or [])
        probable_dates = sorted(group.get("probable_absence_dates") or [])
        # Only dates that exceed the allowed limit carry payment risk. First
        # `limit` confirmed absences are within the paid allowance.
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
                absence_unresolved = True
                _join_unmatched += 1
                continue
            authorization = auth_by_id.get(group.get("authorization_id")) or auth_by_name.get(
                _text(schedule, "CI_Authorization_Id__c", "authorization_id")
            ) or {}
            county_id = group.get("county_id")
            provider_id = group.get("provider_id")
            _holiday_names = (county_policy_by_id.get(county_id or "", {}) or {}).get("holiday_names") or set()
            rate, hours, blocker = _rated_amount_for_schedule(
                schedule, authorization, county_id, provider_id, schedule_index, rate_lookup,
                holidays, provider_closures, _holiday_names, as_of_date,
            )
            authorization_id = _text(schedule, "CI_Authorization_Id__c", "authorization_id")
            _record(
                group.get("child_name"), authorization_id, group.get("county_name"), hours or Decimal("0"), rate, blocker,
                "Absence beyond the confirmed limit is at risk of exclusion from payment", "absence",
            )

    for item in unconfirmed:
        if not isinstance(item, dict):
            continue
        if _skip(item.get("child_name"), None):
            continue
        _join_attempts += 1
        schedule = by_id.get(str(item.get("schedule_id")))
        if not schedule:
            unconfirmed_unresolved = True
            _join_unmatched += 1
            continue
        identity = _risk_identity(schedule, fallback_auth=item.get("auth_id"), fallback_date=item.get("date"), fallback_child=item.get("child_id"))
        if identity in unconfirmed_identities:
            continue
        unconfirmed_identities[identity] = 1
        county_id = item.get("county_id") or _text(schedule, "CDE_COUNTY__c")
        provider_id = _text(schedule, "IDN_PROVIDER__c")
        authorization = auth_by_id.get(item.get("auth_id")) or auth_by_name.get(
            _text(schedule, "CI_Authorization_Id__c", "authorization_id")
        ) or {}
        _holiday_names = (county_policy_by_id.get(county_id or "", {}) or {}).get("holiday_names") or set()
        rate, hours, blocker = _rated_amount_for_schedule(
            schedule, authorization, county_id, provider_id, schedule_index, rate_lookup,
            holidays, provider_closures, _holiday_names, as_of_date,
        )
        _record(
            item.get("child_name"), item.get("auth_id"), county_name_by_id.get(county_id), hours or Decimal("0"), rate, blocker,
            "Pending parent confirmation -- payment not yet finalized", "unconfirmed",
        )

    for schedule in all_schedules:
        check_in_count = _count_value(schedule, "Check_In_Count__c", "check_in_count", "checkInCount")
        check_out_count = _count_value(schedule, "Check_Out_Count__c", "check_out_count", "checkOutCount")
        if not ((check_in_count > 0 and check_out_count == 0) or (check_out_count > 0 and check_in_count == 0)):
            continue
        service_date_txt = _text(schedule, "CI_Authorization_Date__c", "date")
        if _win_start and service_date_txt and service_date_txt < _win_start:
            continue
        authorization_ref = _text(schedule, "CI_Authorization_Id__c", "authorization_id")
        authorization = auth_by_name.get(authorization_ref) or auth_by_id.get(authorization_ref) or {}
        child_name = _text(
            authorization.get("IDN_CLIENT__r") if isinstance(authorization, dict) else None, "Name", "name", "NAM_FIRST__c",
        ) or _text(schedule, "child_name", "childName")
        _county_name_for_skip = _text(authorization.get("CDE_COUNTY__r") if isinstance(authorization, dict) else None, "Name", "name")
        if _skip(child_name, _county_name_for_skip):
            continue
        _join_attempts += 1
        if _risk_identity(
            schedule, fallback_auth=authorization_ref, fallback_date=service_date_txt,
            fallback_child=_text(schedule, "IDN_CLIENT__c", "child_id", "childId"),
        ) in unconfirmed_identities:
            continue
        county_id = _text(authorization, "CDE_COUNTY__c", "county_id")
        provider_id = _text(schedule, "IDN_PROVIDER__c", "provider_id") or _text(authorization, "IDN_PROVR__c", "provider_id")
        _holiday_names = (county_policy_by_id.get(county_id or "", {}) or {}).get("holiday_names") or set()
        rate, hours, blocker = _rated_amount_for_schedule(
            schedule, authorization, county_id, provider_id, schedule_index, rate_lookup,
            holidays, provider_closures, _holiday_names, as_of_date,
        )
        _record(
            child_name, authorization_ref, _text(authorization.get("CDE_COUNTY__r") if isinstance(authorization, dict) else None, "Name", "name"),
            hours or Decimal("0"), rate, blocker, "Incomplete check-in or check-out -- payment may be withheld", "incomplete",
        )
        if rows:
            rows[-1]["schedule_id"] = _text(schedule, "Id", "id")
            rows[-1]["date"] = service_date_txt

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


# ==============================================================================
# ENTRY POINT HELPERS
# ==============================================================================

def _ctx(key, default=None):
    """Read shared task state from context only."""
    parts = key.split(".")
    value = read_context(parts[0])
    for part in parts[1:]:
        if not isinstance(value, dict):
            return default
        value = value.get(part)
    return value if value is not None else default


def _extract_ids(items, *fields):
    source = items if isinstance(items, list) else _as_list(items)
    ids = []
    for item in source:
        if not isinstance(item, dict):
            continue
        for field in fields:
            value = (item.get(field) or "").strip()
            if value and value not in ids:
                ids.append(value)
                break
    return ids


def _as_list(v):
    if isinstance(v, list):
        return [item for item in v if isinstance(item, dict)]
    if isinstance(v, dict):
        for k in ("records", "items", "results", "data"):
            if isinstance(v.get(k), list):
                return [item for item in v[k] if isinstance(item, dict)]
    return []


# ==============================================================================
# ENTRY POINT -- reads context ONCE, applies child/county filtering ONCE
# (shared by every view below), then dispatches by turnRequest.action.
# ==============================================================================

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

# Shared child/county filtering -- applied ONCE for every view (payment,
# attendance risk, payout impact). Previously this same filter logic was
# independently re-implemented in all three original task files.
_child_filter = {c.strip().lower() for c in (_turn_request.get("childNames") or []) if c}
_county_name_filter = {c.strip().lower() for c in (_turn_request.get("countyNames") or []) if c}

_authorizations = _authorizations_all
if _child_filter:
    _authorizations = [
        a for a in _authorizations
        if _text((a.get("IDN_CLIENT__r") or {}) if isinstance(a, dict) else {}, "Name") is not None
        and _text(a.get("IDN_CLIENT__r") or {}, "Name").strip().lower() in _child_filter
    ]
if _county_name_filter:
    _county_name_to_id = {}
    for _row in _county_info if isinstance(_county_info, list) else []:
        _name = _text(_row, "countyName", "county_name", "NAM_COUNTY__c", "Name")
        _cid = _text(_row, "countyId", "county_id", "CDE_COUNTY__c", "Id", "id")
        if _name and _cid:
            _county_name_to_id.setdefault(_name.strip().lower(), _cid)
    _allowed_county_ids = {_county_name_to_id[n] for n in _county_name_filter if n in _county_name_to_id}
    _authorizations = [a for a in _authorizations if _text(a, "CDE_COUNTY__c", "county_id") in _allowed_county_ids]
    _vacant_slots_bundle = _payment_bundle.get("vacantSlots") if isinstance(_payment_bundle, dict) else None
    if isinstance(_vacant_slots_bundle, list):
        _payment_bundle["vacantSlots"] = [
            s for s in _vacant_slots_bundle
            if isinstance(s, dict) and _text(s, "CDE_COUNTY__c") in _allowed_county_ids
        ]


def _schedule_matches_filters(schedule):
    if not isinstance(schedule, dict):
        return False
    if _child_filter:
        child_name = _text(schedule, "IDN_CLIENT__r.Name", "childName", "child_name", "clientName", "client_name")
        if not child_name or child_name.strip().lower() not in _child_filter:
            return False
    if _county_name_filter:
        county_name = _text(schedule, "CDE_COUNTY__r.Name", "countyName", "county_name")
        if not county_name or county_name.strip().lower() not in _county_name_filter:
            return False
    return True


_schedules = _schedules_all
if _child_filter or _county_name_filter:
    _schedules = [s for s in _schedules_all if _schedule_matches_filters(s)]

_provider_closures = _records(_first(_payment_bundle, "provider_closures", "providerClosures", "getProviderClosures")) if isinstance(_payment_bundle, dict) else []
_county_policy_by_id = _county_policy_index(_county_info)
_fiscal_agreements = _records(_first(_payment_bundle, "fiscal_agreements", "fiscalAgreements")) if isinstance(_payment_bundle, dict) else []
_fiscal_schedules = _records(_first(_payment_bundle, "fiscal_schedules", "fiscalSchedules")) if isinstance(_payment_bundle, dict) else []
_fiscal_rates = _records(_first(_payment_bundle, "fiscal_rates", "fiscalRates", "getFiscalRates")) if isinstance(_payment_bundle, dict) else []

_payment_result = None
_attendance_result = None
_impact_result = None

if _action == "PAYMENT":
    if not isinstance(_payment_bundle, dict) or not _payment_bundle:
        _payment_result = _blocked(["payment_data_collection"])
    else:
        _raw_bundle = {
            **_payment_bundle,
            "authData": {"authorizations": _authorizations},
            "schedules": _schedules,
            "holidayList": _holidays,
            "countyRatePlans": _county_info,
        }
        _payment_result = calculate_payment(_raw_bundle)

    _resolved_period_ids = (
        [p.get("service_period_id") for p in (_payment_result.get("periods") or [])]
        if _payment_result.get("mode") == "multi_period"
        else [_payment_result.get("service_period_id")]
    )
    _payment_result["scopeFingerprint"] = {
        "resolved_service_period_ids": sorted(str(p) for p in _resolved_period_ids if p),
        "child_filter": sorted(_child_filter),
        "county_filter": sorted(_county_name_filter),
        "as_of_date": _as_of_date.isoformat(),
        "dataSnapshotVersion": _data_snapshot_version,
        # Which subFilter produced this result -- a cached result from a
        # different subFilter (e.g. ALL vs NEXT_PAYOUT) must never be reused
        # just because child/county/snapshot happen to match.
        "subFilter": _sub_filter,
    }
    write_context("paymentResult", _payment_result)

if _action in ("ATTENDANCE", "STARTER"):
    # engine_cache_gate can route here with engineCacheValid=NO purely because
    # PAYOUT_IMPACT/STARTER always forces a fresh engine run (to recompute
    # impact) -- that does NOT mean the attendance-risk SCAN itself needs to
    # re-run. Check attendanceCacheValid separately so a cache-valid scope
    # still reuses the cached scan instead of paying for it twice.
    _attendance_cache_valid = _turn_request.get("attendanceCacheValid") == "YES"
    _cached_attendance = _ctx("attendance_risks_analyzer_py")
    if _attendance_cache_valid and isinstance(_cached_attendance, dict) and _cached_attendance.get("status") != "FAILED_BAD_INPUT":
        _attendance_result = _cached_attendance
    else:
        _attendance_result = analyze_attendance_risks(
            _providers, _county_info, _authorizations, _schedules, _holidays, _provider_closures,
            _child_filter, _county_name_filter, _data_snapshot_version,
        )
        write_context("input.provider_id", _attendance_result.get("provider_id"))
        write_context("input.schedules_count", len(_schedules))

    if _attendance_result.get("status") == "FAILED_BAD_INPUT":
        write_context("result.error", _attendance_result)
    else:
        # Compat key: ccare_response_formatter.py reads _ctx("attendance_risks_analyzer_py")
        # directly -- preserved so the formatter needs no changes.
        write_context("attendance_risks_analyzer_py", _attendance_result)
        write_context("result.approaching_absence_limits", _attendance_result["approaching_absence_limits"])
        write_context("result.pending_confirmation_records", _attendance_result["pending_confirmation_records"])
        write_context("result.scopeFingerprint", _attendance_result["scopeFingerprint"])

        if _sub_filter == "PAYOUT_IMPACT" or _action == "STARTER":
            _impact_result = correlate_payout_impact(
                _attendance_result, _authorizations, _schedules, _fiscal_agreements, _fiscal_schedules,
                _fiscal_rates, _county_info, _holidays, _provider_closures, _county_policy_by_id,
                _child_filter, _county_name_filter, _as_of_date,
            )
            # Same snapshot risk_categories update the original correlator performed.
            _data_result = _ctx("data_collection_result") or {}
            _snapshot = (_data_result.get("snapshot") if isinstance(_data_result, dict) else None) or {}
            _risk_categories = _snapshot.setdefault("risk_categories", {})
            _absence_category = _risk_categories.setdefault("approaching_absence_limits", {})
            _pending_category = _risk_categories.setdefault("pending_parent_confirmations", {})
            _absence_category["potential_loss_hours"] = _impact_result["absence_risk_hours"]
            _absence_category["potential_loss_amount"] = _impact_result["absence_risk_amount"]
            _pending_category["potential_loss_hours"] = _impact_result["unconfirmed_risk_hours"]
            _pending_category["potential_loss_amount"] = _impact_result["unconfirmed_risk_amount"]
            _pending_category["days"] = _impact_result.get("unconfirmed_count", 0)
            _pending_category["children"] = _impact_result.get("unconfirmed_children", 0)
            _incomplete_category = _risk_categories.setdefault("incomplete_attendance", {})
            _incomplete_category["potential_loss_hours"] = _impact_result["incomplete_risk_hours"]
            _incomplete_category["potential_loss_amount"] = _impact_result["incomplete_risk_amount"]
            _data_result["snapshot"] = _snapshot
            write_context("snapshot", _snapshot)
            write_context("data_collection_result", _data_result)
            write_context("payoutImpactResult", _impact_result)

_final_result = _payment_result if _payment_result is not None else (_impact_result if _impact_result is not None else (_attendance_result or {}))
respond(_final_result, confidence=1.0)

# __________________________GenAI: Generated code ends here______________________________