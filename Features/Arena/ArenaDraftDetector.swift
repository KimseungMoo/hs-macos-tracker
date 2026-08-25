import Foundation

public enum ArenaPhase: String, Equatable, Sendable {
    case unknown
    case draft
    case redraft
    case idle
}

/// Arena.log / LoadingScreen markers only. Does not guess the 3-card offer.
public enum ArenaDraftDetector {
    public static func detect(from line: String, current: ArenaPhase) -> ArenaPhase {
        let text = line
        if matches(text, [#"REDRAFT"#, #"Redraft"#, #"Client-Redraft"#]) {
            return .redraft
        }
        if matches(text, [#"nextMode=DRAFT"#, #"HUB -> DRAFT"#, #"Entering ARENA"#, #"prevMode=\w+ nextMode=DRAFT"#]) {
            return .draft
        }
        if current == .draft || current == .redraft {
            if matches(text, [#"nextMode=GAMEPLAY"#, #"nextMode=HUB"#, #"DRAFT -> GAMEPLAY"#, #"DRAFT -> HUB"#]) {
                return .idle
            }
        }
        return current
    }

    private static func matches(_ line: String, _ patterns: [String]) -> Bool {
        patterns.contains { pattern in
            line.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
