"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________

ccare_payment_engine, v1.5.0. Calculates CCCAP payment from raw
Salesforce/DECL service-period, authorization, schedule, fiscal-rate, and
payment-history data. Handles settlement short-circuit, absence/drop-in
limit enforcement, vacant-slot fees, and single/multi-period dispatch by
subFilter (NEXT_PAYOUT, LAST_PAYOUT, CURRENT_PERIOD_FORECAST, CURRENT_MONTH,
ALL, SPECIFIC_PERIOD).

Runtime affordances: read_context, write_context, respond.
"""

import encodings.idna
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
# CALCULATION CORE (pure functions -- no AAF context access)
# ==============================================================================

# Same lookback window attendance_risks_analyzer_py.py uses for
# unconfirmed-attendance detection -- a calculated day inside this window is
# "at risk" (not yet guaranteed), not a settled amount.
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
    """Same normalization attendance_risks_analyzer uses, so both tasks agree
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
            # 2026-09-26 (confirmed): countyholidayList is semicolon-separated
            # holiday NAMES, matched against getHolidayList's CDE_HOL__c.
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

    Two real sources feed this, both confirmed against live samples:
    - fiscal_agreements (from the provider-data bundle) carries nested
      Rate_Schedules__r records directly under each agreement.
    - fiscal_schedules (the flat list from getFiscalRates) links back to its
      agreement via IDN_AGRMT_FISCAL__c, so the agreement's provider/county
      scope is resolved from fiscal_agreements first.
    """
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
    """2026-09-26 (confirmed rule): checked BEFORE holiday/absence when a
    scheduled day has zero attendance. Closures come from getProviderData's
    providerClosures (T_PROVR_CLOSURE__c: IDN_PROVIDER__c, CDE_COUNTY__c,
    DTE_BEGIN_CLOSURE__c, IND_ACTIVE__c) -- single-day closures (no end-date
    field confirmed), matched by exact date."""
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
    NO_PAYMENT row (a real $0 rate) before giving up. Never guesses."""
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
    """2026-09-26 (confirmed): countyholidayList is semicolon-separated
    holiday NAMES; getHolidayList's CDE_HOL__c carries the matching name.
    A county with no configured holiday list has no county-specific
    holidays applied (fails closed -- never falls back to a global match)."""
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
    """2026-09-26 (confirmed rule): weekly service period, monthly cap
    recomputed fresh every call from config alone -- never from stored
    history or a running total. A period straddling a month boundary is
    split into per-month segments; each segment's remaining cap room =
    CNT_DAYS_OF_MONTH__c minus the eligible days that fall between that
    month's 1st and the day before this segment starts (recomputed the same
    way, not fetched). Returns (payable_days, excluded_days) -- excluded_days
    are eligible but beyond the month's remaining cap room this week."""
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
    """2026-09-26 (corrected mapping, confirmed against real
    batchsit_t_fiscal_rate__x rows -- there is no cde_care_level__c field on
    that object; the only differentiator per rate_type+care_unit is
    cde_age_group__c). A vacant slot has no child, so its CDE_CARE_LEVEL__c
    fills the age_group slot in the SAME rate_lookup attended-care rows
    use: (ext_id, rate_type, age_group, care_unit)."""
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


