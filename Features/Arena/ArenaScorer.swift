import Foundation

public struct ArenaAdvice: Equatable, Sendable {
    public var pick: ArenaCard
    public var runnerUp: ArenaCard
    public var scores: [String: Int]
    public var reasons: [String]
    public var confidence: String
}

/// Local rules only. Current 3 + already picked. No remaining-pool / next-offer odds.
public enum ArenaScorer {
    public static func advise(picked: [ArenaCard], offer: [ArenaCard]) -> ArenaAdvice? {
        advise(picked: picked, offers: offer.map { ArenaOffer(face: $0, bucket: []) })
    }

    public static func advise(picked: [ArenaCard], offers: [ArenaOffer]) -> ArenaAdvice? {
        guard offers.count == 3 else { return nil }
        let firstPick = picked.isEmpty
        let hasBucket = offers.contains { !$0.bucket.isEmpty }
        if firstPick, hasBucket, offers.contains(where: { $0.bucket.isEmpty }) {
            return nil
        }
        let scored = offers.map { offer -> (ArenaCard, Int, [String]) in
            let result = score(offer: offer, picked: picked, firstPick: firstPick)
            return (offer.face, result.0, result.1)
        }
        let ranked = scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.name < rhs.0.name
        }
        let best = ranked[0]
        let second = ranked[1]
        var reasons = best.2
        reasons.append("runner-up \(second.0.name) (\(second.1))")
        var scores: [String: Int] = [:]
        for item in ranked {
            scores[item.0.name] = item.1
        }
        return ArenaAdvice(
            pick: best.0,
            runnerUp: second.0,
            scores: scores,
            reasons: reasons,
            confidence: "high"
        )
    }

    public static func score(_ card: ArenaCard, picked: [ArenaCard]) -> (Int, [String]) {
        var total = 50
        var reasons: [String] = ["base 50"]

        let curve = curveDelta(card: card, picked: picked)
        total += curve.0
        if let note = curve.1 { reasons.append(note) }

        let role = roleDelta(card: card, picked: picked)
        total += role.0
        reasons.append(contentsOf: role.1)

        let synergy = synergyDelta(card: card, picked: picked)
        total += synergy.0
        if let note = synergy.1 { reasons.append(note) }

        let dup = duplicateDelta(card: card, picked: picked)
        total += dup.0
        if let note = dup.1 { reasons.append(note) }

        return (total, reasons)
    }

    private static func score(offer: ArenaOffer, picked: [ArenaCard], firstPick: Bool) -> (Int, [String]) {
        if firstPick, !offer.bucket.isEmpty {
            let parts = offer.pack.map { score($0, picked: picked) }
            let avg = Int((Double(parts.map(\.0).reduce(0, +)) / Double(parts.count)).rounded())
            var reasons = ["bucket avg \(avg) (n=\(offer.pack.count))"]
            reasons.append(contentsOf: parts[0].1)
            return (avg, reasons)
        }
        return score(offer.face, picked: picked)
    }

    private static func curveDelta(card: ArenaCard, picked: [ArenaCard]) -> (Int, String?) {
        let counts = [2, 3, 4].map { cost in picked.filter { $0.cost == cost }.count }
        let holeCost = [2, 3, 4].enumerated().min { lhs, rhs in
            if counts[lhs.offset] != counts[rhs.offset] { return counts[lhs.offset] < counts[rhs.offset] }
            return lhs.element < rhs.element
        }?.element
        let holeEmpty = (counts.min() ?? 0) == 0

        if let holeCost, card.cost == holeCost {
            return (20, "curve hole \(holeCost)")
        }
        if holeEmpty, card.cost >= 7 {
            return (-10, "late over empty 2-4")
        }
        return (0, nil)
    }

    private static func roleDelta(card: ArenaCard, picked: [ArenaCard]) -> (Int, [String]) {
        var delta = 0
        var notes: [String] = []
        let removal = picked.filter { $0.tags.contains(.removal) }.count
        let draw = picked.filter { $0.tags.contains(.draw) }.count
        let survival = picked.filter { $0.tags.contains(.survival) }.count
        if card.tags.contains(.removal), removal < 2 {
            delta += 12
            notes.append("removal (have \(removal))")
        }
        if card.tags.contains(.draw), draw == 0 {
            delta += 8
            notes.append("first draw")
        }
        if card.tags.contains(.survival), survival == 0 {
            delta += 8
            notes.append("first survival")
        }
        return (delta, notes)
    }

    /// Synergy starts at 2 copies. One-card packages get no bonus.
    private static func synergyDelta(card: ArenaCard, picked: [ArenaCard]) -> (Int, String?) {
        var bonus = 0
        var hit: ArenaTag?
        for tribe in card.tribes {
            let have = picked.filter { $0.tribes.contains(tribe) }.count
            if have >= 2 {
                bonus += 6
                hit = tribe
            }
        }
        if let hit {
            return (bonus, "synergy \(hit.rawValue)")
        }
        return (0, nil)
    }

    private static func duplicateDelta(card: ArenaCard, picked: [ArenaCard]) -> (Int, String?) {
        let have = picked.filter { $0.id == card.id }.count
        if have >= 2 { return (-20, "duplicate \(have)") }
        if have == 1 { return (-8, "duplicate 1") }
        return (0, nil)
    }
}
