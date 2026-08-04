import Foundation

/// The on-disk journal schema this build reads and writes. The number has
/// been a committed claim since unit 01; ADR-0008 gives it a physical
/// meaning, and the placeholder that carried it died absorbed into this file.
public enum JournalSchema {

    /// Version named by the header record of every journal file.
    public static let version = 1
}

/// What reconstruction refuses on. ADR-0008's asymmetry: a torn tail is
/// dropped and reported, never thrown; these are the shapes with no safe
/// recovery.
public enum JournalError: Error, Equatable, Sendable {

    /// A record that fails to parse with valid records after it. Refused
    /// rather than skipped: skipping would fabricate a shorter history than
    /// the one on disk.
    case corruptRecord(line: Int)

    /// The header names a schema version this build cannot read.
    case unsupportedSchemaVersion(Int)
}

/// An append-only file of framed records: one JSON object per line, UTF-8,
/// newline-terminated, one writer, read forward from the first line. The
/// schema, its two failure shapes and its durability boundary are ADR-0008;
/// the ordering rule the file exists to serve — record before effect — is
/// ADR-0002 and INV-10.
///
/// The first record of every file is a header naming the schema version.
/// Opening replays the file forward: a torn tail — a final line that fails
/// to parse or lacks its terminator — is dropped, reported through
/// `tornTailDropped`, and truncated away so the next append cannot merge
/// with its bytes. A corrupt non-final record refuses with
/// `JournalError.corruptRecord`.
///
/// One instance holds one file handle. Nothing here enforces that a file has
/// only one live instance; that discipline belongs to the composition root.
public actor Journal<Entry: Codable & Sendable> {

    private struct Header: Codable {
        var schemaVersion: Int
    }

    private let handle: FileHandle
    private let encoder = JSONEncoder()

    /// Entries replayed from disk at open, then appended in order. Never
    /// reordered, never rewritten.
    public private(set) var entries: [Entry] = []

    /// True when opening dropped a torn tail. The drop is safe by
    /// ADR-0002's ordering: the write never returned, so the effect that
    /// follows a journal write was never started.
    public let tornTailDropped: Bool

    /// Opens the journal at `url`, creating it with a header record when it
    /// does not exist, and replays every record on disk. The location is
    /// the caller's decision; this type is platform-neutral.
    public init(url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try Data().write(to: url)
        }
        let handle = try FileHandle(forUpdating: url)
        let data = try handle.readToEnd() ?? Data()
        let replay = try Self.replay(data)

        // Complete the drop physically: bytes past the last valid record
        // are not records, and appending after them would merge two lines
        // into one corrupt record on the next open.
        try handle.truncate(atOffset: UInt64(replay.validByteCount))
        try handle.seekToEnd()
        if replay.needsHeader {
            var headerLine = try JSONEncoder().encode(Header(schemaVersion: JournalSchema.version))
            headerLine.append(Self.newline)
            try handle.write(contentsOf: headerLine)
        }

        self.handle = handle
        self.entries = replay.entries
        self.tornTailDropped = replay.tornTailDropped
    }

    deinit {
        try? handle.close()
    }

    /// Appends one entry: bytes reach the kernel before memory changes, so
    /// `entries` never claims a record the file does not hold.
    public func append(_ entry: Entry) throws {
        var line = try encoder.encode(entry)
        line.append(Self.newline)
        try handle.write(contentsOf: line)
        entries.append(entry)
    }

    /// Closes the file handle. The instance is unusable afterwards; reopen
    /// by constructing a new `Journal` on the same URL — which is exactly
    /// what a relaunch does.
    public func close() throws {
        try handle.close()
    }

    private static var newline: UInt8 { UInt8(ascii: "\n") }

    private struct Replay {
        var entries: [Entry] = []
        var tornTailDropped = false
        var needsHeader = false
        var validByteCount = 0
    }

    /// Reads the file forward, deciding every line by ADR-0008's asymmetry.
    /// Line numbers in errors are 1-based and count the header.
    private static func replay(_ data: Data) throws -> Replay {
        var lines: [(bytes: Data, terminated: Bool)] = []
        var start = data.startIndex
        for index in data.indices where data[index] == newline {
            lines.append((data[start..<index], true))
            start = data.index(after: index)
        }
        if start < data.endIndex {
            lines.append((data[start..<data.endIndex], false))
        }

        var replay = Replay()
        guard let first = lines.first else {
            replay.needsHeader = true
            return replay
        }

        let decoder = JSONDecoder()
        let header = first.terminated ? try? decoder.decode(Header.self, from: first.bytes) : nil
        guard let header else {
            // A header that fails to parse is a torn tail only when nothing
            // follows it; with records after it, it is a corrupt non-final
            // record like any other.
            guard lines.count == 1 else { throw JournalError.corruptRecord(line: 1) }
            replay.tornTailDropped = true
            replay.needsHeader = true
            return replay
        }
        guard header.schemaVersion == JournalSchema.version else {
            throw JournalError.unsupportedSchemaVersion(header.schemaVersion)
        }
        replay.validByteCount = first.bytes.count + 1

        for (offset, line) in lines.enumerated().dropFirst() {
            let entry = line.terminated ? try? decoder.decode(Entry.self, from: line.bytes) : nil
            guard let entry else {
                guard offset == lines.count - 1 else {
                    throw JournalError.corruptRecord(line: offset + 1)
                }
                replay.tornTailDropped = true
                return replay
            }
            replay.entries.append(entry)
            replay.validByteCount += line.bytes.count + 1
        }
        return replay
    }
}
