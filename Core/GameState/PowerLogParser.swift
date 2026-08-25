import Foundation

/// Conservative Power.log reader. PowerTaskList + DebugPrintGame only. Hidden zones stay unknown.
public struct PowerLogParser: Sendable {
    public var catalog: CardCatalog
    public var friendlyPlayerId: Int?

    private var entityZone: [Int: String] = [:]
    private var entityPlayer: [Int: Int] = [:]
    private var playerNames: [Int: String] = [:]
    private var pendingShow: (entityId: Int, cardId: String, player: Int?, fromZone: String?)?

    public init(catalog: CardCatalog = .empty, friendlyPlayerId: Int? = nil) {
        self.catalog = catalog
        self.friendlyPlayerId = friendlyPlayerId
    }

    public mutating func resetEntities() {
        entityZone = [:]
        entityPlayer = [:]
        playerNames = [:]
        pendingShow = nil
    }

    public mutating func feed(_ line: String) -> [GameEvent] {
        if let event = parsePlayerName(line) {
            return [event]
        }
        guard let payload = powerPayload(line) else { return [] }

        if payload.contains("CREATE_GAME") {
            resetEntities()
            return [.gameReset]
        }
        if let event = parseShowEntity(payload) {
            return event.map { [$0] } ?? []
        }
        if let event = parsePendingShowTag(payload) {
            return [event]
        }
        if let events = parseTagChange(payload) {
            return events
        }
        return []
    }

    private mutating func parsePlayerName(_ line: String) -> GameEvent? {
        guard let match = firstMatch(line, #"GameState\.DebugPrintGame\(\) - PlayerID=(\d+),\s*PlayerName=(.+)$"#) else {
            return nil
        }
        let id = Int(match[0])
        let name = match[1].trimmingCharacters(in: .whitespaces)
        guard let id else { return nil }
        playerNames[id] = name
        if friendlyPlayerId == nil, let inferred = inferFriendlyPlayer() {
            friendlyPlayerId = inferred
            return .setFriendlyPlayer(inferred)
        }
        return nil
    }

    /// Only when exactly one side looks like the opponent placeholder.
    private func inferFriendlyPlayer() -> Int? {
        let unknownTokens = ["UNKNOWN HUMAN PLAYER", "UNKNOWN", "The Innkeeper"]
        let unknown = playerNames.filter { _, name in
            unknownTokens.contains(where: { name.localizedCaseInsensitiveContains($0) })
        }
        let known = playerNames.filter { id, _ in unknown[id] == nil }
        guard unknown.count == 1, known.count == 1, let id = known.keys.first else { return nil }
        return id
    }

