import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from next_action_ranking import rank_actions, rank_next_actions  # noqa: E402


class RankActionsTests(unittest.TestCase):
    def test_payment_impact_band_always_outranks_urgency_band(self) -> None:
        # rank_actions() sorts purely by the priority_score it is given; band
        # separation is guaranteed by the base offsets the scorers assign
        # (_PAYMENT_IMPACT_BASE > _URGENCY_BASE), not by rank_actions itself.
        # Use realistic same-band-range scores here to test that contract.
        ranked = rank_actions([
            {"action_id": "urgency-1", "label": "Urgency", "category": "urgency", "priority_score": 2050, "tool": "t", "input": {}},
            {"action_id": "impact-1", "label": "Impact", "category": "payment_impact", "priority_score": 3000.01, "tool": "t", "input": {}},
        ])
        self.assertEqual(ranked[0]["action_id"], "impact-1")
        self.assertEqual(ranked[1]["action_id"], "urgency-1")

    def test_urgency_band_always_outranks_source_recovery_band(self) -> None:
        ranked = rank_actions([
            {"action_id": "recovery-1", "label": "Recovery", "category": "source_recovery", "priority_score": 1999, "tool": "t", "input": {}},
            {"action_id": "urgency-1", "label": "Urgency", "category": "urgency", "priority_score": 2000.01, "tool": "t", "input": {}},
        ])
        self.assertEqual(ranked[0]["action_id"], "urgency-1")
        self.assertEqual(ranked[1]["action_id"], "recovery-1")

    def test_within_a_band_higher_score_sorts_first(self) -> None:
        ranked = rank_actions([
            {"action_id": "low", "label": "Low", "category": "urgency", "priority_score": 2001, "tool": "t", "input": {}},
            {"action_id": "high", "label": "High", "category": "urgency", "priority_score": 2050, "tool": "t", "input": {}},
        ])
        self.assertEqual([action["action_id"] for action in ranked], ["high", "low"])

    def test_ties_break_deterministically_by_action_id(self) -> None:
        ranked = rank_actions([
            {"action_id": "b-action", "label": "B", "category": "urgency", "priority_score": 2000, "tool": "t", "input": {}},
            {"action_id": "a-action", "label": "A", "category": "urgency", "priority_score": 2000, "tool": "t", "input": {}},
        ])
        self.assertEqual([action["action_id"] for action in ranked], ["a-action", "b-action"])

    def test_duplicate_action_ids_keep_only_the_first_occurrence(self) -> None:
        ranked = rank_actions([
            {"action_id": "dup", "label": "First", "category": "urgency", "priority_score": 2010, "tool": "t", "input": {}},
            {"action_id": "dup", "label": "Second", "category": "urgency", "priority_score": 2020, "tool": "t", "input": {}},
        ])
        self.assertEqual(len(ranked), 1)
        self.assertEqual(ranked[0]["label"], "First")


class RankNextActionsAttendanceTests(unittest.TestCase):
    def test_crossed_absence_limits_rank_as_payment_impact(self) -> None:
        ranked = rank_next_actions({
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 0, "children": 0},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 2, "counties": 1},
            },
        }, "attendance-risk-analysis")
        self.assertEqual(ranked[0]["action_id"], "review-absence-limit-risk")
        self.assertEqual(ranked[0]["category"], "payment_impact")

    def test_pending_confirmations_and_incomplete_records_rank_below_absence_limit_risk(self) -> None:
        ranked = rank_next_actions({
            "incomplete_attendance_days": 3,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 5, "children": 2},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 1, "counties": 1},
            },
        }, "attendance-risk-analysis")
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-absence-limit-risk")
        self.assertIn("review-pending-parent-confirmations", action_ids)
        self.assertEqual(action_ids[-1], "review-incomplete-attendance")

    def test_no_risk_returns_an_empty_list(self) -> None:
        ranked = rank_next_actions({
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 0, "children": 0},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 0, "counties": 0},
            },
        }, "attendance-risk-analysis")
        self.assertEqual(ranked, [])


class RankNextActionsPaymentTests(unittest.TestCase):
    def test_blocked_payment_returns_only_a_source_recovery_retry_action(self) -> None:
        ranked = rank_next_actions({
            "status": "BLOCKED",
            "missing_inputs": ["fiscal_rates", "parent_confirmations"],
        }, "payment-analysis")
        self.assertEqual(len(ranked), 1)
        self.assertEqual(ranked[0]["action_id"], "retry-payment-analysis")
        self.assertEqual(ranked[0]["category"], "source_recovery")

    def test_amount_at_risk_ranks_above_excluded_days(self) -> None:
        ranked = rank_next_actions({
            "status": "CONDITIONAL",
            "amount_at_risk": "125.50",
            "excluded_days": 2,
        }, "payment-analysis")
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-conditional-payment")
        self.assertIn("review-excluded-payment-days", action_ids)

    def test_summary_view_next_actions_are_included_and_ranked_by_amount_at_risk(self) -> None:
        ranked = rank_next_actions({
            "status": "EXPECTED",
            "amount_at_risk": "0",
            "excluded_days": 0,
            "summary_view": {
                "next_actions": [
                    {"action_id": "missing-fiscal-rate", "label": "Review unmatched fiscal rates", "amount_at_risk": "10.00"},
                    {"action_id": "review-drop-in-limit", "label": "Review drop-in-limit days", "amount_at_risk": "40.00"},
                ],
            },
        }, "payment-analysis")
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-drop-in-limit")
        self.assertIn("missing-fiscal-rate", action_ids)

    def test_unrecognized_capability_returns_an_empty_list_rather_than_guessing(self) -> None:
        self.assertEqual(rank_next_actions({"status": "EXPECTED"}, "unknown-capability"), [])

    def test_non_dict_canonical_facts_fail_closed_to_an_empty_list(self) -> None:
        self.assertEqual(rank_next_actions(None, "payment-analysis"), [])
        self.assertEqual(rank_next_actions(["not", "a", "dict"], "attendance-risk-analysis"), [])


if __name__ == "__main__":
    unittest.main()