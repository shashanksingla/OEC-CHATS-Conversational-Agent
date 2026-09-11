export function normalizePaymentStatus(value) {
    const status = String(value ?? "").trim().toUpperCase();
    if (status === "4" || status === "PAID")
        return "PAID";
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
export function assertPaymentEnginePayload(payload) {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        throw new Error("Payment engine payload must be an object");
    }
    const record = payload;
    if (record.rule_version !== "provider-risk-payment-v3") {
        throw new Error("Payment engine payload rule_version must be provider-risk-payment-v3");
    }
    const requiredArrayFields = [
        "authorizations",
        "attendance_days",
        "county_policies",
        "fiscal_rates",
        "existing_sub_payments",
    ];
    for (const field of requiredArrayFields) {
        if (!Array.isArray(record[field])) {
            throw new Error(`Payment engine payload.${field} must be an array`);
        }
    }
    const servicePeriod = record.service_period;
    if (!servicePeriod
        || typeof servicePeriod !== "object"
        || Array.isArray(servicePeriod)
        || typeof servicePeriod.id !== "string"
        || typeof servicePeriod.start_date !== "string"
        || typeof servicePeriod.end_date !== "string") {
        throw new Error("Payment engine payload.service_period must include id, start_date, and end_date");
    }
}
