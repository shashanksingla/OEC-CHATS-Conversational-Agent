#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Deterministic next-action ranking for Provider Assist conversational responses.

This module codifies the ranking rule previously expressed only in prose in
`skills/provider-assist-conversation-templates/SKILL.md` ("Actions are ranked by
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


def _magnitude(dollar_amount: float, hours_fallback: Any) -> float:
    """Severity input for rank_score. A category with no verified dollar figure must not be
    hardcoded to 0 (a category with a genuine dollar figure - however tiny - would always
    outrank it regardless of true relative severity). Falls back to the category's own
    already-computed hours-at-risk figure (same value shown in the provider-facing "At-Risk
    Hours" table) so every candidate is scored on one comparable magnitude."""
    if dollar_amount > 0:
        return dollar_amount
    return _amount(hours_fallback)


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
        # Prefer fiscal-rate amounts because they measure payment impact directly.
        crossed_amount = _amount(crossed.get("risk_amount_estimate"))
        # Use a wide default because no deadline is guaranteed.
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
        # Use a wide default because no deadline is guaranteed.
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
            # No dollar figure yet - falls back to potential_loss_hours (same value shown in the
            # provider-facing "At-Risk Hours" table) so this is never structurally stuck at 0.
            rank_score(
                _magnitude(0.0, pending.get("potential_loss_hours")),
                _days_remaining(pending.get("confirmation_days_remaining")),
            ),
            "cccap_analyze_payment_risk",
            {"riskFocus": "PARENT_CONFIRMATIONS"},
        ))

    incomplete = categories.get("incomplete_attendance")
    incomplete = incomplete if isinstance(incomplete, dict) else {}
    incomplete_days = _count(attendance_risk.get("incomplete_attendance_days"))
    if incomplete_days:
        candidates.append(_action(
            "review-incomplete-attendance",
            f"Review incomplete attendance — {incomplete_days} records",
            "source_recovery",
            # No dollar figure yet - falls back to potential_loss_hours, same as pending confirmations above.
            rank_score(_magnitude(0.0, incomplete.get("potential_loss_hours")), 30),  # no deadline field; use a wide documented default
            "cccap_analyze_payment_risk",
            {"riskFocus": "INCOMPLETE_ATTENDANCE"},
        ))

    return candidates


def _payment_candidates(payment: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    status = payment.get("status")

    if status == "BLOCKED":
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
            # Excluded payment days currently have no dollar signal.
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
            # Treat evaluator summary flags as urgency candidates ranked by reported risk.
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


def rank_next_actions(
    attendance_facts: dict[str, Any] | None = None,
    payment_facts: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    """Public entrypoint. `attendance_facts` is the attendance-risk evaluator
    result; `payment_facts` is the payment evaluator result's `payment`
    object. Either or both may be provided - when both are present, candidates
    from both capabilities are generated and ranked TOGETHER in one list, so a
    provider's top action reflects the highest-priority item across
    attendance and payment, not whichever capability happened to be called.
    Malformed input for a given slot is simply skipped rather than guessed at."""
    candidates: list[dict[str, Any]] = []
    if isinstance(attendance_facts, dict):
        candidates.extend(_attendance_candidates(attendance_facts))
    if isinstance(payment_facts, dict):
        candidates.extend(_payment_candidates(payment_facts))
    return rank_actions(candidates)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rank next actions from attendance and/or payment evaluator results."
    )
    parser.add_argument("payload", type=Path, help="Path to a JSON file with optional attendance_facts and/or payment_facts")
    args = parser.parse_args()
    try:
        payload = json.loads(args.payload.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("input must be an object")
        attendance_facts = payload.get("attendance_facts")
        payment_facts = payload.get("payment_facts")
        if attendance_facts is None and payment_facts is None:
            raise ValueError("at least one of attendance_facts or payment_facts is required")
        result = {
            "status": "ok",
            "result": {
                "rule_version": RULE_VERSION,
                "actions": rank_next_actions(attendance_facts, payment_facts),
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