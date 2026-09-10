export type RecordValue = Record<string, unknown>;

export interface CanonicalServicePeriod {
  id: string;
  start_date: string;
  end_date: string;
}

export interface CanonicalExistingSubPayment {
  authorization_id: string;
  service_period_id: string;
  status: "PAID" | "REQUESTED";
}

export interface CanonicalPaymentFeeSchedule {
  authorization_id: string;
  fiscal_schedule_id: string;
  slot_contract_id: string;
  care_level: string;
  effective_start: string;
  effective_end?: string;
  days_of_month?: number;
  days_of_week?: string | number;
  slot_rate_amount: number;
  activity_amount?: number;
  activity_frequency?: string;
  activity_months?: string;
  registration_amount?: number;
  registration_frequency?: string;
  registration_months?: string;
  transportation_amount?: number;
  transportation_frequency?: string;
  transportation_months?: string;
}

export interface CanonicalVacantSlotSchedule {
  slot_contract_id: string;
  county_id: string;
  fiscal_schedule_id: string;
  effective_start: string;
  effective_end?: string;
  days_of_month?: number;
  days_of_week?: string | number;
  slot_rate_amount: number;
  provider_closure_dates?: string[];
}

export function normalizePaymentStatus(value: unknown): "PAID" | "REQUESTED" | undefined {
  const status = String(value ?? "").trim().toUpperCase();
  if (status === "4" || status === "PAID") return "PAID";
  if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
    return "REQUESTED";
  }
  return undefined;
}

/**
 * Fails closed before the payload crosses the TypeScript-to-Python process
 * boundary. This is a lightweight structural check (top-level shape only) so
 * an obviously malformed payload is rejected here with a clear message
 * instead of being handed to the subprocess; the Python engine still owns
 * full field-level validation of every record it consumes.
 */
export function assertPaymentEnginePayload(payload: unknown): void {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new Error("Payment engine payload must be an object");
  }
  const record = payload as RecordValue;
  if (record.rule_version !== "provider-risk-payment-v1") {
    throw new Error("Payment engine payload rule_version must be provider-risk-payment-v1");
  }
  const requiredArrayFields = [
    "authorizations",
    "attendance_days",
    "county_policies",
    "fiscal_rates",
    "existing_sub_payments",
  ] as const;
  for (const field of requiredArrayFields) {
    if (!Array.isArray(record[field])) {
      throw new Error(`Payment engine payload.${field} must be an array`);
    }
  }
  const servicePeriod = record.service_period;
  if (
    !servicePeriod
    || typeof servicePeriod !== "object"
    || Array.isArray(servicePeriod)
    || typeof (servicePeriod as RecordValue).id !== "string"
    || typeof (servicePeriod as RecordValue).start_date !== "string"
    || typeof (servicePeriod as RecordValue).end_date !== "string"
  ) {
    throw new Error("Payment engine payload.service_period must include id, start_date, and end_date");
  }
}