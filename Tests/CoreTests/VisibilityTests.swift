import GameState
import LogReader
import Testing
import Visibility

struct VisibilityTests {
    @Test func opponentHandNeverLeavesFilter() {
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=64 CardID=CS2_029",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
            "D 00:00:01.3 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=80 CardID=EX1_116",
            "D 00:00:01.4 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:01.5 GameState.DebugPrintPower() -     tag=CONTROLLER value=2",
        ]
        let state = SpikePipeline.ingest(
            lines: lines,
            source: .power,
            state: GameState(friendlyControllerID: 1)
        )
        let published = SpikePipeline.published(state)

        #expect(published.entities.contains { $0.id == 64 && $0.cardID == "CS2_029" && $0.zone == .hand })
        #expect(!published.entities.contains { $0.id == 80 })
        #expect(!published.entities.contains { $0.cardID == "EX1_116" })
    }

    @Test func opponentCardVisibleAfterPlay() {
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=80 CardID=EX1_116",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=2",
            "D 00:00:02.0 GameState.DebugPrintPower() - SHOW_ENTITY - Updating Entity=80 CardID=EX1_116",
            "D 00:00:02.1 GameState.DebugPrintPower() -     tag=ZONE value=PLAY",
        ]
        let state = SpikePipeline.ingest(
            lines: lines,
            source: .power,
            state: GameState(friendlyControllerID: 1)
        )
        let published = SpikePipeline.published(state)
        #expect(published.entities.contains { $0.id == 80 && $0.cardID == "EX1_116" && $0.zone == .play })
    }

    @Test func redactDropsAccountIdentifiers() {
        let line = "Player EntityID=2 PlayerID=1 PlayerName=Foo#1234 GameAccountId=[hi=99 lo=88]"
        let clean = Visibility.redact(line)
        #expect(!clean.contains("Foo"))
        #expect(!clean.contains("#1234"))
        #expect(!clean.contains("99"))
        #expect(!clean.contains("88"))
        #expect(clean.contains("REDACTED"))
    }

    @Test func unknownFriendlyHidesHands() {
        let lines = [
            "D 00:00:01.0 GameState.DebugPrintPower() - FULL_ENTITY - Creating ID=64 CardID=CS2_029",
            "D 00:00:01.1 GameState.DebugPrintPower() -     tag=ZONE value=HAND",
            "D 00:00:01.2 GameState.DebugPrintPower() -     tag=CONTROLLER value=1",
        ]
        let published = SpikePipeline.published(SpikePipeline.ingest(lines: lines, source: .power))
        #expect(published.entities.isEmpty)
    }
}
