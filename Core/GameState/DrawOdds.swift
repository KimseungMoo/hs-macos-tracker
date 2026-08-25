import Foundation

public enum DrawOdds {
    /// Next-card probability from a known remaining deck. nil if remaining is empty or counts are invalid.
    public static func nextDraw(count: Int, remaining: Int) -> Double? {
        guard remaining > 0, count >= 0, count <= remaining else { return nil }
        return Double(count) / Double(remaining)
    }
}
