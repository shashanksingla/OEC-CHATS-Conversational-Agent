#!/usr/bin/env python3

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "provider_risk_payment_engine.py"
SPEC = importlib.util.spec_from_file_location("provider_risk_payment_engine", SCRIPT_PATH)
assert SPEC and SPEC.loader
provider_risk_payment_engine = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(provider_risk_payment_engine)


class ProviderRiskPaymentEngineTests(unittest.TestCase):
    def test_complete_canonical_input_returns_rule_traceable_payment(self) -> None:
        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(
            self._complete_input()
        )

        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["rule_version"], "provider-risk-payment-v3")
        self.assertEqual(result["attendance"]["days"][0]["classification"], "ATTENDED")
        self.assertEqual(result["attendance"]["days"][0]["paid_tier"], "PART_TIME")
        self.assertEqual(result["payment"]["status"], "EXPECTED")
        self.assertEqual(result["payment"]["amount"], "45.00")

    def test_over_36_tier_uses_lower_of_authorized_and_attended_hours(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["authorized_hours"] = 5
        payload["attendance_days"][0]["attended_hours"] = 8

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["paid_tier"], "PART_TIME")
        self.assertIn("OVER_ATTENDANCE", day["flags"])

    def test_missing_live_payment_inputs_returns_blocked_without_amount(self) -> None:
        payload = self._complete_input()
        del payload["fiscal_rates"]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["payment"]["status"], "BLOCKED")
        self.assertNotIn("amount", result["payment"])
        self.assertIn("fiscal_rates", result["payment"]["missing_inputs"])

    def test_existing_requested_or_paid_payment_returns_duplicate_guard(self) -> None:
        payload = self._complete_input()
        payload["existing_sub_payments"] = [{
            "authorization_id": "auth-1",
            "service_period_id": "period-1",
            "status": "REQUESTED",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["status"], "DUPLICATE_GUARD")
        self.assertNotIn("amount", result["payment"])

    def test_pending_confirmation_returns_conditional_amount_and_count(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["parent_confirmation"] = "PENDING"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["status"], "CONDITIONAL")
        self.assertEqual(result["payment"]["amount"], "0.00")
        self.assertEqual(result["payment"]["gross_amount"], "0.00")
        self.assertEqual(result["payment"]["amount_at_risk"], "45.00")
        self.assertEqual(result["attendance"]["county_counts"][0]["conditional_days"], 1)

    def test_attendance_basis_totals_sum_actual_and_scheduled_hours(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["attendance_basis"] = "ACTUAL"
        payload["attendance_days"].append({
            **payload["attendance_days"][0],
            "service_date": "2026-09-03",
            "attended_hours": 0,
            "attendance_basis": "SCHEDULED",
            "forecast_basis": "SCHEDULED",
            "parent_confirmation": "PENDING",
        })
        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)
        self.assertEqual(result["attendance"]["actual_hours_total"], "5.00")
        self.assertEqual(result["attendance"]["scheduled_hours_total"], "5.00")
        self.assertEqual(result["attendance"]["days"][0]["attendance_basis"], "ACTUAL")
        self.assertEqual(result["attendance"]["days"][1]["attendance_basis"], "SCHEDULED")

    def test_current_week_forecast_projects_future_scheduled_day_as_conditional(self) -> None:
        payload = self._complete_input()
        payload["calculation_mode"] = "CURRENT_WEEK_FORECAST"
        payload["attendance_days"].append({
            **payload["attendance_days"][0],
            "service_date": "2026-09-09",
            "attended_hours": 0,
            "parent_confirmation": "PENDING",
            "forecast_basis": "SCHEDULED",
            "child_name": "Taylor Example",
            "county_id": "denver",
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["calculation_mode"], "CURRENT_WEEK_FORECAST")
        self.assertEqual(result["payment"]["status"], "CONDITIONAL")
        self.assertEqual(result["payment"]["amount"], "45.00")
        self.assertEqual(result["payment"]["gross_amount"], "45.00")
        self.assertEqual(result["payment"]["amount_at_risk"], "45.00")
        future_day = result["attendance"]["days"][1]
        self.assertEqual(future_day["classification"], "SCHEDULED_FORECAST")
        self.assertEqual(future_day["child_name"], "Taylor Example")

    def test_over_36_absence_over_limit_is_excluded_after_limit(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"] = [
            {
                **payload["attendance_days"][0],
                "service_date": f"2026-09-0{day}",
                "attended_hours": 0,
            }
            for day in range(1, 4)
        ]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["amount"], "90.00")
        self.assertEqual(result["payment"]["excluded_days"], 1)
        self.assertIn("ABSENCE_LIMIT_EXCEEDED", result["attendance"]["days"][2]["flags"])

    def test_absence_parent_approved_field_no_longer_gates_payability(self) -> None:
        # v3 redesign: absence determination is holiday-list + confirmation-
        # window driven, not gated by absence_parent_approved/age-band. The
        # field may still be present on input but must have no effect.
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "attended_hours": 0,
            "absence_parent_approved": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ABSENCE")
        self.assertTrue(day["payable"])
        self.assertNotIn("PARENT_APPROVED_ABSENCE_NOT_PAYABLE", day["flags"])
        self.assertEqual(result["payment"]["amount"], "45.00")

    def test_missing_absence_approval_field_no_longer_blocks_absence(self) -> None:
        # v3 redesign: absence_parent_approved is no longer read at all, so
        # its absence must not block classification/payability.
        payload = self._complete_input()
        payload["attendance_days"][0]["attended_hours"] = 0
        del payload["attendance_days"][0]["absence_parent_approved"]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "ok")
        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ABSENCE")
        self.assertTrue(day["payable"])
        self.assertEqual(result["payment"]["amount"], "45.00")

    def test_cli_emits_structured_json(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            input_path = Path(directory) / "payment.json"
            input_path.write_text(json.dumps(self._complete_input()), encoding="utf-8")

            completed = subprocess.run(
                [sys.executable, str(SCRIPT_PATH), str(input_path)],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(completed.returncode, 0)
        output = json.loads(completed.stdout)
        self.assertEqual(output["status"], "ok")
        self.assertEqual(output["result"]["payment"]["amount"], "45.00")

    def test_enrollment_absence_uses_override_only_after_absence_cap(self) -> None:
        payload = self._complete_input()
        payload["county_policies"][0]["absence_limit"] = 1
        payload["attendance_days"] = [
            {
                **payload["attendance_days"][0],
                "service_date": f"2026-09-0{day}",
                "attended_hours": 0,
                "age_band": "ZERO_TO_36_MONTHS",
                "absence_parent_approved": True,
            }
            for day in range(1, 3)
        ]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["classification"], "ABSENCE")
        self.assertEqual(result["attendance"]["days"][1]["classification"], "ENROLLMENT_ABSENCE")
        self.assertEqual(result["payment"]["amount"], "90.00")

    def test_care_not_offered_has_no_payment(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["care_not_offered"] = True

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "CARE_NOT_OFFERED")
        self.assertFalse(day["payable"])
        self.assertEqual(result["payment"]["amount"], "0.00")

    def test_closed_facility_zero_hour_day_is_omitted_from_payment_counts(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"].append({
            **payload["attendance_days"][0],
            "service_date": "2026-09-02",
            "authorized_hours": 0,
            "attended_hours": 0,
            "care_not_offered": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        overview = result["payment"]["summary_view"]["overview"]
        self.assertEqual(overview["paid_days"], 1)
        self.assertEqual(overview["excluded_days"], 0)
        self.assertIn(
            "2026-09-02",
            [day["service_date"] for day in result["attendance"]["days"]],
        )

    def test_provider_closure_with_zero_authorized_hours_does_not_pay_drop_in(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "authorized_hours": 0,
            "attended_hours": 4,
            "care_not_offered": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "CARE_NOT_OFFERED")
        self.assertFalse(day["payable"])
        self.assertEqual(result["payment"]["amount"], "0.00")

    def test_eligible_enrollment_absence_remains_payable(self) -> None:
        payload = self._complete_input()
        payload["county_policies"][0]["absence_limit"] = 0
        payload["attendance_days"][0].update({
            "attended_hours": 0,
            "age_band": "ZERO_TO_36_MONTHS",
            "absence_parent_approved": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["classification"], "ENROLLMENT_ABSENCE")
        self.assertEqual(result["payment"]["amount"], "45.00")

    def test_observed_holiday_with_occupied_slot_is_slot_contract_holiday(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "observed_holiday": True,
            "occupied_slot_contract": True,
            "attended_hours": 0,
        })
        # v3 redesign: classification requires a match against this county's
        # specific paid-holiday list, not the generic observed_holiday flag.
        payload["county_policies"][0]["allow_paid_holidays"] = True
        payload["county_policies"][0]["county_holiday_list"] = ["2026-09-02"]
        payload["fee_schedules"] = [{
            "authorization_id": "auth-1",
            "effective_start": "2026-09-01",
            "slot_rate_amount": "9.00",
            "days_of_month": 5,
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["classification"], "HOLIDAY")
        self.assertEqual(result["payment"]["amount"], "45.00")

    def test_holiday_with_zero_authorized_hours_uses_drop_in_rules(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "authorized_hours": 0,
            "attended_hours": 4,
            "observed_holiday": True,
        })
        payload["county_policies"][0]["max_drop_in_days_per_month"] = 1

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "DROP_IN")
        self.assertTrue(day["payable"])
        self.assertEqual(day["unit_hours"], "4.00")
        self.assertEqual(result["payment"]["amount"], "36.00")

    def test_attended_holiday_is_regular_and_uses_minimum_hours(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "authorized_hours": 8,
            "attended_hours": 4,
            "observed_holiday": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ATTENDED")
        self.assertEqual(day["payment_type"], "REGULAR")
        self.assertEqual(day["unit_hours"], "4.00")
        self.assertEqual(result["payment"]["amount"], "36.00")

    def test_observed_holiday_falls_to_absence_when_actual_date_was_paid(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "authorized_hours": 5,
            "attended_hours": 0,
            "observed_holiday": True,
            "holiday_date": "2026-09-01",
            "observed_holiday_date": "2026-09-02",
            "absence_parent_approved": False,
        })
        payload["fee_history"] = [{
            "authorization_id": "auth-1",
            "service_date": "2026-09-01",
            "info_code": "1",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ABSENCE")
        self.assertEqual(day["info_code"], "4")
        self.assertTrue(day["payable"])
        self.assertIn("HOLIDAY_ALREADY_PAID_ON_PAIRED_DATE", day["flags"])

    def test_attendance_ignores_occupied_slot_and_vacant_slot_is_separate(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["slot_contract_present"] = True
        payload["attendance_days"][0].update({
            "slot_contract_present": True,
            "occupied_slot_contract": True,
        })
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-01",
            "slot_rate_amount": "6.00",
            "days_of_month": 1,
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)
        self.assertEqual(result["payment"]["amount"], "51.00")
        self.assertEqual(result["payment"]["vacant_slot_fee"], "6.00")

        payload["attendance_days"][0]["occupied_slot_contract"] = False
        vacant = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)
        self.assertEqual(vacant["payment"]["amount"], "51.00")

    def test_occupied_slot_regular_day_uses_regular_code_and_copay(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["occupied_slot_contract"] = True
        payload["authorization_copays"] = [{
            "authorization_id": "auth-1",
            "amount": "12.00",
            "effective_start": "2026-09-01",
            "effective_end": "2026-09-30",
        }]
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-01",
            "slot_rate_amount": "6.00",
            "days_of_month": 1,
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ATTENDED")
        self.assertEqual(day["info_code"], "0")
        self.assertEqual(result["payment"]["parent_copay"], "12.00")
        self.assertEqual(result["payment"]["amount"], "39.00")

    def test_date_not_on_county_holiday_list_falls_through_to_absence(self) -> None:
        # v3 redesign: classification matches the county-specific holiday
        # list directly; a date absent from that list is never classified
        # HOLIDAY (no "holiday-but-unpayable" state) - it falls straight
        # through to Absence.
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "observed_holiday": True,
            "attended_hours": 0,
        })
        payload["county_policies"][0]["allow_paid_holidays"] = True
        payload["county_policies"][0]["county_holiday_list"] = "2026-12-25"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ABSENCE")
        self.assertTrue(day["payable"])

    def test_holiday_can_match_county_plan_by_name_or_either_date(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "observed_holiday": True,
            "attended_hours": 0,
            "holiday_name": "Labor Day",
            "holiday_date": "2026-08-31",
            "observed_holiday_date": "2026-09-01",
        })
        payload["county_policies"][0]["allow_paid_holidays"] = True
        payload["county_policies"][0]["county_holiday_list"] = ["Labor Day"]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "HOLIDAY")
        self.assertTrue(day["payable"])

    def test_missing_confirmation_source_blocks_payment_conclusion(self) -> None:
        payload = self._complete_input()
        del payload["attendance_days"][0]["parent_confirmation"]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["payment"]["status"], "BLOCKED")
        self.assertNotIn("amount", result["payment"])

    def test_out_of_period_attendance_blocks_payment_conclusion(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["service_date"] = "2026-10-01"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertIn("service_period_dates", result["payment"]["missing_inputs"])

    def test_reversed_service_period_blocks_payment_conclusion(self) -> None:
        payload = self._complete_input()
        payload["service_period"]["end_date"] = "2026-08-31"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertIn("service_period_dates", result["payment"]["missing_inputs"])

    def test_nonmatching_rate_excludes_authorization_from_payment_conclusion(self) -> None:
        payload = self._complete_input()
        payload["fiscal_rates"][0]["paid_tier"] = "FULL_TIME"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["payment"]["amount"], "0.00")
        self.assertEqual(result["payment"]["excluded_authorizations"], 1)
        self.assertEqual(result["payment"]["excluded_days"], 1)

    def test_missing_authorization_rate_is_excluded_while_other_authorizations_calculate(self) -> None:
        payload = self._complete_input()
        payload["authorizations"].append({
            "id": "auth-2",
            "child_id": "child-2",
            "county_id": "denver",
            "quality_tier": 3,
        })
        payload["attendance_days"].append({
            **payload["attendance_days"][0],
            "authorization_id": "auth-2",
            "child_name": "Excluded Child",
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["payment"]["amount"], "45.00")
        self.assertEqual(result["payment"]["excluded_authorizations"], 1)
        self.assertEqual(result["payment"]["excluded_days"], 1)
        self.assertTrue(result["attendance"]["days"][1]["payment_excluded"])
        self.assertIn("FISCAL_RATE_UNAVAILABLE", result["attendance"]["days"][1]["flags"])

    def test_payment_summary_groups_actual_and_scheduled_rows(self) -> None:
        payload = self._complete_input()
        payload["calculation_mode"] = "CURRENT_WEEK_FORECAST"
        payload["attendance_days"].append({
            **payload["attendance_days"][0],
            "service_date": "2026-09-03",
            "attended_hours": 0,
            "parent_confirmation": "PENDING",
            "forecast_basis": "SCHEDULED",
            "child_name": "Taylor Example",
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        summary = result["payment"]["summary"]
        self.assertEqual(len(summary), 2)
        self.assertEqual(summary[0]["basis"], "ACTUAL")
        self.assertEqual(summary[0]["children_served"], 1)
        self.assertEqual(summary[0]["hours"], "5.00")
        self.assertEqual(summary[0]["amount"], "45.00")
        self.assertEqual(summary[1]["basis"], "SCHEDULED")
        self.assertEqual(summary[1]["children_served"], 1)
        self.assertEqual(summary[1]["hours"], "5.00")
        self.assertEqual(summary[1]["conditional_amount"], "45.00")

    def test_payment_summary_view_separates_categories_children_and_vacant_slots(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["child_name"] = "Taylor Example"
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-02",
            "effective_end": "2026-09-02",
            "slot_rate_amount": "6.00",
            "days_of_month": 1,
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)
        view = result["payment"]["summary_view"]

        self.assertEqual(view["overview"]["paid_days"], 1)
        self.assertEqual(view["categories"][0]["label"], "Regular care")
        self.assertEqual(view["counties"][0]["label"], "Unavailable from the current source")
        self.assertEqual(view["children"][0]["label"], "Taylor Example")
        self.assertEqual(len(view["vacant_slots"]), 1)
        self.assertEqual(view["vacant_slots"][0]["classification"], "VACANT_SLOT")

    def test_paid_payment_returns_duplicate_guard(self) -> None:
        payload = self._complete_input()
        payload["existing_sub_payments"] = [{
            "authorization_id": "auth-1",
            "service_period_id": "period-1",
            "status": "PAID",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["status"], "DUPLICATE_GUARD")

    def test_no_payment_care_unit_produces_zero_base_amount(self) -> None:
        payload = self._complete_input()
        payload["fiscal_rates"][0]["paid_tier"] = "NO_PAYMENT"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["amount"], "0.00")

    def test_monthly_copay_is_deducted_once_per_authorization_month(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"].append({**payload["attendance_days"][0], "service_date": "2026-09-03"})
        payload["authorization_copays"] = [{
            "authorization_id": "auth-1",
            "amount": "12.00",
            "effective_start": "2026-09-01",
            "effective_end": "2026-09-30",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["gross_amount"], "90.00")
        self.assertEqual(result["payment"]["parent_copay"], "12.00")
        self.assertEqual(result["payment"]["amount"], "78.00")

    def test_scheduled_fees_are_offset_by_payment_detail_history(self) -> None:
        payload = self._complete_input()
        payload["fee_schedules"] = [{
            "authorization_id": "auth-1",
            "effective_start": "2026-09-01",
            "activity_amount": "10.00",
            "activity_frequency": "MTH",
        }]
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-01",
            "slot_rate_amount": "4.00",
            "days_of_month": 5,
            "days_of_week": "Wednesday",
        }]
        payload["fee_history"] = [{
            "authorization_id": "auth-1",
            "service_date": "2026-09-01",
            "slot_paid": "4.00",
            "activity_paid": "3.00",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["slot_fee"], "20.00")
        self.assertEqual(result["payment"]["activity_fee"], "7.00")
        self.assertEqual(result["payment"]["amount"], "72.00")

    def test_paid_hours_are_multiplied_by_the_fiscal_rate(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["authorized_hours"] = 4
        payload["attendance_days"][0]["attended_hours"] = 3
        payload["fiscal_rates"][0]["amount"] = "10.00"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["unit_hours"], "3.00")
        self.assertEqual(result["payment"]["amount"], "30.00")

    def test_history_absence_codes_are_counted_before_current_absence(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["attended_hours"] = 0
        payload["county_policies"][0]["absence_limit"] = 1
        payload["fee_history"] = [{
            "authorization_id": "auth-1",
            "service_date": "2026-09-01",
            "info_code": "4",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["classification"], "ABSENCE")
        self.assertFalse(result["attendance"]["days"][0]["payable"])
        self.assertIn("ABSENCE_LIMIT_EXCEEDED", result["attendance"]["days"][0]["flags"])

    def test_drop_in_uses_actual_hours_and_drop_in_history_limit(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "authorized_hours": 0,
            "attended_hours": 4,
        })
        payload["authorizations"][0]["drop_in_limit"] = 1
        payload["fee_history"] = [{
            "authorization_id": "auth-1",
            "service_date": "2026-09-01",
            "info_code": "3",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "DROP_IN")
        self.assertFalse(day["payable"])
        self.assertIn("DROP_IN_LIMIT_EXCEEDED", day["flags"])
        self.assertEqual(result["payment"]["amount_at_risk"], "36.00")

    def test_slot_weekday_names_and_monthly_capacity_limit_slot_fee(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"] = [
            {**payload["attendance_days"][0], "service_date": "2026-09-02", "slot_contract_present": True, "occupied_slot_contract": False},
            {**payload["attendance_days"][0], "service_date": "2026-09-03", "slot_contract_present": True, "occupied_slot_contract": False},
        ]
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-01",
            "slot_rate_amount": "4.00",
            "days_of_month": 1,
            "days_of_week": "Monday,Wednesday",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["slot_fee"], "4.00")

    def test_slot_fee_respects_weekday_and_effective_date_constraints(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"] = [
            {**payload["attendance_days"][0], "service_date": "2026-09-02", "slot_contract_present": True},
            {**payload["attendance_days"][0], "service_date": "2026-09-09", "slot_contract_present": True},
        ]
        payload["vacant_slot_schedules"] = [{
            "slot_contract_id": "slot-1",
            "county_id": "county-1",
            "effective_start": "2026-09-05",
            "effective_end": "2026-09-30",
            "slot_rate_amount": "4.00",
            "days_of_month": 1,
            "days_of_week": "Monday,Wednesday",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["slot_fee"], "4.00")

    def test_deleted_history_does_not_consume_absence_limit(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["attended_hours"] = 0
        payload["county_policies"][0]["absence_limit"] = 1
        payload["fee_history"] = [{
            "authorization_id": "auth-1",
            "service_date": "2026-09-01",
            "info_code": "4",
            "deleted": True,
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertTrue(result["attendance"]["days"][0]["payable"])

    def test_child_payment_impacts_are_dollar_accurate_and_deterministically_rankable(self) -> None:
        payload = self._complete_input()
        payload["authorizations"].append({
            "id": "auth-2",
            "child_id": "child-2",
            "county_id": "denver",
            "quality_tier": 3,
        })
        payload["attendance_days"][0]["child_name"] = "Lower exposure"
        payload["attendance_days"].append({
            "authorization_id": "auth-2",
            "service_date": "2026-09-03",
            "authorized_hours": 3,
            "attended_hours": 3,
            "parent_confirmation": "CONFIRMED",
            "absence_parent_approved": False,
            "age_band": "OVER_36_MONTHS",
            "child_name": "Higher exposure",
            "county_id": "denver",
        })
        payload["fiscal_rates"].append({
            "authorization_id": "auth-2",
            "paid_tier": "PART_TIME",
            "amount": "12.00",
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        impacts = result["child_payment_impacts"]
        ranked = sorted(
            impacts,
            key=lambda row: (-float(row["amount_at_risk"]), -float(row["total_amount"]), row["child_name"]),
        )
        self.assertEqual([row["child_name"] for row in ranked], ["Lower exposure", "Higher exposure"])
        amounts = {row["child_name"]: row for row in impacts}
        self.assertEqual(amounts["Lower exposure"]["total_amount"], "45.00")
        self.assertEqual(amounts["Higher exposure"]["total_amount"], "36.00")
        self.assertEqual(
            [row["total_amount"] for row in ranked],
            ["45.00", "36.00"],
        )

    @staticmethod
    def _complete_input() -> dict:
        return {
            "rule_version": "provider-risk-payment-v3",
            "as_of_date": "2026-09-30",
            "service_period": {
                "id": "period-1",
                "start_date": "2026-09-01",
                "end_date": "2026-09-30",
            },
            "authorizations": [{
                "id": "auth-1",
                "child_id": "child-1",
                "county_id": "denver",
                "quality_tier": 3,
            }],
            "attendance_days": [{
                "authorization_id": "auth-1",
                "service_date": "2026-09-02",
                "authorized_hours": 5,
                "attended_hours": 5,
                "parent_confirmation": "CONFIRMED",
                "absence_parent_approved": False,
                "age_band": "OVER_36_MONTHS",
            }],
            "county_policies": [{
                "county_id": "denver",
                "quality_tier": 3,
                "absence_limit": 2,
            }],
            "fiscal_rates": [{
                "authorization_id": "auth-1",
                "paid_tier": "PART_TIME",
                "amount": "9.00",
            }],
            "existing_sub_payments": [],
        }


if __name__ == "__main__":
    unittest.main()