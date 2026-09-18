#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Deterministic provider-scoped attendance and payment evaluation."""

import argparse
import json
import sys
from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path
from typing import Any

from _shared import CONFIRMATION_WINDOW_DAYS, aggregate_by

RULE_VERSION = "provider-risk-payment-v3"
PAID_PAYMENT_STATUSES = {"PAID", "REQUESTED"}
CURRENCY_QUANTUM = Decimal("0.01")


def compute_payout_date(service_period_end: date) -> date:
    """Return the payout date, twelve days after the period's Sunday end.

    For a Sunday period end, +12 days is Friday - the true payment release
    date, confirmed against real T_SERV_PERIOD__c sample data
    (DTE_BATCH_FILE_PMT__c/release is one day after
    DTE_BATCH_PRCS_PMT__c/processing). This is a last-resort formula only -
    resolve_payout_date() below prefers the real Apex-sourced release date
    threaded through payload["service_period"]["payout_date"] whenever one
    is present.
    """
    payout_date = service_period_end + timedelta(days=12)
    return payout_date


def resolve_payout_date(payload: dict[str, Any], period_end: date) -> date:
    """Prefer the real Apex-sourced release date; fall back to the formula.

    payload["service_period"]["payout_date"] carries the actual
    DTE_BATCH_FILE_PMT__c value (or Apex's own ISO-week fallback) whenever a
    resolved service-period record reached this call - only a synthetic
    CUSTOM_RANGE payload with no matching T_SERV_PERIOD__c record omits it,
    in which case compute_payout_date() is the only option.
    """
    service_period = payload.get("service_period")
    raw_payout_date = service_period.get("payout_date") if isinstance(service_period, dict) else None
    resolved = _date_value(raw_payout_date) if isinstance(raw_payout_date, str) else None
    return resolved if resolved else compute_payout_date(period_end)


def _actual_payment_total(payload: dict[str, Any], service_period_id: Any) -> Decimal | None:
    """Sums existing_sub_payments rows already on file for this service period, or None if
    none exist yet. Shared by _settlement_fields (additive is_settled signal) and the
    settlement short-circuit in evaluate_provider_risk_and_payment (skips recomputation
    entirely once this is authoritative) - one source of truth for "is there a real record"."""
    actual_entries = [
        row
        for row in payload.get("existing_sub_payments", [])
        if isinstance(row, dict)
        and row.get("service_period_id") == service_period_id
        and isinstance(row.get("amount"), (int, float))
        and not isinstance(row.get("amount"), bool)
    ]
    if not actual_entries:
        return None
    return sum((Decimal(str(row["amount"])) for row in actual_entries), Decimal("0"))


def _settlement_fields(
    payload: dict[str, Any],
    period_end: date,
    as_of_date: date,
    net_total: Decimal,
) -> dict[str, Any]:
    """Additive actual-vs-calculated settlement signal.

    Purely additive - never changes status/amount/expected_amount/etc.
    elsewhere in the payment dict. A caller that wants the "settled" shape
    (last payout / last month payout) reads is_settled/settled_amount/
    settlement_source instead of the calculated Expected/Forecasted/At-risk
    breakdown. Per the locked design: once as_of_date is at or past the
    period's payout_date, the period is treated as settled REGARDLESS of
    whether existing_sub_payments actually confirms a PAID status yet - the
    payout date alone is the trigger. If an actual paid amount is on record
    for this period, it is authoritative and permanent (never reconciled
    against attendance data afterward, even if that data changes later); if
    not, the calculated net_total is used as the best available figure,
    explicitly flagged as such. NOTE: when an actual record already exists,
    evaluate_provider_risk_and_payment short-circuits before this function
    is even reached for that period (see the settlement check there) - this
    function's ACTUAL_PAYMENT_RECORD branch only remains reachable for
    callers (e.g. ledger comparisons across many periods) that still pass a
    fully-computed net_total in for periods this function alone evaluates.
    """
    if as_of_date < resolve_payout_date(payload, period_end):
        return {"is_settled": False}
    service_period = payload.get("service_period")
    service_period_id = service_period.get("id") if isinstance(service_period, dict) else None
    actual_total = _actual_payment_total(payload, service_period_id)
    if actual_total is not None:
        return {
            "is_settled": True,
            "settled_amount": _money(actual_total),
            "settlement_source": "ACTUAL_PAYMENT_RECORD",
        }
    return {
        "is_settled": True,
        "settled_amount": _money(net_total),
        "settlement_source": "CALCULATED_NO_PAYMENT_RECORD_YET",
    }


def _settled_result(
    payload: dict[str, Any],
    attendance: dict[str, Any],
    period_end: date,
    actual_total: Decimal,
    duplicate: dict[str, Any] | None,
) -> dict[str, Any]:
    """Payment result for a period whose payout date has passed AND whose actual payment
    record is already on file - see the settlement short-circuit in
    evaluate_provider_risk_and_payment for why this skips fiscal-rate matching and per-day
    pricing entirely. Category/county/child/composition views render empty (via the same
    _render_summary_view used by the full computation path, so the output shape is identical,
    just with zeroed/empty aggregates) rather than reconstructed, because no day-wise
    actual-payment source is available yet - see settlement_source below."""
    zero = Decimal("0")
    empty_summary_view = _render_summary_view(
        {}, {}, {}, {}, {}, [], actual_total, actual_total, zero, 0, set(), 0,
        forecasted_total=zero, at_risk_total=zero,
    )
    return {
        "status": "ok",
        "rule_version": RULE_VERSION,
        "calculation_mode": payload.get("calculation_mode", "STATUS"),
        "source_readiness": "COMPLETE",
        "attendance": attendance,
        "holiday_classification_mismatches": [],
        "total_amount_incorrectly_at_risk": _money(zero),
        "child_payment_impacts": [],
        "payment": {
            "status": "PAID",
            "amount": _money(actual_total),
            "base_amount": _money(actual_total),
            "scheduled_forecast_amount": _money(zero),
            "gross_amount": _money(actual_total),
            "amount_at_risk": _money(zero),
            "expected_amount": _money(actual_total),
            "forecasted_amount": _money(zero),
            "at_risk_amount": _money(zero),
            "guaranteed_amount": _money(zero),
            "holiday_classification_mismatches": [],
            "total_amount_incorrectly_at_risk": _money(zero),
            "payout_date": resolve_payout_date(payload, period_end).isoformat(),
            "excluded_days": 0,
            "excluded_authorizations": 0,
            "slot_fee": _money(zero),
            "vacant_slot_fee": _money(zero),
            "vacant_slot_days": [],
            "potential_total": _money(actual_total),
            "estimated_total": _money(actual_total),
            **({"existing_status": duplicate["status"]} if duplicate else {}),
            "summary": [],
            "summary_view": empty_summary_view,
            "is_settled": True,
            "settled_amount": _money(actual_total),
            "settlement_source": "ACTUAL_PAYMENT_RECORD",
        },
    }


def _date_value(value: Any) -> date | None:
    if not isinstance(value, str):
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def _hours(value: Any) -> Decimal | None:
    if isinstance(value, bool):
        return None
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return parsed if parsed.is_finite() and parsed >= 0 else None


def _signed_amount(value: Any) -> Decimal | None:
    if isinstance(value, bool):
        return None
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return parsed if parsed.is_finite() else None


