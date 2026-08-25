import Dispatch
import Foundation

public final class LogTailReader: @unchecked Sendable {
    public typealias LineHandler = @Sendable (String) -> Void

    private let url: URL
    private let queue = DispatchQueue(label: "io.hs-macos-tracker.log-tail")
    private var handle: FileHandle?
    private var offset: UInt64 = 0
    private var lineBuffer = LogLineBuffer()
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private var reconnectTimer: DispatchSourceTimer?
    private var deviceIdentifier: (dev: UInt64, ino: UInt64)?

    public var onLine: LineHandler?

    public init(url: URL) {
        self.url = url
    }

    deinit {
        stop()
    }

    public func start() {
        queue.async { [self] in
            self.openOrReconnect(force: true, readFromStart: false)
            self.scheduleReconnectIfNeeded()
        }
    }

    public func stop() {
        queue.sync {
            fileSystemSource?.cancel()
            fileSystemSource = nil
            reconnectTimer?.cancel()
            reconnectTimer = nil
            try? handle?.close()
            handle = nil
            deviceIdentifier = nil
        }
    }

    /// Reads any newly appended bytes. Safe to call from tests on the reader queue.
    public func readAvailableForTesting() {
        queue.sync {
            openOrReconnect(force: false, readFromStart: false)
            readAvailable()
        }
    }

    public func bootstrapForTesting() {
        queue.sync {
            openOrReconnect(force: true, readFromStart: false)
        }
    }

    public func reopenFromStartForTesting() {
        queue.sync {
            closeHandle()
            openOrReconnect(force: true, readFromStart: true)
        }
    }

    private func openOrReconnect(force: Bool, readFromStart: Bool = false) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            closeHandle()
            return
        }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let sizeNumber = attrs[.size] as? NSNumber,
              let systemFileNumber = attrs[.systemFileNumber] as? NSNumber,
              let systemNumber = attrs[.systemNumber] as? NSNumber
        else {
            closeHandle()
            return
        }

        let identity = (dev: systemNumber.uint64Value, ino: systemFileNumber.uint64Value)
        let size = sizeNumber.uint64Value

        if let previous = deviceIdentifier, previous != identity {
            closeHandle()
            openOrReconnect(force: true, readFromStart: true)
            return
        }

        if force || deviceIdentifier == nil {
            closeHandle()
            guard let newHandle = FileHandle(forReadingAtPath: url.path) else { return }
            handle = newHandle
            deviceIdentifier = identity
            offset = readFromStart ? 0 : size
            lineBuffer = LogLineBuffer()
            installWatch(on: newHandle)
            if offset < size {
                readAvailable()
            }
            return
        }

        if size < offset {
            closeHandle()
            openOrReconnect(force: true, readFromStart: true)
            return
        }

        readAvailable()
    }

    private func readAvailable() {
        guard let handle else { return }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let sizeNumber = attrs[.size] as? NSNumber
        else { return }

        let size = sizeNumber.uint64Value
        if size < offset {
            closeHandle()
            openOrReconnect(force: true, readFromStart: true)
            return
        }
        guard size > offset else { return }

        do {
            try handle.seek(toOffset: offset)
            let data = try handle.read(upToCount: Int(size - offset)) ?? Data()
            offset += UInt64(data.count)
            guard let chunk = String(data: data, encoding: .utf8) else { return }
            emitLines(lineBuffer.append(chunk))
        } catch {
            closeHandle()
        }
    }

    private func emitLines(_ lines: [String]) {
        guard let onLine else { return }
        for line in lines where !line.isEmpty {
            onLine(line)
        }
    }

    private func installWatch(on handle: FileHandle) {
        fileSystemSource?.cancel()
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: handle.fileDescriptor,
            eventMask: [.extend, .delete, .rename, .revoke],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = source.data
            if event.contains(.delete) || event.contains(.rename) || event.contains(.revoke) {
                self.closeHandle()
                self.scheduleReconnectIfNeeded()
                return
            }
            self.openOrReconnect(force: false, readFromStart: false)
        }
        source.setCancelHandler { [weak handle] in
            // Keep handle alive until source cancels.
            _ = handle
        }
        source.resume()
        fileSystemSource = source
    }

    private func scheduleReconnectIfNeeded() {
        guard handle == nil else {
            reconnectTimer?.cancel()
            reconnectTimer = nil
            return
        }
        guard reconnectTimer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.openOrReconnect(force: true, readFromStart: false)
            self?.readAvailable()
            if self?.handle != nil {
                self?.reconnectTimer?.cancel()
                self?.reconnectTimer = nil
            }
        }
        timer.resume()
        reconnectTimer = timer
    }

    private func closeHandle() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
        try? handle?.close()
        handle = nil
        deviceIdentifier = nil
    }
}
