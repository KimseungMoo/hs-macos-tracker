import Foundation

public struct FeatureFlags: Equatable, Sendable {
    public var trackerEnabled: Bool
    public var arenaEnabled: Bool
    public var adviceEnabled: Bool
    public var advicePrescriptive: Bool

    public init(
        trackerEnabled: Bool = true,
        arenaEnabled: Bool = true,
        adviceEnabled: Bool = true,
        advicePrescriptive: Bool = false
    ) {
        self.trackerEnabled = trackerEnabled
        self.arenaEnabled = arenaEnabled
        self.adviceEnabled = adviceEnabled
        self.advicePrescriptive = advicePrescriptive
    }
}
