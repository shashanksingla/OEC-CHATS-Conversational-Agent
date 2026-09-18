#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

import argparse
import json
import sys
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path
from typing import Any

from _shared import ABSENCE_LIMIT_APPROACHING_THRESHOLD_DAYS, CONFIRMATION_WINDOW_DAYS


class AttendanceRiskError(ValueError):
    pass


def _date_value(value: Any, field: str) -> date:
    if not isinstance(value, str):
        raise AttendanceRiskError(f"{field} must be an ISO date")
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise AttendanceRiskError(f"{field} must be an ISO date") from None


def _non_negative_integer(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise AttendanceRiskError(f"{field} must be a non-negative integer")
    return value


def _optional_hours(value: Any) -> float:
    # This estimate fails soft to zero because it is not a payable amount.
    if isinstance(value, bool):
        return 0.0
    if isinstance(value, (int, float)) and value >= 0:
        return float(value)
    return 0.0


def _absence_limit(schedule: dict[str, Any], plans: dict[str, dict[str, Any]]) -> int | None:
    county_id = schedule.get("countyId")
    tier = schedule.get("qualityTier")
    if not isinstance(county_id, str) or not isinstance(tier, int):
        return None
    plan = plans.get(county_id)
    if not plan:
        return None
    return _non_negative_integer(plan.get(f"absenceDaysTier{tier}"), "absence limit")


def _optional_text(schedule: dict[str, Any], *fields: str) -> str | None:
    for field in fields:
        value = schedule.get(field)
        if isinstance(value, str) and value:
            return value
    return None


def _county_name(schedule: dict[str, Any]) -> str | None:
    county = schedule.get("Authorization__r", {}).get("County__r", {})
    if isinstance(county, dict):
        value = county.get("County_Name__c")
        if isinstance(value, str) and value:
            return value
    return _optional_text(schedule, "county_name")


def _rate_estimate(schedule: dict[str, Any]) -> float | None:
    # Best-effort fiscal-rate estimate is for payment-risk sizing only; missing values are unavailable, not zero-dollar risk.
    value = schedule.get("daily_rate_estimate")
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value <= 0:
        return None
    return float(value)


def evaluate(snapshot: dict[str, Any]) -> dict[str, Any]:
    as_of_date = _date_value(snapshot.get("as_of_date"), "as_of_date")
    schedules = snapshot.get("schedules")
    if not isinstance(schedules, list):
        raise AttendanceRiskError("schedules must be an array")
    rate_plans = snapshot.get("county_rate_plans", [])
    if not isinstance(rate_plans, list):
        raise AttendanceRiskError("county_rate_plans must be an array")
    closure_dates = snapshot.get("provider_closure_dates", [])
    holiday_dates = snapshot.get("holiday_dates", [])
    if not isinstance(closure_dates, list) or not all(isinstance(value, str) for value in closure_dates):
        raise AttendanceRiskError("provider_closure_dates must be an array of ISO dates")
    if not isinstance(holiday_dates, list) or not all(isinstance(value, str) for value in holiday_dates):
        raise AttendanceRiskError("holiday_dates must be an array of ISO dates")
    closure_date_set = {_date_value(value, "provider_closure_date") for value in closure_dates}
    holiday_date_set = {_date_value(value, "holiday_date") for value in holiday_dates}
    requested_children = snapshot.get("child_names")
    if requested_children is not None:
        if not isinstance(requested_children, list) or not all(
            isinstance(name, str) and name for name in requested_children
        ):
            raise AttendanceRiskError("child_names must be an array of names")
        requested_children = set(requested_children)
    plans = {
        plan["countyId"]: plan
        for plan in rate_plans
        if isinstance(plan, dict) and isinstance(plan.get("countyId"), str)
    }
    cutoff_date = as_of_date - timedelta(days=CONFIRMATION_WINDOW_DAYS)
    children: dict[str, dict[str, Any]] = defaultdict(
        lambda: {
            "scheduled_days": 0,
            "absence_days": 0,
            "pending_confirmation_days": 0,
            "incomplete_attendance_days": 0,
            # Scheduled hours are fail-soft because potential loss is only an estimate.
            "pending_confirmation_hours": 0.0,
            "incomplete_attendance_hours": 0.0,
            "absence_hours": 0.0,
            "absence_limit": None,
            "conflicting_absence_limits": set(),
            "counties": set(),
            "household_name": None,
            "authorization_dates": set(),
            "absence_dates": set(),
            "pending_confirmation_dates": set(),
            "incomplete_attendance_records": [],
            "authorization_names": set(),
            "absence_risk_amount_estimate": 0.0,
            "absence_risk_amount_available": False,
        }
    )
    today = {
        "scheduled_children": set(),
        "checked_in_children": set(),
    }
    excluded_closure_dates: set[str] = set()
    excluded_holiday_dates: set[str] = set()

    for schedule in schedules:
        if not isinstance(schedule, dict):
            raise AttendanceRiskError("each schedule must be an object")
        child_name = schedule.get("Contact_Name__c")
        if not isinstance(child_name, str) or not child_name:
            raise AttendanceRiskError("Contact_Name__c is required")
        if requested_children is not None and child_name not in requested_children:
            continue
        service_date = _date_value(
            schedule.get("CI_Authorization_Date__c"), "CI_Authorization_Date__c"
        )
        if service_date > as_of_date:
            continue
        check_ins = _non_negative_integer(
            schedule.get("Check_In_Count__c"), "Check_In_Count__c"
        )
        check_outs = _non_negative_integer(
            schedule.get("Check_Out_Count__c"), "Check_Out_Count__c"
        )
        if service_date in closure_date_set:
            excluded_closure_dates.add(service_date.isoformat())
            continue
        if service_date in holiday_date_set and check_ins == 0 and check_outs == 0:
            excluded_holiday_dates.add(service_date.isoformat())
            continue
        if service_date == as_of_date:
            today["scheduled_children"].add(child_name)
            if check_ins:
                today["checked_in_children"].add(child_name)
        child = children[child_name]
        child["scheduled_days"] += 1
        county = _county_name(schedule) or _optional_text(
            schedule, "countyId", "County__c", "CDE_COUNTY__c"
        )
        if county:
            child["counties"].add(county)
        household_name = _optional_text(
            schedule, "Household_Name__c", "Household__c", "Household_Name"
        )
        if household_name:
            child["household_name"] = household_name
        child["authorization_dates"].add(service_date.isoformat())
        authorization_name = _optional_text(
            schedule,
            "authorization_name",
            "Authorization_Name__c",
            "Authorization_Number__c",
            "Authorizaton_Number__c",
            "Name",
        )
        if authorization_name:
            child["authorization_names"].add(authorization_name)
        limit = _absence_limit(schedule, plans)
        if limit is not None:
            existing_limit = child["absence_limit"]
            conflicting_limits = child.setdefault("conflicting_absence_limits", set())
            if existing_limit is not None and existing_limit != limit:
                conflicting_limits.update((existing_limit, limit))
                child["absence_limit"] = None
            elif not conflicting_limits:
                child["absence_limit"] = limit

        scheduled_hours = _optional_hours(schedule.get("CI_Authorization_Hours__c"))
        if check_ins == 0 and check_outs == 0:
            if service_date <= cutoff_date:
                child["absence_days"] += 1
                child["absence_dates"].add(service_date.isoformat())
                child["absence_hours"] += scheduled_hours
                rate_estimate = _rate_estimate(schedule)
                if rate_estimate is not None:
                    child["absence_risk_amount_estimate"] += rate_estimate
                    child["absence_risk_amount_available"] = True
            else:
                child["pending_confirmation_days"] += 1
                child["pending_confirmation_dates"].add(service_date.isoformat())
                child["pending_confirmation_hours"] += scheduled_hours
        elif check_ins == 0 or check_outs == 0:
            child["incomplete_attendance_days"] += 1
            child["incomplete_attendance_hours"] += scheduled_hours
            child["incomplete_attendance_records"].append({
                "date": service_date.isoformat(),
                "missing_record": "Missing check-in" if check_ins == 0 and check_outs > 0
                else "Missing check-out" if check_ins > 0 and check_outs == 0
                else "Missing check-in and check-out",
                "care_hours_at_risk": scheduled_hours,
            })

    requested_child_names = sorted(requested_children) if requested_children is not None else []
    child_results = []
    for child_name, child in sorted(children.items()):
        risk_codes = []
        if child["absence_days"]:
            risk_codes.append("ABSENCE_AFTER_CONFIRMATION_WINDOW")
        if child["pending_confirmation_days"]:
            risk_codes.append("PARENT_CONFIRMATION_PENDING")
        if child["incomplete_attendance_days"]:
            risk_codes.append("INCOMPLETE_ATTENDANCE_RECORD")
        conflicting_limits = child.get("conflicting_absence_limits", set())
        if conflicting_limits:
            risk_codes.append("ABSENCE_LIMIT_CONFLICT")
        if (
            not conflicting_limits
            and child["absence_days"]
            and child["absence_limit"] is None
            and plans
        ):
            risk_codes.append("ABSENCE_LIMIT_UNAVAILABLE")
        elif (
            child["absence_limit"] is not None
            and child["absence_days"] > child["absence_limit"]
        ):
            risk_codes.append("ABSENCE_LIMIT_EXCEEDED")
        elif (
            child["absence_limit"] is not None
            and child["absence_days"] > 0
            and child["absence_days"] <= child["absence_limit"]
            and child["absence_limit"] - child["absence_days"] <= ABSENCE_LIMIT_APPROACHING_THRESHOLD_DAYS
        ):
            risk_codes.append("ABSENCE_LIMIT_APPROACHING")
        counties = sorted(child.pop("counties"))
        authorization_dates = sorted(child.pop("authorization_dates"))
        authorization_names = sorted(child.pop("authorization_names"))
        absence_dates = sorted(child.pop("absence_dates"))
        pending_confirmation_dates = sorted(child.pop("pending_confirmation_dates", set()))
        incomplete_attendance_records = sorted(
            child.pop("incomplete_attendance_records", []),
            key=lambda record: record["date"],
        )
        next_confirmation_deadline = None
        confirmation_days_remaining = None
        if pending_confirmation_dates:
            earliest_pending_date = date.fromisoformat(pending_confirmation_dates[0])
            deadline_date = earliest_pending_date + timedelta(days=CONFIRMATION_WINDOW_DAYS)
            next_confirmation_deadline = deadline_date.isoformat()
            # Clamp remaining days at zero because the source date can lag a viewer's local day.
            confirmation_days_remaining = max(0, (deadline_date - as_of_date).days)
        conflicting_absence_limits = sorted(child.pop("conflicting_absence_limits", set()))
        absence_risk_amount_available = child.pop("absence_risk_amount_available")
        absence_risk_amount_estimate = child.pop("absence_risk_amount_estimate")
        # Provider-facing note/potential_impact prose used to be generated here and passed
        # through to the TypeScript layer, but the audited read-sites confirmed neither
        # string's CONTENT ever reached a rendered response or structuredContent (only a
        # presence/non-empty check on potential_impact was live, and this function always
        # produced a non-empty string for every child) - so the facts below (risk_codes,
        # absence_days, absence_limit, pending_confirmation_days) are the complete contract;
        # any future provider-facing sentence is TypeScript's responsibility to render from them.
        child_results.append({
            "child_name": child_name,
            **child,
            "county": counties[0] if len(counties) == 1 else ("Multiple" if counties else None),
            "authorization_names": authorization_names,
            "authorization_dates": authorization_dates,
            "absence_dates": absence_dates,
            "pending_confirmation_dates": pending_confirmation_dates,
            "incomplete_attendance_records": incomplete_attendance_records,
            "conflicting_absence_limits": conflicting_absence_limits,
            "next_confirmation_deadline": next_confirmation_deadline,
            "confirmation_days_remaining": confirmation_days_remaining,
            "risk_codes": risk_codes,
            "risk_amount_estimate": absence_risk_amount_estimate if absence_risk_amount_available else None,
        })

    pending_children = [
        child for child in child_results if child["pending_confirmation_days"] > 0
    ]
    approaching_children = [
        child for child in child_results if "ABSENCE_LIMIT_APPROACHING" in child["risk_codes"]
    ]
    crossed_children = [
        child for child in child_results if "ABSENCE_LIMIT_EXCEEDED" in child["risk_codes"]
    ]
    county_aggregates: dict[str, dict[str, Any]] = {}
    for child in child_results:
        county = child["county"]
        if county is None:
            county = "Unavailable from the current source"
        aggregate = county_aggregates.setdefault(
            county,
            {"county": county, "children": 0, "children_over_limit_count": 0, "approved_limit": None, "conflicting_limits": False},
        )
        aggregate["children"] += 1
        if "ABSENCE_LIMIT_EXCEEDED" in child["risk_codes"]:
            aggregate["children_over_limit_count"] += 1
        # Report a county limit only when all children agree; mismatches remain explicit.
        child_limit = child.get("absence_limit")
        if child_limit is not None and not aggregate["conflicting_limits"]:
            if aggregate["approved_limit"] is None:
                aggregate["approved_limit"] = child_limit
            elif aggregate["approved_limit"] != child_limit:
                aggregate["conflicting_limits"] = True
                aggregate["approved_limit"] = None

    def county_count(children: list[dict[str, Any]]) -> int:
        return len({child["county"] for child in children if child["county"] not in (None, "Multiple")})

    def _category_risk_amount_estimate(children: list[dict[str, Any]]) -> float | None:
        # Omit the estimate when no affected child has a fiscal rate.
        available = [
            child["risk_amount_estimate"]
            for child in children
            if child["risk_amount_estimate"] is not None
        ]
        return round(sum(available), 2) if available else None

    absence_risk_codes = {
        "ABSENCE_AFTER_CONFIRMATION_WINDOW",
        "ABSENCE_LIMIT_UNAVAILABLE",
        "ABSENCE_LIMIT_EXCEEDED",
        "ABSENCE_LIMIT_APPROACHING",
        "ABSENCE_LIMIT_CONFLICT",
    }
    attendance_concern_codes = {
        "PARENT_CONFIRMATION_PENDING",
        "INCOMPLETE_ATTENDANCE_RECORD",
    }

    return {
        "as_of_date": as_of_date.isoformat(),
        "confirmation_cutoff_date": cutoff_date.isoformat(),
        "earliest_confirmation_deadline": (
            min(
                (child["next_confirmation_deadline"] for child in child_results if child["next_confirmation_deadline"]),
                default=None,
            )
        ),
        "earliest_confirmation_days_remaining": (
            min(
                (
                    child["confirmation_days_remaining"]
                    for child in child_results
                    if child["next_confirmation_deadline"] is not None
                ),
                default=None,
            )
        ),
        "today": {key: len(value) for key, value in today.items()},
        "scheduled_days": sum(child["scheduled_days"] for child in child_results),
        "absence_days": sum(
            child["absence_days"] for child in child_results
        ),
        "pending_confirmation_days": sum(
            child["pending_confirmation_days"] for child in child_results
        ),
        "incomplete_attendance_days": sum(
            child["incomplete_attendance_days"] for child in child_results
        ),
        "absence_risk_children": sum(
            bool(set(child["risk_codes"]) & absence_risk_codes)
            for child in child_results
        ),
        "attendance_concern_children": sum(
            bool(set(child["risk_codes"]) & attendance_concern_codes)
            for child in child_results
        ),
        "risk_child_count": sum(bool(child["risk_codes"]) for child in child_results),
        "risk_categories": {
            "pending_parent_confirmations": {
                "days": sum(child["pending_confirmation_days"] for child in pending_children),
                "children": len(pending_children),
                # All unresolved days remain potential loss until confirmed.
                "potential_loss_hours": round(
                    sum(child["pending_confirmation_hours"] for child in pending_children), 2,
                ),
            },
            "approaching_absence_limits": {
                "children": len(approaching_children),
                "counties": county_count(approaching_children),
                "minimum_days_until_exceeded": min(
                    (
                        child["absence_limit"] - child["absence_days"] + 1
                        for child in approaching_children
                    ),
                    default=None,
                ),
                "risk_amount_estimate": _category_risk_amount_estimate(approaching_children),
            },
            "crossed_absence_limits": {
                "children": len(crossed_children),
                "counties": county_count(crossed_children),
                # Only hours over the county limit are at risk.
                "potential_loss_hours": round(
                    sum(
                        child["absence_hours"] * (
                            (child["absence_days"] - child["absence_limit"]) / child["absence_days"]
                        )
                        for child in crossed_children
                        if child["absence_days"] > 0
                    ), 2,
                ),
                "maximum_days_over_limit": max(
                    (
                        child["absence_days"] - child["absence_limit"]
                        for child in crossed_children
                    ),
                    default=0,
                ),
                "risk_amount_estimate": _category_risk_amount_estimate(crossed_children),
            },
            "incomplete_attendance": {
                "days": sum(
                    child["incomplete_attendance_days"] for child in child_results
                ),
                "children": sum(
                    bool(child["incomplete_attendance_days"]) for child in child_results
                ),
                # All days lacking attendance records remain potential loss.
                "potential_loss_hours": round(
                    sum(
                        child["incomplete_attendance_hours"] for child in child_results
                    ), 2,
                ),
            },
        },
        "children": child_results,
        "counties": sorted(county_aggregates.values(), key=lambda county: county["county"]),
        "requested_child_names": requested_child_names,
        "unmatched_child_names": sorted(
            set(requested_child_names) - {child["child_name"] for child in child_results},
        ),
        "excluded_closure_dates": sorted(excluded_closure_dates),
        "excluded_holiday_dates": sorted(excluded_holiday_dates),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Evaluate current attendance risks from normalized schedule data."
    )
    parser.add_argument("snapshot", type=Path, help="Path to attendance snapshot JSON")
    parser.add_argument("-o", "--output", type=Path, help="Write JSON to this path")
    parser.add_argument("--verbose", action="store_true", help="Report input path")
    args = parser.parse_args()
    if args.verbose:
        print(f"Reading {args.snapshot}", file=sys.stderr)
    try:
        snapshot = json.loads(args.snapshot.read_text(encoding="utf-8"))
        if not isinstance(snapshot, dict):
            raise AttendanceRiskError("input must be an object")
        rendered = json.dumps({"status": "ok", "result": evaluate(snapshot)}, indent=2)
    except (OSError, json.JSONDecodeError, AttendanceRiskError) as error:
        print(json.dumps({"status": "error", "error": str(error)}))
        return 2
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())