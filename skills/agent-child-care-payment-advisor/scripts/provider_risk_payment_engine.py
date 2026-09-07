#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Deterministic provider-scoped attendance and payment evaluation."""

import argparse
import json
import sys
from collections import defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path
from typing import Any


RULE_VERSION = "provider-risk-payment-v1"
PAID_PAYMENT_STATUSES = {"PAID", "REQUESTED"}
CURRENCY_QUANTUM = Decimal("0.01")


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


def _money(value: Decimal) -> str:
    return format(value.quantize(CURRENCY_QUANTUM, rounding=ROUND_HALF_UP), ".2f")


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
            (authorization.get("county_id"), authorization.get("quality_tier")),
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

    authorization_by_id = {
        authorization.get("id"): authorization
        for authorization in authorizations
        if isinstance(authorization, dict) and isinstance(authorization.get("id"), str)
    }
    policy_by_authorization = _policy_by_authorization(authorizations, county_policies)
    absence_counts: dict[str, int] = defaultdict(int)
    county_counts: dict[str, dict[str, int]] = defaultdict(
        lambda: {"attended_days": 0, "payable_absence_days": 0, "excluded_absence_days": 0, "conditional_days": 0}
    )
    results = []

    for attendance_day in sorted(
        (day for day in attendance_days if isinstance(day, dict)),
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
        if attendance_day.get("care_not_offered") is True:
            classification = "CARE_NOT_OFFERED"
            payable = False
            paid_tier = None
        elif attendance_day.get("observed_holiday") is True and occupied_slot_contract:
            classification = "SLOT_CONTRACT_HOLIDAY"
            payable = True
            paid_tier = _tier_for_hours(authorized_hours)
        elif attended_hours > 0:
            classification = "ATTENDED"
            payable = True
            paid_tier = _tier_for_hours(min(authorized_hours, attended_hours))
            if attended_hours > authorized_hours:
                flags.append("OVER_ATTENDANCE")
        elif authorized_hours == 0:
            classification = "NO_CARE"
            payable = False
            paid_tier = None
        else:
            classification = "ABSENCE"
            paid_tier = _tier_for_hours(authorized_hours)
            age_band = attendance_day.get("age_band")
            absence_limit = policy.get("absence_limit")
            parent_approved = attendance_day.get("absence_parent_approved")
            absence_counts[authorization_id] += 1
            if not isinstance(parent_approved, bool):
                classification = "BLOCKED"
                payable = False
                flags.append("ABSENCE_APPROVAL_UNAVAILABLE")
            elif not isinstance(absence_limit, int) or isinstance(absence_limit, bool) or absence_limit < 0:
                classification = "BLOCKED"
                payable = False
                flags.append("ABSENCE_LIMIT_UNAVAILABLE")
            elif absence_counts[authorization_id] <= absence_limit:
                if age_band == "ZERO_TO_36_MONTHS":
                    payable = True
                elif age_band == "OVER_36_MONTHS":
                    payable = not parent_approved
                    if parent_approved:
                        flags.append("PARENT_APPROVED_ABSENCE_NOT_PAYABLE")
                else:
                    classification = "BLOCKED"
                    payable = False
                    flags.append("AGE_BAND_UNAVAILABLE")
            elif age_band == "ZERO_TO_36_MONTHS":
                classification = "ENROLLMENT_ABSENCE"
                payable = True
            elif age_band == "OVER_36_MONTHS":
                payable = False
                flags.append("ABSENCE_LIMIT_EXCEEDED")
            else:
                classification = "BLOCKED"
                payable = False
                flags.append("AGE_BAND_UNAVAILABLE")

        confirmation = attendance_day.get("parent_confirmation")
        conditional = confirmation == "PENDING"
        if conditional:
            flags.append("PARENT_CONFIRMATION_PENDING")
        elif confirmation != "CONFIRMED":
            classification = "BLOCKED"
            payable = False
            flags.append("PARENT_CONFIRMATION_UNAVAILABLE")

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
            "classification": classification,
            "payable": payable,
            "conditional": conditional,
            "paid_tier": paid_tier,
            "flags": sorted(flags),
        })

    return {
        "days": results,
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
            and payment.get("authorization_id") in authorization_ids
            and payment.get("service_period_id") == period["id"]
            and payment.get("status") in PAID_PAYMENT_STATUSES
        ),
        None,
    )
    if duplicate:
        return {
            "status": "ok",
            "rule_version": RULE_VERSION,
            "source_readiness": "COMPLETE",
            "attendance": attendance,
            "payment": {"status": "DUPLICATE_GUARD", "existing_status": duplicate["status"]},
        }

    rates: dict[tuple[str, str], Decimal] = {}
    for rate in payload["fiscal_rates"]:
        if not isinstance(rate, dict):
            return _blocked(["fiscal_rate_record"], attendance)
        authorization_id = rate.get("authorization_id")
        paid_tier = rate.get("paid_tier")
        amount = _hours(rate.get("amount"))
        if not isinstance(authorization_id, str) or not isinstance(paid_tier, str) or amount is None:
            return _blocked(["fiscal_rate_record"], attendance)
        rate_key = (authorization_id, paid_tier)
        if rate_key in rates:
            return _blocked(["ambiguous_fiscal_rate"], attendance)
        rates[rate_key] = amount
    total = Decimal("0")
    conditional_total = Decimal("0")
    excluded_days = 0
    for day in attendance["days"]:
        if not day["payable"]:
            excluded_days += 1
            continue
        rate = rates.get((day["authorization_id"], day["paid_tier"]))
        if rate is None:
            return _blocked(["matching_fiscal_rate"], attendance)
        total += rate
        if day["conditional"]:
            conditional_total += rate
    payment_status = "CONDITIONAL" if conditional_total else "EXPECTED"
    return {
        "status": "ok",
        "rule_version": RULE_VERSION,
        "source_readiness": "COMPLETE",
        "attendance": attendance,
        "payment": {
            "status": payment_status,
            "amount": _money(total),
            "amount_at_risk": _money(conditional_total),
            "excluded_days": excluded_days,
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

    rendered = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())