def calculate_payment(raw_bundle: dict[str, Any]) -> dict[str, Any]:
    """Calculate CCCAP payment from a bundle of raw endpoint responses.

    2026-09-25 (service-period date filter rework): now a thin dispatcher
    over three modes, all sharing the same already-fetched authorizations/
    schedules/rates -- no extra endpoint calls per mode:
    - multi_period (raw_bundle["multi_period_window"] = (start, end)):
      CURRENT_MONTH/ALL -- runs _calculate_for_period once per period that
      genuinely overlaps the window (via _periods_overlapping, not Apex's
      strict containment), returns a periods[] list instead of forcing a
      single-period pick.
    - select_last_released (raw_bundle["select_last_released"] = True):
      LAST_PAYOUT -- picks the most recently RELEASED period client-side
      (_select_last_released_period), since the Apex layer has no reverse
      equivalent of paymentAfter.
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

    period, candidates = _select_period_or_candidates(service_periods, raw_bundle.get("service_period_id"))
    if candidates is not None:
        # 2026-09-25: service-period disambiguation -- 2+ matches used to
        # silently return None -> blocked with no detail. Now surfaces the
        # candidate list so ccare_response_formatter can ask the provider
        # which one they meant, and ccare_unified_intent_router's STEP 0 can
        # resolve a follow-up "the second one" against this same list.
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
    """The original calculate_payment per-day core, extracted so both the
    single-period and multi-period dispatch paths in calculate_payment()
    share one implementation instead of duplicating it."""
    period_id = _text(period, "servicePeriodId", "Id", "id", "ID_SERVICE_PERIOD__c", "service_period_id")
    start = _date(period, "serviceBeginDate", "Start_Date__c", "DTE_START__c", "start_date", "startDate", "period_start")
    end = _date(period, "serviceEndDate", "End_Date__c", "DTE_END__c", "end_date", "endDate", "period_end")
    if not period_id or not start or not end or end < start:
        return _blocked(["service_period_dates"])

    # ---- FIX 1: settlement short-circuit -----------------------------------
    # Once an actual PAID/REQUESTED record is on file for this period, that
    # record is authoritative -- return it directly and skip all per-day
    # computation (no recalculation, ever, for a settled period).
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
        }

    auth_by_id = _unique_index(authorizations, "Id", "id", "ID_AUTH__c", "authorization_id")
    auth_by_name = _unique_index(authorizations, "Name", "name", "NAM_AUTH__c", "authorization_name")
    fiscal_schedule_index = _fiscal_schedule_index(fiscal_agreements, fiscal_schedules)
    rate_lookup = _rate_lookup(fiscal_rates)

    # ---- FIX 2/3: per-authorization absence-day and drop-in-day counters ---
    # Counted across this authorization's schedule rows within the service
    # period (the same population calculate_payment already iterates below),
    # in date order, so the Nth+1 absence/drop-in day beyond the county's
    # monthly limit is excluded from payment.
    absence_day_counts: dict[str, int] = {}
    drop_in_day_counts: dict[str, int] = {}
    as_of_date = date.today()

    rows: list[dict[str, Any]] = []
    blockers: list[str] = []
    for schedule in sorted(
        schedules,
        key=lambda row: _text(row, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c", "service_date", "schedule_date", "date") or "",
    ):
        service_date = _date(schedule, "CI_Authorization_Date__c", "Service_Date__c", "Schedule_Date__c", "service_date", "schedule_date", "date")
        if not service_date or not start <= service_date <= end:
            continue

        # FIX: schedule.CI_Authorization_Id__c (bare number) matches
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

        # FIX: authorized_hours lives on the schedule row, not on the
        # authorization record.
        authorized_hours = _number(schedule, "CI_Authorization_Hours__c", "authorized_hours", "authorization_hours", "hours")
        attended_hours = _attended_hours(schedule)
        if authorized_hours is None or attended_hours is None:
            rows.append(_blocked_row("ATTENDED_CARE", service_date, "hours"))
            blockers.append("attendance_hours")
            continue

        provider_id = _text(authorization, "IDN_PROVR__c", "provider_id")
        county_id = _text(authorization, "county_id", "CDE_COUNTY__c", "countyId")
        classification = _classification(
            provider_closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays,
        )
        rate_type_code = _text(schedule, "CI_Authorization_Rate_Type__c", "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c") \
            or _text(authorization, "rate_type_code", "Rate_Type_Code__c", "CDE_RATE_TYPE__c")
        age_group_code = _text(schedule, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c", "fiscal_age_group_code") \
            or _text(authorization, "age_group_code", "Age_Group_Code__c", "CDE_AGE_GROUP__c") \
            or _age_group_code(_child_dob(authorization), service_date)

        policy = county_policy_by_id.get(county_id or "", {})
        # FIX: quality tier lives on the resolved fiscal schedule
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
                _abs_key = (auth_id, service_date.strftime("%Y-%m"))
                absence_day_counts[_abs_key] = absence_day_counts.get(_abs_key, 0) + 1
                if not isinstance(absence_limit, int):
                    limit_exceeded_blocker = "absence_limit_unavailable"
                elif absence_day_counts[_abs_key] > absence_limit:
                    limit_exceeded_blocker = "absence_limit_exceeded"
        elif classification == "DROP_IN":
            max_drop_in = policy.get("max_drop_in_days_per_month")
            allow_drop_in = policy.get("allow_drop_in_days")
            if allow_drop_in is False:
                limit_exceeded_blocker = "drop_in_not_allowed"
            elif isinstance(max_drop_in, int):
                _di_key = (auth_id, service_date.strftime("%Y-%m"))
                drop_in_day_counts[_di_key] = drop_in_day_counts.get(_di_key, 0) + 1
                if drop_in_day_counts[_di_key] > max_drop_in:
                    limit_exceeded_blocker = "drop_in_limit_exceeded"

        auth_name = _text(authorization, "Name")
        county_name = (county_policy_by_id.get(county_id or "", {}) or {}).get("county_name")

        if limit_exceeded_blocker:
            rows.append({
                "kind": "ATTENDED_CARE",
                "service_date": service_date.isoformat(),
                "authorization_id": auth_id,
                "authorization_name": auth_name,
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
        row = {
            "kind": "ATTENDED_CARE",
            "service_date": service_date.isoformat(),
            "authorization_id": auth_id,
            "authorization_name": auth_name,
            "county_id": county_id,
            "county_name": county_name,
            "classification": classification,
            "paid_tier": paid_tier,
            "payable_hours": _money(payable_hours),
            "rate": _money(rate),
            "amount": _money(amount),
            "status": "at_risk" if confirmation_risk else "calculated",
        }
        if confirmation_risk:
            row["confirmation_risk"] = confirmation_risk
        rows.append(row)

    # ---- FIX 14/2026-09-26: vacant slots are contract ranges, monthly cap
    # recomputed stateless per week (see _vacant_slot_payable_days) --------
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
        "attended_care_amount": _money(sum((Decimal(r["amount"]) for r in calculated_rows if r["kind"] == "ATTENDED_CARE"), Decimal("0"))),
        "vacant_slot_amount": _money(sum((Decimal(r["amount"]) for r in calculated_rows if r["kind"] == "VACANT_SLOT"), Decimal("0"))),
        "amount_at_risk": _money(amount_at_risk),
        "at_risk_day_count": len(at_risk_rows),
        "potential_total_amount": _money(total + amount_at_risk),
        "blockers": unique_blockers,
    }


def paid_tier_for_hours(hours) -> str:
    value = _decimal(hours)
    if value is None or value <= 0:
        return "NO_PAYMENT"
    for boundary, tier in PAID_TIERS[1:]:
        if value <= boundary:
            return tier
    return "FULL_TIME_PLUS_FULL_TIME"


def _payable_hours(classification, authorized, attended, schedule):
    if classification in {"HOLIDAY", "ABSENCE", "ENROLLMENT_ABSENCE"}:
        return authorized
    if classification == "DROP_IN":
        return attended
    if classification == "FORECAST":
        return authorized
    return min(authorized, attended)


def _classification(closures, provider_id, county_id, service_date, authorized_hours, attended_hours, holidays):
    """Derived purely from hours + closure + holiday + status semantics
    (CCCAP_AUTHORIZED/CCCAP_NOT_AUTHORIZED/CARE_NOT_OFFERED are states, not
    booleans) -- confirmed rule: closure checked first, then hours decide
    authorized vs. drop-in vs. no-care, then holiday/absence for a scheduled
    day with zero attendance."""
    if _is_provider_closure(closures, provider_id, county_id, service_date):
        return "CARE_NOT_OFFERED"
    if authorized_hours == 0:
        return "DROP_IN" if attended_hours > 0 else "NO_CARE"
    if attended_hours > 0:
        return "REGULAR"
    if any(_date(row, "DTE_HOL__c", "DTE_OBSERVED_HOL__c", "holiday_date", "date") == service_date for row in holidays):
        return "HOLIDAY"
    return "ABSENCE"


def _attended_hours(schedule):
    direct = _number(schedule, "attended_hours", "Hours__c", "unit_hours")
    if direct is not None:
        return direct
    check_in = _number(schedule, "Check_In_Count__c", "check_in")
    check_out = _number(schedule, "Check_Out_Count__c", "check_out")
    return (check_out - check_in) if (check_in is not None and check_out is not None and check_out >= check_in) else None


def _attendance_confirmation_risk(schedule, service_date, as_of_date, classification=None):
    """Within the 9-day confirmation window, a day is 'at risk' (not yet
    guaranteed) if its attendance transaction is still PARENT_PENDING, or if
    no attendance transaction was logged at all -- confirmed field location:
    Attendance__r.records[].Status__c (a child Transaction__c record, NOT a
    top-level Schedule__c field).
    HOLIDAY and ENROLLMENT_ABSENCE are payable without parent confirmation --
    no attendance records are expected, so MISSING_ATTENDANCE never applies."""
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
    """FIX 13: real settlement records are subPayments rows
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


