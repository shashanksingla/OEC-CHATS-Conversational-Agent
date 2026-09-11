#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Deterministic next-action ranking for Provider Assist conversational responses.

This module codifies the ranking rule previously expressed only in prose in
`skills/carepay-conversation-templates/SKILL.md` ("Actions are ranked by
payment impact, then urgency and source-data recovery"). It takes the same
canonical evaluator output already produced by `evaluate_attendance_risks.py`
or `provider_risk_payment_engine.py` and returns a deterministic, numerically
scored, sorted list of next actions. It never fetches Salesforce data and
never mutates its input.
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

RULE_VERSION = "provider-next-action-ranking-v1"

URGENCY_WEIGHT = 5  # tunable - if real conversation data later suggests a different value, that's a config change, not a rewrite


def rank_score(dollar_amount_at_risk: float, days_remaining: int) -> float:
    """Hybrid dollar+urgency score.

    The urgency multiplier makes equally sized items due sooner rank higher,
    while retaining dollar magnitude as the primary signal for substantially
    different risks.
    """
    days_remaining = max(days_remaining, 1)  # avoid div-by-zero / infinite same-day weighting
    urgency_multiplier = 1 + (URGENCY_WEIGHT / days_remaining)
    return dollar_amount_at_risk * urgency_multiplier


def _amount(value: Any) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _count(value: Any) -> int:
    return value if isinstance(value, int) and not isinstance(value, bool) and value > 0 else 0


def _days_remaining(value: Any, default: int = 30) -> int:
    return value if isinstance(value, int) and not isinstance(value, bool) else default


def _action(
    action_id: str,
    label: str,
    category: str,
    priority_score: float,
    tool: str,
    input_: dict[str, Any],
) -> dict[str, Any]:
    return {
        "action_id": action_id,
        "label": label,
        "category": category,
        "priority_score": round(priority_score, 4),
        "tool": tool,
        "input": input_,
    }


def _attendance_candidates(attendance_risk: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    categories = attendance_risk.get("risk_categories")
    categories = categories if isinstance(categories, dict) else {}

    crossed = categories.get("crossed_absence_limits")
    crossed = crossed if isinstance(crossed, dict) else {}
    crossed_children = _count(crossed.get("children"))
    if crossed_children:
        # A real dollar figure (when the fiscal-rate fetch produced one) always
        # outranks a same-band action sized only by child count, since it is a
        # more accurate measure of payment impact.
        crossed_amount = _amount(crossed.get("risk_amount_estimate"))
        # No deadline field is guaranteed for this candidate; use a wide default.
        candidates.append(_action(
            "review-absence-limit-risk",
            f"Review absence-limit risk — {crossed_children} children",
            "payment_impact",
            rank_score(
                crossed_amount,
                _days_remaining(crossed.get("confirmation_days_remaining")),
            ),
            "cccap_analyze_payment_risk",
            {"riskFocus": "ABSENCE_LIMITS"},
        ))

    approaching = categories.get("approaching_absence_limits")
    approaching = approaching if isinstance(approaching, dict) else {}
    approaching_children = _count(approaching.get("children"))
    if approaching_children:
        approaching_amount = _amount(approaching.get("risk_amount_estimate"))
        # No deadline field is guaranteed for this candidate; use a wide default.
        candidates.append(_action(
            "review-approaching-absence-limit",
            f"Review approaching absence limits — {approaching_children} children",
            "urgency",
            rank_score(
                approaching_amount,
                _days_remaining(approaching.get("confirmation_days_remaining")),
            ),
            "cccap_analyze_payment_risk",
            {"riskFocus": "ABSENCE_LIMITS"},
        ))

    pending = categories.get("pending_parent_confirmations")
    pending = pending if isinstance(pending, dict) else {}
    pending_days = _count(pending.get("days"))
    if pending_days:
        candidates.append(_action(
            "review-pending-parent-confirmations",
            f"Review pending confirmations — {pending_days} days",
            "urgency",
            # No dollar signal is currently available for pending confirmations.
            rank_score(0.0, _days_remaining(pending.get("confirmation_days_remaining"))),
            "cccap_analyze_payment_risk",
            {"riskFocus": "PARENT_CONFIRMATIONS"},
        ))

    incomplete_days = _count(attendance_risk.get("incomplete_attendance_days"))
    if incomplete_days:
        candidates.append(_action(
            "review-incomplete-attendance",
            f"Review incomplete attendance — {incomplete_days} records",
            "source_recovery",
            # No dollar signal is currently available for incomplete attendance.
            rank_score(0.0, 30),  # no deadline field; use a wide documented default
            "cccap_analyze_payment_risk",
            {"riskFocus": "INCOMPLETE_ATTENDANCE"},
        ))

    return candidates


def _payment_candidates(payment: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    status = payment.get("status")

    if status == "BLOCKED":
        missing_inputs = payment.get("missing_inputs")
        missing_count = len(missing_inputs) if isinstance(missing_inputs, list) else 0
        candidates.append(_action(
            "retry-payment-analysis",
            "Retry payment review",
            "source_recovery",
            # No dollar signal or deadline is available for blocked payment review.
            rank_score(0.0, 30),
            "cccap_analyze_payment",
            {},
        ))
        return candidates

    amount_at_risk = _amount(payment.get("amount_at_risk"))
    if amount_at_risk > 0:
        candidates.append(_action(
            "review-conditional-payment",
            f"Review conditional payment — ~ ${amount_at_risk:,.2f}",
            "payment_impact",
            rank_score(amount_at_risk, _days_remaining(payment.get("confirmation_days_remaining"))),
            "cccap_analyze_payment",
            {"detailPage": 1},
        ))

    excluded_days = _count(payment.get("excluded_days"))
    if excluded_days:
        candidates.append(_action(
            "review-excluded-payment-days",
            "Review excluded payment days",
            "urgency",
            # No dollar signal is currently available for excluded payment days.
            rank_score(0.0, payment.get("confirmation_days_remaining", 30)),
            "cccap_analyze_payment",
            {"detailPage": 1, "excludedOnly": True},
        ))

    summary_view = payment.get("summary_view")
    summary_view = summary_view if isinstance(summary_view, dict) else {}
    next_actions = summary_view.get("next_actions")
    if isinstance(next_actions, list):
        for entry in next_actions:
            if not isinstance(entry, dict):
                continue
            action_id = entry.get("action_id")
            label = entry.get("label")
            if not isinstance(action_id, str) or not isinstance(label, str):
                continue
            # These are already summary-level review flags (missing rate,
            # absence/drop-in limit exceeded, pending confirmation, holiday
            # policy) computed by the payment evaluator; treat them as
            # urgency-band candidates ranked by their reported amount at risk.
            candidates.append(_action(
                action_id,
                label,
                "urgency",
                rank_score(
                    _amount(entry.get("amount_at_risk")),
                    _days_remaining(entry.get("confirmation_days_remaining")),
                ),
                "cccap_analyze_payment",
                {"detailPage": 1},
            ))

    return candidates


def rank_actions(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Sort candidate actions by priority_score descending, action_id
    ascending as a deterministic tiebreaker, and de-duplicate by action_id
    (first occurrence wins) so a capability cannot double-count the same
    action from two derivation paths."""
    seen: set[str] = set()
    deduplicated: list[dict[str, Any]] = []
    for candidate in candidates:
        action_id = candidate["action_id"]
        if action_id in seen:
            continue
        seen.add(action_id)
        deduplicated.append(candidate)
    return sorted(deduplicated, key=lambda action: (-action["priority_score"], action["action_id"]))


def rank_next_actions(canonical_facts: dict[str, Any], active_capability: str) -> list[dict[str, Any]]:
    """Public entrypoint. `canonical_facts` is the attendance-risk evaluator
    result (for `active_capability == "attendance-risk-analysis"`) or the
    payment evaluator result's `payment` object (for
    `active_capability == "payment-analysis"`). Returns a ranked, deterministic
    NextAction list; an unrecognized capability or malformed input yields an
    empty list rather than guessing."""
    if not isinstance(canonical_facts, dict):
        return []
    if active_capability == "attendance-risk-analysis":
        return rank_actions(_attendance_candidates(canonical_facts))
    if active_capability == "payment-analysis":
        return rank_actions(_payment_candidates(canonical_facts))
    return []


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rank next actions from a canonical attendance or payment evaluator result."
    )
    parser.add_argument("payload", type=Path, help="Path to a JSON file with canonical_facts and active_capability")
    args = parser.parse_args()
    try:
        payload = json.loads(args.payload.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("input must be an object")
        canonical_facts = payload.get("canonical_facts")
        active_capability = payload.get("active_capability")
        if not isinstance(active_capability, str):
            raise ValueError("active_capability is required")
        result = {
            "status": "ok",
            "result": {
                "rule_version": RULE_VERSION,
                "actions": rank_next_actions(canonical_facts, active_capability),
            },
        }
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(json.dumps({"status": "error", "error": str(error)}))
        return 2
    except Exception as error:  # noqa: BLE001 - fail closed on any unexpected defect
        print(json.dumps({"status": "error", "error": f"Next-action ranking failed unexpectedly: {error}"}))
        return 2

    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())