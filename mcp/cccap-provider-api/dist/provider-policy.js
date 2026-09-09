export function normalizeQualityTier(providerQualityRating, _providerType) {
    if (providerQualityRating === "Level 1")
        return 1;
    if (providerQualityRating === "Level 2")
        return 2;
    if (providerQualityRating === "Level 3")
        return 3;
    if (providerQualityRating === "Level 4")
        return 4;
    if (providerQualityRating === "Level 5")
        return 5;
    throw new Error("provider quality tier is unavailable or unsupported");
}
