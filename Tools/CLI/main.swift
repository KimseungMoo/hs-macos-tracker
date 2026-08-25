import Advice
import Arena
import CardCatalog
import Foundation
import GameState
import LogReader
import Tracker
import Visibility

#if canImport(Glibc)
import Glibc
#endif
#if canImport(Darwin)
import Darwin
#endif

@main
enum HSCore {
    static func main() {
        do {
            try run(arguments: CommandLine.arguments)
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(1)
        }
    }

    static func run(arguments: [String]) throws {
        let args = Args.parse(arguments)
        if args.help || args.isEmpty {
            FileHandle.standardError.write(
                Data(
                    """
                    usage: hs-core [--power FILE] [--arena FILE] [--loading FILE] [--deck CODE] [--catalog FILE] [--scores FILE] [--pick a|b|c] [--friendly N] [--enable-arena] [--enable-prescriptive]
                    """.utf8
                )
            )
            FileHandle.standardError.write(Data("\n".utf8))
            exit(args.help ? 0 : 2)
        }

        var state = GameState(friendlyControllerID: args.friendly)
        if let loading = args.loading {
            state = SpikePipeline.ingest(lines: try lines(at: loading), source: .loadingScreen, state: state)
        }
        if let arena = args.arena {
            state = SpikePipeline.ingest(lines: try lines(at: arena), source: .arena, state: state)
        }
        if let power = args.power {
            state = SpikePipeline.ingest(lines: try lines(at: power), source: .power, state: state)
        }
        if let pick = args.pick {
            state = try state.applyingManualDraft(pick)
        }

        let catalog = try args.catalog.map { try CardCatalog.load(from: $0) }
        if let code = args.deck {
            let decoded = try Deckstring.decode(code)
            state = state.applyingDecklist(Deckstring.resolve(decoded, catalog: catalog ?? CardCatalog(pack: CardPack(build: "none", cards: []))))
        } else if state.decklist.isEmpty, let catalog, !state.draft.picked.isEmpty {
            state = state.applyingDecklist(Tracker.decklist(from: state.draft.picked, catalog: catalog))
        }

        let published = SpikePipeline.published(state)
        let flags = RuntimeFlags(
            arenaRecommendations: args.enableArena,
            prescriptiveAdvice: args.enablePrescriptive
        )
        let scores = try args.scores.map { try UserScores.load(from: $0) } ?? [:]
        let arena: ArenaDecision = {
            guard let catalog else { return .failClosed("no catalog") }
            return ArenaAdvisor.recommend(
                draft: published.draft,
                catalog: catalog,
                build: published.build,
                scores: scores,
                flags: flags
            )
        }()

        let report = Report(
            build: published.build.pinnedValue ?? "unknown",
            turn: published.turn,
            manaLeft: published.friendlyManaLeft,
            tracker: Tracker.snapshot(from: published, catalog: catalog),
            advice: Advice.items(from: published, catalog: catalog, flags: flags),
            arena: arena
        )
        let data = try JSONEncoder.pretty.encode(report)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }

    static func lines(at url: URL) throws -> [String] {
        try String(contentsOf: url, encoding: .utf8)
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
    }
}

struct Args {
    var power: URL?
    var arena: URL?
    var loading: URL?
    var deck: String?
    var catalog: URL?
    var scores: URL?
    var pick: [String]?
    var friendly = 1
    var enableArena = false
    var enablePrescriptive = false
    var help = false

    var isEmpty: Bool {
        power == nil && arena == nil && loading == nil && deck == nil && pick == nil && catalog == nil
    }

    static func parse(_ argv: [String]) -> Args {
        var args = Args()
        var index = 1
        while index < argv.count {
            let item = argv[index]
            switch item {
            case "--help", "-h":
                args.help = true
            case "--enable-arena":
                args.enableArena = true
            case "--enable-prescriptive":
                args.enablePrescriptive = true
            case "--power":
                args.power = url(argv, &index)
            case "--arena":
                args.arena = url(argv, &index)
            case "--loading":
                args.loading = url(argv, &index)
            case "--deck":
                args.deck = value(argv, &index)
            case "--catalog":
                args.catalog = url(argv, &index)
            case "--scores":
                args.scores = url(argv, &index)
            case "--pick":
                args.pick = value(argv, &index)?.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            case "--friendly":
                args.friendly = Int(value(argv, &index) ?? "") ?? 1
            default:
                break
            }
            index += 1
        }
        return args
    }

    private static func value(_ argv: [String], _ index: inout Int) -> String? {
        index += 1
        return index < argv.count ? argv[index] : nil
    }

    private static func url(_ argv: [String], _ index: inout Int) -> URL? {
        value(argv, &index).map { URL(fileURLWithPath: $0) }
    }
}

struct Report: Encodable {
    var build: String
    var turn: Int?
    var manaLeft: Int?
    var tracker: TrackerSnapshot
    var advice: [AdviceItem]
    var arena: ArenaDecision
}

extension ArenaDecision: Encodable {
    enum CodingKeys: String, CodingKey {
        case status, reason, choice, runnerUp, scores
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .disabled:
            try container.encode("disabled", forKey: .status)
        case .failClosed(let reason):
            try container.encode("failClosed", forKey: .status)
            try container.encode(reason, forKey: .reason)
        case .pick(let choice, let runnerUp, let reason, let scores):
            try container.encode("pick", forKey: .status)
            try container.encode(choice.nameOrID, forKey: .choice)
            try container.encodeIfPresent(runnerUp?.nameOrID, forKey: .runnerUp)
            try container.encode(reason, forKey: .reason)
            try container.encode(scores, forKey: .scores)
        }
    }
}

extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
