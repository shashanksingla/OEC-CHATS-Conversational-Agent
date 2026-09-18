import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import next_action_ranking  # noqa: E402
from next_action_ranking import rank_actions, rank_next_actions, rank_score  # noqa: E402


class RankScoreTests(unittest.TestCase):
    def test_equal_dollars_due_sooner_rank_higher(self) -> None:
        self.assertGreater(rank_score(1000, 1), rank_score(1000, 10))

    def test_large_dollar_amount_due_later_still_wins(self) -> None:
        self.assertGreater(rank_score(10000, 10), rank_score(500, 1))

    def test_rendered_action_wording_has_no_superlative_claims(self) -> None:
        rendered = rank_next_actions(payment_facts={
            "status": "CONDITIONAL",
            "amount_at_risk": 100,
            "excluded_days": 1,
            "summary_view": {"next_actions": [{
                "action_id": "review-summary",
                "label": "Review summary",
                "amount_at_risk": 25,
            }]},
        })
        text = " ".join(
            str(value)
            for action in rendered
            for value in (action.get("label", ""), action.get("reason", ""))
        ).lower()
        self.assertNotIn("highest impact", text)
        self.assertNotIn("biggest", text)


class RankActionsTests(unittest.TestCase):
    def test_payment_impact_band_always_outranks_urgency_band(self) -> None:
        # Band separation comes from scorer base offsets, not rank_actions.
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
        ranked = rank_next_actions(attendance_facts={
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 0, "children": 0},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 2, "counties": 1},
            },
        })
        self.assertEqual(ranked[0]["action_id"], "review-absence-limit-risk")
        self.assertEqual(ranked[0]["category"], "payment_impact")

    def test_pending_confirmations_and_incomplete_records_rank_below_absence_limit_risk(self) -> None:
        ranked = rank_next_actions(attendance_facts={
            "incomplete_attendance_days": 3,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 5, "children": 2},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 1, "counties": 1},
            },
        })
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-absence-limit-risk")
        self.assertIn("review-pending-parent-confirmations", action_ids)
        self.assertIn("review-incomplete-attendance", action_ids)
        self.assertGreaterEqual(len(action_ids), 3)

    def test_large_hours_at_risk_outranks_a_tiny_dollar_absence_limit_risk(self) -> None:
        # Reproduces the chat_09_17_3.md scenario: pending confirmations (no dollar figure,
        # 561 hours at risk) must outrank absence-limit risk (a tiny $ estimate) - previously
        # pending confirmations was hardcoded to a 0.0 dollar signal and could never win.
        ranked = rank_next_actions(attendance_facts={
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 57, "children": 7, "potential_loss_hours": 561.0},
                "approaching_absence_limits": {"children": 1, "counties": 1, "risk_amount_estimate": 5.0},
                "crossed_absence_limits": {"children": 6, "counties": 1, "risk_amount_estimate": 5.0},
            },
        })
        self.assertEqual(ranked[0]["action_id"], "review-pending-parent-confirmations")

    def test_no_risk_returns_an_empty_list(self) -> None:
        ranked = rank_next_actions(attendance_facts={
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 0, "children": 0},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 0, "counties": 0},
            },
        })
        self.assertEqual(ranked, [])


class RankNextActionsPaymentTests(unittest.TestCase):
    def test_blocked_payment_returns_only_a_source_recovery_retry_action(self) -> None:
        ranked = rank_next_actions(payment_facts={
            "status": "BLOCKED",
            "missing_inputs": ["fiscal_rates", "parent_confirmations"],
        })
        self.assertEqual(len(ranked), 1)
        self.assertEqual(ranked[0]["action_id"], "retry-payment-analysis")
        self.assertEqual(ranked[0]["category"], "source_recovery")

    def test_amount_at_risk_ranks_above_excluded_days(self) -> None:
        ranked = rank_next_actions(payment_facts={
            "status": "CONDITIONAL",
            "amount_at_risk": "125.50",
            "excluded_days": 2,
        })
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-conditional-payment")
        self.assertIn("review-excluded-payment-days", action_ids)

    def test_summary_view_next_actions_are_included_and_ranked_by_amount_at_risk(self) -> None:
        ranked = rank_next_actions(payment_facts={
            "status": "EXPECTED",
            "amount_at_risk": "0",
            "excluded_days": 0,
            "summary_view": {
                "next_actions": [
                    {"action_id": "missing-fiscal-rate", "label": "Review unmatched fiscal rates", "amount_at_risk": "10.00"},
                    {"action_id": "review-drop-in-limit", "label": "Review drop-in-limit days", "amount_at_risk": "40.00"},
                ],
            },
        })
        action_ids = [action["action_id"] for action in ranked]
        self.assertEqual(action_ids[0], "review-drop-in-limit")
        self.assertIn("missing-fiscal-rate", action_ids)

    def test_neither_fact_block_returns_an_empty_list_rather_than_guessing(self) -> None:
        self.assertEqual(rank_next_actions(), [])
        self.assertEqual(rank_next_actions(attendance_facts=None, payment_facts=None), [])

    def test_non_dict_facts_fail_closed_and_are_simply_skipped(self) -> None:
        self.assertEqual(rank_next_actions(payment_facts=None), [])
        self.assertEqual(rank_next_actions(attendance_facts=["not", "a", "dict"]), [])


class RankNextActionsCrossCapabilityTests(unittest.TestCase):
    def test_both_fact_blocks_rank_candidates_from_both_capabilities_together(self) -> None:
        ranked = rank_next_actions(
            attendance_facts={
                "incomplete_attendance_days": 0,
                "risk_categories": {
                    "pending_parent_confirmations": {"days": 5, "children": 2},
                    "approaching_absence_limits": {"children": 0, "counties": 0},
                    "crossed_absence_limits": {"children": 0, "counties": 0},
                },
            },
            payment_facts={
                "status": "CONDITIONAL",
                "amount_at_risk": "500.00",
                "excluded_days": 0,
            },
        )
        action_ids = [action["action_id"] for action in ranked]
        self.assertIn("review-pending-parent-confirmations", action_ids)
        self.assertIn("review-conditional-payment", action_ids)
        # A real dollar amount at risk outranks a zero-dollar-signal pending-confirmation candidate.
        self.assertEqual(action_ids[0], "review-conditional-payment")

    def test_combined_ranking_uses_the_same_deterministic_tiebreak_as_a_single_capability(self) -> None:
        combined = rank_next_actions(
            attendance_facts={
                "incomplete_attendance_days": 0,
                "risk_categories": {
                    "pending_parent_confirmations": {"days": 0, "children": 0},
                    "approaching_absence_limits": {"children": 0, "counties": 0},
                    "crossed_absence_limits": {"children": 2, "counties": 1},
                },
            },
            payment_facts=None,
        )
        attendance_only = rank_next_actions(attendance_facts=combined and {
            "incomplete_attendance_days": 0,
            "risk_categories": {
                "pending_parent_confirmations": {"days": 0, "children": 0},
                "approaching_absence_limits": {"children": 0, "counties": 0},
                "crossed_absence_limits": {"children": 2, "counties": 1},
            },
        })
        self.assertEqual(combined, attendance_only)


if __name__ == "__main__":
    unittest.main()