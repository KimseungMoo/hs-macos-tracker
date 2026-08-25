import Foundation

public struct LogDiscovery: Equatable, Sendable {
    public let directory: URL
    public let powerLog: URL
    public let arenaLog: URL
    public let loadingScreenLog: URL

    public init(directory: URL, powerLog: URL, arenaLog: URL, loadingScreenLog: URL) {
        self.directory = directory
        self.powerLog = powerLog
        self.arenaLog = arenaLog
        self.loadingScreenLog = loadingScreenLog
    }
}

public enum LogPaths {
    public static func candidateDirectories() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Library/Logs/Hearthstone", isDirectory: true),
            home.appendingPathComponent("Library/Logs/Blizzard Entertainment/Hearthstone", isDirectory: true),
        ]
    }

    /// Returns a directory only when `Power.log` exists. Does not guess alternate layouts.
    public static func discover() -> LogDiscovery? {
        for directory in candidateDirectories() {
            let powerLog = directory.appendingPathComponent("Power.log")
            guard FileManager.default.fileExists(atPath: powerLog.path) else { continue }
            return LogDiscovery(
                directory: directory,
                powerLog: powerLog,
                arenaLog: directory.appendingPathComponent("Arena.log"),
                loadingScreenLog: directory.appendingPathComponent("LoadingScreen.log")
            )
        }
        return nil
    }
}
