#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "analyze_attendance_transactions.py"
SPEC = importlib.util.spec_from_file_location("analyze_attendance_transactions", SCRIPT_PATH)
assert SPEC and SPEC.loader
analyze_attendance_transactions = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(analyze_attendance_transactions)

analyze = analyze_attendance_transactions.analyze
AttendanceTransactionError = analyze_attendance_transactions.AttendanceTransactionError


def _schedule(**overrides: object) -> dict:
    schedule = {
        "schedule_id": "sch-1",
        "child_name": "Ava",
        "county_id": "denver",
        "quality_tier": 3,
        "work_date": "2026-09-10",
        "schedule_type": "CCCAP_AUTHORIZED",
        "is_deleted": False,
        "denial_reason": None,
        "auth_status": "APPROVED",
        "auth_begin_date": "2026-01-01",
        "auth_end_date": "2026-12-31",
        "ci_authorization_hours": 8,
        "raw_hours": None,
        "check_in_count": 1,
        "check_out_count": 1,
    }
    schedule.update(overrides)
    return schedule


def _transaction(**overrides: object) -> dict:
    txn = {
        "transaction_id": "txn-1",
        "schedule_id": "sch-1",
        "type": 1,
        "sub_type": "CCCAP",
        "status": "PARENT_APPROVED",
        "result": 1,
        "attended_hours": 8,
        "is_historical": False,
        "entered_by": "PARENT",
    }
    txn.update(overrides)
    return txn


def _payload(schedules: list[dict], transactions: list[dict] | None = None, **overrides: object) -> dict:
    payload = {
        "service_period": {"start": "2026-09-01", "end": "2026-09-30"},
        "schedules": schedules,
        "transactions": transactions or [],
    }
    payload.update(overrides)
    return payload


