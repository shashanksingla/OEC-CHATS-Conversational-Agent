#!/usr/bin/env python3
"""Shared constants for the deterministic evaluator scripts.

Extracted because CONFIRMATION_WINDOW_DAYS previously existed as two independent
copies (provider_risk_payment_engine.py and evaluate_attendance_risks.py) with a
comment asking a human to keep them synchronized manually - a silent-drift risk
with no test that would catch the two values diverging. This module is a plain
importable sibling file, not a subprocess entry point: each evaluator is still
invoked independently via `uv run <script>.py <input.json>`, so the
one-evaluator-one-subprocess-one-rule_version boundary is unchanged.
"""

# Days after a service date during which a parent can still confirm attendance
# before it becomes a counted absence. Used by both the attendance-risk snapshot
# (evaluate_attendance_risks.py) and the payment engine's attendance waterfall
# (provider_risk_payment_engine.py) - these two MUST agree, since the same
# service date must resolve to the same confirmation state in both places.
CONFIRMATION_WINDOW_DAYS = 9

# Number of absence days remaining before the county limit counts as
# "approaching" (used in evaluate_attendance_risks.py's risk-code derivation).
ABSENCE_LIMIT_APPROACHING_THRESHOLD_DAYS = 2

# Provider-facing placeholder for a value that could not be resolved from the
# current source data. Repeated verbatim across evaluator outputs; centralized
# here so a wording change only needs to happen once.
UNAVAILABLE_FROM_SOURCE = "Unavailable from the current source"

from decimal import Decimal


def aggregate_by(
    records,
    key_fn,
    sum_fields=(),
    collect_fields=(),
    label_fn=None,
    count_field="count",
):
    """Generic groupby reducer, replacing hand-written per-dimension accumulator
    blocks in both provider_risk_payment_engine.py and evaluate_attendance_risks.py.

    For each distinct `key_fn(record)`:
    - sums the numeric value of each field named in `sum_fields` across every
      matching record (missing/non-numeric values are treated as 0, matching
      the existing accumulator behavior of never raising on a partial record)
    - collects the distinct values of each field named in `collect_fields`
      into a set (skipping None/missing); if a record's field value is itself
      a list or set, every item in it is unioned into the group's set instead
      of the list/set being added as one opaque value - this lets one record
      contribute multiple distinct values to a collected field (e.g. a single
      day carrying more than one exclusion reason)
    - always includes a count of matching records, under the key named by
      `count_field` (default "count"; pass e.g. "days" or "children" to get
      that name directly instead of renaming the result afterward)
    - if `label_fn` is given, calls it once per group with the first matching
      record to set a `label` field (e.g. a county or category display name)

    Returns {key: {<count_field>: int, <sum_field>: number, <collect_field>: set(), ...}}.

    This intentionally does NOT try to cover every existing accumulator shape
    (e.g. the payment engine's `composition_bucket`, which nests per-category
    sub-dicts, or `summary_groups`, which collects a `rates` set with
    different semantics) - those keep their own dedicated logic rather than
    being forced through this generic shape. Use this only where the existing
    accumulator is a flat "sum some numbers, collect some sets, count" block -
    the payment engine's `categories`/`counties`/`children` buckets and the
    attendance evaluator's `county_aggregates` are exactly that shape.
    """
    groups = {}
    for record in records:
        key = key_fn(record)
        group = groups.get(key)
        if group is None:
            group = {count_field: 0}
            for field in sum_fields:
                group[field] = 0
            for field in collect_fields:
                group[field] = set()
            if label_fn is not None:
                group["label"] = label_fn(record)
            groups[key] = group
        group[count_field] += 1
        for field in sum_fields:
            value = record.get(field)
            if isinstance(value, (int, float, Decimal)) and not isinstance(value, bool):
                group[field] += value
        for field in collect_fields:
            value = record.get(field)
            if isinstance(value, (list, set)):
                group[field].update(item for item in value if item is not None)
            elif value is not None:
                group[field].add(value)
    return groups