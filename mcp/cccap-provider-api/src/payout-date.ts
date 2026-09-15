/**
 * Payout Date = Service Period End Date (Sunday) + 12 days - always resolves
 * to Friday, the true payment release date (confirmed against real
 * T_SERV_PERIOD__c sample data: DTE_BATCH_FILE_PMT__c/release is one day
 * after DTE_BATCH_PRCS_PMT__c/processing). Mirrors compute_payout_date() in
 * skills/agent-child-care-payment-advisor/scripts/provider_risk_payment_engine.py
 * exactly - do not change the +12 offset here without updating that Python
 * function and both test suites in the same change. This formula is now
 * strictly a last-resort fallback - the real Apex-sourced
 * paymentReleaseDate (from ServicePeriodService.cls) is preferred wherever
 * a resolved service-period record is available.
 */
export const PAYOUT_DATE_OFFSET_DAYS = 12;

/**
 * The engine's payment.payout_date is authoritative when available; this
 * utility is for call sites that do not perform a full engine run.
 *
 * @param serviceEndDateIso ISO date string (YYYY-MM-DD) for the service period end date.
 * @returns ISO date string (YYYY-MM-DD) for the computed payout date.
 */
// Engine payment.payout_date is authoritative when available; use this for call sites without a full engine run.
export function computePayoutDate(serviceEndDateIso: string): string {
  const parsed = new Date(`${serviceEndDateIso}T00:00:00Z`);
  parsed.setUTCDate(parsed.getUTCDate() + PAYOUT_DATE_OFFSET_DAYS);
  return parsed.toISOString().slice(0, 10);
}