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


def _month_allowed(value: Any, service_date: date) -> bool:
    if not isinstance(value, str) or not value.strip():
        return True
    month = service_date.month
    tokens = {token.strip().upper() for token in value.replace(";", ",").split(",") if token.strip()}
    return str(month) not in tokens and service_date.strftime("%B").upper() not in tokens


def _frequency_applies(frequency: Any, month: str, charged_months: set[str]) -> bool:
    normalized = str(frequency or "").strip().upper()
    if normalized in {"MTH", "MONTH", "MONTHLY"}:
        return month not in charged_months
    if normalized in {"ANN", "ANNUAL", "YEARLY"}:
        return not charged_months
    if normalized in {"ONE", "ONE_TIME", "ONETIME"}:
        return not charged_months
    return False


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


def _county_holiday_allowed(
    value: Any,
    service_date: date,
    holiday_name: Any = None,
    holiday_date: Any = None,
    observed_holiday_date: Any = None,
) -> bool:
    if value is None or str(value).strip() == "":
        return True
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


def _scheduled_fee_totals(payload: dict[str, Any], attendance_days: list[dict[str, Any]]) -> tuple[Decimal, Decimal, Decimal, Decimal]:
    schedules = payload.get("fee_schedules")
    if not isinstance(schedules, list):
        return Decimal("0"), Decimal("0"), Decimal("0"), Decimal("0")
    history = payload.get("fee_history") if isinstance(payload.get("fee_history"), list) else []
    payable_by_auth_month: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for day in attendance_days:
        if day.get("payable") and isinstance(day.get("service_date"), str):
            service_date = _date_value(day["service_date"])
            if service_date:
                payable_by_auth_month[(str(day.get("authorization_id")), _month_key(service_date))].append(day)
    fee_totals = {"slot": Decimal("0"), "activity": Decimal("0"), "registration": Decimal("0"), "transportation": Decimal("0")}
    for schedule in schedules:
        if not isinstance(schedule, dict):
            continue
        authorization_id = schedule.get("authorization_id")
        if not isinstance(authorization_id, str):
            continue
        scheduled_months: dict[str, set[str]] = defaultdict(set)
        for (auth_id, month), days in payable_by_auth_month.items():
            if auth_id != authorization_id:
                continue
            eligible_days = [
                day for day in days
                if (
                    day.get("slot_contract_present") is True
                    or day.get("occupied_slot_contract") is True
                )
                and (
                    (schedule.get("effective_start") is None
                     or _date_value(day["service_date"]) >= _date_value(schedule["effective_start"]))
                    and (schedule.get("effective_end") is None
                         or _date_value(day["service_date"]) <= _date_value(schedule["effective_end"]))
                )
                and _weekday_allowed(schedule.get("days_of_week"), _date_value(day["service_date"]))
            ]
            eligible_days.sort(key=lambda day: day["service_date"])
            if schedule.get("days_of_month") is not None:
                monthly_limit = _hours(schedule["days_of_month"])
                if monthly_limit is None:
                    continue
                eligible_days = eligible_days[: int(monthly_limit)]
            if eligible_days:
                fee_totals["slot"] += (_hours(schedule.get("slot_rate_amount")) or Decimal("0")) * len(eligible_days)
            month_date = _date_value(f"{month}-01")
            if not month_date:
                continue
            for fee_type, amount_key, frequency_key, months_key in (
                ("activity", "activity_amount", "activity_frequency", "activity_months"),
                ("registration", "registration_amount", "registration_frequency", "registration_months"),
                ("transportation", "transportation_amount", "transportation_frequency", "transportation_months"),
            ):
                amount = _hours(schedule.get(amount_key))
                if amount is None or not _month_allowed(schedule.get(months_key), month_date):
                    continue
                if _frequency_applies(schedule.get(frequency_key), month, scheduled_months[fee_type]):
                    fee_totals[fee_type] += amount
                    scheduled_months[fee_type].add(month)
    paid_totals = {
        fee_type: sum(
            (_signed_amount(item.get(f"{fee_type}_paid")) or Decimal("0")
             for item in history if isinstance(item, dict) and item.get("deleted") is not True),
            Decimal("0"),
        )
        for fee_type in ("slot", "activity", "registration", "transportation")
    }
    return tuple(max(fee_totals[key] - paid_totals[key], Decimal("0")) for key in ("slot", "activity", "registration", "transportation"))


