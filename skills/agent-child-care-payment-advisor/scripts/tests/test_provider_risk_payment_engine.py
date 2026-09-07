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
        self.assertEqual(result["rule_version"], "provider-risk-payment-v1")
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
        self.assertEqual(result["payment"]["amount"], "45.00")
        self.assertEqual(result["payment"]["amount_at_risk"], "45.00")
        self.assertEqual(result["attendance"]["county_counts"][0]["conditional_days"], 1)

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

    def test_parent_approved_over_36_absence_is_not_payable(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0].update({
            "attended_hours": 0,
            "absence_parent_approved": True,
        })

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        day = result["attendance"]["days"][0]
        self.assertEqual(day["classification"], "ABSENCE")
        self.assertFalse(day["payable"])
        self.assertIn("PARENT_APPROVED_ABSENCE_NOT_PAYABLE", day["flags"])
        self.assertEqual(result["payment"]["amount"], "0.00")

    def test_missing_absence_approval_blocks_payment_conclusion(self) -> None:
        payload = self._complete_input()
        payload["attendance_days"][0]["attended_hours"] = 0
        del payload["attendance_days"][0]["absence_parent_approved"]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertIn("complete_attendance_inputs", result["payment"]["missing_inputs"])
        self.assertNotIn("amount", result["payment"])

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

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["attendance"]["days"][0]["classification"], "SLOT_CONTRACT_HOLIDAY")
        self.assertEqual(result["payment"]["amount"], "45.00")

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

    def test_nonmatching_rate_blocks_payment_conclusion(self) -> None:
        payload = self._complete_input()
        payload["fiscal_rates"][0]["paid_tier"] = "FULL_TIME"

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["status"], "blocked")
        self.assertIn("matching_fiscal_rate", result["payment"]["missing_inputs"])

    def test_paid_payment_returns_duplicate_guard(self) -> None:
        payload = self._complete_input()
        payload["existing_sub_payments"] = [{
            "authorization_id": "auth-1",
            "service_period_id": "period-1",
            "status": "PAID",
        }]

        result = provider_risk_payment_engine.evaluate_provider_risk_and_payment(payload)

        self.assertEqual(result["payment"]["status"], "DUPLICATE_GUARD")

    @staticmethod
    def _complete_input() -> dict:
        return {
            "rule_version": "provider-risk-payment-v1",
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
                "amount": "45.00",
            }],
            "existing_sub_payments": [],
        }


if __name__ == "__main__":
    unittest.main()