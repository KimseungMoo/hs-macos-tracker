import CardCatalog
import GameState
import Visibility

public struct AdviceItem: Equatable, Sendable, Encodable {
    public var kind: Kind
    public var text: String

    public enum Kind: String, Sendable, Encodable {
        case lethal
        case unusedMana
        case publicThreat
        case publicRemoval
        case prescriptive
    }

    public init(kind: Kind, text: String) {
        self.kind = kind
        self.text = text
    }
}

public enum Advice {
    public static func items(
        from state: PublicState,
        catalog: CardCatalog?,
        flags: RuntimeFlags = .release
    ) -> [AdviceItem] {
        var items: [AdviceItem] = []
        items.append(contentsOf: lethal(state))
        items.append(contentsOf: unusedMana(state, catalog: catalog))
        items.append(contentsOf: threats(state))
        items.append(contentsOf: removalInHand(state, catalog: catalog))
        if flags.prescriptiveAdvice {
            items.append(contentsOf: prescriptive(from: items))
        }
        return items
    }

    static func lethal(_ state: PublicState) -> [AdviceItem] {
        let boardAttack = state.entities
            .filter { $0.side == .friendly && $0.zone == .play && $0.cardType == .minion }
            .compactMap(\.attack)
            .reduce(0, +)
        guard let hero = state.opponentHeroHealth, boardAttack >= hero, boardAttack > 0 else {
            return []
        }
        return [AdviceItem(kind: .lethal, text: "public board attack \(boardAttack) >= opponent hero \(hero)")]
    }

    static func unusedMana(_ state: PublicState, catalog: CardCatalog?) -> [AdviceItem] {
        guard let left = state.friendlyManaLeft, left > 0 else { return [] }
        let playable = state.entities.contains { entity in
            entity.side == .friendly && entity.zone == .hand && resolvedCost(entity, catalog: catalog).map { $0 <= left } == true
        }
        guard playable else { return [] }
        return [AdviceItem(kind: .unusedMana, text: "mana left \(left) with a playable public hand card")]
    }

    static func threats(_ state: PublicState) -> [AdviceItem] {
        state.entities
            .filter { $0.side == .opponent && $0.zone == .play && ($0.attack ?? 0) >= 5 }
            .map { entity in
                AdviceItem(
                    kind: .publicThreat,
                    text: "opponent \(entity.cardID ?? "minion") attack \(entity.attack ?? 0)"
                )
            }
    }

    static func removalInHand(_ state: PublicState, catalog: CardCatalog?) -> [AdviceItem] {
        let hits = state.entities.filter { entity in
            entity.side == .friendly && entity.zone == .hand && isRemoval(entity, catalog: catalog)
        }
        guard !hits.isEmpty else { return [] }
        return [AdviceItem(kind: .publicRemoval, text: "removal in hand: \(hits.compactMap(\.cardID).joined(separator: ", "))")]
    }

    static func prescriptive(from facts: [AdviceItem]) -> [AdviceItem] {
        if facts.contains(where: { $0.kind == .lethal }) {
            return [AdviceItem(kind: .prescriptive, text: "send public board face")]
        }
        return []
    }

    static func resolvedCost(_ entity: PublicEntity, catalog: CardCatalog?) -> Int? {
        entity.cost ?? entity.cardID.flatMap { catalog?.card(id: $0)?.cost }
    }

    static func isRemoval(_ entity: PublicEntity, catalog: CardCatalog?) -> Bool {
        guard let cardID = entity.cardID, let card = catalog?.card(id: cardID) else { return false }
        let text = (card.text ?? "").lowercased()
        return text.contains("destroy") || text.contains("파괴") || text.contains("damage") || text.contains("피해")
    }
}