def _monthly_copay_total(payload: dict[str, Any], attendance_days: list[dict[str, Any]]) -> Decimal:
    copays = payload.get("authorization_copays")
    if not isinstance(copays, list):
        return Decimal("0")
    payable_months = {
        (str(day.get("authorization_id")), str(day.get("service_date"))[:7])
        for day in attendance_days
        if (
            day.get("payable") is True
            and day.get("payment_type") == "REGULAR"
            and day.get("occupied_slot_contract") is not True
        )
    }
    total = Decimal("0")
    for authorization_id, month in payable_months:
        effective_date = _date_value(f"{month}-01")
        if not effective_date:
            continue
        matching = []
        for copay in copays:
            if not isinstance(copay, dict) or copay.get("authorization_id") != authorization_id:
                continue
            start = _date_value(copay.get("effective_start"))
            end = _date_value(copay.get("effective_end")) if copay.get("effective_end") else None
            if start and start <= effective_date and (not end or end >= effective_date):
                matching.append(copay)
        if len(matching) > 1:
            raise ValueError("ambiguous_authorization_copay")
        if matching:
            total += _hours(matching[0].get("amount")) or Decimal("0")
    return total


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
    history = payload.get("fee_history") if isinstance(payload.get("fee_history"), list) else []
    absence_counts: dict[str, int] = defaultdict(int)
    drop_in_counts: dict[str, int] = defaultdict(int)
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
        scheduled_forecast = attendance_day.get("forecast_basis") == "SCHEDULED"
        unit_hours = Decimal("0")
        payment_type = "NONE"
        if scheduled_forecast:
            classification = "SCHEDULED_FORECAST"
            payable = True
            paid_tier = _tier_for_hours(authorized_hours)
            unit_hours = authorized_hours
            payment_type = "FORECAST"
            info_code = "FORECAST"
            flags.append("SCHEDULED_FUTURE_DAY")
        elif attendance_day.get("care_not_offered") is True:
            classification = "CARE_NOT_OFFERED"
            payable = False
            paid_tier = None
            info_code = "14"
        elif attendance_day.get("observed_holiday") is True:
            holiday_code = "9" if occupied_slot_contract else "1"
            holiday_already_paid = any(
                isinstance(item, dict)
                and item.get("authorization_id") == authorization_id
                and item.get("service_date") == service_date.isoformat()
                and str(item.get("info_code", "")).strip() == holiday_code
                for item in history
            )
            classification = "SLOT_CONTRACT_HOLIDAY" if occupied_slot_contract else "HOLIDAY"
            allow_paid_holidays = policy.get("allow_paid_holidays")
            holiday_list = policy.get("county_holiday_list")
            payable = (
                allow_paid_holidays is not False
                and _county_holiday_allowed(
                    holiday_list,
                    service_date,
                    attendance_day.get("holiday_name"),
                    attendance_day.get("holiday_date"),
                    attendance_day.get("observed_holiday_date"),
                )
            )
            paid_tier = _tier_for_hours(authorized_hours)
            unit_hours = authorized_hours
            payment_type = "SLOT_CONTRACT" if occupied_slot_contract else "HOLIDAY"
            info_code = holiday_code
            if not payable:
                unit_hours = Decimal("0")
                payment_type = "NONE"
                flags.append(
                    "PAID_HOLIDAY_NOT_ALLOWED"
                    if allow_paid_holidays is False
                    else "HOLIDAY_NOT_IN_COUNTY_PLAN"
                )
            if holiday_already_paid:
                payable = False
                unit_hours = Decimal("0")
                payment_type = "NONE"
                flags.append("HOLIDAY_ALREADY_PAID")
        elif authorized_hours == 0 and attended_hours > 0:
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
                paid_tier = None
                flags.append("DROP_IN_LIMIT_EXCEEDED")
            else:
                payable = True
                paid_tier = _tier_for_hours(attended_hours)
                unit_hours = attended_hours
                payment_type = "DROP_IN"
            if occupied_slot_contract:
                classification = "SLOT_CONTRACT_DROP_IN"
                info_code = "10"
            else:
                info_code = "3"
        elif attended_hours > 0:
            classification = "ATTENDED"
            payable = True
            paid_tier = _tier_for_hours(min(authorized_hours, attended_hours))
            unit_hours = min(authorized_hours, attended_hours)
            payment_type = "REGULAR"
            info_code = "0"
            if occupied_slot_contract:
                classification = "SLOT_CONTRACT_REGULAR"
                payment_type = "SLOT_CONTRACT"
                info_code = "8"
            if attended_hours > authorized_hours:
                flags.append("OVER_ATTENDANCE")
        elif authorized_hours == 0:
            classification = "NO_CARE"
            payable = False
            paid_tier = None
            info_code = "0"
        else:
            classification = "ABSENCE"
            paid_tier = _tier_for_hours(authorized_hours)
            age_band = attendance_day.get("age_band")
            absence_limit = policy.get("absence_limit")
            parent_approved = attendance_day.get("absence_parent_approved")
            if authorization_id not in absence_counts:
                absence_counts[authorization_id] = _history_count(history, authorization_id, service_date, {"4", "11", "13"})
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
                    unit_hours = authorized_hours
                    payment_type = "ABSENCE"
                elif age_band == "OVER_36_MONTHS":
                    payable = not parent_approved
                    if payable:
                        unit_hours = authorized_hours
                        payment_type = "ABSENCE"
                    if parent_approved:
                        flags.append("PARENT_APPROVED_ABSENCE_NOT_PAYABLE")
                else:
                    classification = "BLOCKED"
                    payable = False
                    flags.append("AGE_BAND_UNAVAILABLE")
            elif age_band == "ZERO_TO_36_MONTHS":
                classification = "ENROLLMENT_ABSENCE"
                payable = True
                unit_hours = authorized_hours
                payment_type = "ENROLLMENT"
            elif age_band == "OVER_36_MONTHS":
                payable = False
                flags.append("ABSENCE_LIMIT_EXCEEDED")
            else:
                classification = "BLOCKED"
                payable = False
                flags.append("AGE_BAND_UNAVAILABLE")
            if occupied_slot_contract and payable:
                classification = "SLOT_CONTRACT_ABSENCE"
                payment_type = "SLOT_CONTRACT"
                info_code = "11"
            else:
                info_code = "13" if classification == "ENROLLMENT_ABSENCE" else "4"

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
            **({"child_name": attendance_day["child_name"]} if isinstance(attendance_day.get("child_name"), str) else {}),
            **({"county_id": attendance_day["county_id"]} if isinstance(attendance_day.get("county_id"), str) else {}),
            "classification": classification,
            "payable": payable,
            "unit_hours": _money(unit_hours),
            "payment_type": payment_type,
            "info_code": info_code,
            "occupied_slot_contract": occupied_slot_contract,
            "slot_contract_present": attendance_day.get("slot_contract_present") is True,
            "conditional": conditional,
            **({"forecast_basis": "SCHEDULED"} if scheduled_forecast else {}),
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
        rates[rate_key] = Decimal("0") if paid_tier == "NO_PAYMENT" else amount
    total = Decimal("0")
    conditional_total = Decimal("0")
    excluded_days = 0
    for day in attendance["days"]:
        if not day["payable"]:
            excluded_days += 1
            continue
        rate = rates.get((day["authorization_id"], day["paid_tier"]))
        if rate is None:
            rate = rates.get((day["authorization_id"], "NO_PAYMENT"))
        if rate is None:
            return _blocked(["matching_fiscal_rate"], attendance)
        unit_hours = _hours(day.get("unit_hours")) or Decimal("0")
        if day.get("occupied_slot_contract") is True:
            continue
        total += rate * unit_hours
        if day["conditional"]:
            if day.get("occupied_slot_contract") is not True:
                conditional_total += rate * unit_hours
    slot_fee, activity_fee, registration_fee, transportation_fee = _scheduled_fee_totals(
        payload,
        attendance["days"],
    )
    copay = _monthly_copay_total(payload, attendance["days"])
    scheduled_fees = slot_fee + activity_fee + registration_fee + transportation_fee
    gross_total = total + scheduled_fees
    net_total = max(gross_total - copay, Decimal("0"))
    payment_status = "CONDITIONAL" if conditional_total else "EXPECTED"
    return {
        "status": "ok",
        "rule_version": RULE_VERSION,
        "calculation_mode": payload.get("calculation_mode", "STATUS"),
        "source_readiness": "COMPLETE",
        "attendance": attendance,
        "payment": {
            "status": payment_status,
            "amount": _money(net_total),
            "gross_amount": _money(gross_total),
            "amount_at_risk": _money(conditional_total),
            "excluded_days": excluded_days,
            "slot_fee": _money(slot_fee),
            "activity_fee": _money(activity_fee),
            "registration_fee": _money(registration_fee),
            "transportation_fee": _money(transportation_fee),
            "parent_copay": _money(copay),
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