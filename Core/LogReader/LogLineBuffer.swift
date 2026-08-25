import Foundation

/// Buffers incomplete log lines across read chunks. ponytail: single-byte UTF-8 only; upgrade if HS emits split multibyte.
public struct LogLineBuffer: Sendable {
    public private(set) var remainder = ""

    public init() {}

    public mutating func append(_ chunk: String) -> [String] {
        guard !chunk.isEmpty else { return [] }

        let normalized = chunk.replacingOccurrences(of: "\r\n", with: "\n")
        let combined = remainder + normalized
        var parts = combined.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        if combined.hasSuffix("\n") {
            remainder = ""
            if parts.last == "" {
                parts.removeLast()
            }
        } else if let last = parts.popLast() {
            remainder = last
        } else {
            remainder = ""
        }

        return parts.compactMap { part in
            let trimmed = part.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    public mutating func takeRemainder() -> String? {
        guard !remainder.isEmpty else { return nil }
        defer { remainder = "" }
        return remainder.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
    }
}