def _select_period(records, requested_id):
    if requested_id is not None:
        requested = str(requested_id)
        matches = [r for r in records if _text(r, "servicePeriodId", "Id", "id", "service_period_id") == requested]
        return matches[0] if len(matches) == 1 else None
    return records[0] if len(records) == 1 else None


def _select_period_or_candidates(records, requested_id):
    """2026-09-25: distinguishes "no match" from "2+ matches" instead of
    collapsing both into a bare blocked result. Returns (period, None) on an
    exact single match, or (None, candidates) when disambiguation is needed
    -- candidates is None when there is truly nothing to disambiguate."""
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


def _as_list(v):
    if isinstance(v, list):
        return [item for item in v if isinstance(item, dict)]
    if isinstance(v, dict):
        for k in ("records", "items", "results", "data"):
            if isinstance(v.get(k), list):
                return [item for item in v[k] if isinstance(item, dict)]
    return []


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


def _extract_fiscal_schedule_ids(raw_prov_data):
    if not isinstance(raw_prov_data, dict):
        return []
    bundle = raw_prov_data.get("providerDataRaw") if isinstance(raw_prov_data.get("providerDataRaw"), dict) else raw_prov_data
    if not isinstance(bundle, dict):
        return []
    agreements = bundle.get("fiscalAgreements") or []
    ids = []
    for agreement in _as_list(agreements):
        rs_records = _as_list(agreement.get("Rate_Schedules__r") or {})
        if rs_records:
            for rs in rs_records:
                fsid = (rs.get("Id") or rs.get("id") or "").strip()
                if fsid and fsid not in ids:
                    ids.append(fsid)
        else:
            aid = (agreement.get("Id") or agreement.get("id") or "").strip()
            if aid and aid not in ids:
                ids.append(aid)
    return ids


