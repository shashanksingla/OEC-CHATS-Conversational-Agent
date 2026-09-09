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

export function normalizePaymentStatus(value: unknown): "PAID" | "REQUESTED" | undefined {
  const status = String(value ?? "").trim().toUpperCase();
  if (status === "4" || status === "PAID") return "PAID";
  if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
    return "REQUESTED";
  }
  return undefined;
}
