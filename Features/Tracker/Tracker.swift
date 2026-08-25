import CardCatalog
import GameState
import Visibility

public struct RemainingCard: Equatable, Sendable, Encodable {
    public var dbfId: Int
    public var cardID: String?
    public var name: String?
    public var remaining: Int

    public init(dbfId: Int, cardID: String?, name: String?, remaining: Int) {
        self.dbfId = dbfId
        self.cardID = cardID
        self.name = name
        self.remaining = remaining
    }
}

public struct TrackerSnapshot: Equatable, Sendable, Encodable {
    public var remaining: [RemainingCard]
    public var publicOpponentCards: [String]
    public var turn: Int?
    public var manaLeft: Int?
    public var friendlyHeroHealth: Int?
    public var opponentHeroHealth: Int?

    public init(
        remaining: [RemainingCard],
        publicOpponentCards: [String],
        turn: Int?,
        manaLeft: Int?,
        friendlyHeroHealth: Int?,
        opponentHeroHealth: Int?
    ) {
        self.remaining = remaining
        self.publicOpponentCards = publicOpponentCards
        self.turn = turn
        self.manaLeft = manaLeft
        self.friendlyHeroHealth = friendlyHeroHealth
        self.opponentHeroHealth = opponentHeroHealth
    }
}

public enum Tracker {
    public static func decklist(from picks: [DraftCard], catalog: CardCatalog) -> [DeckCard] {
        var counts: [Int: Int] = [:]
        var order: [Int] = []
        for pick in picks {
            guard let card = catalog.card(nameOrID: pick.nameOrID) else { continue }
            if counts[card.dbfId] == nil {
                order.append(card.dbfId)
            }
            counts[card.dbfId, default: 0] += 1
        }
        return order.map { dbfId in
            DeckCard(dbfId: dbfId, cardID: catalog.card(dbfId: dbfId)?.id, count: counts[dbfId] ?? 0)
        }
    }

    public static func snapshot(from state: PublicState, catalog: CardCatalog?) -> TrackerSnapshot {
        TrackerSnapshot(
            remaining: remaining(from: state, catalog: catalog),
            publicOpponentCards: state.entities
                .filter { $0.side == .opponent && $0.cardID != nil }
                .compactMap(\.cardID),
            turn: state.turn,
            manaLeft: state.friendlyManaLeft,
            friendlyHeroHealth: state.friendlyHeroHealth,
            opponentHeroHealth: state.opponentHeroHealth
        )
    }

    public static func remaining(from state: PublicState, catalog: CardCatalog?) -> [RemainingCard] {
        var seen: [String: Int] = [:]
        for entity in state.entities where entity.side == .friendly {
            guard entity.zone != .deck, let cardID = entity.cardID else { continue }
            seen[cardID, default: 0] += 1
        }

        return state.decklist.map { card in
            let cardID = card.cardID ?? catalog?.card(dbfId: card.dbfId)?.id
            let used = cardID.flatMap { seen[$0] } ?? 0
            let record = cardID.flatMap { catalog?.card(id: $0) } ?? catalog?.card(dbfId: card.dbfId)
            return RemainingCard(
                dbfId: card.dbfId,
                cardID: cardID,
                name: record?.displayName(),
                remaining: max(0, card.count - used)
            )
        }
    }
}
