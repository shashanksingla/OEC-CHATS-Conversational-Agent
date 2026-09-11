#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "evaluate_attendance_risks.py"
SPEC = importlib.util.spec_from_file_location("evaluate_attendance_risks", SCRIPT_PATH)
assert SPEC and SPEC.loader
evaluate_attendance_risks = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evaluate_attendance_risks)


class EvaluateAttendanceRisksTests(unittest.TestCase):
    def test_filters_to_requested_children_without_changing_risk_rules(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-05",
            "child_names": ["Ava"],
            "schedules": [
                {
                    "Contact_Name__c": "Ava",
                    "CI_Authorization_Date__c": "2026-09-04",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Ben",
                    "CI_Authorization_Date__c": "2026-09-04",
                    "Check_In_Count__c": 1,
                    "Check_Out_Count__c": 1,
                },
            ],
            "county_rate_plans": [],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual([child["child_name"] for child in result["children"]], ["Ava"])
        self.assertEqual(result["pending_confirmation_days"], 1)

    def test_reports_requested_children_missing_from_scope(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-05",
            "child_names": ["Missing Child"],
            "schedules": [self._schedule("Ava", "2026-09-04", 1, 1)],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["children"], [])
        self.assertEqual(result["unmatched_child_names"], ["Missing Child"])

    def test_separates_todays_operational_counts_from_month_risks(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "schedules": [
                self._schedule("Ava", "2026-09-15", check_ins=1, check_outs=0),
                self._schedule("Ben", "2026-09-15", check_ins=1, check_outs=1),
                self._schedule("Cara", "2026-09-15", check_ins=0, check_outs=0),
                self._schedule("Drew", "2026-09-05", check_ins=0, check_outs=0),
            ],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["today"], {
            "scheduled_children": 3,
            "checked_in_children": 2,
        })
        self.assertEqual(result["absence_days"], 1)
        self.assertEqual(result["absence_risk_children"], 1)
        self.assertEqual(result["attendance_concern_children"], 2)

    def test_flags_unattended_days_at_least_five_days_old_as_probable_absences(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "schedules": [
                self._schedule("Ava", "2026-09-10", check_ins=0, check_outs=0),
                self._schedule("Ava", "2026-09-12", check_ins=0, check_outs=0),
            ],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["scheduled_days"], 2)
        self.assertEqual(result["absence_days"], 1)
        self.assertEqual(result["pending_confirmation_days"], 1)
        self.assertEqual(result["children"][0]["risk_codes"], [
            "ABSENCE_AFTER_CONFIRMATION_WINDOW",
            "PARENT_CONFIRMATION_PENDING",
        ])

    def test_excludes_closures_and_unworked_holidays_from_risk_counts(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "provider_closure_dates": ["2026-09-01"],
            "holiday_dates": ["2026-09-02"],
            "schedules": [
                self._schedule("Ava", "2026-09-01", 0, 0),
                self._schedule("Ava", "2026-09-02", 0, 0),
                self._schedule("Ava", "2026-09-03", 0, 0),
            ],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["scheduled_days"], 1)
        self.assertEqual(result["absence_days"], 1)
        self.assertEqual(result["pending_confirmation_days"], 0)

    def test_applies_county_absence_limit_when_schedule_has_county_and_tier(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{
                "countyId": "denver",
                "absenceDaysTier3": 1,
            }],
            "schedules": [
                self._schedule(
                    "Ava", "2026-09-01", check_ins=0, check_outs=0,
                    county_id="denver", quality_tier=3,
                ),
                self._schedule(
                    "Ava", "2026-09-02", check_ins=0, check_outs=0,
                    county_id="denver", quality_tier=3,
                ),
            ],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["children"][0]["absence_days"], 2)
        self.assertEqual(result["children"][0]["absence_limit"], 1)
        self.assertEqual(result["children"][0]["risk_codes"], [
            "ABSENCE_AFTER_CONFIRMATION_WINDOW",
            "ABSENCE_LIMIT_EXCEEDED",
        ])

    def test_classifies_small_absence_limits_at_the_boundary(self) -> None:
        approaching = evaluate_attendance_risks.evaluate({
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{"countyId": "denver", "absenceDaysTier3": 2}],
            "schedules": [self._schedule("Ava", "2026-09-01", 0, 0, "denver", 3)],
        })
        exceeded = evaluate_attendance_risks.evaluate({
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{"countyId": "denver", "absenceDaysTier3": 1}],
            "schedules": [
                self._schedule("Ava", "2026-09-01", 0, 0, "denver", 3),
                self._schedule("Ava", "2026-09-02", 0, 0, "denver", 3),
            ],
        })

        self.assertIn("ABSENCE_LIMIT_APPROACHING", approaching["children"][0]["risk_codes"])
        self.assertNotIn("ABSENCE_LIMIT_EXCEEDED", approaching["children"][0]["risk_codes"])
        self.assertIn("ABSENCE_LIMIT_EXCEEDED", exceeded["children"][0]["risk_codes"])

    def test_isolates_conflicting_absence_limit_to_affected_child(self) -> None:
        result = evaluate_attendance_risks.evaluate({
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{
                "countyId": "denver",
                "absenceDaysTier1": 1,
                "absenceDaysTier3": 3,
            }],
            "schedules": [
                self._schedule("Ava", "2026-09-01", 0, 0, "denver", 1),
                self._schedule("Ava", "2026-09-02", 0, 0, "denver", 3),
                self._schedule("Ben", "2026-09-01", 1, 1, "denver", 1),
            ],
        })

        children = {child["child_name"]: child for child in result["children"]}
        self.assertIn("ABSENCE_LIMIT_CONFLICT", children["Ava"]["risk_codes"])
        self.assertEqual(children["Ava"]["conflicting_absence_limits"], [1, 3])
        self.assertNotIn("ABSENCE_LIMIT_CONFLICT", children["Ben"]["risk_codes"])

    def test_does_not_guess_an_absence_limit_without_county_mapping(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{
                "countyId": "denver",
                "absenceDaysTier3": 1,
            }],
            "schedules": [self._schedule("Ava", "2026-09-01", 0, 0)],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertIsNone(result["children"][0]["absence_limit"])
        self.assertEqual(result["children"][0]["risk_codes"], [
            "ABSENCE_AFTER_CONFIRMATION_WINDOW",
            "ABSENCE_LIMIT_UNAVAILABLE",
        ])

    def test_returns_three_risk_categories_and_provider_detail_fields(self) -> None:
        snapshot = {
            "as_of_date": "2026-09-15",
            "county_rate_plans": [{
                "countyId": "denver",
                "absenceDaysTier3": 2,
            }],
            "schedules": [
                {
                    "Contact_Name__c": "Ava",
                    "Household_Name__c": "Ava Household",
                    "Authorizaton_Number__c": "AUTH-AVA-1",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-01",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Ava",
                    "Household_Name__c": "Ava Household",
                    "Authorizaton_Number__c": "AUTH-AVA-1",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-02",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Ben",
                    "Household_Name__c": "Ben Household",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-14",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Cara",
                    "Household_Name__c": "Cara Household",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-01",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Cara",
                    "Household_Name__c": "Cara Household",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-02",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
                {
                    "Contact_Name__c": "Cara",
                    "Household_Name__c": "Cara Household",
                    "countyId": "denver",
                    "qualityTier": 3,
                    "CI_Authorization_Date__c": "2026-09-03",
                    "Check_In_Count__c": 0,
                    "Check_Out_Count__c": 0,
                },
            ],
        }

        result = evaluate_attendance_risks.evaluate(snapshot)

        self.assertEqual(result["risk_categories"], {
            "pending_parent_confirmations": {
                "days": 1,
                "children": 1,
                "potential_loss_hours": 0.0,
            },
            "approaching_absence_limits": {
                "children": 1,
                "counties": 1,
                "minimum_days_until_exceeded": 1,
                "risk_amount_estimate": None,
            },
            "crossed_absence_limits": {
                "children": 1,
                "counties": 1,
                "potential_loss_hours": 0.0,
                "maximum_days_over_limit": 1,
                "risk_amount_estimate": None,
            },
            "incomplete_attendance": {
                "days": 0,
                "children": 0,
                "potential_loss_hours": 0.0,
            },
        })
        ava = result["children"][0]
        self.assertEqual(ava["household_name"], "Ava Household")
        self.assertEqual(ava["county"], "denver")
        self.assertEqual(ava["authorization_dates"], ["2026-09-01", "2026-09-02"])
        self.assertEqual(ava["authorization_names"], ["AUTH-AVA-1"])
        self.assertIn("2 absence days", ava["note"])
        self.assertIn("1 more absence day", ava["potential_impact"])

    @staticmethod
    def _schedule(
        child_name: str,
        service_date: str,
        check_ins: int,
        check_outs: int,
        county_id: str | None = None,
        quality_tier: int | None = None,
    ) -> dict:
        schedule = {
            "Contact_Name__c": child_name,
            "CI_Authorization_Date__c": service_date,
            "CI_Authorization_Hours__c": 8,
            "Check_In_Count__c": check_ins,
            "Check_Out_Count__c": check_outs,
        }
        if county_id:
            schedule["countyId"] = county_id
        if quality_tier:
            schedule["qualityTier"] = quality_tier
        return schedule


if __name__ == "__main__":
    unittest.main()