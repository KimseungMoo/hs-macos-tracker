import XCTest
@testable import HSMacOSTrackerLib

final class AdviceEngineTests: XCTestCase {
    func testUnusedManaKnownOnly() {
        XCTAssertEqual(AdviceEngine.unusedMana(mana: 6, used: 4), 2)
        XCTAssertNil(AdviceEngine.unusedMana(mana: 6, used: nil))
        XCTAssertNil(AdviceEngine.unusedMana(mana: nil, used: 2))
    }

    func testLethalNeedsBothNumbers() {
        XCTAssertEqual(
            AdviceEngine.lethal(friendlyFaceDamage: 8, opponentHealth: 6),
            "lethal possible (8 >= 6)"
        )
        XCTAssertNil(AdviceEngine.lethal(friendlyFaceDamage: 5, opponentHealth: 12))
        XCTAssertNil(AdviceEngine.lethal(friendlyFaceDamage: nil, opponentHealth: 6))
        XCTAssertNil(AdviceEngine.lethal(friendlyFaceDamage: 8, opponentHealth: nil))
    }

    func testRemindersFromPublicView() {
        var state = MatchState()
        state = MatchState.reduce(state, .importDeck([9: 2, 10: 8]))
        state = MatchState.reduce(state, .friendlyResources(available: 5, used: 3))
        state = MatchState.reduce(
            state,
            .opponentPlay(entityId: 40, dbfId: 1, cardId: "CS2_122")
        )
        let catalog = CardCatalog(cards: [CardInfo(dbfId: 9, cardId: "CS2_029", name: "Fireball")])
        let view = PublicMatchView.project(state, catalog: catalog)
        let lines = AdviceEngine.lines(from: view)
        let texts = lines.map(\.text)
        XCTAssertTrue(texts.contains("unused mana 2"))
        XCTAssertTrue(texts.contains("public threats 1 on board"))
        XCTAssertTrue(texts.contains("removal reminder (public board)"))
        XCTAssertTrue(texts.contains(where: { $0.contains("next draw Fireball") }))
        XCTAssertFalse(texts.contains(where: { $0.lowercased().contains("play ") }))
    }

    func testNoLethalGuessWithoutHealth() {
        let view = PublicMatchView.project(MatchState(), catalog: .empty)
        let lines = AdviceEngine.lines(from: view, opponentHeroHealth: nil, friendlyFaceDamage: 10)
        XCTAssertFalse(lines.contains(where: { $0.id == "lethal" }))
    }
}