    private func powerPayload(_ line: String) -> String? {
        guard let match = firstMatch(line, #"PowerTaskList\.DebugPrintPower\(\) - (.+)$"#) else { return nil }
        return match[0]
    }

    private mutating func parseShowEntity(_ payload: String) -> GameEvent?? {
        guard let match = firstMatch(payload, #"SHOW_ENTITY - Updating Entity=\[(.*?)\] CardID=(\S+)"#) else {
            return nil
        }
        let blob = match[0]
        let cardId = match[1]
        guard let entityId = intField(blob, "id") else { return .some(nil) }
        let player = intField(blob, "player")
        if let player { entityPlayer[entityId] = player }
        if let zone = stringField(blob, "zone") { entityZone[entityId] = zone }
        let fromZone = entityZone[entityId]
        if let toZone = firstMatch(payload, #"tag=ZONE value=(\w+)"#)?[0] {
            return .some(finishShow(entityId: entityId, cardId: cardId, player: player, fromZone: fromZone, toZone: toZone))
        }
        pendingShow = (entityId, cardId, player, fromZone)
        return .some(nil)
    }

    private mutating func parsePendingShowTag(_ payload: String) -> GameEvent? {
        let trimmed = payload.trimmingCharacters(in: .whitespaces)
        guard let pending = pendingShow else { return nil }
        if let controller = firstMatch(trimmed, #"^tag=CONTROLLER value=(\d+)"#), let player = Int(controller[0]) {
            entityPlayer[pending.entityId] = player
            pendingShow?.player = player
            return nil
        }
        guard let zone = firstMatch(trimmed, #"^tag=ZONE value=(\w+)"#) else { return nil }
        pendingShow = nil
        return finishShow(
            entityId: pending.entityId,
            cardId: pending.cardId,
            player: pending.player ?? entityPlayer[pending.entityId],
            fromZone: pending.fromZone,
            toZone: zone[0]
        )
    }

    private mutating func finishShow(entityId: Int, cardId: String, player: Int?, fromZone: String?, toZone: String) -> GameEvent? {
        entityZone[entityId] = toZone
        if let player { entityPlayer[entityId] = player }
        let dbfId = catalog.dbfId(for: cardId)
        guard let player = player ?? entityPlayer[entityId] else { return nil }
        guard let friendly = friendlyPlayerId else { return nil }

        if player == friendly, fromZone == "DECK", toZone == "HAND" {
            return .friendlyDraw(dbfId: dbfId)
        }
        if player == friendly, toZone == "PLAY" {
            return .friendlyPlay(entityId: entityId, dbfId: dbfId, cardId: cardId)
        }
        if player != friendly, toZone == "PLAY" {
            return .opponentPlay(entityId: entityId, dbfId: dbfId, cardId: cardId)
        }
        return nil
    }

    private mutating func parseTagChange(_ payload: String) -> [GameEvent]? {
        guard let match = firstMatch(payload, #"TAG_CHANGE Entity=(.+) tag=(\w+) value=(\S+)"#) else {
            return nil
        }
        let entityRaw = match[0]
        let tag = match[1]
        let value = match[2]

        if entityRaw == "GameEntity" || entityRaw.hasPrefix("GameEntity") {
            if tag == "TURN", let turn = Int(value) {
                return [.turn(turn)]
            }
            return nil
        }

        let entityId = intField(entityRaw, "id") ?? Int(entityRaw)
        if let entityId, let player = intField(entityRaw, "player") {
            entityPlayer[entityId] = player
        }
        if let entityId, let zone = stringField(entityRaw, "zone") {
            entityZone[entityId] = zone
        }

        if tag == "RESOURCES" || tag == "RESOURCES_USED" {
            return parseResources(entityRaw: entityRaw, tag: tag, value: value)
        }

        if tag == "ZONE", let entityId {
            let from = entityZone[entityId]
            entityZone[entityId] = value
            return parseZoneChange(entityId: entityId, entityRaw: entityRaw, from: from, to: value)
        }
        return nil
    }

    private func parseResources(entityRaw: String, tag: String, value: String) -> [GameEvent]? {
        guard let friendly = friendlyPlayerId else { return nil }
        let player = intField(entityRaw, "player") ?? entityPlayer[intField(entityRaw, "id") ?? -1]
        guard player == friendly, let amount = Int(value) else { return nil }
        if tag == "RESOURCES" {
            return [.friendlyResources(available: amount, used: nil)]
        }
        return [.friendlyResources(available: nil, used: amount)]
    }

    private mutating func parseZoneChange(entityId: Int, entityRaw: String, from: String?, to: String) -> [GameEvent]? {
        let player = intField(entityRaw, "player") ?? entityPlayer[entityId]
        let cardId = stringField(entityRaw, "cardId").flatMap { $0.isEmpty ? nil : $0 }
        let dbfId = cardId.flatMap { catalog.dbfId(for: $0) }
        guard let player else { return nil }

        if to == "GRAVEYARD" || to == "REMOVEDFROMGAME" || to == "SETASIDE" {
            return [.boardLeave(entityId: entityId)]
        }

        guard let friendly = friendlyPlayerId else { return nil }

        if player == friendly, from == "DECK", to == "HAND" {
            return [.friendlyDraw(dbfId: dbfId)]
        }
        if player == friendly, to == "PLAY" {
            return [.friendlyPlay(entityId: entityId, dbfId: dbfId, cardId: cardId)]
        }
        if player != friendly, to == "PLAY" {
            return [.opponentPlay(entityId: entityId, dbfId: dbfId, cardId: cardId)]
        }
        return nil
    }
}

private func intField(_ blob: String, _ key: String) -> Int? {
    guard let text = stringField(blob, key), let value = Int(text) else { return nil }
    return value
}

private func stringField(_ blob: String, _ key: String) -> String? {
    firstMatch(blob, #"\#(key)=(\S+)"#)?[0]
}

private func firstMatch(_ text: String, _ pattern: String) -> [String]? {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range) else { return nil }
    var parts: [String] = []
    for index in 1..<match.numberOfRanges {
        guard let capture = Range(match.range(at: index), in: text) else { return nil }
        parts.append(String(text[capture]))
    }
    return parts
}
