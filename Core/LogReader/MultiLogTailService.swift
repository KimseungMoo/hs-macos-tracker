import Foundation
import SwiftUI

@MainActor
public final class MultiLogTailService: ObservableObject {
    @Published public private(set) var recentLines: [String] = []
    @Published public private(set) var lineCounts: [String: Int] = [:]

    public var onPowerLine: ((String) -> Void)?
    public var onArenaLine: ((String) -> Void)?

    private var readers: [LogTailReader] = []
    private let maxRecentLines = 50

    public init() {}

    public func start(discovery: LogDiscovery) {
        stop()
        let files: [(String, URL)] = [
            ("Power.log", discovery.powerLog),
            ("Arena.log", discovery.arenaLog),
            ("LoadingScreen.log", discovery.loadingScreenLog),
        ]
        readers = files.map { label, url in
            let reader = LogTailReader(url: url)
            reader.onLine = { [weak self] line in
                Task { @MainActor in
                    self?.appendLine("[\(label)] \(line)")
                    self?.lineCounts[label, default: 0] += 1
                    if label == "Power.log" {
                        self?.onPowerLine?(line)
                    }
                    if label == "Arena.log" || label == "LoadingScreen.log" {
                        self?.onArenaLine?(line)
                    }
                }
            }
            reader.start()
            return reader
        }
    }

    public func stop() {
        readers.forEach { $0.stop() }
        readers = []
    }

    private func appendLine(_ line: String) {
        recentLines.append(line)
        if recentLines.count > maxRecentLines {
            recentLines.removeFirst(recentLines.count - maxRecentLines)
        }
    }
}
