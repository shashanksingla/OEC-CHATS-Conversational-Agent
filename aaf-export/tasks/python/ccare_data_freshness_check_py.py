"""_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________
Checks whether the current childcare data snapshot satisfies the turn request.
Version: 1.0.0.
Writes freshness status and session validation to context.
"""

from datetime import date as _date

log = print

def _ctx(key, default=None):
    val = _context
    for part in key.split('.'):
        if not isinstance(val, dict):
            return default
        val = val.get(part)
    return val if val is not None else default

tr = _ctx('turnRequest') or {}
if not isinstance(tr, dict):
    tr = {}

dcr      = _ctx('data_collection_result') or {}
snap     = dcr.get('snapshot') or {} if isinstance(dcr, dict) else {}
rc       = (tr.get('routingClass') or '').upper()
sf       = (tr.get('subFilter')    or '').upper()
df       = (tr.get('dateFilter')   or 'THIS_MONTH').upper()
complete = isinstance(dcr, dict) and dcr.get('status') == 'DATA_COLLECTION_COMPLETE'
snap_df  = (snap.get('date_filter') or '').upper() if isinstance(snap, dict) else ''

# Detect an unexpected drop in absence-risk count.
prev_count = _ctx('prev_absence_risk_count')
curr_count = int(snap.get('absence_risk_children_count') or 0) if isinstance(snap, dict) else 0
incon = (complete and prev_count is not None and int(prev_count or 0) > 0 and curr_count == 0)

WEEKLY        = {'THIS_WEEK', 'LAST_WEEK', 'NEXT_WEEK'}
THIS_MONTH_OK = {
    'PENDING_CONFIRMATIONS', 'ABSENCE_LIMITS', 'INCOMPLETE_ATTENDANCE', 'ALL',
    'NEXT_PAYOUT', 'CURRENT_PERIOD_FORECAST', 'CURRENT_MONTH',
}

if rc in ('CLARIFY', 'END'):
    status, reason = 'NO_DATA_NEEDED', 'no data required for CLARIFY/END'
elif not complete:
    status, reason = 'NEEDS_REFRESH', 'no complete snapshot in context'
elif df in WEEKLY:
    status, reason = 'NEEDS_REFRESH', f'weekly filter {df} may span month boundary'
elif sf == 'LAST_PAYOUT':
    status, reason = 'NEEDS_REFRESH', 'LAST_PAYOUT always requires prior-month data'
elif incon:
    status, reason = 'NEEDS_REFRESH', f'absence count dropped {prev_count} -> 0, re-verifying'
elif snap_df == 'THIS_MONTH' and sf in THIS_MONTH_OK:
    status, reason = 'SUFFICIENT',    f'THIS_MONTH snapshot covers {sf}'
elif snap_df and snap_df == df:
    status, reason = 'SUFFICIENT',    f'snapshot date_filter matches request ({df})'
else:
    status, reason = 'NEEDS_REFRESH', f'snapshot ({snap_df}) does not cover {df}/{sf}'

# Persist count so next turn can detect an unexpected drop to 0
if complete and isinstance(snap, dict):
    write_context('prev_absence_risk_count', curr_count)

# 2026-09-26: sessionValidated REMOVED from this task. It used to be derived
# from `complete` (this turn's data_collection freshness) and conflated with
# provider-identity verification -- since data_collection legitimately
# re-runs every turn (different dateFilter/subFilter needs different data),
# `complete`-derived sessionValidated could never stay true across turns,
# so provider_validated_gate never actually skipped ccare_provider_data_py.
# Provider identity is now a separate, persistent context.sessionState.
# providerVerified flag written once by ccare_provider_data_py -- this task
# only ever concerns itself with per-turn DATA freshness (dataStatus/reason).
write_context('turnRequest', dict(tr, dataStatus=status))
write_context('freshnessResult', {'dataStatus': status, 'reason': reason})

log(f'dataStatus={status}  reason={reason}')
respond({'dataStatus': status, 'reason': reason}, confidence=1.0)