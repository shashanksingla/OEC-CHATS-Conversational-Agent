#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///

import importlib.util
import unittest
from decimal import Decimal
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "calculate_payout.py"
SPEC = importlib.util.spec_from_file_location("calculate_payout", SCRIPT_PATH)
assert SPEC and SPEC.loader
calculate_payout = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(calculate_payout)


class CalculatePayoutTests(unittest.TestCase):
    def test_denver_monthly_absence_cap_example(self) -> None:
        payment_case = {
            "as_of_date": "2026-11-03",
            "service_period": {
                "authorized_days": 22,
                "attended_days": 18,
                "absence_days": 4,
            },
            "rate_plan": {
                "reimbursable_absence_limit": 3,
                "daily_rate": "65.00",
                "daily_parent_copay": "5.00",
            },
            "parent_confirmation": {
                "status": "CONFIRMED",
                "deadline": "2026-11-05",
                "confirmed_at": "2026-11-03",
            },
        }

        result = calculate_payout.calculate(payment_case)

        self.assertEqual(result["reimbursable_attendance_days"], 18)
        self.assertEqual(result["reimbursable_absence_days"], 3)
        self.assertEqual(result["reimbursable_days"], 21)
        self.assertEqual(result["non_reimbursable_absence_days"], 1)
        self.assertEqual(result["net_daily_rate"], Decimal("60.00"))
        self.assertEqual(result["expected_payout"], Decimal("1260.00"))
        self.assertEqual(result["amount_at_risk"], Decimal("0.00"))
        self.assertEqual(result["amount_excluded"], Decimal("60.00"))
        self.assertEqual(result["payment_status"], "EXPECTED")
        self.assertEqual(result["risk_codes"], ["ABSENCE_LIMIT_EXCEEDED"])
        self.assertEqual(result["source_contract"], "legacy_normalized_fixture")
        self.assertFalse(result["production_ready"])

    def test_pending_confirmation_is_conditional_before_deadline(self) -> None:
        payment_case = self._payment_case("2026-11-03", "PENDING")

        result = calculate_payout.calculate(payment_case)

        self.assertEqual(result["expected_payout"], Decimal("1260.00"))
        self.assertEqual(result["amount_at_risk"], Decimal("1260.00"))
        self.assertEqual(result["payment_status"], "CONDITIONAL")
        self.assertEqual(
            result["risk_codes"],
            ["ABSENCE_LIMIT_EXCEEDED", "PARENT_CONFIRMATION_PENDING"],
        )

    def test_missed_confirmation_deadline_excludes_payout(self) -> None:
        payment_case = self._payment_case("2026-11-06", "PENDING")

        result = calculate_payout.calculate(payment_case)

        self.assertEqual(result["calculated_payout"], Decimal("1260.00"))
        self.assertEqual(result["expected_payout"], Decimal("0.00"))
        self.assertEqual(result["amount_at_risk"], Decimal("1260.00"))
        self.assertEqual(result["payment_status"], "DISPUTED")
        self.assertEqual(
            result["risk_codes"],
            ["ABSENCE_LIMIT_EXCEEDED", "PARENT_CONFIRMATION_MISSED"],
        )

    def test_portfolio_totals_are_calculated_without_llm_arithmetic(self) -> None:
        confirmed = self._payment_case("2026-11-03", "CONFIRMED")
        confirmed["parent_confirmation"]["confirmed_at"] = "2026-11-03"
        confirmed["case_id"] = "denver-child-1"
        pending = self._payment_case("2026-11-03", "PENDING")
        pending["case_id"] = "denver-child-2"

        result = calculate_payout.calculate_portfolio([confirmed, pending])

        self.assertEqual(result["case_count"], 2)
        self.assertEqual(result["expected_payout"], Decimal("2520.00"))
        self.assertEqual(result["amount_at_risk"], Decimal("1260.00"))
        self.assertEqual(result["amount_excluded"], Decimal("120.00"))
        self.assertEqual(result["risk_case_count"], 2)

    @staticmethod
    def _payment_case(as_of_date: str, confirmation_status: str) -> dict:
        return {
            "as_of_date": as_of_date,
            "service_period": {
                "authorized_days": 22,
                "attended_days": 18,
                "absence_days": 4,
            },
            "rate_plan": {
                "reimbursable_absence_limit": 3,
                "daily_rate": "65.00",
                "daily_parent_copay": "5.00",
            },
            "parent_confirmation": {
                "status": confirmation_status,
                "deadline": "2026-11-05",
                "confirmed_at": None,
            },
        }


if __name__ == "__main__":
    unittest.main()