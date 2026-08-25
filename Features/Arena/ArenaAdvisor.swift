import CardCatalog
import GameState

public enum ArenaDecision: Equatable, Sendable {
    case disabled
    case failClosed(String)
    case pick(choice: DraftCard, runnerUp: DraftCard?, reason: String, scores: [String: Int])
}

public enum ArenaAdvisor {
    public static func recommend(
        draft: DraftState,
        catalog: CardCatalog,
        build: BuildRef,
        scores: [String: Int] = [:],
        flags: RuntimeFlags = .release
    ) -> ArenaDecision {
        guard flags.arenaRecommendations else { return .disabled }
        guard let pinned = build.pinnedValue, catalog.matches(build: pinned) else {
            return .failClosed("unknown or mismatched build")
        }
        guard draft.offered.count == 3 else {
            return .failClosed("need three cards")
        }
        guard draft.offered.allSatisfy({ $0.confidence == .high }) else {
            return .failClosed("low confidence cards")
        }

        var resolved: [(DraftCard, CardRecord)] = []
        for card in draft.offered {
            guard let record = catalog.card(nameOrID: card.nameOrID) else {
                return .failClosed("unresolved card")
            }
            resolved.append((card, record))
        }

        let pickedRecords = draft.picked.compactMap { catalog.card(nameOrID: $0.nameOrID) }
        let scored = resolved.map { card, record in
            (card, record, score(record, picked: pickedRecords, scores: scores))
        }
        .sorted { $0.2 > $1.2 }

        let best = scored[0]
        let second = scored.count > 1 ? scored[1] : nil
        let reason = explain(best.1, score: best.2, picked: pickedRecords)
        let scoreMap = Dictionary(uniqueKeysWithValues: scored.map { ($0.1.id, $0.2) })
        return .pick(choice: best.0, runnerUp: second?.0, reason: reason, scores: scoreMap)
    }

    public static func score(
        _ card: CardRecord,
        picked: [CardRecord],
        scores: [String: Int]
    ) -> Int {
        let base = scores[card.id] ?? scores[String(card.dbfId)] ?? heuristicBase(card)
        return base + curveBonus(card, picked: picked) + roleBonus(card) + synergy(card, picked: picked)
            - duplicatePenalty(card, picked: picked)
    }

    static func heuristicBase(_ card: CardRecord) -> Int {
        var value = 50
        switch card.rarity?.uppercased() {
        case "RARE": value += 4
        case "EPIC": value += 8
        case "LEGENDARY": value += 12
        default: break
        }
        if card.type.uppercased() == "MINION", let attack = card.attack, let health = card.health {
            let cost = card.cost ?? 0
            value += (attack + health) - (cost * 2)
        }
        return value
    }

    static func curveBonus(_ card: CardRecord, picked: [CardRecord]) -> Int {
        let cost = card.cost ?? 0
        guard (2...4).contains(cost) else { return cost >= 7 ? -4 : 0 }
        let mid = picked.filter { (2...4).contains($0.cost ?? -1) }.count
        return mid < 4 ? 8 : 2
    }

    static func roleBonus(_ card: CardRecord) -> Int {
        var bonus = 0
        let mechanics = Set(card.mechanics.map { $0.uppercased() })
        if mechanics.contains("TAUNT") { bonus += 4 }
        if mechanics.contains("CHARGE") || mechanics.contains("RUSH") { bonus += 5 }
        if mechanics.contains("DIVINE_SHIELD") { bonus += 6 }
        if mechanics.contains("LIFESTEAL") { bonus += 4 }
        if mechanics.contains("DISCOVER") { bonus += 4 }
        if mechanics.contains("SECRET") { bonus += classSecretPenalty(card) }
        let text = (card.text ?? "").lowercased()
        if text.contains("draw") || text.contains("뽑") { bonus += 5 }
        if text.contains("damage") || text.contains("피해") { bonus += 3 }
        if text.contains("destroy") || text.contains("파괴") { bonus += 4 }
        return bonus
    }

    static func classSecretPenalty(_ card: CardRecord) -> Int {
        card.cardClass?.uppercased() == "MAGE" ? -10 : 1
    }

    static func synergy(_ card: CardRecord, picked: [CardRecord]) -> Int {
        guard picked.count >= 2 else { return 0 }
        let tags = Set(card.mechanics.map { $0.uppercased() })
        let overlap = picked.filter { record in
            !tags.isDisjoint(with: record.mechanics.map { $0.uppercased() })
        }.count
        return overlap >= 2 ? 5 : 0
    }

    static func duplicatePenalty(_ card: CardRecord, picked: [CardRecord]) -> Int {
        picked.filter { $0.id == card.id }.count * 6
    }

    static func explain(_ card: CardRecord, score: Int, picked: [CardRecord]) -> String {
        let cost = card.cost.map(String.init) ?? "?"
        let curve = (2...4).contains(card.cost ?? -1) && picked.filter { (2...4).contains($0.cost ?? -1) }.count < 4
            ? "fills 2-4 curve"
            : "value"
        return "\(card.displayName()) (\(cost)) score \(score), \(curve)"
    }
}