def _money(value: Decimal) -> str:
    return format(value.quantize(CURRENCY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


def _month_key(value: date) -> str:
    return value.strftime("%Y-%m")


def _weekday_allowed(value: Any, service_date: date) -> bool:
    if value is None or str(value).strip() == "":
        return True
    names = {
        token.strip().upper()
        for token in str(value).replace(";", ",").split(",")
        if token.strip()
    }
    aliases = {
        service_date.strftime("%A").upper(),
        service_date.strftime("%a").upper(),
    }
    return bool(names & aliases)


def _matches_county_holiday_list(
    value: Any,
    service_date: date,
    holiday_name: Any = None,
    holiday_date: Any = None,
    observed_holiday_date: Any = None,
) -> bool:
    """Strict membership test for CLASSIFICATION (not payability).

    Unlike `_county_holiday_allowed` (which defaults to True/"allowed" when
    the county's list is empty, because that function only gates payability
    once something is already classified HOLIDAY), an empty/missing list
    here means "not a holiday" - a day only classifies as HOLIDAY when it
    genuinely appears on THIS authorization's county-specific paid-holiday
    list. A day merely present in the payload-level generic holiday_dates
    list is not sufficient for classification; it must match this county's
    own list, or it falls through to Absence.
    """
    if value is None or str(value).strip() == "" or (isinstance(value, list) and len(value) == 0):
        return False
    date_values = {service_date.isoformat().upper(), service_date.strftime("%m/%d").upper()}
    for candidate in (holiday_date, observed_holiday_date):
        parsed = _date_value(candidate)
        if parsed:
            date_values.update({parsed.isoformat().upper(), parsed.strftime("%m/%d").upper()})
    raw_tokens = value if isinstance(value, list) else str(value).replace(";", ",").split(",")
    tokens = {str(token).strip().upper() for token in raw_tokens if str(token).strip()}
    return bool(tokens & date_values) or (
        isinstance(holiday_name, str) and holiday_name.strip().upper() in tokens
    )


def _history_count(
    history: list[dict[str, Any]],
    authorization_id: str,
    service_date: date,
    codes: set[str],
) -> int:
    count = 0
    for item in history:
        if not isinstance(item, dict) or item.get("authorization_id") != authorization_id:
            continue
        if item.get("deleted") is True:
            continue
        item_date = _date_value(item.get("service_date"))
        if not item_date or item_date >= service_date or _month_key(item_date) != _month_key(service_date):
            continue
        if str(item.get("info_code", "")).strip() in codes:
            count += 1
    return count


def _holiday_paid_on_paired_date(
    history: list[dict[str, Any]],
    authorization_id: str,
    service_date: date,
    holiday_date: Any,
    observed_holiday_date: Any,
) -> bool:
    actual_date = _date_value(holiday_date)
    observed_date = _date_value(observed_holiday_date)
    other_date = (
        observed_date
        if actual_date == service_date and observed_date != service_date
        else actual_date
        if observed_date == service_date and actual_date != service_date
        else None
    )
    return bool(other_date) and any(
        isinstance(item, dict)
        and item.get("authorization_id") == authorization_id
        and item.get("service_date") == other_date.isoformat()
        and str(item.get("info_code", "")).strip() in {"1", "9"}
        for item in history
    )


def _vacant_slot_fee_totals(payload: dict[str, Any]) -> tuple[Decimal, list[dict[str, Any]]]:
    schedules = payload.get("vacant_slot_schedules")
    period = payload.get("service_period")
    if not isinstance(schedules, list) or not isinstance(period, dict):
        return Decimal("0"), []
    period_start = _date_value(period.get("start_date"))
    period_end = _date_value(period.get("end_date"))
    if not period_start or not period_end:
        return Decimal("0"), []
    total = Decimal("0")
    rows: list[dict[str, Any]] = []
    for schedule in schedules:
        if not isinstance(schedule, dict):
            continue
        effective_start = _date_value(schedule.get("effective_start")) or period_start
        effective_end = _date_value(schedule.get("effective_end")) or period_end
        monthly_limit = _hours(schedule.get("days_of_month"))
        if schedule.get("days_of_month") is not None and monthly_limit is None:
            continue
        current = min(effective_start, period_start.replace(day=1))
        last_day = max(effective_end, period_end)
        used_by_month: dict[str, int] = defaultdict(int)
        closure_dates = {str(value)[:10] for value in schedule.get("provider_closure_dates", []) if isinstance(value, str)}
        while current <= last_day:
            eligible = (
                effective_start <= current <= effective_end
                and _weekday_allowed(schedule.get("days_of_week"), current)
                and current.isoformat() not in closure_dates
            )
            month = _month_key(current)
            if eligible and (monthly_limit is None or used_by_month[month] < int(monthly_limit)):
                used_by_month[month] += 1
                if period_start <= current <= period_end:
                    amount = _hours(schedule.get("slot_rate_amount")) or Decimal("0")
                    total += amount
                    rows.append({
                        "slot_contract_id": schedule.get("slot_contract_id"),
                        "county_id": schedule.get("county_id"),
                        "county_name": schedule.get("county_name"),
                        "service_date": current.isoformat(),
                        "amount": _money(amount),
                        "classification": "VACANT_SLOT",
                        "payment_type": "GUARANTEED",
                    })
            current = current.fromordinal(current.toordinal() + 1)
    return total, rows


def _resolve_rate(
    rates: dict[tuple[str, str, str, str], Decimal],
    authorization_id: str,
    paid_tier: str,
    rate_type_code: str | None,
    age_group_code: str | None,
) -> Decimal | None:
    """Joins a schedule day to its fiscal rate by (authorization_id, paid_tier,
    rate_type_code, age_group_code) - the day's own scheduled rate type
    (regular/overnight/weekend/etc) AND the child's fiscal age group AS OF THAT
    SPECIFIC DAY (there are 8 age bands, ~6 months wide each) matched against the
    fiscal rate row's own rate type, care unit (already encoded in paid_tier), and
    age group. The authorization is a service contract spanning many schedule
    days; each day is its own care event, so BOTH rate type and age group are
    genuine per-day joins, not per-authorization constants - a child can age
    into a new fiscal band partway through a single service period. Shared by
    both the exclusion check and the category/composition amount calculation so
    they never disagree.
    """
    key_rate_type = str(rate_type_code or "")
    key_age_group = str(age_group_code or "")
    rate = rates.get((authorization_id, paid_tier, key_rate_type, key_age_group))
    if rate is not None:
        return rate
    return rates.get((authorization_id, "NO_PAYMENT", key_rate_type, key_age_group))


def _render_summary_view(
    categories: dict[str, dict[str, Any]],
    counties: dict[str, dict[str, Any]],
    county_composition: dict[str, dict[str, Any]],
    children: dict[str, dict[str, Any]],
    actions: dict[str, dict[str, Any]],
    vacant_slot_days: list[dict[str, Any]],
    gross_total: Decimal,
    net_total: Decimal,
    conditional_total: Decimal,
    excluded_days: int,
    distinct_children_served: set[str],
    paid_days: int,
    forecasted_total: Decimal = Decimal("0"),
    at_risk_total: Decimal | None = None,
) -> dict[str, Any]:
    # Render pre-accumulated data so all financial views share one per-day calculation.
    if at_risk_total is None:
        at_risk_total = conditional_total

    def render_bucket(item: dict[str, Any]) -> dict[str, Any]:
        return {
            "label": item["label"],
            "days": item["days"],
            "hours": _money(item["hours"]),
            "amount": _money(item["amount"]),
            "conditional_amount": _money(item["conditional_amount"]),
            "excluded_days": item["excluded_days"],
            "excluded_reasons": sorted(item.get("excluded_reasons", set())),
            "authorization_names": sorted(item.get("authorization_names", set())),
            "children_served": len(item.get("children_served", set())),
        }

    def render_composition(item: dict[str, Any]) -> dict[str, Any]:
        rendered: dict[str, Any] = {"county": item["county"], "children_served": len(item.get("children_served", set()))}
        for component in ("care", "absence", "enrollment_absence", "drop_in", "paid_holidays"):
            source = item[component]
            conditional_amount = source["conditional_amount"]
            scheduled_forecast = source.get("scheduled_forecast", Decimal("0"))
            rendered[component] = {
                **({"days": source["days"]} if "days" in source else {}),
                "hours": _money(source["hours"]),
                "amount": _money(source["amount"] - conditional_amount - scheduled_forecast),
                "confirmed_amount": _money(source["confirmed_amount"]),
                "conditional_amount": _money(source["conditional_amount"]),
                "scheduled_forecast": _money(scheduled_forecast),
            }
        vacant_slots = item["vacant_slots"]
        rendered["vacant_slots"] = {
            "days": vacant_slots["days"],
            "amount": _money(vacant_slots["amount"]),
        }
        rendered["attendance_based_amount"] = _money(item["attendance_based_amount"])
        rendered["authorized_based_amount"] = _money(item["authorized_based_amount"])
        component_at_risk = sum(
            item[component]["conditional_amount"]
            for component in ("care", "absence", "enrollment_absence", "drop_in", "paid_holidays")
        )
        rendered["amount_at_risk"] = _money(component_at_risk)
        component_forecast = sum(
            item[component].get("scheduled_forecast", Decimal("0"))
            for component in ("care", "absence", "enrollment_absence", "drop_in", "paid_holidays")
        )
        # Include forecast in potential_total even though amount is confirmed-only.
        rendered["potential_total"] = _money(
            sum(
                _hours(rendered[component]["amount"]) or Decimal("0")
                for component in ("care", "absence", "enrollment_absence", "drop_in", "paid_holidays")
            )
            + component_at_risk
            + component_forecast
            + (_hours(rendered["vacant_slots"]["amount"]) or Decimal("0")),
        )
        rendered["estimated_total"] = rendered["potential_total"]
        return rendered

    return {
        "overview": {
            "gross_amount": _money(gross_total),
            "net_amount": _money(net_total),
            "amount_at_risk": _money(conditional_total),
            "children_served": len(distinct_children_served),
            "base_amount": _money(net_total),
            "scheduled_forecast_amount": _money(forecasted_total),
            "potential_total": _money(net_total + forecasted_total + at_risk_total + sum(
                (_signed_amount(slot.get("amount")) or Decimal("0"))
                for slot in vacant_slot_days
            )),
            "estimated_total": _money(net_total + forecasted_total + at_risk_total + sum(
                (_signed_amount(slot.get("amount")) or Decimal("0"))
                for slot in vacant_slot_days
            )),
            "excluded_days": excluded_days,
            "paid_days": paid_days,
            "review_items": len(actions),
        },
        "categories": [render_bucket(item) for item in sorted(categories.values(), key=lambda value: value["label"])],
        "counties": [
            {"county": key, **render_bucket(item)}
            for key, item in sorted(counties.items(), key=lambda value: value[0])
        ],
        "county_composition": [
            render_composition(item)
            for _, item in sorted(county_composition.items(), key=lambda value: value[0])
        ],
        "children": [
            {"child": key, **render_bucket(item)}
            for key, item in sorted(children.items(), key=lambda value: value[0])
        ],
        "vacant_slots": vacant_slot_days,
        "next_actions": [
            {**action, "amount_at_risk": _money(action["amount_at_risk"])}
            for action in sorted(actions.values(), key=lambda value: (value["priority"], value["action_id"]))
        ],
    }


def _blocked(missing_inputs: list[str], attendance: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "status": "blocked",
        "rule_version": RULE_VERSION,
        "source_readiness": "BLOCKED_MISSING_REQUIRED_INPUTS",
        "attendance": attendance or {"days": [], "county_counts": []},
        "payment": {"status": "BLOCKED", "missing_inputs": sorted(missing_inputs)},
    }


def _required_input_gaps(payload: dict[str, Any]) -> list[str]:
    required = (
        "service_period",
        "authorizations",
        "attendance_days",
        "county_policies",
        "fiscal_rates",
        "existing_sub_payments",
    )
    return [field for field in required if not isinstance(payload.get(field), list if field != "service_period" else dict)]


def _service_period_dates(payload: dict[str, Any]) -> tuple[date, date] | None:
    period = payload.get("service_period")
    if not isinstance(period, dict):
        return None
    start_date = _date_value(period.get("start_date"))
    end_date = _date_value(period.get("end_date"))
    if not isinstance(period.get("id"), str) or not start_date or not end_date:
        return None
    return (start_date, end_date) if start_date <= end_date else None


def _tier_for_hours(hours: Decimal) -> str | None:
    if hours <= 0:
        return None
    if hours <= 5:
        return "PART_TIME"
    if hours <= 12:
        return "FULL_TIME"
    if hours <= 17:
        return "FULL_TIME_PLUS_PART_TIME"
    return "FULL_TIME_PLUS_FULL_TIME"


def _policy_by_authorization(
    authorizations: list[dict[str, Any]], county_policies: list[dict[str, Any]]
) -> dict[str, dict[str, Any]]:
    policies: dict[tuple[str, int], dict[str, Any]] = {}
    for policy in county_policies:
        if not isinstance(policy, dict):
            continue
        county_id = policy.get("county_id")
        quality_tier = policy.get("quality_tier")
        if not isinstance(county_id, str) or isinstance(quality_tier, bool) or not isinstance(quality_tier, int):
            continue
        policies[(county_id, quality_tier)] = policy
    return {
        authorization["id"]: policies.get(
            (str(authorization.get("county_id", "")), int(authorization.get("quality_tier", -1))),
            {},
        )
        for authorization in authorizations
        if isinstance(authorization, dict) and isinstance(authorization.get("id"), str)
    }


def _classify_attendance_day(
    attendance_day: dict[str, Any],
    authorization_by_id: dict[str, Any],
    policy_by_authorization: dict[str, Any],
    provider_closure_dates: set[str],
    history: list[dict[str, Any]],
    absence_counts: dict[str, int],
    drop_in_counts: dict[str, int],
    as_of_date_raw: Any,
) -> dict[str, Any]:
    """Classifies one attendance day into its payment-relevant state (holiday, absence,
    drop-in, pending confirmation, etc.) and returns the day's result record. Pure
    classification only - no aggregation, no rendering. `absence_counts`/`drop_in_counts`
    are mutated in place (cumulative per-authorization counters), matching the original
    inline-loop behavior exactly; this is the same lift-and-shift of the classification
    waterfall that used to live directly inside evaluate_attendance's loop body."""
    authorization_id = attendance_day.get("authorization_id")
    if not isinstance(authorization_id, str):
        return {
            "authorization_id": authorization_id,
            "service_date": attendance_day.get("service_date"),
            "classification": "BLOCKED",
            "flags": ["INVALID_AUTHORIZATION_ID"],
        }
    authorization = authorization_by_id.get(authorization_id)
    service_date = _date_value(attendance_day.get("service_date"))
    authorized_hours = _hours(attendance_day.get("authorized_hours"))
    attended_hours = _hours(attendance_day.get("attended_hours"))
    if not authorization or not service_date or authorized_hours is None or attended_hours is None:
        return {
            "authorization_id": authorization_id,
            "service_date": attendance_day.get("service_date"),
            "classification": "BLOCKED",
            "flags": ["MISSING_ATTENDANCE_DAY_INPUT"],
        }

    policy = policy_by_authorization.get(authorization_id, {})
    county_id = authorization.get("county_id")
    flags: list[str] = []
    occupied_slot_contract = attendance_day.get("occupied_slot_contract") is True
    as_of_date = _date_value(as_of_date_raw)
    scheduled_forecast = (
        attendance_day.get("forecast_basis") == "SCHEDULED"
        and as_of_date is not None
        and service_date > as_of_date
    )
    unit_hours = Decimal("0")
    payment_type = "NONE"
    # Classify holidays only from the authorization's county-specific list.
    county_holiday_match = _matches_county_holiday_list(
        policy.get("county_holiday_list"),
        service_date,
        attendance_day.get("holiday_name"),
        attendance_day.get("holiday_date"),
        attendance_day.get("observed_holiday_date"),
    )
    provider_closed = service_date.isoformat() in provider_closure_dates
    holiday_paid_on_other_date = _holiday_paid_on_paired_date(
        history,
        authorization_id,
        service_date,
        attendance_day.get("holiday_date"),
        attendance_day.get("observed_holiday_date"),
    )
    # Schedule's own Type__c (CCCAP_AUTHORIZED / CCCAP_NOT_AUTHORIZED / CARE_NOT_OFFERED) - the
    # explicit primary signal for the two branches below. Absent for older fixtures/data, so
    # every branch below OR's it with the pre-existing inference (care_not_offered boolean /
    # authorized_hours == 0) to keep prior behavior identical when it's not present.
    authorization_type = attendance_day.get("authorization_type")
    if attendance_day.get("parent_confirmation") == "REJECTED":
        # A parent-rejected attendance record is an explicit non-payment decision.
        # Keep the day in the detail response, but exclude it from every financial total.
        classification = "PARENT_REJECTED"
        payable = False
        paid_tier = None
        info_code = "REJECTED"
        flags.append("PARENT_CONFIRMATION_REJECTED")
    elif (
        authorization_type == "CARE_NOT_OFFERED"
        or attendance_day.get("care_not_offered") is True
        or provider_closed
    ) and not county_holiday_match:
        # CARE_NOT_OFFERED always wins, no exceptions - checked ahead of scheduled_forecast and
        # the not-authorized/drop-in branch below so a closure or holiday-adjacent non-offering
        # is excluded outright, even if a schedule row somehow still carries hours or attendance.
        classification = "CARE_NOT_OFFERED"
        payable = False
        paid_tier = None
        info_code = "14"
        if provider_closed:
            flags.append("PROVIDER_CLOSED")
    elif authorization_type == "CCCAP_NOT_AUTHORIZED" or (authorized_hours == 0 and attended_hours > 0):
        # Explicit CCCAP_NOT_AUTHORIZED (or the pre-existing implicit authorized_hours==0
        # fallback, for data that doesn't carry authorization_type) - the schedule was never
        # authorized, so CI_Authorization_Hours__c is always 0 here; attended_hours (sourced from
        # Hours__c/actual transactions) is the only signal that distinguishes a genuine drop-in
        # (kid attended anyway, counts against the county drop-in limit) from no care at all.
        if attended_hours > 0:
            classification = "DROP_IN"
            if authorization_id not in drop_in_counts:
                drop_in_counts[authorization_id] = _history_count(history, authorization_id, service_date, {"3", "10"})
            drop_in_allowed = policy.get("allow_drop_in_days")
            drop_in_limit = authorization.get("drop_in_limit")
            if drop_in_limit is None:
                drop_in_limit = policy.get("max_drop_in_days_per_month")
            if not isinstance(drop_in_limit, int) or isinstance(drop_in_limit, bool) or drop_in_limit < 0:
                payable = False
                paid_tier = None
                flags.append("DROP_IN_LIMIT_UNAVAILABLE")
            elif drop_in_allowed is False:
                payable = False
                paid_tier = None
                flags.append("DROP_IN_NOT_ALLOWED")
            elif drop_in_counts[authorization_id] >= drop_in_limit:
                payable = False
                paid_tier = _tier_for_hours(attended_hours)
                unit_hours = attended_hours
                # Preserve the drop-in category so at-risk amounts appear in breakdowns.
                payment_type = "DROP_IN"
                flags.append("DROP_IN_LIMIT_EXCEEDED")
            else:
                payable = True
                paid_tier = _tier_for_hours(attended_hours)
                unit_hours = attended_hours
                payment_type = "DROP_IN"
            info_code = "3"
        else:
            # Not authorized and no attendance transaction either - excluded, nothing to risk.
            classification = "NO_CARE"
            payable = False
            paid_tier = None
            info_code = "NONE"
    elif scheduled_forecast and authorized_hours > 0:
        # Gated on authorized_hours > 0: a future day with zero scheduled hours (a closure or
        # CCCAP_NOT_AUTHORIZED day, not an actual care schedule) is not a real forecast - forcing
        # payable=True here left paid_tier=_tier_for_hours(0)=None, which can never match a real
        # fiscal-rate row's paid_tier and always surfaced as "rate not yet available for these
        # dates" (confirmed via the logged fiscal_rate_gaps: every gap on 0-hour future days had
        # requestedPaidTier=null). Falling through instead lets the CARE_NOT_OFFERED/CCCAP_NOT_
        # AUTHORIZED branches above and the NO_CARE branch below classify it properly.
        classification = "SCHEDULED_FORECAST"
        payable = True
        paid_tier = _tier_for_hours(authorized_hours)
        unit_hours = authorized_hours
        payment_type = "FORECAST"
        info_code = "FORECAST"
        flags.append("SCHEDULED_FUTURE_DAY")
    elif attended_hours > 0 and not county_holiday_match:
        classification = "ATTENDED"
        payable = True
        paid_tier = _tier_for_hours(min(authorized_hours, attended_hours))
        unit_hours = min(authorized_hours, attended_hours)
        payment_type = "REGULAR"
        info_code = "0"
        if attended_hours > authorized_hours:
            flags.append("OVER_ATTENDANCE")
    elif authorized_hours == 0:
        # No authorization and no attendance is terminal and non-payable.
        classification = "NO_CARE"
        payable = False
        paid_tier = None
        info_code = "NONE"
    elif county_holiday_match and not holiday_paid_on_other_date:
        # An unattended date on the county holiday list is classified as a holiday.
        holiday_code = "1"
        holiday_hours = authorized_hours
        holiday_already_paid = any(
            isinstance(item, dict)
            and item.get("authorization_id") == authorization_id
            and item.get("service_date") == service_date.isoformat()
            and str(item.get("info_code", "")).strip() in {"1", "9"}
            for item in history
        )
        classification = "HOLIDAY"
        allow_paid_holidays = policy.get("allow_paid_holidays")
        # After list membership, only the county's paid-holiday policy gates payment.
        payable = allow_paid_holidays is not False
        paid_tier = _tier_for_hours(holiday_hours)
        unit_hours = holiday_hours
        payment_type = "HOLIDAY"
        info_code = holiday_code
        if not payable:
            unit_hours = Decimal("0")
            payment_type = "NONE"
            flags.append("PAID_HOLIDAY_NOT_ALLOWED")
        if holiday_already_paid:
            payable = False
            unit_hours = Decimal("0")
            payment_type = "NONE"
            flags.append("HOLIDAY_ALREADY_PAID")
    elif as_of_date is None:
        # Without as_of_date, fail closed rather than guess the resolution state.
        classification = "BLOCKED"
        payable = False
        paid_tier = None
        info_code = "4"
        flags.append("AS_OF_DATE_UNAVAILABLE")
    elif (as_of_date - service_date).days < CONFIRMATION_WINDOW_DAYS:
        # Within the confirmation window, unresolved days stay conditional; PENDING indicates an unapproved transaction, otherwise no transaction was logged.
        confirmation_state = attendance_day.get("parent_confirmation")
        if confirmation_state == "PENDING":
            classification = "PENDING_CONFIRMATION"
            flags.append("PARENT_CONFIRMATION_PENDING")
        else:
            classification = "INCOMPLETE_ATTENDANCE_RECORD"
            flags.append("MISSING_ATTENDANCE_TRANSACTION")
        # Keep unresolved days conditional and categorized so scheduled value contributes to risk and remains visible in composition tables.
        payable = True
        paid_tier = _tier_for_hours(authorized_hours)
        unit_hours = authorized_hours
        payment_type = "REGULAR"
        info_code = "PENDING"
        conditional = True
    else:
        # After the confirmation window, unattended non-holidays become absences governed by the county limit and enrollment carve-out.
        classification = "ABSENCE"
        paid_tier = _tier_for_hours(authorized_hours)
        if holiday_paid_on_other_date:
            flags.append("HOLIDAY_ALREADY_PAID_ON_PAIRED_DATE")
        age_band = attendance_day.get("age_band")
        absence_limit = policy.get("absence_limit")
        if authorization_id not in absence_counts:
            absence_counts[authorization_id] = _history_count(history, authorization_id, service_date, {"4", "11", "13"})
        absence_counts[authorization_id] += 1
        if not isinstance(absence_limit, int) or isinstance(absence_limit, bool) or absence_limit < 0:
            classification = "BLOCKED"
            payable = False
            flags.append("ABSENCE_LIMIT_UNAVAILABLE")
        elif absence_counts[authorization_id] <= absence_limit:
            payable = True
            unit_hours = authorized_hours
            payment_type = "ABSENCE"
        elif age_band == "ZERO_TO_36_MONTHS":
            classification = "ENROLLMENT_ABSENCE"
            payable = True
            unit_hours = authorized_hours
            payment_type = "ENROLLMENT"
        else:
            payable = False
            unit_hours = authorized_hours
            # Preserve the absence category so at-risk amounts appear in breakdowns.
            payment_type = "ABSENCE"
            flags.append("ABSENCE_LIMIT_EXCEEDED")
        info_code = "13" if classification == "ENROLLMENT_ABSENCE" else "4"

    category = payment_type
    payment_class = {
        "HOLIDAY": "GUARANTEED",
        "VACANT_SLOT": "GUARANTEED",
        "REGULAR": "ATTENDANCE_DEPENDENT",
        "ABSENCE": "ATTENDANCE_DEPENDENT",
        "ENROLLMENT": "ATTENDANCE_DEPENDENT",
        "DROP_IN": "ATTENDANCE_DEPENDENT",
    }.get(category, category)
    # The waterfall owns holiday, absence, and unresolved states; the generic confirmation gate applies only to forecast, attended, and drop-in records.
    if classification in {"ATTENDED", "DROP_IN"}:
        confirmation = attendance_day.get("parent_confirmation")
        conditional = confirmation == "PENDING"
        if conditional:
            flags.append("PARENT_CONFIRMATION_PENDING")
        elif confirmation != "CONFIRMED":
            classification = "BLOCKED"
            payable = False
            flags.append("PARENT_CONFIRMATION_UNAVAILABLE")
    elif classification == "SCHEDULED_FORECAST":
        # Future schedules are forecasts, not payment risk, until service occurs.
        conditional = False
    else:
        conditional = classification in {"PENDING_CONFIRMATION", "INCOMPLETE_ATTENDANCE_RECORD"}

    # Report actual hours but value unresolved confirmations at authorized hours.
    risk_hours = authorized_hours if conditional and classification in {
        "ATTENDED",
        "PENDING_CONFIRMATION",
        "INCOMPLETE_ATTENDANCE_RECORD",
    } else unit_hours

    day_result = {
        "authorization_id": authorization_id,
        "service_date": service_date.isoformat(),
        "authorized_hours": _money(authorized_hours),
        "attended_hours": _money(attended_hours),
        **({"confirm_by_date": (service_date + timedelta(days=CONFIRMATION_WINDOW_DAYS)).isoformat()} if as_of_date and as_of_date <= service_date + timedelta(days=CONFIRMATION_WINDOW_DAYS) else {}),
        **({"child_name": attendance_day["child_name"]} if isinstance(attendance_day.get("child_name"), str) else {}),
        **({"authorization_name": attendance_day["authorization_name"]} if isinstance(attendance_day.get("authorization_name"), str) else {}),
        **({"county_id": attendance_day["county_id"]} if isinstance(attendance_day.get("county_id"), str) else {}),
        **({"county_name": attendance_day["county_name"]} if isinstance(attendance_day.get("county_name"), str) else {}),
        "classification": classification,
        **({"attendance_basis": attendance_day["attendance_basis"]} if attendance_day.get("attendance_basis") in {"ACTUAL", "SCHEDULED"} else {}),
        "payable": payable,
        # Mark rows excluded by the payment engine for downstream filtering.
        "payment_excluded": False,
        "unit_hours": _money(unit_hours),
        "risk_hours": _money(risk_hours),
        "category": category,
        "payment_type": category if category == "REGULAR" and classification == "ATTENDED" else payment_class,
        "info_code": info_code,
        **({"rate_type_code": attendance_day["rate_type_code"]} if isinstance(attendance_day.get("rate_type_code"), str) else {}),
        # Per-day fiscal age-group code (derived by the TS canonicalizer from this day's own
        # service_date, not the authorization's period-start date) - passed through unchanged
        # so the rate-resolution loop below can join on it. Was missing from this passthrough
        # list when _classify_attendance_day was first extracted, which silently dropped the
        # field before it ever reached the rate join - caught by the age-group regression test.
        **({"fiscal_age_group_code": attendance_day["fiscal_age_group_code"]} if isinstance(attendance_day.get("fiscal_age_group_code"), str) else {}),
        "occupied_slot_contract": occupied_slot_contract,
        "slot_contract_present": attendance_day.get("slot_contract_present") is True,
        "conditional": conditional,
        **({"forecast_basis": "SCHEDULED"} if scheduled_forecast else {}),
        "paid_tier": paid_tier,
        "flags": sorted(flags),
    }
    # Second element is the AUTHORITATIVE county_id for aggregation (from the authorization
    # record) - distinct from the optional display-only county_id/county_name passthrough
    # fields above (sourced from attendance_day, not included unless the source provided them).
    return day_result, str(county_id)


def evaluate_attendance(payload: dict[str, Any]) -> dict[str, Any]:
    """Thin orchestrator: builds lookup context once, classifies each day via
    _classify_attendance_day, then aggregates county counts from the results.
    Same return shape as before this extraction - lift-and-shift, no behavior change."""
    authorizations = payload.get("authorizations")
    attendance_days = payload.get("attendance_days")
    county_policies = payload.get("county_policies")
    if not all(isinstance(value, list) for value in (authorizations, attendance_days, county_policies)):
        return {"days": [], "county_counts": [], "missing_inputs": ["attendance_inputs"]}

    authorization_rows = [value for value in (authorizations or []) if isinstance(value, dict)]
    attendance_rows = [value for value in (attendance_days or []) if isinstance(value, dict)]
    county_policy_rows = [value for value in (county_policies or []) if isinstance(value, dict)]

    authorization_by_id = {
        authorization.get("id"): authorization
        for authorization in authorization_rows
        if isinstance(authorization, dict) and isinstance(authorization.get("id"), str)
    }
    policy_by_authorization = _policy_by_authorization(authorization_rows, county_policy_rows)
    provider_closure_dates = {
        str(value)[:10]
        for value in payload.get("provider_closure_dates", [])
        if isinstance(value, str)
    }
    history = [item for item in payload.get("fee_history", []) if isinstance(item, dict)]
    absence_counts: dict[str, int] = defaultdict(int)
    drop_in_counts: dict[str, int] = defaultdict(int)
    county_counts: dict[str, dict[str, int]] = defaultdict(
        lambda: {"attended_days": 0, "payable_absence_days": 0, "excluded_absence_days": 0, "conditional_days": 0}
    )
    results = []

    for attendance_day in sorted(
        attendance_rows,
        key=lambda day: (str(day.get("authorization_id")), str(day.get("service_date"))),
    ):
        day_result, county_id = _classify_attendance_day(
            attendance_day,
            authorization_by_id,
            policy_by_authorization,
            provider_closure_dates,
            history,
            absence_counts,
            drop_in_counts,
            payload.get("as_of_date"),
        )
        results.append(day_result)
        # Blocked-before-classification stubs (invalid authorization ID, missing input) carry
        # no "payable" key and never reached county aggregation in the original inline loop either.
        if "payable" not in day_result:
            continue
        county = county_counts[county_id]
        if day_result["conditional"]:
            county["conditional_days"] += 1
        if day_result["classification"] == "ATTENDED":
            county["attended_days"] += 1
        elif day_result["payable"] and day_result["classification"] in {"ABSENCE", "ENROLLMENT_ABSENCE"}:
            county["payable_absence_days"] += 1
        elif day_result["classification"] == "ABSENCE" and not day_result["payable"]:
            county["excluded_absence_days"] += 1

    actual_hours_total = sum(
        (_hours(day.get("unit_hours")) or Decimal("0") for day in results if day.get("attendance_basis") == "ACTUAL"),
        Decimal("0"),
    )
    scheduled_hours_total = sum(
        (_hours(day.get("unit_hours")) or Decimal("0") for day in results if day.get("attendance_basis") == "SCHEDULED"),
        Decimal("0"),
    )
    return {
        "days": results,
        "actual_hours_total": _money(actual_hours_total),
        "scheduled_hours_total": _money(scheduled_hours_total),
        "county_counts": [
            {"county_id": county_id, **counts}
            for county_id, counts in sorted(county_counts.items())
        ],
    }


def evaluate_provider_risk_and_payment(payload: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(payload, dict):
        return _blocked(["canonical_input"])
    missing_inputs = _required_input_gaps(payload)
    if payload.get("rule_version") != RULE_VERSION:
        missing_inputs.append("approved_rule_version")
    if missing_inputs:
        return _blocked(missing_inputs)

    period_dates = _service_period_dates(payload)
    if not period_dates:
        return _blocked(["service_period_dates"])
    period_start, period_end = period_dates
    as_of_date = _date_value(payload.get("as_of_date"))
    if not as_of_date:
        return _blocked(["as_of_date"])
    for attendance_day in payload["attendance_days"]:
        if not isinstance(attendance_day, dict):
            return _blocked(["attendance_day_record"])
        service_date = _date_value(attendance_day.get("service_date"))
        if not service_date or not period_start <= service_date <= period_end:
            return _blocked(["service_period_dates"])

    attendance = evaluate_attendance(payload)
    if any(day["classification"] == "BLOCKED" for day in attendance["days"]):
        return _blocked(["complete_attendance_inputs"], attendance)

    period = payload["service_period"]
    authorization_ids = {authorization.get("id") for authorization in payload["authorizations"] if isinstance(authorization, dict)}
    duplicate = next(
        (
            payment
            for payment in payload["existing_sub_payments"]
            if isinstance(payment, dict)
            and (
                payment.get("authorization_id") is None
                or payment.get("authorization_id") in authorization_ids
            )
            and payment.get("service_period_id") == period["id"]
            and payment.get("status") in PAID_PAYMENT_STATUSES
        ),
        None,
    )
    # Settlement short-circuit: once the payout date has passed AND an actual payment record
    # already exists for this period, that record is permanently authoritative (locked design -
    # never recompute or reconcile against attendance data afterward, even retroactively). Skip
    # fiscal-rate matching and per-day pricing entirely for this branch - the class of computation
    # a settled period no longer needs, and the one where a data gap like an unmatched fiscal rate
    # can no longer change the real amount anyway. Day/category/county/child breakdowns render
    # empty rather than reconstructed, because no day-wise actual-payment source is available yet.
    actual_total = _actual_payment_total(payload, period["id"])
    if as_of_date >= resolve_payout_date(payload, period_end) and actual_total is not None:
        return _settled_result(payload, attendance, period_end, actual_total, duplicate)
    # Match each day by rate type, age group, and care unit - all three are genuine per-day
    # joins now (the authorization is a service contract spanning many schedule days; each
    # day is its own care event, and a child can age into a new fiscal band partway through
    # one service period). Retain the first stable candidate when duplicate rows collide.
    rates: dict[tuple[str, str, str, str], Decimal] = {}
    # Diagnostic index only (never consulted for pricing) - lets a fiscal-rate miss report
    # exactly which (paid_tier, rate_type_code, age_group_code) keys DID survive upstream
    # rate-type filtering for that same authorization, so a "fiscal rate unavailable" day can
    # be attributed to a specific missing combination instead of reported as an opaque gap count.
    available_keys_by_authorization: dict[str, set[tuple[str, str, str]]] = defaultdict(set)
    for rate in payload["fiscal_rates"]:
        if not isinstance(rate, dict):
            return _blocked(["fiscal_rate_record"], attendance)
        authorization_id = rate.get("authorization_id")
        paid_tier = rate.get("paid_tier")
        amount = _hours(rate.get("amount"))
        rate_type_code = str(rate.get("rate_type_code") or "")
        age_group_code = str(rate.get("age_group_code") or "")
        if not isinstance(authorization_id, str) or not isinstance(paid_tier, str) or amount is None:
            return _blocked(["fiscal_rate_record"], attendance)
        rate_key = (authorization_id, paid_tier, rate_type_code, age_group_code)
        available_keys_by_authorization[authorization_id].add((paid_tier, rate_type_code, age_group_code))
        if rate_key in rates:
            continue
        rates[rate_key] = Decimal("0") if paid_tier == "NO_PAYMENT" else amount

    excluded_authorizations: set[str] = set()
    unavailable_rate_days: set[tuple[str, str]] = set()
    # Bounded diagnostic detail for the "Review unmatched fiscal rates" action - capped so a
    # widespread source-data gap can't inflate the response; enough entries to identify the
    # missing combination without needing a follow-up investigation each time it recurs.
    fiscal_rate_gaps: list[dict[str, Any]] = []
    MAX_FISCAL_RATE_GAP_DETAILS = 10
    for day in attendance["days"]:
        if not day["payable"]:
            continue
        authorization_id = day["authorization_id"]
        requested_paid_tier = day["paid_tier"]
        requested_rate_type_code = day.get("rate_type_code")
        requested_age_group_code = day.get("fiscal_age_group_code")
        if _resolve_rate(rates, authorization_id, requested_paid_tier, requested_rate_type_code, requested_age_group_code) is None:
            excluded_authorizations.add(authorization_id)
            unavailable_rate_days.add((authorization_id, str(day.get("service_date"))))
            if len(fiscal_rate_gaps) < MAX_FISCAL_RATE_GAP_DETAILS:
                fiscal_rate_gaps.append({
                    "authorization_id": authorization_id,
                    "service_date": day.get("service_date"),
                    "requested_paid_tier": requested_paid_tier,
                    "requested_rate_type_code": requested_rate_type_code,
                    "requested_age_group_code": requested_age_group_code,
                    # Every (paid_tier, rate_type_code, age_group_code) triple the fiscal-rate
                    # source actually returned for this authorization, after upstream rate-type
                    # filtering - an empty list means the authorization has NO fiscal rate rows
                    # at all (a broader mapping gap); a non-empty list that simply doesn't
                    # contain the requested triple means that specific tier/rate-type/age-group
                    # combination is the one missing from the county's published fiscal schedule.
                    "available_paid_tier_rate_type_age_group_triples": sorted(
                        f"{tier}/{rate_type}/{age_group}"
                        for tier, rate_type, age_group in available_keys_by_authorization.get(authorization_id, set())
                    ),
                })
    total = Decimal("0")
    conditional_total = Decimal("0")
    # Keep this provider-facing breakdown additive to the existing totals.
    expected_total = Decimal("0")
    forecasted_total = Decimal("0")
    at_risk_total = Decimal("0")
    guaranteed_total = Decimal("0")
    excluded_days = 0
    holiday_classification_mismatches: list[dict[str, Any]] = []
    total_amount_incorrectly_at_risk = Decimal("0")
    child_payment_impact: dict[str, Decimal] = defaultdict(Decimal)
    child_payment_total: dict[str, Decimal] = defaultdict(Decimal)

    # Build all downstream financial views in one pass so every table shares the same per-day amounts.
    category_labels = {
        "REGULAR": "Regular care",
        "HOLIDAY": "Holiday",
        "ABSENCE": "Paid absence",
        "ENROLLMENT": "Enrollment absence",
        "DROP_IN": "Drop-in",
        "FORECAST": "Scheduled forecast",
    }
    county_composition: dict[str, dict[str, Any]] = {}
    actions: dict[str, dict[str, Any]] = {}
    summary_groups: dict[tuple[str, str, str], dict[str, Any]] = {}
    distinct_children_served: set[str] = set()
    paid_days = 0
    # One row per day, rendered into categories/counties/children below via aggregate_by -
    # replaces the old bucket() closure and its 3-way "for store, key, item_label" loop.
    # All three views share the exact same per-day contribution fields; only the grouping
    # key/label differ, which is why one row list can serve all three renders.
    view_rows: list[dict[str, Any]] = []

    def composition_bucket(county_key: str, county_label: str) -> dict[str, Any]:
        # Track days for categories whose composition view displays day counts.
        county = county_composition.setdefault(county_key, {
            "county": county_label,
            "children_served": set(),
            "attendance_based_amount": Decimal("0"),
            "authorized_based_amount": Decimal("0"),
            "amount_at_risk": Decimal("0"),
            "care": {"hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0"), "scheduled_forecast": Decimal("0")},
            "absence": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0"), "scheduled_forecast": Decimal("0")},
            "enrollment_absence": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0"), "scheduled_forecast": Decimal("0")},
            "drop_in": {"hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0"), "scheduled_forecast": Decimal("0")},
            "vacant_slots": {"days": 0, "amount": Decimal("0")},
            "paid_holidays": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0"), "scheduled_forecast": Decimal("0")},
        })
        if county["county"] == "Unavailable from the current source" and county_label != county["county"]:
            county["county"] = county_label
        return county

    def add_attendance_component(
        county: dict[str, Any],
        component: str,
        hours: Decimal,
        amount: Decimal,
        conditional: bool,
        forecast: bool = False,
    ) -> None:
        if component not in county:
            return
        item = county[component]
        if "days" in item:
            item["days"] += 1
        item["hours"] += hours
        item["amount"] += amount
        if conditional:
            item["conditional_amount"] += amount
        elif forecast and "scheduled_forecast" in item:
            item["scheduled_forecast"] += amount
        else:
            item["confirmed_amount"] += amount

    def add_action(action_id: str, label: str, reason: str, impact: Decimal, priority: str = "medium") -> None:
        current = actions.get(action_id)
        if current is None:
            actions[action_id] = {
                "action_id": action_id,
                "label": label,
                "reason": reason,
                "priority": priority,
                "amount_at_risk": impact,
                "days": 1,
            }
        else:
            current["amount_at_risk"] += impact
            current["days"] += 1

    for day in attendance["days"]:
        if (
            day.get("classification") == "CARE_NOT_OFFERED"
            and (_hours(day.get("authorized_hours")) or Decimal("0")) == 0
            and (_hours(day.get("unit_hours")) or Decimal("0")) == 0
            and day.get("payable") is False
        ):
            continue
        if day.get("classification") == "PARENT_REJECTED":
            excluded_days += 1
            day["payment_excluded"] = True
            continue
        # Reuse one per-day rate join across all financial views.
        rate = _resolve_rate(rates, day["authorization_id"], day["paid_tier"], day.get("rate_type_code"), day.get("fiscal_age_group_code"))
        unit_hours = _hours(day.get("unit_hours")) or Decimal("0")
        # FISCAL_RATE_UNAVAILABLE is deliberately not checked here: that flag is only
        # added to day["flags"] later in this same iteration (once rate_unavailable is
        # known below), so it can never be true at this point - checking it was a no-op.
        # rate_unavailable-driven risk is already captured via will_be_excluded further
        # down, and every dollar figure risk_day feeds is separately gated on
        # `rate is not None`, which is always None on a rate-unavailable day anyway.
        risk_day = day["conditional"] or any(
            flag in day["flags"]
            for flag in ("DROP_IN_LIMIT_EXCEEDED", "ABSENCE_LIMIT_EXCEEDED")
        )
        risk_hours = _hours(day.get("risk_hours")) or unit_hours
        amount_hours = risk_hours if risk_day else unit_hours
        if (
            isinstance(day.get("child_name"), str)
            and rate is not None
            and risk_day
        ):
            child_payment_impact[day["child_name"]] += rate * amount_hours
        if isinstance(day.get("child_name"), str) and rate is not None:
            child_payment_total[day["child_name"]] += rate * amount_hours
        if day.get("child_name"):
            distinct_children_served.add(str(day.get("child_name")))
        if rate is not None and risk_day:
            conditional_total += rate * amount_hours

        # Separate resolved, forecast, and at-risk amounts for the payment breakdown.
        is_future_day = day.get("forecast_basis") == "SCHEDULED"
        limit_exceeded = any(
            flag in day.get("flags", [])
            for flag in ("DROP_IN_LIMIT_EXCEEDED", "ABSENCE_LIMIT_EXCEEDED")
        )
        # Pending confirmations remain unresolved rather than excluded until the window closes.
        still_pending = day.get("classification") in {"PENDING_CONFIRMATION", "INCOMPLETE_ATTENDANCE_RECORD"}
        rate_unavailable = (day["authorization_id"], str(day.get("service_date"))) in unavailable_rate_days
        will_be_excluded = (not day["payable"] and not still_pending) or rate_unavailable
        classified_amount = (rate * amount_hours) if rate is not None else Decimal("0")
        if day.get("payment_type") == "GUARANTEED":
            guaranteed_total += classified_amount
        expected_holiday = day.get("service_date") in {str(value)[:10] for value in payload.get("holiday_dates", []) if isinstance(value, str)}
        resolved_holiday = day.get("classification") == "HOLIDAY"
        if expected_holiday != resolved_holiday:
            mismatch_amount = classified_amount
            holiday_classification_mismatches.append({**day, "amount_incorrectly_at_risk": _money(mismatch_amount), "risk_code": "HOLIDAY_CLASSIFICATION_MISMATCH"})
            total_amount_incorrectly_at_risk += mismatch_amount
        # limit_exceeded's two flags (DROP_IN_LIMIT_EXCEEDED, ABSENCE_LIMIT_EXCEEDED) are both
        # already covered by risk_day above, so a dedicated elif branch here was unreachable.
        if will_be_excluded or still_pending or risk_day:
            amount_class = "AT_RISK"
        elif is_future_day:
            amount_class = "FORECASTED"
        else:
            amount_class = "EXPECTED"
        day["amount_class"] = amount_class
        if amount_class == "EXPECTED":
            expected_total += classified_amount
        elif amount_class == "FORECASTED":
            forecasted_total += classified_amount
        else:
            at_risk_total += classified_amount

        # Finalize exclusion before accumulating category and composition views.
        if still_pending:
            pass  # Not yet resolved - never counted as paid or excluded while the confirmation window remains open.
        elif not day["payable"] or rate_unavailable:
            excluded_days += 1
            day["payment_excluded"] = True
            if rate_unavailable:
                day["flags"] = sorted({*day["flags"], "FISCAL_RATE_UNAVAILABLE"})
        else:
            # `rate` was already resolved from the same (rates, authorization_id, paid_tier,
            # rate_type_code, fiscal_age_group_code) inputs at the top of this iteration, and
            # `rates` is never mutated inside this loop - re-resolving here is guaranteed to
            # return the identical value, so reuse it instead of calling _resolve_rate again.
            if rate is None:
                excluded_days += 1
                day["payment_excluded"] = True
            elif amount_class == "EXPECTED":
                total += rate * unit_hours

        # ---- summary_groups accumulation (replaces the old separate loop) ----
        if day["payable"] and not day.get("payment_excluded"):
            paid_days += 1
            if rate is not None:
                county_id = day.get("county_id", "")
                paid_tier = day.get("paid_tier") or "NO_PAYMENT"
                basis = "SCHEDULED" if day.get("forecast_basis") == "SCHEDULED" else "ACTUAL"
                group_key = (county_id, paid_tier, basis)
                group = summary_groups.setdefault(group_key, {"county_id": county_id, "county_name": day.get("county_name"), "rates": set(), "paid_tier": paid_tier, "basis": basis, "children_served": set(), "hours": Decimal("0"), "amount": Decimal("0"), "conditional_amount": Decimal("0")})
                group["rates"].add(_money(rate))
                group_hours = _hours(day.get("unit_hours")) or Decimal("0")
                group_amount = rate * group_hours
                group["children_served"].add(day.get("child_name") or day["authorization_id"])
                group["hours"] += group_hours
                if day["conditional"]:
                    group["conditional_amount"] += group_amount
                else:
                    group["amount"] += group_amount

        # Accumulate category, county, child, and composition views in this pass.
        payment_type = str(day.get("category") or day.get("payment_type") or "NONE")
        label = category_labels.get(payment_type, "Not paid")
        is_risk = amount_class == "AT_RISK"
        # Reuse risk-adjusted hours and amounts computed above.
        summary_hours = amount_hours
        summary_amount = classified_amount
        county_key = str(day.get("county_id") or "UNKNOWN")
        county_label = day.get("county_name") or "Unavailable from the current source"
        child_key = str(day.get("child_name") or day.get("authorization_id") or "UNKNOWN")
        child_label = day.get("child_name") or "Unavailable from the current source"
        component = {
            "REGULAR": "care",
            "FORECAST": "care",
            "ABSENCE": "absence",
            "ENROLLMENT": "absence",
            "DROP_IN": "drop_in",
            "HOLIDAY": "paid_holidays",
        }.get(payment_type)
        if payment_type == "ENROLLMENT":
            component = "enrollment_absence"
        county = composition_bucket(county_key, str(county_label))
        if component:
            add_attendance_component(county, component, summary_hours, summary_amount, is_risk, payment_type == "FORECAST")
        if child_key != "UNKNOWN":
            county["children_served"].add(child_key)
        if is_risk and rate is not None:
            county["amount_at_risk"] += summary_amount
        elif day.get("payable") is True and not day.get("payment_excluded") and rate is not None and payment_type in {"REGULAR", "FORECAST", "DROP_IN"}:
            county["attendance_based_amount"] += summary_amount

        # categories/counties/children (rendered below via aggregate_by, after this loop)
        # share this exact per-day contribution shape - only their grouping key/label differ.
        authorization_name = day.get("authorization_name")
        row_hours = Decimal("0")
        row_amount = Decimal("0")
        row_conditional_amount = Decimal("0")
        row_excluded_days = 0
        row_excluded_reasons: list[str] = []
        if is_risk and rate is not None:
            # Keep at-risk amounts in their source category across every view.
            row_hours = summary_hours
            row_conditional_amount = summary_amount
        elif day.get("payable") is True and not day.get("payment_excluded") and rate is not None:
            # Count hours only when this row represents payable money.
            row_hours = summary_hours
            row_amount = summary_amount
        elif day.get("classification") not in {"NO_CARE", "CARE_NOT_OFFERED"}:
            row_excluded_days = 1
            for flag in day.get("flags", []):
                if flag in {"PARENT_CONFIRMATION_PENDING", "PARENT_CONFIRMATION_UNAVAILABLE"}:
                    row_excluded_reasons.append("pending confirmation")
                elif flag == "ABSENCE_LIMIT_EXCEEDED":
                    row_excluded_reasons.append("absence limit exceeded")
                elif flag == "DROP_IN_LIMIT_EXCEEDED":
                    row_excluded_reasons.append("drop-in limit exceeded")
                elif flag == "FISCAL_RATE_UNAVAILABLE":
                    # Use provider-facing wording rather than internal fiscal-rate terminology.
                    row_excluded_reasons.append("rate not yet available for these dates")
        view_rows.append({
            "category_key": payment_type,
            "category_label": label,
            "county_key": county_key,
            "county_label": county_label,
            "child_key": child_key,
            "child_label": child_label,
            "hours": row_hours,
            "amount": row_amount,
            "conditional_amount": row_conditional_amount,
            "excluded_days": row_excluded_days,
            "authorization_names": authorization_name if isinstance(authorization_name, str) and authorization_name else None,
            "children_served": child_key if child_key != "UNKNOWN" else None,
            "excluded_reasons": row_excluded_reasons,
        })

        if "FISCAL_RATE_UNAVAILABLE" in day.get("flags", []):
            add_action("missing-fiscal-rate", "Review unmatched fiscal rates", "A payable day has no matching fiscal rate.", summary_amount, "high")
        if "ABSENCE_LIMIT_EXCEEDED" in day.get("flags", []):
            add_action("review-absence-limit", "Review absence-limit days", "An absence exceeded the available county allowance.", summary_amount, "high")
        if "DROP_IN_LIMIT_EXCEEDED" in day.get("flags", []):
            add_action("review-drop-in-limit", "Review drop-in-limit days", "A drop-in day exceeded the available allowance.", summary_amount, "high")
        if "PARENT_CONFIRMATION_PENDING" in day.get("flags", []):
            add_action("confirm-pending-attendance", "Review pending confirmations", "Confirmation is still pending and may affect the payable amount.", summary_amount, "high")

    # Render categories/counties/children from the collected rows - each view groups the
    # same rows by a different key/label pair, sharing one generic reducer instead of three
    # copies of hand-rolled get-or-create-then-sum/collect logic.
    _AGGREGATE_SUM_FIELDS = ("hours", "amount", "conditional_amount", "excluded_days")
    _AGGREGATE_COLLECT_FIELDS = ("authorization_names", "children_served", "excluded_reasons")
    categories = aggregate_by(
        view_rows, key_fn=lambda row: row["category_key"], label_fn=lambda row: row["category_label"],
        sum_fields=_AGGREGATE_SUM_FIELDS, collect_fields=_AGGREGATE_COLLECT_FIELDS, count_field="days",
    )
    counties = aggregate_by(
        view_rows, key_fn=lambda row: row["county_key"], label_fn=lambda row: row["county_label"],
        sum_fields=_AGGREGATE_SUM_FIELDS, collect_fields=_AGGREGATE_COLLECT_FIELDS, count_field="days",
    )
    children = aggregate_by(
        view_rows, key_fn=lambda row: row["child_key"], label_fn=lambda row: row["child_label"],
        sum_fields=_AGGREGATE_SUM_FIELDS, collect_fields=_AGGREGATE_COLLECT_FIELDS, count_field="days",
    )

    vacant_slot_fee, vacant_slot_days = _vacant_slot_fee_totals(payload)
    # Vacant slots have no confirmation concept; include them only in potential_total.
    for slot_day in vacant_slot_days:
        slot_day["amount_class"] = "VACANT_SLOT"
        slot_county_key = str(slot_day.get("county_id") or "UNKNOWN")
        slot_county = composition_bucket(slot_county_key, str(slot_day.get("county_name") or "Unavailable from the current source"))
        slot_county["vacant_slots"]["days"] += 1
        slot_county["vacant_slots"]["amount"] += _hours(slot_day.get("amount")) or Decimal("0")
    scheduled_fees = vacant_slot_fee
    base_total = total
    # potential_total and estimated_total are the same figure (Maximum estimated payout =
    # net + scheduled forecast + conditional at-risk, per PAYMENT_AMOUNT_LEGEND) - a single
    # formula, matching summary_view's own overview.estimated_total/potential_total, which
    # previously disagreed with this top-level pair (estimated_total omitted at_risk_total here).
    potential_total = base_total + forecasted_total + at_risk_total + scheduled_fees
    estimated_total = potential_total
    gross_total = base_total
    net_total = base_total
    conditional_total = at_risk_total
    payment_status = "CONDITIONAL" if at_risk_total else "EXPECTED"
    if duplicate:
        payment_status = "SUBMITTED"
    payment_summary = [{**{"county_id": group["county_id"]}, **({"county_name": group["county_name"]} if isinstance(group["county_name"], str) and group["county_name"] else {}), "paid_tier": group["paid_tier"], "rate": next(iter(group["rates"])) if len(group["rates"]) == 1 else "Multiple", "rates": sorted(group["rates"]), "basis": group["basis"], "children_served": len(group["children_served"]), "hours": _money(group["hours"]), "amount": _money(group["amount"]), "conditional_amount": _money(group["conditional_amount"])} for group in sorted(summary_groups.values(), key=lambda value: (value["county_id"], value["paid_tier"], value["basis"]))]
    summary_view = _render_summary_view(
        categories,
        counties,
        county_composition,
        children,
        actions,
        vacant_slot_days,
        gross_total,
        net_total,
        conditional_total,
        excluded_days,
        distinct_children_served,
        paid_days,
        forecasted_total=forecasted_total,
        at_risk_total=at_risk_total,
    )
    return {
        "status": "ok",
        "rule_version": RULE_VERSION,
        "calculation_mode": payload.get("calculation_mode", "STATUS"),
        "source_readiness": "COMPLETE",
        "attendance": attendance,
        "holiday_classification_mismatches": holiday_classification_mismatches,
        "total_amount_incorrectly_at_risk": _money(total_amount_incorrectly_at_risk),
        "child_payment_impacts": [
            {
                "child_name": child_name,
                "amount_at_risk": _money(child_payment_impact.get(child_name, Decimal("0"))),
                "total_amount": _money(child_payment_total.get(child_name, Decimal("0"))),
            }
            for child_name in sorted(set(child_payment_impact) | set(child_payment_total))
        ],
        "payment": {
            "status": payment_status,
            "amount": _money(net_total),
            "base_amount": _money(base_total),
            "scheduled_forecast_amount": _money(forecasted_total),
            "gross_amount": _money(gross_total),
            "amount_at_risk": _money(conditional_total),
            # Provider-facing three-way breakdown: Expected (window elapsed),
            "expected_amount": _money(expected_total),
            "forecasted_amount": _money(forecasted_total),
            "at_risk_amount": _money(at_risk_total),
            "guaranteed_amount": _money(guaranteed_total),
            "holiday_classification_mismatches": holiday_classification_mismatches,
            "total_amount_incorrectly_at_risk": _money(total_amount_incorrectly_at_risk),
            "payout_date": resolve_payout_date(payload, period_end).isoformat(),
            "excluded_days": excluded_days,
            "excluded_authorizations": len(excluded_authorizations),
            "slot_fee": _money(vacant_slot_fee),
            "vacant_slot_fee": _money(vacant_slot_fee),
            "vacant_slot_days": vacant_slot_days,
            "potential_total": _money(potential_total),
            "estimated_total": _money(estimated_total),
            **({"existing_status": duplicate["status"]} if duplicate else {}),
            "summary": payment_summary,
            "summary_view": summary_view,
            **({"fiscal_rate_gaps": fiscal_rate_gaps} if fiscal_rate_gaps else {}),
            **_settlement_fields(payload, period_end, as_of_date, net_total),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Evaluate a canonical provider attendance and payment payload."
    )
    parser.add_argument("payload", type=Path, help="Path to canonical payment JSON")
    parser.add_argument("-o", "--output", type=Path, help="Write JSON to this path")
    args = parser.parse_args()
    try:
        payload = json.loads(args.payload.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("input must be an object")
        result = {"status": "ok", "result": evaluate_provider_risk_and_payment(payload)}
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(json.dumps({"status": "error", "error": str(error)}))
        return 2
    except Exception as error:  # noqa: BLE001 - fail closed on any unexpected evaluator defect
        # Return JSON for unexpected defects so callers can parse the failure.
        print(json.dumps({"status": "error", "error": f"Payment engine failed unexpectedly: {error}"}))
        return 2

    rendered = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())