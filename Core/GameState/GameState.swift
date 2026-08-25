public struct GameState: Equatable, Sendable {
    public var entities: [Int: Entity]
    public var friendlyControllerID: Int?
    public var turn: Int?
    public var build: BuildRef
    public var draft: DraftState
    public var decklist: [DeckCard]

    public init(
        entities: [Int: Entity] = [:],
        friendlyControllerID: Int? = nil,
        turn: Int? = nil,
        build: BuildRef = .unknown,
        draft: DraftState = DraftState(),
        decklist: [DeckCard] = []
    ) {
        self.entities = entities
        self.friendlyControllerID = friendlyControllerID
        self.turn = turn
        self.build = build
        self.draft = draft
        self.decklist = decklist
    }

    public func applying(_ event: RawEvent) -> GameState {
        var next = self
        switch event {
        case .gameCreate:
            next.entities = [:]
            next.turn = nil
        case .fullEntity(let id, let cardID):
            var entity = next.entities[id] ?? Entity(id: id)
            if let cardID {
                entity.cardID = cardID
            }
            next.entities[id] = entity
        case .showEntity(let id, let cardID):
            var entity = next.entities[id] ?? Entity(id: id)
            entity.cardID = cardID
            if entity.zone.isPublic {
                entity.publiclyRevealed = true
            }
            next.entities[id] = entity
        case .tag(let id, let name, let value):
            next.applyTag(entityID: id, name: name, value: value)
        case .tagChange(let id, let name, let value):
            if let id {
                next.applyTag(entityID: id, name: name, value: value)
            } else if name.uppercased() == "TURN" {
                next.turn = Int(value)
            }
        case .arenaReset:
            next.draft.offered = []
        case .arenaCard(let card):
            next.draft.offered.append(
                DraftCard(nameOrID: card, source: .arenaLog, confidence: .low)
            )
        case .arenaPick(let card):
            next.draft.picked.append(
                DraftCard(nameOrID: card, source: .arenaLog, confidence: .low)
            )
        case .build(let build):
            next.build = .pinned(build)
        }
        return next
    }

    public func applyingManualDraft(_ cards: [String]) throws -> GameState {
        var next = self
        next.draft = try DraftInput.manual(cards)
        return next
    }

    public func applyingDecklist(_ cards: [DeckCard]) -> GameState {
        var next = self
        next.decklist = cards
        return next
    }

    private mutating func applyTag(entityID: Int, name: String, value: String) {
        var entity = entities[entityID] ?? Entity(id: entityID)
        switch name.uppercased() {
        case "ZONE":
            entity.zone = Zone.parse(value)
            if entity.zone.isPublic, entity.cardID != nil {
                entity.publiclyRevealed = true
            }
        case "CONTROLLER":
            entity.controllerID = Int(value)
        case "SECRET":
            entity.isSecret = value == "1" || value.lowercased() == "true"
        case "TURN":
            turn = Int(value)
        case "CARDTYPE":
            entity.cardType = CardType.parse(value)
        case "COST":
            entity.cost = Int(value)
        case "ATK":
            entity.attack = Int(value)
        case "HEALTH":
            entity.health = Int(value)
        case "DAMAGE":
            entity.damage = Int(value)
        case "RESOURCES":
            entity.resources = Int(value)
        case "RESOURCES_USED":
            entity.resourcesUsed = Int(value)
        case "CURRENT_PLAYER":
            entity.isCurrentPlayer = value == "1" || value.lowercased() == "true"
        default:
            break
        }
        entities[entityID] = entity
    }
}
