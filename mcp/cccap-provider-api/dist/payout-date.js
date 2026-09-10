/**
 * Payout Date = Service Period End Date (Sunday) + 11 days - always resolves
 * to Thursday. Mirrors compute_payout_date() in
 * skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py
 * exactly - do not change the +11 offset here without updating that Python
 * function and both test suites in the same change.
 */
export const PAYOUT_DATE_OFFSET_DAYS = 11;
/**
 * The engine's payment.payout_date is authoritative when available; this
 * utility is for call sites that do not perform a full engine run.
 *
 * @param serviceEndDateIso ISO date string (YYYY-MM-DD) for the service period end date.
 * @returns ISO date string (YYYY-MM-DD) for the computed payout date.
 */
// Engine payment.payout_date is authoritative when available; use this for call sites without a full engine run.
export function computePayoutDate(serviceEndDateIso) {
    const parsed = new Date(`${serviceEndDateIso}T00:00:00Z`);
    parsed.setUTCDate(parsed.getUTCDate() + PAYOUT_DATE_OFFSET_DAYS);
    return parsed.toISOString().slice(0, 10);
}
