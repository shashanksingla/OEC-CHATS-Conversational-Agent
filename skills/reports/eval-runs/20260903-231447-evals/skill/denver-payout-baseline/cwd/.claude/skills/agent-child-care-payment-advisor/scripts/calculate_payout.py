#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

import argparse
import json
import sys
from datetime import date
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path
from typing import Any


CURRENCY_QUANTUM = Decimal("0.01")


class PaymentCaseError(ValueError):
    pass


def _non_negative_integer(container: dict[str, Any], field: str) -> int:
    value = container.get(field)
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise PaymentCaseError(f"{field} must be a non-negative integer")
    return value


def _non_negative_decimal(container: dict[str, Any], field: str) -> Decimal:
    try:
        value = Decimal(str(container[field]))
    except (KeyError, InvalidOperation):
        raise PaymentCaseError(f"{field} must be a decimal value") from None
    if not value.is_finite() or value < 0:
        raise PaymentCaseError(f"{field} must be a non-negative finite decimal")
    return value


def _date_value(container: dict[str, Any], field: str) -> date:
    value = container.get(field)
    if not isinstance(value, str):
        raise PaymentCaseError(f"{field} must be an ISO date")
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise PaymentCaseError(f"{field} must be an ISO date") from None


def calculate(payment_case: dict[str, Any]) -> dict[str, Any]:
    try:
        service_period = payment_case["service_period"]
        rate_plan = payment_case["rate_plan"]
        parent_confirmation = payment_case["parent_confirmation"]
    except KeyError as error:
        raise PaymentCaseError(f"missing required object: {error.args[0]}") from None
    if not all(
        isinstance(value, dict)
        for value in (service_period, rate_plan, parent_confirmation)
    ):
        raise PaymentCaseError(
            "service_period, rate_plan, and parent_confirmation must be objects"
        )

    authorized_days = _non_negative_integer(service_period, "authorized_days")
    attended_days = _non_negative_integer(service_period, "attended_days")
    absence_days = _non_negative_integer(service_period, "absence_days")
    absence_limit = _non_negative_integer(rate_plan, "reimbursable_absence_limit")
    daily_rate = _non_negative_decimal(rate_plan, "daily_rate")
    daily_parent_copay = _non_negative_decimal(rate_plan, "daily_parent_copay")
    as_of_date = _date_value(payment_case, "as_of_date")
    confirmation_deadline = _date_value(parent_confirmation, "deadline")
    confirmation_status = parent_confirmation.get("status")
    if confirmation_status not in {"CONFIRMED", "PENDING", "MISSED"}:
        raise PaymentCaseError(
            "parent_confirmation.status must be CONFIRMED, PENDING, or MISSED"
        )

    if attended_days > authorized_days:
        raise PaymentCaseError("attended_days cannot exceed authorized_days")
    if attended_days + absence_days > authorized_days:
        raise PaymentCaseError(
            "attended_days plus absence_days cannot exceed authorized_days"
        )
    if daily_parent_copay > daily_rate:
        raise PaymentCaseError("daily_parent_copay cannot exceed daily_rate")

    reimbursable_absence_days = min(
        absence_days,
        absence_limit,
        authorized_days - attended_days,
    )
    reimbursable_days = attended_days + reimbursable_absence_days
    net_daily_rate = (daily_rate - daily_parent_copay).quantize(
        CURRENCY_QUANTUM, rounding=ROUND_HALF_UP
    )
    expected_payout = (net_daily_rate * reimbursable_days).quantize(
        CURRENCY_QUANTUM, rounding=ROUND_HALF_UP
    )
    amount_excluded = (
        net_daily_rate * (absence_days - reimbursable_absence_days)
    ).quantize(CURRENCY_QUANTUM, rounding=ROUND_HALF_UP)
    risk_codes = []
    if amount_excluded:
        risk_codes.append("ABSENCE_LIMIT_EXCEEDED")

    payment_status = "EXPECTED"
    amount_at_risk = Decimal("0.00")
    if confirmation_status == "CONFIRMED":
        confirmed_at = _date_value(parent_confirmation, "confirmed_at")
        if confirmed_at > confirmation_deadline:
            payment_status = "DISPUTED"
            amount_at_risk = expected_payout
            expected_payout = Decimal("0.00")
            risk_codes.append("PARENT_CONFIRMATION_MISSED")
    elif confirmation_status == "PENDING" and as_of_date <= confirmation_deadline:
        payment_status = "CONDITIONAL"
        amount_at_risk = expected_payout
        risk_codes.append("PARENT_CONFIRMATION_PENDING")
    else:
        payment_status = "DISPUTED"
        amount_at_risk = expected_payout
        expected_payout = Decimal("0.00")
        risk_codes.append("PARENT_CONFIRMATION_MISSED")

    result = {
        "reimbursable_attendance_days": attended_days,
        "reimbursable_absence_days": reimbursable_absence_days,
        "reimbursable_days": reimbursable_days,
        "non_reimbursable_absence_days": absence_days - reimbursable_absence_days,
        "net_daily_rate": net_daily_rate,
        "calculated_payout": net_daily_rate * reimbursable_days,
        "expected_payout": expected_payout,
        "amount_at_risk": amount_at_risk,
        "amount_excluded": amount_excluded,
        "payment_status": payment_status,
        "risk_codes": risk_codes,
    }
    if "case_id" in payment_case:
        result["case_id"] = payment_case["case_id"]
    return result


def calculate_portfolio(payment_cases: list[dict[str, Any]]) -> dict[str, Any]:
    if not isinstance(payment_cases, list):
        raise PaymentCaseError("payment_cases must be an array")
    case_results = [calculate(payment_case) for payment_case in payment_cases]
    return {
        "case_count": len(case_results),
        "risk_case_count": sum(bool(result["risk_codes"]) for result in case_results),
        "expected_payout": sum(
            (result["expected_payout"] for result in case_results), Decimal("0.00")
        ),
        "amount_at_risk": sum(
            (result["amount_at_risk"] for result in case_results), Decimal("0.00")
        ),
        "amount_excluded": sum(
            (result["amount_excluded"] for result in case_results), Decimal("0.00")
        ),
        "cases": case_results,
    }


def _json_ready(value: Any) -> Any:
    if isinstance(value, Decimal):
        return format(value, ".2f")
    if isinstance(value, dict):
        return {key: _json_ready(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_json_ready(item) for item in value]
    return value


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Calculate a payout from one normalized payment-case JSON file. "
            "All rules and rates must be supplied by approved source data."
        )
    )
    parser.add_argument("payment_case", type=Path, help="Path to payment-case JSON")
    parser.add_argument("-o", "--output", type=Path, help="Write JSON to this path")
    parser.add_argument("--verbose", action="store_true", help="Report input path")
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    if args.verbose:
        print(f"Reading {args.payment_case}", file=sys.stderr)
    try:
        payment_case = json.loads(args.payment_case.read_text(encoding="utf-8"))
        if isinstance(payment_case, dict) and "payment_cases" in payment_case:
            calculation = calculate_portfolio(payment_case["payment_cases"])
        elif isinstance(payment_case, dict):
            calculation = calculate(payment_case)
        else:
            raise PaymentCaseError("input must be a payment case object")
        result = {"status": "ok", "result": _json_ready(calculation)}
    except (OSError, json.JSONDecodeError, PaymentCaseError) as error:
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