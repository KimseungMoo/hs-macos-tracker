import Foundation

public struct RemainingRow: Equatable, Sendable, Identifiable {
    public var id: Int { dbfId }
    public var dbfId: Int
    public var name: String
    public var count: Int
    public var nextDraw: Double?
}

public struct PublicMatchView: Equatable, Sendable {
    public var remainingKnown: Bool
    public var remainingRows: [RemainingRow]
    public var remainingTotal: Int
    public var turn: Int?
    public var mana: Int?
    public var manaUsed: Int?
    public var friendlyBoard: [BoardEntity]
    public var opponentBoard: [BoardEntity]
    public var opponentPublic: [PublicCard]

    public static func project(_ state: MatchState, catalog: CardCatalog) -> PublicMatchView {
        let total = state.remainingTotal
        let rows: [RemainingRow]
        if state.remainingKnown {
            rows = state.remaining.keys.sorted().map { dbfId in
                let count = state.remaining[dbfId] ?? 0
                return RemainingRow(
                    dbfId: dbfId,
                    name: catalog.label(dbfId: dbfId),
                    count: count,
                    nextDraw: DrawOdds.nextDraw(count: count, remaining: total)
                )
            }
        } else {
            rows = []
        }
        return PublicMatchView(
            remainingKnown: state.remainingKnown,
            remainingRows: rows,
            remainingTotal: total,
            turn: state.turn,
            mana: state.friendlyResources,
            manaUsed: state.friendlyResourcesUsed,
            friendlyBoard: state.friendlyBoard,
            opponentBoard: state.opponentBoard,
            opponentPublic: state.opponentPublic
        )
    }
}

public enum Visibility {
    /// Opponent hand / deck / secrets never become events. Pass-through for public + friendly-only events.
    public static func allow(_ event: GameEvent) -> GameEvent? {
        event
    }
}
