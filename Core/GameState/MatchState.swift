import Foundation

public struct MatchState: Equatable, Sendable {
    public var importedDeck: [Int: Int] = [:]
    public var remaining: [Int: Int] = [:]
    public var remainingKnown = false
    public var friendlyPlayerId: Int?
    public var turn: Int?
    public var friendlyResources: Int?
    public var friendlyResourcesUsed: Int?
    public var friendlyBoard: [BoardEntity] = []
    public var opponentBoard: [BoardEntity] = []
    public var opponentPublic: [PublicCard] = []

    public init() {}

    public var remainingTotal: Int {
        remaining.values.reduce(0, +)
    }

    public static func reduce(_ state: MatchState, _ event: GameEvent) -> MatchState {
        var next = state
        switch event {
        case .importDeck(let counts):
            next.importedDeck = counts
            next.remaining = counts
            next.remainingKnown = true
        case .setFriendlyPlayer(let id):
            next.friendlyPlayerId = id
        case .gameReset:
            next.remaining = next.importedDeck
            next.remainingKnown = !next.importedDeck.isEmpty
            next.turn = nil
            next.friendlyResources = nil
            next.friendlyResourcesUsed = nil
            next.friendlyBoard = []
            next.opponentBoard = []
            next.opponentPublic = []
        case .gap:
            next.remainingKnown = false
            next.remaining = [:]
            next.turn = nil
            next.friendlyResources = nil
            next.friendlyResourcesUsed = nil
        case .turn(let value):
            next.turn = value
        case .friendlyResources(let available, let used):
            if let available { next.friendlyResources = available }
            if let used { next.friendlyResourcesUsed = used }
        case .friendlyDraw(let dbfId):
            guard next.remainingKnown else { break }
            guard let dbfId, let count = next.remaining[dbfId], count > 0 else {
                next.remainingKnown = false
                next.remaining = [:]
                break
            }
            if count == 1 {
                next.remaining.removeValue(forKey: dbfId)
            } else {
                next.remaining[dbfId] = count - 1
            }
        case .friendlyPlay(let entityId, let dbfId, let cardId):
            upsert(&next.friendlyBoard, BoardEntity(id: entityId, dbfId: dbfId, cardId: cardId))
        case .opponentPlay(let entityId, let dbfId, let cardId):
            upsert(&next.opponentBoard, BoardEntity(id: entityId, dbfId: dbfId, cardId: cardId))
            next.opponentPublic.append(PublicCard(dbfId: dbfId, cardId: cardId))
        case .boardLeave(let entityId):
            next.friendlyBoard.removeAll { $0.id == entityId }
            next.opponentBoard.removeAll { $0.id == entityId }
        }
        return next
    }
}

private func upsert(_ board: inout [BoardEntity], _ entity: BoardEntity) {
    if let index = board.firstIndex(where: { $0.id == entity.id }) {
        board[index] = entity
    } else {
        board.append(entity)
    }
}
