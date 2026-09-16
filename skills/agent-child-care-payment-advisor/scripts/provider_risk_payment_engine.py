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


RULE_VERSION = "provider-risk-payment-v3"
PAID_PAYMENT_STATUSES = {"PAID", "REQUESTED"}
CURRENCY_QUANTUM = Decimal("0.01")
# Mirrors evaluate_attendance_risks.py's CONFIRMATION_WINDOW_DAYS. Duplicated
# rather than shared because the two scripts have no common import path; keep
# both constants in sync if the window rule ever changes.
CONFIRMATION_WINDOW_DAYS = 9


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
    # Sunday (6) + 12 modulo 7 = Friday (4).
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
    for this period, it is authoritative; if not, the calculated net_total
    is used as the best available figure, explicitly flagged as such.
    """
    if as_of_date < resolve_payout_date(payload, period_end):
        return {"is_settled": False}
    service_period = payload.get("service_period")
    service_period_id = service_period.get("id") if isinstance(service_period, dict) else None
    actual_entries = [
        row
        for row in payload.get("existing_sub_payments", [])
        if isinstance(row, dict)
        and row.get("service_period_id") == service_period_id
        and isinstance(row.get("amount"), (int, float))
        and not isinstance(row.get("amount"), bool)
    ]
    if actual_entries:
        actual_total = sum((Decimal(str(row["amount"])) for row in actual_entries), Decimal("0"))
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
    rates: dict[tuple[str, str, str], Decimal],
    authorization_id: str,
    paid_tier: str,
    rate_type_code: str | None,
) -> Decimal | None:
    """Joins a schedule day to its fiscal rate by (authorization_id,
    paid_tier, rate_type_code) - the day's own scheduled rate type
    (regular/overnight/weekend/etc) matched against the fiscal rate row's
    own rate type, care unit (already encoded in paid_tier), and age group
    (already filtered upstream before a rate row ever reaches here). An
    authorization's schedule days can each carry a different rate type
    across one period, so this is a real per-day join, not a per-
    authorization constant - shared by both the exclusion check and the
    category/composition amount calculation so they never disagree.
    """
    key_rate_type = str(rate_type_code or "")
    rate = rates.get((authorization_id, paid_tier, key_rate_type))
    if rate is not None:
        return rate
    return rates.get((authorization_id, "NO_PAYMENT", key_rate_type))


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
    # Single-pass consolidation (2026-09-15): this function used to iterate
    # attendance_days itself (a second/third full pass, after the main
    # financial loop and the summary_groups loop had already each iterated
    # it once) and independently re-derive its own per-day risk/rate state.
    # That duplication was the confirmed root cause of a real cross-table
    # amount mismatch (category/composition tables disagreeing with the
    # headline totals - see 2026-09-15 memory). categories/counties/
    # county_composition/children/actions are now accumulated exactly once,
    # inline in evaluate_provider_risk_and_payment's own single per-day loop,
    # and this function only renders the already-built dicts - it performs
    # no attendance-day classification of its own.
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
            rendered[component] = {
                **({"days": source["days"]} if "days" in source else {}),
                "hours": _money(source["hours"]),
                "amount": _money(source["amount"] - conditional_amount),
                "confirmed_amount": _money(source["confirmed_amount"]),
                "conditional_amount": _money(source["conditional_amount"]),
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
        rendered["potential_total"] = _money(
            sum(
                _hours(rendered[component]["amount"]) or Decimal("0")
                for component in ("care", "absence", "enrollment_absence", "drop_in", "paid_holidays")
            )
            + component_at_risk
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


def evaluate_attendance(payload: dict[str, Any]) -> dict[str, Any]:
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
        authorization_id = attendance_day.get("authorization_id")
        if not isinstance(authorization_id, str):
            results.append({
                "authorization_id": authorization_id,
                "service_date": attendance_day.get("service_date"),
                "classification": "BLOCKED",
                "flags": ["INVALID_AUTHORIZATION_ID"],
            })
            continue
        authorization = authorization_by_id.get(authorization_id)
        service_date = _date_value(attendance_day.get("service_date"))
        authorized_hours = _hours(attendance_day.get("authorized_hours"))
        attended_hours = _hours(attendance_day.get("attended_hours"))
        if not authorization or not service_date or authorized_hours is None or attended_hours is None:
            results.append({
                "authorization_id": authorization_id,
                "service_date": attendance_day.get("service_date"),
                "classification": "BLOCKED",
                "flags": ["MISSING_ATTENDANCE_DAY_INPUT"],
            })
            continue

        policy = policy_by_authorization.get(authorization_id, {})
        county_id = authorization.get("county_id")
        flags: list[str] = []
        occupied_slot_contract = attendance_day.get("occupied_slot_contract") is True
        as_of_date = _date_value(payload.get("as_of_date"))
        scheduled_forecast = (
            attendance_day.get("forecast_basis") == "SCHEDULED"
            and as_of_date is not None
            and service_date > as_of_date
        )
        unit_hours = Decimal("0")
        payment_type = "NONE"
        # Classification-time holiday check: match against THIS authorization's
        # county-specific paid-holiday list only (per the v3 redesign) - a day
        # merely present in a generic payload-level holiday_dates list is no
        # longer sufficient to classify as HOLIDAY; it must appear on this
        # county's own list, or it falls through to Drop-in/Absence below.
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
        if scheduled_forecast:
            classification = "SCHEDULED_FORECAST"
            payable = True
            paid_tier = _tier_for_hours(authorized_hours)
            unit_hours = authorized_hours
            payment_type = "FORECAST"
            info_code = "FORECAST"
            flags.append("SCHEDULED_FUTURE_DAY")
        elif (attendance_day.get("care_not_offered") is True or provider_closed) and not county_holiday_match:
            classification = "CARE_NOT_OFFERED"
            payable = False
            paid_tier = None
            info_code = "14"
            if provider_closed:
                flags.append("PROVIDER_CLOSED")
        elif attended_hours > 0 and authorized_hours == 0:
            # Genuine drop-in: attended without any authorized hours that day.
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
                # Must still carry the real category (not the "NONE"/"Not
                # paid" default) so this at-risk amount lands in the
                # "Drop-ins" row/component instead of silently disappearing
                # from the category and county-composition tables (it was
                # still counted in the headline at_risk_total, just invisible
                # in the breakdown tables - the exact cross-table mismatch
                # this fix addresses).
                payment_type = "DROP_IN"
                flags.append("DROP_IN_LIMIT_EXCEEDED")
            else:
                payable = True
                paid_tier = _tier_for_hours(attended_hours)
                unit_hours = attended_hours
                payment_type = "DROP_IN"
            info_code = "3"
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
            # attended_hours == 0 and authorized_hours == 0: no authorization
            # existed for this day and nothing was attended - nothing owed,
            # nothing to be absent from. Terminal, non-payable classification;
            # does not enter the holiday/window/absence waterfall below.
            classification = "NO_CARE"
            payable = False
            paid_tier = None
            info_code = "NONE"
        elif county_holiday_match and not holiday_paid_on_other_date:
            # attended_hours == 0 (any authorized_hours value) and this date
            # matches the specific county's paid-holiday list.
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
            # The county-list match above already proves this date is on
            # THIS county's paid-holiday list; the only remaining payability
            # gate is whether the county allows paid holidays at all.
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
            # Cannot determine the confirmation window without as_of_date -
            # fail closed rather than guess whether this day is still pending
            # or should already be resolved as an absence.
            classification = "BLOCKED"
            payable = False
            paid_tier = None
            info_code = "4"
            flags.append("AS_OF_DATE_UNAVAILABLE")
        elif (as_of_date - service_date).days < CONFIRMATION_WINDOW_DAYS:
            # Not a holiday, attended_hours == 0, still within the 9-day
            # confirmation window - too soon to resolve as Absence. The
            # existing parent_confirmation field already distinguishes the
            # two real-world cases here: "PENDING" means a check-in/check-out
            # transaction exists but has not yet been parent-approved (once
            # approved, Hours__c/attended_hours is updated to reflect it);
            # anything else (missing/unset) means no check-in/check-out
            # transaction was logged for this scheduled day at all.
            confirmation_state = attendance_day.get("parent_confirmation")
            if confirmation_state == "PENDING":
                classification = "PENDING_CONFIRMATION"
                flags.append("PARENT_CONFIRMATION_PENDING")
            else:
                classification = "INCOMPLETE_ATTENDANCE_RECORD"
                flags.append("MISSING_ATTENDANCE_TRANSACTION")
            # Keep unresolved days eligible for pricing, but conditional, so
            # their scheduled value can contribute to risk without entering
            # the base payable total. Must carry a real category ("REGULAR" -
            # this is unconfirmed attended care, not an absence) instead of
            # the "NONE"/"Not paid" default: same reasoning as the
            # DROP_IN_LIMIT_EXCEEDED/ABSENCE_LIMIT_EXCEEDED fixes above - an
            # uncategorized amount is invisible in the category and county-
            # composition tables even though it is already counted in the
            # headline amount_at_risk total, producing a cross-table mismatch.
            payable = True
            paid_tier = _tier_for_hours(authorized_hours)
            unit_hours = authorized_hours
            payment_type = "REGULAR"
            info_code = "PENDING"
            conditional = True
        else:
            # Not a holiday, attended_hours == 0, past the confirmation
            # window: Absence. No parent-approval or age-band payable/
            # not-payable split (per the v3 redesign) - the county's monthly
            # absence-limit count is the only remaining gate, with the
            # existing ENROLLMENT_ABSENCE carve-out for 0-36-month children
            # who are over that limit.
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
                # Same reasoning as DROP_IN_LIMIT_EXCEEDED above: carry the
                # real category so this at-risk amount surfaces under "Paid
                # absence" in the category/composition tables instead of
                # falling into the "NONE"/"Not paid" bucket, which is
                # invisible in both breakdown tables even though it is
                # already counted in the headline amount_at_risk total.
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
        # The v3 redesign moved Holiday/Absence/Enrollment-Absence/NO_CARE/
        # PENDING_CONFIRMATION/INCOMPLETE_ATTENDANCE_RECORD determination to
        # the county-holiday-list + confirmation-window waterfall above, so
        # this generic parent_confirmation-field gate must not override those
        # classifications - it still applies to SCHEDULED_FORECAST, ATTENDED,
        # and DROP_IN, which genuinely depend on a real-time confirmed
        # attendance record. `conditional` is already set directly above for
        # PENDING_CONFIRMATION/INCOMPLETE_ATTENDANCE_RECORD.
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
            # A future authorized schedule is a forecast, not a payment risk.
            # There is no attendance confirmation to resolve until the service
            # date occurs, so parent confirmation must not move it into risk.
            conditional = False
        else:
            conditional = classification in {"PENDING_CONFIRMATION", "INCOMPLETE_ATTENDANCE_RECORD"}

        # Keep actual attendance hours for reporting, but value unresolved
        # confirmations against the authorized scheduled hours for risk.
        risk_hours = authorized_hours if conditional and classification in {
            "ATTENDED",
            "PENDING_CONFIRMATION",
            "INCOMPLETE_ATTENDANCE_RECORD",
        } else unit_hours

        county = county_counts[str(county_id)]
        if conditional:
            county["conditional_days"] += 1
        if classification == "ATTENDED":
            county["attended_days"] += 1
        elif payable and classification in {"ABSENCE", "ENROLLMENT_ABSENCE"}:
            county["payable_absence_days"] += 1
        elif classification == "ABSENCE" and not payable:
            county["excluded_absence_days"] += 1
        results.append({
            "authorization_id": authorization_id,
            "service_date": service_date.isoformat(),
            "authorized_hours": _money(authorized_hours),
            "attended_hours": _money(attended_hours),
            **({"confirm_by_date": (service_date + timedelta(days=CONFIRMATION_WINDOW_DAYS)).isoformat()} if (as_of_date := _date_value(payload.get("as_of_date"))) and as_of_date <= service_date + timedelta(days=CONFIRMATION_WINDOW_DAYS) else {}),
            **({"child_name": attendance_day["child_name"]} if isinstance(attendance_day.get("child_name"), str) else {}),
            **({"authorization_name": attendance_day["authorization_name"]} if isinstance(attendance_day.get("authorization_name"), str) else {}),
            **({"county_id": attendance_day["county_id"]} if isinstance(attendance_day.get("county_id"), str) else {}),
            **({"county_name": attendance_day["county_name"]} if isinstance(attendance_day.get("county_name"), str) else {}),
            "classification": classification,
            **({"attendance_basis": attendance_day["attendance_basis"]} if attendance_day.get("attendance_basis") in {"ACTUAL", "SCHEDULED"} else {}),
            "payable": payable,
            # Set to True below (evaluate_provider_risk_and_payment) for any
            # day the payment engine actually excludes from payment, so
            # callers can filter to excluded-only rows without re-deriving
            # this engine's exclusion logic themselves.
            "payment_excluded": False,
            "unit_hours": _money(unit_hours),
            "risk_hours": _money(risk_hours),
            "category": category,
            "payment_type": category if category == "REGULAR" and classification == "ATTENDED" else payment_class,
            "info_code": info_code,
            **({"rate_type_code": attendance_day["rate_type_code"]} if isinstance(attendance_day.get("rate_type_code"), str) else {}),
            "occupied_slot_contract": occupied_slot_contract,
            "slot_contract_present": attendance_day.get("slot_contract_present") is True,
            "conditional": conditional,
            **({"forecast_basis": "SCHEDULED"} if scheduled_forecast else {}),
            "paid_tier": paid_tier,
            "flags": sorted(flags),
        })

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
    # The unique join between a schedule day and its fiscal rate is the
    # day's own rate type (regular/overnight/weekend/etc) + age group +
    # care unit (care unit is already what paid_tier encodes, derived from
    # finalized/calculated hours) - matched against the fiscal rate row's
    # own rate type + age group + care unit. An authorization's schedule
    # days can each be scheduled under a DIFFERENT rate type across one
    # service period (live-confirmed: one authorization's 7 days in a
    # week used 5 different rate types), so fiscal_rates can legitimately
    # contain several rows for the same (authorization_id, paid_tier) -
    # one per rate type. Age group is already filtered upstream (TS layer)
    # to the authorization's list of acceptable codes, not narrowed to a
    # single exact value - two rows can still legitimately share
    # (authorization_id, paid_tier, rate_type_code) while differing only
    # in age_group_code. That is a genuine remaining data-quality/
    # precision gap, not grounds to hard-block the entire computation:
    # deterministically keep the first candidate seen (stable since
    # fiscal_rates ordering is stable) rather than crash the whole
    # request over an upstream age-group ambiguity, consistent with the
    # "one ambiguous/bad row never kills the whole batch" resilience
    # pattern applied elsewhere in this pipeline.
    rates: dict[tuple[str, str, str], Decimal] = {}
    for rate in payload["fiscal_rates"]:
        if not isinstance(rate, dict):
            return _blocked(["fiscal_rate_record"], attendance)
        authorization_id = rate.get("authorization_id")
        paid_tier = rate.get("paid_tier")
        amount = _hours(rate.get("amount"))
        rate_type_code = str(rate.get("rate_type_code") or "")
        if not isinstance(authorization_id, str) or not isinstance(paid_tier, str) or amount is None:
            return _blocked(["fiscal_rate_record"], attendance)
        rate_key = (authorization_id, paid_tier, rate_type_code)
        if rate_key in rates:
            continue
        rates[rate_key] = Decimal("0") if paid_tier == "NO_PAYMENT" else amount

    excluded_authorizations: set[str] = set()
    unavailable_rate_days: set[tuple[str, str]] = set()
    for day in attendance["days"]:
        if not day["payable"]:
            continue
        authorization_id = day["authorization_id"]
        if _resolve_rate(rates, authorization_id, day["paid_tier"], day.get("rate_type_code")) is None:
            excluded_authorizations.add(authorization_id)
            unavailable_rate_days.add((authorization_id, str(day.get("service_date"))))
    total = Decimal("0")
    conditional_total = Decimal("0")
    # Expected/Forecasted/At-risk is an additive breakdown alongside the
    # existing total/conditional_total calculation above; it never changes
    # what those two already compute, only re-labels the same day amounts
    # into a provider-facing category.
    expected_total = Decimal("0")
    forecasted_total = Decimal("0")
    at_risk_total = Decimal("0")
    guaranteed_total = Decimal("0")
    excluded_days = 0
    holiday_classification_mismatches: list[dict[str, Any]] = []
    total_amount_incorrectly_at_risk = Decimal("0")
    child_payment_impact: dict[str, Decimal] = defaultdict(Decimal)
    # Total matched payment by child, including non-risk days.
    child_payment_total: dict[str, Decimal] = defaultdict(Decimal)

    # Single-pass consolidation (2026-09-15): categories/counties/
    # county_composition/children/actions/summary_groups/distinct_children_served/
    # paid_days used to be built by THREE separate full passes over
    # attendance["days"] (this financial loop, a dedicated summary_groups loop,
    # and _build_payment_summary_view's own loop) - each independently
    # re-deriving per-day rate/hours/risk state. That duplication was the
    # confirmed root cause of a real cross-table amount mismatch (category/
    # composition tables disagreeing with the headline totals). Folded into
    # this single loop so every downstream table is built from exactly the
    # same per-day computation, once - see _render_summary_view below.
    category_labels = {
        "REGULAR": "Regular care",
        "HOLIDAY": "Holiday",
        "ABSENCE": "Paid absence",
        "ENROLLMENT": "Enrollment absence",
        "DROP_IN": "Drop-in",
        "FORECAST": "Scheduled forecast",
    }
    categories: dict[str, dict[str, Any]] = {}
    counties: dict[str, dict[str, Any]] = {}
    county_composition: dict[str, dict[str, Any]] = {}
    children: dict[str, dict[str, Any]] = {}
    actions: dict[str, dict[str, Any]] = {}
    summary_groups: dict[tuple[str, str, str], dict[str, Any]] = {}
    distinct_children_served: set[str] = set()
    paid_days = 0

    def bucket(store: dict[str, dict[str, Any]], key: str, label: str) -> dict[str, Any]:
        return store.setdefault(key, {
            "label": label,
            "days": 0,
            "hours": Decimal("0"),
            "amount": Decimal("0"),
            "conditional_amount": Decimal("0"),
            "excluded_days": 0,
            "excluded_reasons": set(),
            "children_served": set(),
            # Tracked so the per-child rollup can show which authorization(s)
            # a child's days rolled up from - a child name alone does not
            # uniquely identify a child if duplicate names exist.
            "authorization_names": set(),
        })

    def composition_bucket(county_key: str, county_label: str) -> dict[str, Any]:
        # Absence and paid_holidays additionally track "days" (not just
        # hours), because the county-composition table displays day counts
        # for those two categories instead of hours per the column redesign.
        county = county_composition.setdefault(county_key, {
            "county": county_label,
            "children_served": set(),
            "attendance_based_amount": Decimal("0"),
            "authorized_based_amount": Decimal("0"),
            "amount_at_risk": Decimal("0"),
            "care": {"hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0")},
            "absence": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0")},
            "enrollment_absence": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0")},
            "drop_in": {"hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0")},
            "vacant_slots": {"days": 0, "amount": Decimal("0")},
            "paid_holidays": {"days": 0, "hours": Decimal("0"), "amount": Decimal("0"), "confirmed_amount": Decimal("0"), "conditional_amount": Decimal("0")},
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
    ) -> None:
        if component not in county:
            return
        item = county[component]
        if "days" in item:
            item["days"] += 1
        item["hours"] += hours
        item["amount"] += amount
        item["conditional_amount" if conditional else "confirmed_amount"] += amount

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
        # Same per-day rate/rate-type join reused everywhere below (headline
        # totals, category/composition rendering, and summary grouping) - a
        # single resolution per day, not three independent ones.
        rate = _resolve_rate(rates, day["authorization_id"], day["paid_tier"], day.get("rate_type_code"))
        unit_hours = _hours(day.get("unit_hours")) or Decimal("0")
        risk_day = day["conditional"] or any(
            flag in day["flags"]
            for flag in ("DROP_IN_LIMIT_EXCEEDED", "ABSENCE_LIMIT_EXCEEDED", "FISCAL_RATE_UNAVAILABLE")
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

        # Base/estimated payable is every resolved attendance, absence, or
        # drop-in amount, including resolved rows still inside the window.
        # Scheduled forecast is future authorized schedule only. At-risk is
        # unresolved, excluded, over-limit, or unmatched-rate payment only.
        is_future_day = day.get("forecast_basis") == "SCHEDULED"
        limit_exceeded = any(
            flag in day.get("flags", [])
            for flag in ("DROP_IN_LIMIT_EXCEEDED", "ABSENCE_LIMIT_EXCEEDED")
        )
        # PENDING_CONFIRMATION/INCOMPLETE_ATTENDANCE_RECORD are not-yet-resolved,
        # not excluded - a day cannot be simultaneously "pending" and
        # "excluded" (that label is reserved for a window that has actually
        # closed unconfirmed, or a definitively over-limit/unmatched day).
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
        if will_be_excluded or still_pending or risk_day:
            amount_class = "AT_RISK"
        elif is_future_day:
            amount_class = "FORECASTED"
        elif limit_exceeded:
            amount_class = "AT_RISK"
        else:
            amount_class = "EXPECTED"
        day["amount_class"] = amount_class
        if amount_class == "EXPECTED":
            expected_total += classified_amount
        elif amount_class == "FORECASTED":
            forecasted_total += classified_amount
        else:
            at_risk_total += classified_amount

        # Resolve payment_excluded/excluded_days/total via if/elif/else
        # instead of the early `continue` this used to have - the category/
        # composition/summary-group accumulation further below needs
        # day["payment_excluded"] already finalized for THIS day, in this
        # same iteration, which an early continue would have skipped past.
        if still_pending:
            pass  # Not yet resolved - never counted as paid or excluded while the confirmation window remains open.
        elif not day["payable"] or rate_unavailable:
            excluded_days += 1
            day["payment_excluded"] = True
            if rate_unavailable:
                day["flags"] = sorted({*day["flags"], "FISCAL_RATE_UNAVAILABLE"})
        else:
            recheck_rate = _resolve_rate(rates, day["authorization_id"], day["paid_tier"], day.get("rate_type_code"))
            if recheck_rate is None:
                excluded_days += 1
                day["payment_excluded"] = True
            elif amount_class == "EXPECTED":
                total += recheck_rate * unit_hours

        # ---- summary_groups accumulation (replaces the old separate loop) ----
        if day["payable"] and not day.get("payment_excluded"):
            paid_days += 1
            group_rate = _resolve_rate(rates, day["authorization_id"], day["paid_tier"], day.get("rate_type_code"))
            if group_rate is not None:
                county_id = day.get("county_id", "")
                paid_tier = day.get("paid_tier") or "NO_PAYMENT"
                basis = "SCHEDULED" if day.get("forecast_basis") == "SCHEDULED" else "ACTUAL"
                group_key = (county_id, paid_tier, basis)
                group = summary_groups.setdefault(group_key, {"county_id": county_id, "county_name": day.get("county_name"), "rates": set(), "paid_tier": paid_tier, "basis": basis, "children_served": set(), "hours": Decimal("0"), "amount": Decimal("0"), "conditional_amount": Decimal("0")})
                group["rates"].add(_money(group_rate))
                group_hours = _hours(day.get("unit_hours")) or Decimal("0")
                group_amount = group_rate * group_hours
                group["children_served"].add(day.get("child_name") or day["authorization_id"])
                group["hours"] += group_hours
                if day["conditional"]:
                    group["conditional_amount"] += group_amount
                else:
                    group["amount"] += group_amount

        # ---- category/county/child/composition accumulation (replaces the
        # old separate _build_payment_summary_view pass) ----
        payment_type = str(day.get("category") or day.get("payment_type") or "NONE")
        label = category_labels.get(payment_type, "Not paid")
        is_risk = amount_class == "AT_RISK"
        # amount_hours/classified_amount above already reflect the risk_hours
        # override for a risk day - reused directly instead of recomputing.
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
            add_attendance_component(county, component, summary_hours, summary_amount, is_risk)
        if child_key != "UNKNOWN":
            county["children_served"].add(child_key)
        if is_risk and rate is not None:
            county["amount_at_risk"] += summary_amount
        elif day.get("payable") is True and not day.get("payment_excluded") and rate is not None and payment_type in {"REGULAR", "FORECAST", "DROP_IN"}:
            county["attendance_based_amount"] += summary_amount
        for store, key, item_label in (
            (categories, payment_type, label),
            (counties, county_key, county_label),
            (children, child_key, child_label),
        ):
            item = bucket(store, key, item_label)
            item["days"] += 1
            authorization_name = day.get("authorization_name")
            if isinstance(authorization_name, str) and authorization_name:
                item["authorization_names"].add(authorization_name)
            if child_key != "UNKNOWN":
                item["children_served"].add(child_key)
            if is_risk and rate is not None:
                # Risk remains part of the canonical potential total even when
                # the source row is not currently payable. Keep it in the same
                # category as the source day so category, county, and overview
                # totals all expose the same amount exactly once.
                item["hours"] += summary_hours
                item["conditional_amount"] += summary_amount
            elif day.get("payable") is True and not day.get("payment_excluded") and rate is not None:
                # Hours only count money represented by this row, not excluded
                # rows with no payable amount.
                item["hours"] += summary_hours
                item["amount"] += summary_amount
            elif day.get("classification") not in {"NO_CARE", "CARE_NOT_OFFERED"}:
                item["excluded_days"] += 1
                for flag in day.get("flags", []):
                    if flag in {"PARENT_CONFIRMATION_PENDING", "PARENT_CONFIRMATION_UNAVAILABLE"}:
                        item["excluded_reasons"].add("pending confirmation")
                    elif flag == "ABSENCE_LIMIT_EXCEEDED":
                        item["excluded_reasons"].add("absence limit exceeded")
                    elif flag == "DROP_IN_LIMIT_EXCEEDED":
                        item["excluded_reasons"].add("drop-in limit exceeded")
                    elif flag == "FISCAL_RATE_UNAVAILABLE":
                        item["excluded_reasons"].add("fiscal rate unavailable")

        if "FISCAL_RATE_UNAVAILABLE" in day.get("flags", []):
            add_action("missing-fiscal-rate", "Review unmatched fiscal rates", "A payable day has no matching fiscal rate.", summary_amount, "high")
        if "ABSENCE_LIMIT_EXCEEDED" in day.get("flags", []):
            add_action("review-absence-limit", "Review absence-limit days", "An absence exceeded the available county allowance.", summary_amount, "high")
        if "DROP_IN_LIMIT_EXCEEDED" in day.get("flags", []):
            add_action("review-drop-in-limit", "Review drop-in-limit days", "A drop-in day exceeded the available allowance.", summary_amount, "high")
        if "PARENT_CONFIRMATION_PENDING" in day.get("flags", []):
            add_action("confirm-pending-attendance", "Review pending confirmations", "Confirmation is still pending and may affect the payable amount.", summary_amount, "high")
        if "HOLIDAY_NOT_IN_COUNTY_PLAN" in day.get("flags", []):
            add_action("review-holiday-plan", "Review the county holiday plan", "The date was not found in the active county holiday plan.", summary_amount, "medium")

    vacant_slot_fee, vacant_slot_days = _vacant_slot_fee_totals(payload)
    # Vacant slots have no parent/child confirmation concept. Keep them out of
    # base/forecast child amounts and include them only in potential_total.
    # (slot_within_window/slot_date_value/slot_amount were computed here in
    # the old code but never actually used anywhere - dropped as dead code.)
    for slot_day in vacant_slot_days:
        slot_day["amount_class"] = "VACANT_SLOT"
        slot_county_key = str(slot_day.get("county_id") or "UNKNOWN")
        slot_county = composition_bucket(slot_county_key, str(slot_day.get("county_name") or "Unavailable from the current source"))
        slot_county["vacant_slots"]["days"] += 1
        slot_county["vacant_slots"]["amount"] += _hours(slot_day.get("amount")) or Decimal("0")
    scheduled_fees = vacant_slot_fee
    base_total = total
    potential_total = base_total + forecasted_total + at_risk_total + scheduled_fees
    estimated_total = base_total + forecasted_total + scheduled_fees
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
        # A defensive field check elsewhere in this module can still miss an
        # edge case; surface it as a clean JSON error instead of letting a
        # raw traceback reach stdout, where the TypeScript caller would fail
        # to parse it and report a confusing subprocess error.
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