def _extract_fiscal_agreements(raw_prov_data):
    """FIX 11: the fiscal-rate join needs the full agreement records (provider
    id, county id, nested Rate_Schedules__r), not just their ids -- same
    source _extract_fiscal_schedule_ids already reads."""
    if not isinstance(raw_prov_data, dict):
        return []
    bundle = raw_prov_data.get("providerDataRaw") if isinstance(raw_prov_data.get("providerDataRaw"), dict) else raw_prov_data
    if not isinstance(bundle, dict):
        return []
    return _as_list(bundle.get("fiscalAgreements"))


def _build_date_params(resolved_filters):
    if not isinstance(resolved_filters, dict):
        return {"dateFilter": "THIS_MONTH"}
    date_filter = resolved_filters.get("dateFilter", "THIS_MONTH")
    if date_filter in ("THIS_WEEK", "LAST_WEEK", "NEXT_WEEK", "TODAY"):
        date_filter = "THIS_MONTH"
    params = {"dateFilter": date_filter}
    if date_filter == "DATE_RANGE":
        if resolved_filters.get("dateFrom"):
            params["dateFrom"] = resolved_filters["dateFrom"]
        if resolved_filters.get("dateTo"):
            params["dateTo"] = resolved_filters["dateTo"]
    elif date_filter in ("LAST_N_MONTHS", "LAST_N_DAYS"):
        if resolved_filters.get("periodCount"):
            params["periodCount"] = resolved_filters["periodCount"]
    return params


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


