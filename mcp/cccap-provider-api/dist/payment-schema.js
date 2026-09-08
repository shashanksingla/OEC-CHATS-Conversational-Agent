export function normalizePaymentStatus(value) {
    const status = String(value ?? "").trim().toUpperCase();
    if (status === "4" || status === "PAID")
        return "PAID";
    if (["1", "2", "3", "CREATED", "IN_PROGRESS", "CALCULATED", "REQUESTED"].includes(status)) {
        return "REQUESTED";
    }
    return undefined;
}
