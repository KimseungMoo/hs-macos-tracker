import XCTest
@testable import HSMacOSTrackerLib

final class DeckstringTests: XCTestCase {
    func testRoundTripCounts() throws {
        let original = ImportedDeck(
            format: 2,
            heroes: [7],
            counts: [101: 1, 202: 2, 303: 1]
        )
        let decoded = try Deckstring.decode(Deckstring.encode(original))
        XCTAssertEqual(decoded.format, 2)
        XCTAssertEqual(decoded.heroes, [7])
        XCTAssertEqual(decoded.counts, original.counts)
        XCTAssertEqual(decoded.totalCards, 4)
    }

    func testInvalidBase64() {
        XCTAssertThrowsError(try Deckstring.decode("not-a-deck"))
    }
}

final class DrawOddsTests: XCTestCase {
    func testTwoOfTwenty() {
        XCTAssertEqual(DrawOdds.nextDraw(count: 2, remaining: 20), 0.1)
    }

    func testUnknownWhenEmpty() {
        XCTAssertNil(DrawOdds.nextDraw(count: 1, remaining: 0))
    }

    func testRejectsCountAboveRemaining() {
        XCTAssertNil(DrawOdds.nextDraw(count: 3, remaining: 2))
    }
}

final class MatchStateTests: XCTestCase {
    func testDrawDecrementsAndOdds() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([315: 2, 100: 18]))
        state = MatchState.reduce(state, .friendlyDraw(dbfId: 315))
        XCTAssertTrue(state.remainingKnown)
        XCTAssertEqual(state.remaining[315], 1)
        XCTAssertEqual(state.remainingTotal, 19)
        XCTAssertEqual(DrawOdds.nextDraw(count: 1, remaining: 19), 1.0 / 19.0)
    }

    func testUnknownCardDrawFailsClosed() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([315: 2]))
        state = MatchState.reduce(state, .friendlyDraw(dbfId: nil))
        XCTAssertFalse(state.remainingKnown)
        XCTAssertEqual(state.remaining, [:])
    }

    func testGapClearsRemaining() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([1: 30]))
        state = MatchState.reduce(state, .gap)
        XCTAssertFalse(state.remainingKnown)
        XCTAssertEqual(state.remaining, [:])
    }

    func testGameResetRestoresImported() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([8: 2]))
        state = MatchState.reduce(state, .friendlyDraw(dbfId: 8))
        state = MatchState.reduce(state, .gameReset)
        XCTAssertEqual(state.remaining[8], 2)
        XCTAssertTrue(state.remainingKnown)
        XCTAssertTrue(state.opponentPublic.isEmpty)
    }
}

final class PublicViewTests: XCTestCase {
    func testProjectsKnownRemaining() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([9: 2]))
        let catalog = CardCatalog(cards: [CardInfo(dbfId: 9, cardId: "CS2_029", name: "Fireball")])
        let view = PublicMatchView.project(state, catalog: catalog)
        XCTAssertTrue(view.remainingKnown)
        XCTAssertEqual(view.remainingRows.first?.name, "Fireball")
        XCTAssertEqual(view.remainingRows.first?.nextDraw, 1.0)
    }

    func testUnknownHidesRows() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([9: 2]))
        state = MatchState.reduce(state, .gap)
        let view = PublicMatchView.project(state, catalog: .empty)
        XCTAssertFalse(view.remainingKnown)
        XCTAssertTrue(view.remainingRows.isEmpty)
    }
}

final class PowerLogParserTests: XCTestCase {
    private let catalog = CardCatalog(cards: [
        CardInfo(dbfId: 315, cardId: "CS2_029", name: "Fireball"),
        CardInfo(dbfId: 662, cardId: "EX1_169", name: "Innervate"),
    ])

    func testTurnAndFriendlyDrawFromShowEntity() {
        var parser = PowerLogParser(catalog: catalog)
        var events: [GameEvent] = []
        let lines = [
            "D 00:00:00.0000000 GameState.DebugPrintGame() - PlayerID=1, PlayerName=Sunmoo",
            "D 00:00:00.0000000 GameState.DebugPrintGame() - PlayerID=2, PlayerName=UNKNOWN HUMAN PLAYER",
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() - TAG_CHANGE Entity=GameEntity tag=TURN value=3",
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() - SHOW_ENTITY - Updating Entity=[entityName=UNKNOWN ENTITY id=15 zone=DECK zonePos=0 cardId= player=1] CardID=CS2_029",
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() -     tag=ZONE value=HAND",
        ]
        for line in lines {
            events.append(contentsOf: parser.feed(line))
        }
        XCTAssertEqual(
            events,
            [
                .setFriendlyPlayer(1),
                .turn(3),
                .friendlyDraw(dbfId: 315),
            ]
        )
    }

    func testOpponentPlayIsPublic() {
        var parser = PowerLogParser(catalog: catalog, friendlyPlayerId: 1)
        let events = parser.feed(
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() - SHOW_ENTITY - Updating Entity=[entityName=UNKNOWN ENTITY id=40 zone=HAND zonePos=1 cardId= player=2] CardID=EX1_169 tag=ZONE value=PLAY"
        )
        XCTAssertEqual(events, [.opponentPlay(entityId: 40, dbfId: 662, cardId: "EX1_169")])
    }

    func testUnmappedDrawIsNilDbfId() {
        var parser = PowerLogParser(catalog: catalog, friendlyPlayerId: 1)
        _ = parser.feed(
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() - SHOW_ENTITY - Updating Entity=[entityName=UNKNOWN ENTITY id=16 zone=DECK zonePos=0 cardId= player=1] CardID=NEW_CARD"
        )
        let events = parser.feed(
            "D 00:00:00.0000000 PowerTaskList.DebugPrintPower() -     tag=ZONE value=HAND"
        )
        XCTAssertEqual(events, [.friendlyDraw(dbfId: nil)])
    }

    func testDoesNotReadGameStateHiddenPower() {
        var parser = PowerLogParser(catalog: catalog, friendlyPlayerId: 1)
        let events = parser.feed(
            "D 00:00:00.0000000 GameState.DebugPrintPower() - SHOW_ENTITY - Updating Entity=[entityName=UNKNOWN ENTITY id=99 zone=DECK cardId= player=2] CardID=CS2_029"
        )
        XCTAssertTrue(events.isEmpty)
    }
}
