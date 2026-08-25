import Advice
import Arena
import CardCatalog
import GameState
import LogReader
import Testing
import Tracker
import Visibility

struct TrackerArenaAdviceTests {
    @Test func deckstringRoundTrip() throws {
        let cards = [DeckCard(dbfId: 315, count: 2), DeckCard(dbfId: 559, count: 1)]
        let code = Deckstring.encode(cards, heroDbfId: 637)
        let decoded = try Deckstring.decode(code)
        #expect(decoded.sorted { $0.dbfId < $1.dbfId } == cards.sorted { $0.dbfId < $1.dbfId })
    }

    @Test func remainingSubtractsFriendlyDrawnCards() throws {
        let catalog = try CatalogSupport.catalog()
        let deck = Deckstring.resolve(
            [DeckCard(dbfId: 315, count: 2), DeckCard(dbfId: 559, count: 1)],
            catalog: catalog
        )
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=64 CardID=CS2_029",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
        ]
        let state = SpikePipeline.ingest(
            lines: lines,
            source: .power,
            state: GameState(friendlyControllerID: 1, decklist: deck)
        )
        let remaining = Tracker.remaining(from: SpikePipeline.published(state), catalog: catalog)
        #expect(remaining.first { $0.cardID == "CS2_029" }?.remaining == 1)
        #expect(remaining.first { $0.cardID == "EX1_116" }?.remaining == 1)
    }

    @Test func manaAndHeroFromPublicTags() {
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=2 CardID=HERO_08",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=CARDTYPE value=HERO",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:01.3 GameState.DebugPrintPower() -     tag=HEALTH value=30",
            "D 00:00:01.4 GameState.DebugPrintPower() -     tag=DAMAGE value=6",
            "D 00:00:01.5 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=3 CardID=",
            "D 00:00:01.6 GameState.DebugPrintPower() -     tag=CARDTYPE value=PLAYER",
            "D 00:00:01.7 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:01.8 GameState.DebugPrintPower() -     tag=RESOURCES value=7",
            "D 00:00:01.9 GameState.DebugPrintPower() -     tag=RESOURCES_USED value=2",
            "D 00:00:02.0 GameState.DebugPrintPower() - TAG_CHANGE Entity=GameEntity tag=TURN value=7",
        ]
        let published = SpikePipeline.published(
            SpikePipeline.ingest(lines: lines, source: .power, state: GameState(friendlyControllerID: 1))
        )
        #expect(published.turn == 7)
        #expect(published.friendlyHeroHealth == 24)
        #expect(published.friendlyMana == 7)
        #expect(published.friendlyManaLeft == 5)
    }

    @Test func arenaPickAndReset() {
        let lines = [
            "D 00:00:01.0 DraftManager.OnChoicesAndContents() - cardid=REV_840",
            "D 00:00:01.1 DraftManager.OnChosen(): cardid=REV_840",
            "D 00:00:01.2 DraftManager.OnBegin()",
            "D 00:00:01.3 DraftManager.OnChoicesAndContents() - cardid=KAR_062",
        ]
        let state = SpikePipeline.ingest(lines: lines, source: .arena)
        #expect(state.draft.picked.map(\.nameOrID) == ["REV_840"])
        #expect(state.draft.offered.map(\.nameOrID) == ["KAR_062"])
    }

    @Test func arenaStaysDisabledOnReleaseFlags() throws {
        let catalog = try CatalogSupport.catalog()
        let draft = try DraftInput.manual(["화염구", "얼음 화살", "얼음 방패"])
        let decision = ArenaAdvisor.recommend(
            draft: draft,
            catalog: catalog,
            build: .pinned("216414")
        )
        #expect(decision == .disabled)
    }

    @Test func arenaFailClosedOnUnknownBuild() throws {
        let catalog = try CatalogSupport.catalog()
        let draft = try DraftInput.manual(["화염구", "얼음 화살", "얼음 방패"])
        let decision = ArenaAdvisor.recommend(
            draft: draft,
            catalog: catalog,
            build: .unknown,
            flags: RuntimeFlags(arenaRecommendations: true)
        )
        #expect(decision == .failClosed("unknown or mismatched build"))
    }

    @Test func arenaRecommendHighConfidenceOnly() throws {
        let catalog = try CatalogSupport.catalog()
        let draft = try DraftInput.manual(["황천의 원령 역사가", "얼음 방패", "죽음의 혈통"])
        let decision = ArenaAdvisor.recommend(
            draft: draft,
            catalog: catalog,
            build: .pinned("216414"),
            flags: RuntimeFlags(arenaRecommendations: true)
        )
        guard case .pick(let choice, _, _, _) = decision else {
            Issue.record("expected pick, got \(decision)")
            return
        }
        #expect(choice.nameOrID == "황천의 원령 역사가")
    }

    @Test func lethalAndUnusedManaAdvice() throws {
        let catalog = try CatalogSupport.catalog()
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=10 CardID=EX1_116",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=ZONE value=PLAY",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:01.3 GameState.DebugPrintPower() -     tag=CARDTYPE value=MINION",
            "D 00:00:01.4 GameState.DebugPrintPower() -     tag=ATK value=6",
            "D 00:00:01.5 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=11 CardID=HERO_02",
            "D 00:00:01.6 GameState.DebugPrintPower() -     tag=CARDTYPE value=HERO",
            "D 00:00:01.7 GameState.DebugPrintPower() -     tag=CONTROLLER value=2",
            "D 00:00:01.8 GameState.DebugPrintPower() -     tag=HEALTH value=8",
            "D 00:00:01.9 GameState.DebugPrintPower() -     tag=DAMAGE value=3",
            "D 00:00:02.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=12 CardID=CS2_029",
            "D 00:00:02.1 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:02.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:02.3 GameState.DebugPrintPower() -     tag=COST value=4",
            "D 00:00:02.4 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=3 CardID=",
            "D 00:00:02.5 GameState.DebugPrintPower() -     tag=CARDTYPE value=PLAYER",
            "D 00:00:02.6 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:02.7 GameState.DebugPrintPower() -     tag=RESOURCES value=6",
            "D 00:00:02.8 GameState.DebugPrintPower() -     tag=RESOURCES_USED value=1",
        ]
        let published = SpikePipeline.published(
            SpikePipeline.ingest(lines: lines, source: .power, state: GameState(friendlyControllerID: 1))
        )
        let facts = Advice.items(from: published, catalog: catalog)
        #expect(facts.contains { $0.kind == .lethal })
        #expect(facts.contains { $0.kind == .unusedMana })
        #expect(facts.contains { $0.kind == .publicRemoval })
        #expect(!facts.contains { $0.kind == .prescriptive })

        let scripted = Advice.items(
            from: published,
            catalog: catalog,
            flags: RuntimeFlags(prescriptiveAdvice: true)
        )
        #expect(scripted.contains { $0.kind == .prescriptive })
    }
}
