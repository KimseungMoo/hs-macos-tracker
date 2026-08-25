import GameState
import Visibility

public enum SpikePipeline {
    public static func ingest(
        lines: [String],
        source: LogSource,
        state: GameState = GameState()
    ) -> GameState {
        var parser = LogParser()
        var state = state
        for line in lines {
            let clean = Visibility.redact(line)
            for event in parser.parse(clean, source: source) {
                state = state.applying(event)
            }
        }
        return state
    }

    public static func published(_ state: GameState) -> PublicState {
        Visibility.filter(state)
    }
}
