public enum FeatureFlags: Sendable {
    public static let arenaRecommendations = false
    public static let prescriptiveAdvice = false
}

public struct RuntimeFlags: Equatable, Sendable {
    public var arenaRecommendations: Bool
    public var prescriptiveAdvice: Bool

    public init(
        arenaRecommendations: Bool = FeatureFlags.arenaRecommendations,
        prescriptiveAdvice: Bool = FeatureFlags.prescriptiveAdvice
    ) {
        self.arenaRecommendations = arenaRecommendations
        self.prescriptiveAdvice = prescriptiveAdvice
    }

    public static let release = RuntimeFlags()
}
