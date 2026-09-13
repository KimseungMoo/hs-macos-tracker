import Foundation

public enum ArenaLetterGrade: String, Equatable, Sendable, CaseIterable {
    case s, a, b, c, d, f

    public static func fromScore(_ score: Double) -> ArenaLetterGrade {
        switch score {
        case 100...: return .s
        case 90 ..< 100: return .a
        case 80 ..< 90: return .b
        case 70 ..< 80: return .c
        case 60 ..< 70: return .d
        default: return .f
        }
    }
}

public struct ArenaScoredCard: Equatable, Sendable {
    public var cardID: String
    public var score: Double?
    public var classScore: Double?
    public var letterGrade: ArenaLetterGrade?
    public var maxCopies: Int

    public init(
        cardID: String,
        score: Double? = nil,
        classScore: Double? = nil,
        letterGrade: ArenaLetterGrade? = nil,
        maxCopies: Int = 2
    ) {
        self.cardID = cardID
        self.score = score
        self.classScore = classScore
        self.letterGrade = letterGrade
        self.maxCopies = max(1, maxCopies)
    }
}

public enum ArenaScoreError: Error, Equatable, Sendable {
    case needThreeCards
    case invalidCardID
    case missingScore(cardID: String)
    case emptyOwned
}

public struct PickRecommendation: Equatable, Sendable {
    public var pick: ArenaScoredCard
    public var runnerUp: ArenaScoredCard
    public var pass: ArenaScoredCard
    public var tied: [ArenaScoredCard]
}

public struct DeckEntry: Equatable, Sendable {
    public var card: ArenaScoredCard
    public var copies: Int
}

public struct DeckRecommendation: Equatable, Sendable {
    public var entries: [DeckEntry]
    public var cardCount: Int
    public var meanScore: Double
    public var minScore: Double
    public var incomplete: Bool
}

public enum ArenaScore {
    /// Class score beats a generic reprint. Letter grade never ranks.
    public static func effectiveScore(of card: ArenaScoredCard) -> Double? {
        card.classScore ?? card.score
    }

    public static func recommendPick(_ cards: [ArenaScoredCard]) throws -> PickRecommendation {
        guard cards.count == 3 else { throw ArenaScoreError.needThreeCards }
        try validateCardIDs(cards)
        let ranked = try rankedByScore(cards)
        let pick = ranked[0]
        let pickScore = try requireScore(pick)
        return PickRecommendation(
            pick: pick,
            runnerUp: ranked[1],
            pass: ranked[2],
            tied: ranked.dropFirst().filter { effectiveScore(of: $0) == pickScore }
        )
    }

    public static func recommendDeck(
        from owned: [ArenaScoredCard],
        size: Int = 30
    ) throws -> DeckRecommendation {
        guard size > 0 else { throw ArenaScoreError.emptyOwned }
        try validateCardIDs(owned)
        let unique = mergeOwned(owned)
        let scored = try unique.map { card -> (ArenaScoredCard, Double) in
            (card, try requireScore(card))
        }
        guard !scored.isEmpty else { throw ArenaScoreError.emptyOwned }

        let ranked = scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.cardID < rhs.0.cardID
        }

        var entries: [DeckEntry] = []
        var remaining = size
        var weightedTotal = 0.0
        var minScore = ranked[0].1

        for (card, score) in ranked {
            guard remaining > 0 else { break }
            let copies = min(card.maxCopies, remaining)
            entries.append(DeckEntry(card: card, copies: copies))
            remaining -= copies
            weightedTotal += score * Double(copies)
            minScore = min(minScore, score)
        }

        let cardCount = size - remaining
        return DeckRecommendation(
            entries: entries,
            cardCount: cardCount,
            meanScore: weightedTotal / Double(cardCount),
            minScore: minScore,
            incomplete: cardCount < size
        )
    }

    private static func validateCardIDs(_ cards: [ArenaScoredCard]) throws {
        if cards.contains(where: { $0.cardID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            throw ArenaScoreError.invalidCardID
        }
    }

    private static func requireScore(_ card: ArenaScoredCard) throws -> Double {
        guard let score = effectiveScore(of: card) else {
            throw ArenaScoreError.missingScore(cardID: card.cardID)
        }
        return score
    }

    private static func rankedByScore(_ cards: [ArenaScoredCard]) throws -> [ArenaScoredCard] {
        let scored = try cards.map { card -> (ArenaScoredCard, Double) in
            (card, try requireScore(card))
        }
        return scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.cardID < rhs.0.cardID
        }.map(\.0)
    }

    private static func mergeOwned(_ owned: [ArenaScoredCard]) -> [ArenaScoredCard] {
        var best: [String: ArenaScoredCard] = [:]
        for card in owned {
            guard effectiveScore(of: card) != nil else { continue }
            if let existing = best[card.cardID] {
                let newScore = effectiveScore(of: card) ?? .leastNonzeroMagnitude
                let oldScore = effectiveScore(of: existing) ?? .leastNonzeroMagnitude
                if newScore > oldScore {
                    best[card.cardID] = card
                }
            } else {
                best[card.cardID] = card
            }
        }
        return Array(best.values)
    }
}