def _service_period_params(sub_filter, turn_request):
    """Dispatch getServicePeriods params by subFilter.

    2026-09-25 fix (service-period date filter rework): the Apex service
    (ServicePeriodService.cls) supports exactly 4 filter primitives --
    dateOn (point-in-time), dateFrom/dateTo (STRICT containment, not
    overlap), paymentAfter (forward-looking only, no reverse equivalent),
    limitOne. Three subFilters were wrong as a result:
    - LAST_PAYOUT previously sent {dateFilter: LAST_MONTH, limitOne: true},
      which Apex orders by DTE_BEGIN_EFFV__c ASC (not release date) --
      returning the EARLIEST period in last calendar month, not the most
      recently RELEASED one. Fixed to fetch a padded, un-limited window and
      let _select_last_released_period() pick client-side by release date.
    - CURRENT_MONTH/ALL previously forced a single-period pick (or fell
      through to NEXT_PAYOUT's params, for ALL) when a month legitimately
      has 2+ periods -- that's normal, not an error. Fixed to fetch a
      padded range and let the multi-period aggregation path (see
      calculate_payment) render every matching period, filtered client-side
      by real overlap via _periods_overlapping() rather than Apex's strict
      containment (which drops a period straddling a month boundary).
    """
    fetch_params = turn_request.get("fetchParams") or {} if isinstance(turn_request, dict) else {}
    today = date.today()
    if sub_filter == "LAST_PAYOUT":
        # Padded 2-month lookback, no limitOne -- selection happens
        # client-side in _select_last_released_period().
        return {"dateFilter": "LAST_N_MONTHS", "periodCount": 2}
    if sub_filter == "CURRENT_PERIOD_FORECAST":
        return {"dateOn": "TODAY", "limitOne": True}
    if sub_filter == "CURRENT_MONTH":
        first, last = _month_bounds(today, 0)
        return {"dateFilter": "DATE_RANGE", "dateFrom": (first - timedelta(days=7)).isoformat(), "dateTo": (last + timedelta(days=7)).isoformat()}
    if sub_filter == "ALL":
        last_month_first, _ = _month_bounds(today, 1)
        _, this_month_last = _month_bounds(today, 0)
        return {"dateFilter": "DATE_RANGE", "dateFrom": (last_month_first - timedelta(days=7)).isoformat(), "dateTo": (this_month_last + timedelta(days=7)).isoformat()}
    if sub_filter == "SPECIFIC_PERIOD":
        params = {}
        if isinstance(fetch_params, dict) and fetch_params.get("dateFrom"):
            params["dateFrom"] = fetch_params["dateFrom"]
        if isinstance(fetch_params, dict) and fetch_params.get("dateTo"):
            params["dateTo"] = fetch_params["dateTo"]
        return params or {"dateFilter": "THIS_MONTH"}
    # NEXT_PAYOUT or absent -- default to next upcoming period.
    return {"paymentAfter": "TODAY", "limitOne": True}


def _select_last_released_period(periods):
    """Client-side equivalent of a 'paymentBefore' filter the Apex layer
    doesn't expose: most recent period whose release date is <= today,
    by release date descending. Returns None if nothing has released yet
    (a real, distinct blocked state -- never guesses)."""
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


def _periods_overlapping(periods, window_start, window_end):
    """Real overlap filter (begin <= window_end AND end >= window_start) --
    replaces reliance on Apex's strict-containment dateFrom/dateTo semantics,
    which silently drops a period straddling window_start/window_end."""
    result = []
    for period in periods:
        begin = _date(period, "serviceBeginDate", "DTE_BEGIN_EFFV__c", "Start_Date__c")
        end = _date(period, "serviceEndDate", "DTE_END_EFFV__c", "End_Date__c")
        if begin is None or end is None:
            continue
        if begin <= window_end and end >= window_start:
            result.append(period)
    return result


# ==============================================================================
# ENTRY POINT
# ==============================================================================

