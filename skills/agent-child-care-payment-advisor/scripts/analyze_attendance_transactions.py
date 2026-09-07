#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Transaction-level attendance analysis per attendance-transaction-rules v1.

Scope note: rules requiring cross-provider county-wide aggregation (the
county's total drop-in pool across every provider) cannot be computed from
one provider's authorized dataset and are not implemented here. See
UNIMPLEMENTED_RULES for every rule intentionally not encoded, and why.
"""

import argparse
import json
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any


class AttendanceTransactionError(ValueError):
    pass


VALID_SCHEDULE_TYPES = {"CCCAP_AUTHORIZED", "DROP_IN"}
VALID_TRANSACTION_STATUSES = {"PARENT_APPROVED", "PENDING_PROVIDER"}
PARENT_ENTERED_VALID_STATUSES = {"PENDING_PROVIDER", "PARENT_APPROVED"}
CCCAP_SUB_TYPE = "CCCAP"
DROP_IN_SUB_TYPE = "DROP_IN"
NOT_AUTHORIZED_SUB_TYPE = "CCCAP_NOT_AUTHORIZED"
NO_DROP_IN_DAYS_REMAINING = "NO_DROP_IN_DAYS_REMAINING"
CONFIRMATION_WINDOW_DAYS = 9
MAX_DAILY_HOURS = 24

# Rules intentionally not encoded. Each is a real financial rule that either
# contradicts an adjacent rule as transcribed, needs data this provider-scoped
# dataset cannot see, or needs raw fields not yet in the normalized schema.
UNIMPLEMENTED_RULES = [
    {
        "rule_group": "Authorized Hours",
        "rule": "Overnight schedules spanning midnight split hours across two calendar days.",
        "reason": "Requires provider start/end timestamps and cross-midnight day-splitting logic not yet specified; deferred pending raw timestamp field confirmation.",
    },
    {
        "rule_group": "Transaction Validity",
        "rule": "Orphan transactions with no parent schedule are matched to an authorization by date, client, and provider to create a synthetic drop-in entry.",
        "reason": "Requires an orphan-matching key and synthetic-schedule construction not yet defined; deferred pending matching-key confirmation.",
    },
    {
        "rule_group": "Drop-In Rules",
        "rule": "Orphan drop-in transactions are processed as if a schedule existed, with authorized hours forced to zero.",
        "reason": "Depends on the orphan-matching rule above, which is deferred.",
    },
    {
        "rule_group": "County - Absence",
        "rule": "36-month-old enrollment-absence exception to the county absence limit.",
        "reason": "The transcribed rule rows contradict each other on which age band is Not Payable versus a still-payable Enrollment Absence. Needs business clarification before encoding a payment-affecting age condition.",
    },
    {
        "rule_group": "County - Drop-In Limits",
        "rule": "County-wide drop-in pool exhaustion across all providers in the county.",
        "reason": "Requires the county's aggregate drop-in usage across every provider, which is outside any single provider's authorized dataset. Only a per-authorization (this facility's child+county) drop-in counter is implemented.",
    },
    {
        "rule_group": "County - Summary",
        "rule": "County-wide summary totals.",
        "reason": "Same cross-provider visibility gap as the drop-in pool rule. Only a facility-scoped, per-county summary of this provider's own children is implemented.",
    },
]


def _date_value(value: Any, field: str) -> date:
    if not isinstance(value, str):
        raise AttendanceTransactionError(f"{field} must be an ISO date")
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise AttendanceTransactionError(f"{field} must be an ISO date") from None


def _optional_date(value: Any, field: str) -> date | None:
    if value is None:
        return None
    return _date_value(value, field)


def _non_negative_number(value: Any, field: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        raise AttendanceTransactionError(f"{field} must be a non-negative number")
    return float(value)


def _is_schedule_window_valid(schedule: dict[str, Any], period_start: date, period_end: date) -> bool:
    work_date = _date_value(schedule.get("work_date"), "work_date")
    return period_start <= work_date <= period_end


def _is_care_offered(schedule: dict[str, Any], work_date: date) -> bool:
    denial_reason = schedule.get("denial_reason")
    auth_status = schedule.get("auth_status")
    auth_begin = _optional_date(schedule.get("auth_begin_date"), "auth_begin_date")
    auth_end = _optional_date(schedule.get("auth_end_date"), "auth_end_date")
    if denial_reason not in (None, NO_DROP_IN_DAYS_REMAINING):
        return False
    if auth_status != "APPROVED":
        return False
    if auth_end is not None and auth_end < work_date:
        return False
    if auth_begin is not None and auth_begin > work_date:
        return False
    return True


def _classify_transaction(transaction: dict[str, Any]) -> str:
    txn_type = transaction.get("type")
    sub_type = transaction.get("sub_type")
    if sub_type == NOT_AUTHORIZED_SUB_TYPE:
        return "EXCLUDED"
    if sub_type == CCCAP_SUB_TYPE and txn_type == 1:
        return "CHECK_IN"
    if sub_type == CCCAP_SUB_TYPE and txn_type == 2:
        return "CHECK_OUT"
    if sub_type == DROP_IN_SUB_TYPE and txn_type in (1, 3):
        return "DROP_IN_CHECK_IN"
    if sub_type == DROP_IN_SUB_TYPE and txn_type in (2, 4):
        return "DROP_IN_CHECK_OUT"
    return "EXCLUDED"


def _select_valid_transactions(
    schedule_id: str, work_date: date, transactions: list[dict[str, Any]], flags: set[str]
) -> list[dict[str, Any]]:
    linked = [txn for txn in transactions if txn.get("schedule_id") == schedule_id]
    same_day = []
    for txn in linked:
        transaction_date = txn.get("work_date")
        if transaction_date is not None and transaction_date != work_date.isoformat():
            flags.add("DATE_MISMATCHED_TRANSACTION_EXCLUDED")
            continue
        same_day.append(txn)
    non_historical = [txn for txn in same_day if not txn.get("is_historical")]
    candidates = non_historical
    if not non_historical and linked:
        # Historical/previous transactions are audit-only; none count as attendance.
        flags.add("HISTORICAL_TRANSACTIONS_ONLY")

    valid = []
    for txn in candidates:
        status = txn.get("status")
        result = txn.get("result")
        entered_by = txn.get("entered_by")
        if entered_by == "PARENT" and status not in PARENT_ENTERED_VALID_STATUSES:
            flags.add("INVALID_TRANSACTION_EXCLUDED")
            continue
        if status not in VALID_TRANSACTION_STATUSES:
            flags.add("INVALID_TRANSACTION_EXCLUDED")
            continue
        if result != 1:
            if txn.get("denial_reason") == NO_DROP_IN_DAYS_REMAINING:
                flags.add("DROP_IN_DENIED")
            else:
                flags.add("INVALID_TRANSACTION_EXCLUDED")
            continue
        classification = _classify_transaction(txn)
        if classification == "EXCLUDED":
            flags.add("INVALID_TRANSACTION_EXCLUDED")
            continue
        valid.append({**txn, "classification": classification})
    return valid


def _hours_between(start_ts: str | None, end_ts: str | None) -> float | None:
    if not start_ts or not end_ts:
        return None
    try:
        start = datetime.fromisoformat(start_ts)
        end = datetime.fromisoformat(end_ts)
    except ValueError:
        return None
    delta_hours = (end - start).total_seconds() / 3600
    if delta_hours < 0:
        return None
    return round(delta_hours)


def _compute_attended_hours(
    schedule: dict[str, Any], valid_transactions: list[dict[str, Any]], flags: set[str]
) -> float:
    is_drop_in_day = any(
        txn["classification"] in ("DROP_IN_CHECK_IN", "DROP_IN_CHECK_OUT")
        for txn in valid_transactions
    )
    relevant = [
        txn
        for txn in valid_transactions
        if (txn["classification"] in ("DROP_IN_CHECK_IN", "DROP_IN_CHECK_OUT"))
        == is_drop_in_day
    ]

    has_check_in = any(txn["classification"] in ("CHECK_IN", "DROP_IN_CHECK_IN") for txn in relevant)
    has_check_out = any(txn["classification"] in ("CHECK_OUT", "DROP_IN_CHECK_OUT") for txn in relevant)

    hours_fields = [txn.get("attended_hours") for txn in relevant if txn.get("attended_hours") is not None]
    if hours_fields:
        total = sum(_non_negative_number(value, "attended_hours") for value in hours_fields)
    elif has_check_in and not has_check_out:
        raw_hours = schedule.get("raw_hours")
        if raw_hours is None:
            flags.add("UNPAIRED_ATTENDANCE_RECORDS")
            total = 0.0
        else:
            total = _non_negative_number(raw_hours, "raw_hours")
    elif has_check_in and has_check_out:
        computed = _hours_between(schedule.get("actual_start_ts"), schedule.get("actual_end_ts"))
        if computed is None:
            flags.add("DATA_QUALITY_ATTENDED_HOURS_UNAVAILABLE")
            total = 0.0
        else:
            total = float(computed)
    elif schedule.get("attended_flag") and not relevant:
        flags.add("DATA_QUALITY_ATTENDED_FLAG_WITHOUT_TRANSACTIONS")
        total = 0.0
    else:
        total = 0.0

    if total > MAX_DAILY_HOURS:
        flags.add("ATTENDED_HOURS_CAPPED_AT_24")
        total = float(MAX_DAILY_HOURS)
    return total


def classify_drop_in_tier(attended_hours: float) -> str | None:
    if attended_hours <= 0:
        return None
    if attended_hours <= 5:
        return "PART_TIME"
    if attended_hours <= 12:
        return "FULL_TIME"
    if attended_hours <= 17:
        return "FULL_TIME_PLUS_PART_TIME"
    return "FULL_TIME_PLUS_FULL_TIME"


def _analyze_day(
    schedule: dict[str, Any],
    transactions: list[dict[str, Any]],
    period_start: date,
    period_end: date,
) -> dict[str, Any] | None:
    if schedule.get("is_deleted"):
        return None
    if schedule.get("schedule_type") not in VALID_SCHEDULE_TYPES:
        return None
    if not _is_schedule_window_valid(schedule, period_start, period_end):
        return None

    work_date = _date_value(schedule.get("work_date"), "work_date")
    flags: set[str] = set()

    if not _is_care_offered(schedule, work_date):
        return {
            "work_date": work_date.isoformat(),
            "status": "CARE_NOT_OFFERED",
            "authorized_hours": 0.0,
            "attended_hours": 0.0,
            "is_drop_in": False,
            "flags": [],
        }

    authorized_hours = schedule.get("ci_authorization_hours")
    if authorized_hours is None:
        return None
    authorized_hours = _non_negative_number(authorized_hours, "ci_authorization_hours")

    if schedule.get("multi_restriction_flag"):
        flags.add("MULTI_RESTRICTION_REVIEW_RECOMMENDED")
    if schedule.get("is_saf"):
        flags.add("SAF_TAGGED")
    if schedule.get("check_in_count") is not None and schedule.get("check_out_count") is not None:
        if schedule["check_in_count"] != schedule["check_out_count"]:
            flags.add("UNPAIRED_ATTENDANCE_RECORDS")

    schedule_id = schedule.get("schedule_id")
    valid_transactions = _select_valid_transactions(schedule_id, work_date, transactions, flags)
    is_drop_in = schedule.get("schedule_type") == "DROP_IN" or any(
        txn["classification"] in ("DROP_IN_CHECK_IN", "DROP_IN_CHECK_OUT") for txn in valid_transactions
    )

    if is_drop_in and schedule.get("denial_reason") == NO_DROP_IN_DAYS_REMAINING:
        flags.add("DROP_IN_ALLOWANCE_EXHAUSTED")
        return {
            "work_date": work_date.isoformat(),
            "status": "NOT_PAID",
            "authorized_hours": authorized_hours,
            "attended_hours": 0.0,
            "is_drop_in": True,
            "flags": sorted(flags),
        }

    attended_hours = _compute_attended_hours(schedule, valid_transactions, flags)

    if attended_hours > authorized_hours:
        excess = round(attended_hours - authorized_hours, 2)
        flags.add("OVER_ATTENDANCE")
    else:
        excess = 0.0

    if attended_hours == 0.0 and authorized_hours > 0:
        status = "ABSENT"
    elif is_drop_in:
        status = "DROP_IN"
    else:
        status = "ATTENDED"

    has_unconfirmed = any(
        txn["classification"] in ("CHECK_IN", "CHECK_OUT")
        and txn.get("status") == "PENDING_PROVIDER"
        for txn in valid_transactions
    )
    if has_unconfirmed:
        flags.add("UNCONFIRMED_ATTENDANCE")

    result: dict[str, Any] = {
        "work_date": work_date.isoformat(),
        "status": status,
        "authorized_hours": authorized_hours,
        "attended_hours": attended_hours,
        "is_drop_in": is_drop_in,
        "flags": sorted(flags),
    }
    if excess:
        result["excess_hours"] = excess
    if is_drop_in:
        result["drop_in_tier"] = classify_drop_in_tier(attended_hours)
    return result


def analyze(payload: dict[str, Any]) -> dict[str, Any]:
    schedules = payload.get("schedules")
    if not isinstance(schedules, list):
        raise AttendanceTransactionError("schedules must be an array")
    transactions = payload.get("transactions", [])
    if not isinstance(transactions, list):
        raise AttendanceTransactionError("transactions must be an array")
    service_period = payload.get("service_period")
    if not isinstance(service_period, dict):
        raise AttendanceTransactionError("service_period must be an object")
    period_start = _date_value(service_period.get("start"), "service_period.start")
    period_end = _date_value(service_period.get("end"), "service_period.end")
    county_rate_plans = payload.get("county_rate_plans", [])
    plans = {
        plan["countyId"]: plan
        for plan in county_rate_plans
        if isinstance(plan, dict) and isinstance(plan.get("countyId"), str)
    }

    grouped: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    data_quality_blockers: list[dict[str, str]] = []
    for schedule in schedules:
        if not isinstance(schedule, dict):
            raise AttendanceTransactionError("each schedule must be an object")
        schedule_id = schedule.get("schedule_id")
        source_blockers = schedule.get("data_quality_blockers")
        if isinstance(source_blockers, list) and source_blockers:
            for blocker in source_blockers:
                if isinstance(blocker, dict) and isinstance(blocker.get("code"), str):
                    data_quality_blockers.append({
                        "code": blocker["code"],
                        "field": str(blocker.get("field", "source")),
                        "schedule_id": schedule_id if isinstance(schedule_id, str) else "unavailable",
                    })
            continue
        for field in (
            "schedule_id", "child_name", "county_id", "work_date", "schedule_type",
            "auth_status", "ci_authorization_hours",
        ):
            value = schedule.get(field)
            if value is None or (isinstance(value, str) and not value):
                data_quality_blockers.append({
                    "code": "MISSING_REQUIRED_SOURCE_FIELD",
                    "field": field,
                    "schedule_id": schedule_id if isinstance(schedule_id, str) else "unavailable",
                })
                break
        else:
            child_name = schedule["child_name"]
            county_id = schedule["county_id"]
            day = _analyze_day(schedule, transactions, period_start, period_end)
            if day is not None:
                grouped[(child_name, county_id)].append((schedule, day))
            continue

    children_results = []
    counties: dict[str, dict[str, Any]] = defaultdict(lambda: {
        "scheduled_days": 0,
        "attended_days": 0,
        "absences_within_limit": 0,
        "absences_over_limit": 0,
        "drop_in_days_paid": 0,
        "drop_in_days_denied": 0,
        "unconfirmed_days": 0,
        "care_not_offered_days": 0,
    })

    for (child_name, county_id), day_entries in sorted(grouped.items(), key=lambda item: item[0]):
        day_entries.sort(key=lambda entry: entry[1]["work_date"])
        tier = day_entries[0][0].get("quality_tier")
        plan = plans.get(county_id) if county_id else None
        absence_limit = None
        if plan is not None and isinstance(tier, int):
            limit_value = plan.get(f"absenceDaysTier{tier}")
            if isinstance(limit_value, int):
                absence_limit = limit_value
        drop_in_limit = None
        if plan is not None and isinstance(plan.get("dropInDayLimit"), int):
            drop_in_limit = plan["dropInDayLimit"]

        absences_used = 0
        drop_in_days_used = 0
        over_attendance_days = 0
        unconfirmed_days = 0
        days_out = []
        for schedule, day in day_entries:
            county = counties[county_id or "UNKNOWN"]
            county["scheduled_days"] += 1
            if day["status"] == "CARE_NOT_OFFERED":
                county["care_not_offered_days"] += 1
                days_out.append(day)
                continue
            if day["status"] == "ABSENT":
                absences_used += 1
                if absence_limit is not None and absences_used > absence_limit:
                    day["flags"].append("ABSENCE_LIMIT_EXCEEDED")
                    county["absences_over_limit"] += 1
                else:
                    if absence_limit is not None and absences_used == absence_limit - 1:
                        day["flags"].append("ABSENCE_LIMIT_ONE_AWAY")
                    county["absences_within_limit"] += 1
            elif day["status"] == "NOT_PAID":
                county["drop_in_days_denied"] += 1
            else:
                county["attended_days"] += 1
                if day.get("is_drop_in"):
                    drop_in_days_used += 1
                    if drop_in_limit is not None and drop_in_days_used > drop_in_limit:
                        day["status"] = "NOT_PAID"
                        day["flags"].append("DROP_IN_LIMIT_EXCEEDED")
                        county["drop_in_days_denied"] += 1
                        county["attended_days"] -= 1
                    else:
                        county["drop_in_days_paid"] += 1
                        if drop_in_limit is not None and drop_in_days_used == drop_in_limit:
                            day["flags"].append("DROP_IN_ALLOWANCE_NEARLY_EXHAUSTED")
                if "OVER_ATTENDANCE" in day["flags"]:
                    over_attendance_days += 1
                if "UNCONFIRMED_ATTENDANCE" in day["flags"]:
                    unconfirmed_days += 1
                    county["unconfirmed_days"] += 1
            day["flags"] = sorted(set(day["flags"]))
            days_out.append(day)

        if over_attendance_days > 3:
            for day in days_out:
                if "OVER_ATTENDANCE" in day["flags"]:
                    day["flags"] = sorted(set(day["flags"]) | {"AUTHORIZATION_REVIEW_RECOMMENDED"})

        scheduled_days = len(days_out)
        if scheduled_days and unconfirmed_days > scheduled_days / 2:
            child_flags = ["SUPERVISOR_REVIEW_RECOMMENDED"]
        else:
            child_flags = []

        children_results.append({
            "child_name": child_name,
            "county_id": county_id,
            "absence_limit": absence_limit,
            "absences_used": absences_used,
            "absences_remaining": (
                max(0, absence_limit - absences_used) if absence_limit is not None else None
            ),
            "drop_in_days_used": drop_in_days_used,
            "flags": child_flags,
            "days": days_out,
        })

    county_summaries = [
        {"county_id": county_id, **summary} for county_id, summary in sorted(counties.items())
    ]

    return {
        "rule_version": "attendance-transaction-rules-v1",
        "service_period": {"start": period_start.isoformat(), "end": period_end.isoformat()},
        "children": children_results,
        "counties": county_summaries,
        "data_quality_blockers": sorted(data_quality_blockers, key=lambda blocker: (blocker["schedule_id"], blocker["field"])),
        "unimplemented_rules": UNIMPLEMENTED_RULES,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyze transaction-level attendance per attendance-transaction-rules v1."
    )
    parser.add_argument("payload", type=Path, help="Path to normalized schedules/transactions JSON")
    parser.add_argument("-o", "--output", type=Path, help="Write JSON to this path")
    args = parser.parse_args()
    try:
        payload = json.loads(args.payload.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise AttendanceTransactionError("input must be an object")
        rendered = json.dumps({"status": "ok", "result": analyze(payload)}, indent=2)
    except (OSError, json.JSONDecodeError, AttendanceTransactionError) as error:
        print(json.dumps({"status": "error", "error": str(error)}))
        return 2
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())