class AnalyzeAttendanceTransactionsTests(unittest.TestCase):
    def test_deleted_schedule_is_excluded_entirely(self) -> None:
        result = analyze(_payload([_schedule(is_deleted=True)]))
        self.assertEqual(result["children"], [])

    def test_private_pay_schedule_type_is_skipped(self) -> None:
        result = analyze(_payload([_schedule(schedule_type="PRIVATE_PAY")]))
        self.assertEqual(result["children"], [])

    def test_schedule_outside_service_period_window_is_excluded(self) -> None:
        result = analyze(_payload([_schedule(work_date="2026-08-15")]))
        self.assertEqual(result["children"], [])

    def test_unapproved_authorization_is_care_not_offered(self) -> None:
        result = analyze(_payload([_schedule(auth_status="PENDING")]))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "CARE_NOT_OFFERED")
        self.assertEqual(day["authorized_hours"], 0.0)

    def test_auth_end_date_in_past_is_care_not_offered(self) -> None:
        result = analyze(_payload([_schedule(auth_end_date="2026-09-01")]))
        self.assertEqual(result["children"][0]["days"][0]["status"], "CARE_NOT_OFFERED")

    def test_provider_closure_is_excluded_from_child_day_table(self) -> None:
        result = analyze(_payload(
            [_schedule()],
            provider_closure_dates=["2026-09-10"],
        ))
        self.assertEqual(result["children"][0]["days"], [])
        self.assertEqual(result["counties"][0]["care_not_offered_days"], 1)
        self.assertEqual(result["children"][0]["absences_used"], 0)

    def test_holiday_is_separate_from_absence(self) -> None:
        result = analyze(_payload(
            [_schedule()],
            holiday_dates=["2026-09-10"],
        ))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "HOLIDAY")
        self.assertEqual(result["children"][0]["absences_used"], 0)
        self.assertEqual(result["counties"][0]["holiday_days"], 1)

    def test_licensed_only_drop_in_fails_closed_without_license_status(self) -> None:
        result = analyze(_payload(
            [_schedule(schedule_type="DROP_IN", ci_authorization_hours=0)],
            [_transaction(sub_type="DROP_IN", attended_hours=4)],
            county_rate_plans=[{
                "countyId": "denver",
                "dropInResponse": "LICENSED_ONLY",
                "dropInDayLimit": 5,
            }],
        ))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "NOT_PAID")
        self.assertIn("DROP_IN_LICENSE_STATUS_UNAVAILABLE", day["flags"])

    def test_blank_authorized_hours_means_not_scheduled_and_is_excluded(self) -> None:
        result = analyze(_payload([_schedule(ci_authorization_hours=None)]))
        self.assertEqual(result["children"], [])

    def test_missing_required_source_field_returns_a_blocker_not_an_attendance_fact(self) -> None:
        result = analyze(_payload([_schedule(child_name=None)]))
        self.assertEqual(result["children"], [])
        self.assertEqual(result["data_quality_blockers"], [{
            "code": "MISSING_REQUIRED_SOURCE_FIELD",
            "field": "child_name",
            "schedule_id": "sch-1",
        }])

    def test_valid_check_in_and_check_out_produce_attended_status(self) -> None:
        transactions = [
            _transaction(type=1, attended_hours=4),
            _transaction(transaction_id="txn-2", type=2, attended_hours=4),
        ]
        result = analyze(_payload([_schedule()], transactions))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "ATTENDED")
        self.assertEqual(day["attended_hours"], 8.0)

    def test_check_in_without_check_out_falls_back_to_raw_hours(self) -> None:
        result = analyze(_payload(
            [_schedule(raw_hours=6, check_in_count=1, check_out_count=0)],
            [_transaction(attended_hours=None)],
        ))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["attended_hours"], 6.0)

    def test_check_in_without_check_out_and_no_raw_hours_flags_anomaly(self) -> None:
        result = analyze(_payload(
            [_schedule(raw_hours=None, check_in_count=1, check_out_count=0)],
            [_transaction(attended_hours=None)],
        ))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["attended_hours"], 0.0)
        self.assertIn("UNPAIRED_ATTENDANCE_RECORDS", day["flags"])

    def test_denied_transaction_result_not_one_is_excluded(self) -> None:
        result = analyze(_payload([_schedule()], [_transaction(result=0)]))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "ABSENT")
        self.assertIn("INVALID_TRANSACTION_EXCLUDED", day["flags"])

    def test_transaction_linked_to_a_different_schedule_is_excluded(self) -> None:
        result = analyze(_payload([_schedule()], [_transaction(schedule_id="other-sch")]))
        self.assertEqual(result["children"][0]["days"][0]["status"], "ABSENT")

    def test_date_mismatched_transaction_is_excluded_and_flagged(self) -> None:
        result = analyze(_payload([_schedule()], [_transaction(work_date="2026-09-11")]))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "ABSENT")
        self.assertIn("DATE_MISMATCHED_TRANSACTION_EXCLUDED", day["flags"])

    def test_drop_in_check_in_and_check_out_classify_as_drop_in_with_tier(self) -> None:
        transactions = [
            _transaction(type=1, sub_type="DROP_IN", attended_hours=None),
            _transaction(transaction_id="txn-2", type=2, sub_type="DROP_IN", attended_hours=3),
        ]
        result = analyze(_payload([_schedule(schedule_type="DROP_IN")], transactions))
        day = result["children"][0]["days"][0]
        self.assertTrue(day["is_drop_in"])
        self.assertEqual(day["attended_hours"], 3.0)
        self.assertEqual(day["drop_in_tier"], "PART_TIME")

    def test_drop_in_denied_for_no_days_remaining_is_not_paid(self) -> None:
        result = analyze(_payload([_schedule(schedule_type="DROP_IN", denial_reason="NO_DROP_IN_DAYS_REMAINING")]))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "NOT_PAID")
        self.assertIn("DROP_IN_ALLOWANCE_EXHAUSTED", day["flags"])

    def test_attended_hours_are_capped_at_24_and_flagged(self) -> None:
        transactions = [_transaction(attended_hours=30)]
        result = analyze(_payload([_schedule(ci_authorization_hours=30)], transactions))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["attended_hours"], 24.0)
        self.assertIn("ATTENDED_HOURS_CAPPED_AT_24", day["flags"])

    def test_absence_within_county_limit_is_counted_separately_from_exceeded(self) -> None:
        schedules = [
            _schedule(work_date="2026-09-01"),
            _schedule(schedule_id="sch-2", work_date="2026-09-02"),
            _schedule(schedule_id="sch-3", work_date="2026-09-03"),
        ]
        result = analyze(_payload(schedules, county_rate_plans=[{"countyId": "denver", "absenceDaysTier3": 2}]))
        child = result["children"][0]
        self.assertEqual(child["absence_limit"], 2)
        self.assertEqual(child["absences_used"], 3)
        county = result["counties"][0]
        self.assertEqual(county["absences_within_limit"], 2)
        self.assertEqual(county["absences_over_limit"], 1)

    def test_over_attendance_flags_excess_hours(self) -> None:
        transactions = [_transaction(attended_hours=10)]
        result = analyze(_payload([_schedule(ci_authorization_hours=8)], transactions))
        day = result["children"][0]["days"][0]
        self.assertIn("OVER_ATTENDANCE", day["flags"])
        self.assertEqual(day["excess_hours"], 2.0)

    def test_more_than_three_over_attendance_days_flags_authorization_review(self) -> None:
        schedules = [
            _schedule(schedule_id=f"sch-{n}", work_date=f"2026-09-0{n}", ci_authorization_hours=4)
            for n in range(1, 5)
        ]
        transactions = [
            _transaction(schedule_id=f"sch-{n}", attended_hours=6) for n in range(1, 5)
        ]
        result = analyze(_payload(schedules, transactions))
        flagged_days = [day for day in result["children"][0]["days"] if "AUTHORIZATION_REVIEW_RECOMMENDED" in day["flags"]]
        self.assertEqual(len(flagged_days), 4)

    def test_pending_provider_status_flags_unconfirmed_attendance(self) -> None:
        transactions = [_transaction(status="PENDING_PROVIDER", entered_by="PROVIDER", attended_hours=8)]
        result = analyze(_payload([_schedule()], transactions))
        day = result["children"][0]["days"][0]
        self.assertIn("UNCONFIRMED_ATTENDANCE", day["flags"])
        self.assertEqual(day["status"], "ATTENDED")

    def test_majority_unconfirmed_days_flag_supervisor_review(self) -> None:
        schedules = [
            _schedule(schedule_id=f"sch-{n}", work_date=f"2026-09-0{n}") for n in range(1, 4)
        ]
        transactions = [
            _transaction(schedule_id=f"sch-{n}", status="PENDING_PROVIDER", entered_by="PROVIDER", attended_hours=8)
            for n in range(1, 3)
        ]
        result = analyze(_payload(schedules, transactions))
        self.assertIn("SUPERVISOR_REVIEW_RECOMMENDED", result["children"][0]["flags"])

    def test_drop_in_day_limit_exceeded_marks_remaining_days_not_paid(self) -> None:
        schedules = [
            _schedule(
                schedule_id=f"sch-{n}", work_date=f"2026-09-0{n}",
                schedule_type="DROP_IN",
            )
            for n in range(1, 4)
        ]
        transactions = []
        for n in range(1, 4):
            transactions.append(_transaction(schedule_id=f"sch-{n}", type=1, sub_type="DROP_IN", attended_hours=3))
            transactions.append(_transaction(
                transaction_id=f"txn-{n}-out", schedule_id=f"sch-{n}", type=2, sub_type="DROP_IN", attended_hours=None,
            ))
        result = analyze(_payload(
            schedules, transactions,
            county_rate_plans=[{"countyId": "denver", "dropInDayLimit": 2}],
        ))
        days = result["children"][0]["days"]
        self.assertEqual([day["status"] for day in days], ["DROP_IN", "DROP_IN", "NOT_PAID"])
        self.assertIn("DROP_IN_ALLOWANCE_NEARLY_EXHAUSTED", days[1]["flags"])
        self.assertIn("DROP_IN_LIMIT_EXCEEDED", days[2]["flags"])

    def test_not_authorized_sub_type_is_excluded_from_attendance(self) -> None:
        result = analyze(_payload([_schedule()], [_transaction(sub_type="CCCAP_NOT_AUTHORIZED")]))
        self.assertEqual(result["children"][0]["days"][0]["status"], "ABSENT")

    def test_historical_only_transactions_are_flagged_and_excluded(self) -> None:
        result = analyze(_payload([_schedule()], [_transaction(is_historical=True)]))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "ABSENT")

    def test_multi_restriction_flag_does_not_block_attendance(self) -> None:
        transactions = [_transaction(attended_hours=8)]
        result = analyze(_payload([_schedule(multi_restriction_flag=True)], transactions))
        day = result["children"][0]["days"][0]
        self.assertEqual(day["status"], "ATTENDED")
        self.assertIn("MULTI_RESTRICTION_REVIEW_RECOMMENDED", day["flags"])

    def test_unimplemented_rules_are_reported_for_transparency(self) -> None:
        result = analyze(_payload([_schedule()]))
        rule_groups = {rule["rule_group"] for rule in result["unimplemented_rules"]}
        self.assertIn("County - Drop-In Limits", rule_groups)
        self.assertNotIn("County - Absence", rule_groups)

    def test_missing_service_period_raises(self) -> None:
        with self.assertRaises(AttendanceTransactionError):
            analyze({"schedules": []})


if __name__ == "__main__":
    unittest.main()