_providers = _ctx("provider", [])
_county_info = _ctx("CountyInformation", [])
_authorizations = _ctx("AuthInformation", [])
_schedules = _ctx("ScheduleInformation", [])
_holidays = _ctx("orgHolidays", [])
_turn_request = _ctx("turnRequest", {}) or {}
_resolved_filters = _ctx("turnRequest.fetchParams") or _ctx("resolvedFilters") or {"dateFilter": "THIS_MONTH"}
_payment_bundle = _ctx("paymentData") or {}
_sub_filter = _turn_request.get("subFilter") if isinstance(_turn_request, dict) else None

_provider_ids = _extract_ids(_providers, "Id", "id", "providerId")
_county_ids = _extract_ids(_county_info, "CDE_COUNTY__c", "countyId", "Id", "id")
_fiscal_agreements = _payment_bundle.get("fiscalAgreements") if isinstance(_payment_bundle, dict) else []

# 2026-09-25: wire turnRequest.childNames/.countyNames as real filters --
# previously captured by the router and never read anywhere downstream.
# Narrows authorizations (by nested child name) and county scope before the
# per-day loop runs, so a named-child/county follow-up actually scopes the
# result instead of always returning the full facility.
_child_filter = {c.strip().lower() for c in (_turn_request.get("childNames") or []) if c}
_county_name_filter = {c.strip().lower() for c in (_turn_request.get("countyNames") or []) if c}
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

def _schedule_matches_filters(schedule):
    if not isinstance(schedule, dict):
        return False
    if _child_filter:
        child_name = _text(
            schedule,
            "IDN_CLIENT__r.Name", "childName", "child_name",
            "clientName", "client_name",
        )
        if not child_name or child_name.strip().lower() not in _child_filter:
            return False
    if _county_name_filter:
        county_name = _text(
            schedule,
            "CDE_COUNTY__r.Name", "countyName", "county_name",
        )
        if not county_name or county_name.strip().lower() not in _county_name_filter:
            return False
    return True

if _child_filter or _county_name_filter:
    _schedules = [schedule for schedule in _schedules if _schedule_matches_filters(schedule)]

if not isinstance(_payment_bundle, dict) or not _payment_bundle:
    respond(_blocked(["payment_data_collection"]))
else:
    _raw_bundle = {
        **_payment_bundle,
        "authData": {"authorizations": _authorizations},
        "schedules": _schedules,
        "holidayList": _holidays,
        "countyRatePlans": _county_info,
    }
    _payment_result = calculate_payment(_raw_bundle)

    # Add provider-facing message and next-actions for the response renderer.
    if _payment_result.get("status") == "ok" and _payment_result.get("mode") != "multi_period":
        _total = _payment_result.get("total_amount", "0.00")
        _period = _payment_result.get("service_period_id", chr(8212))
        _blockers = _payment_result.get("blockers") or []
        _sub = (_ctx("turnRequest.subFilter") or "").upper()
        _label = {
            "NEXT_PAYOUT": "Next estimated payout",
            "LAST_PAYOUT": "Last payout",
            "CURRENT_PERIOD_FORECAST": "Current period forecast",
            "CURRENT_MONTH": "Current month payment summary",
        }.get(_sub, "Payment estimate")
        if _blockers:
            _lines = ["**" + _label + ": calculation blocked (" + str(len(_blockers)) + " issue(s))**", "", "| Issue |", "|---|"]
            for _b in _blockers[:10]:
                _lines.append("| " + str(_b) + " |")
            _lines.extend(["", "Final payment cannot be projected until the issues above are resolved."])
        else:
            _lines = [
                "**" + _label + ": $" + _total + "**", "", "Service period: " + _period, "",
                "This is a calculated estimate based on attendance, authorizations, and fiscal rates on file. Final amounts are determined at county payment processing.",
            ]
        _payment_result["providerMessage"] = "\n".join(_lines)
        _payment_result["nextActions"] = [
            "View attendance details for this service period",
            "Check pending parent confirmations that may affect this amount",
            "Ask about a different service period or payment date",
        ]

    write_context("paymentResult", _payment_result)
    respond(_payment_result)

# __________________________GenAI: Generated code ends here______________________________