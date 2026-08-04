import Foundation
import Testing

@testable import MidkeepKit

/// A stand-in entry for exercising the journal. The run engine defines the
/// real entry types; the journal is generic over them and these tests hold
/// it to the schema alone.
private struct Step: Codable, Sendable, Equatable {
    var name: String
    var index: Int
}

/// Real files in a fresh temp directory per test — the real thing is cheap
/// to test, which is why no in-memory fake exists (unit 04, ruling D3).
private func temporaryJournalURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("midkeep-journal-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("run.journal")
}

@Test("A new journal writes its header record first")
func newJournalIsSelfDescribing() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<Step>(url: url)
    try await journal.close()

    let firstLine = try #require(
        String(decoding: Data(contentsOf: url), as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false).first)
    let header = try JSONDecoder().decode([String: Int].self, from: Data(firstLine.utf8))
    #expect(header == ["schemaVersion": 1])
}

@Test("Appended entries replay in order")
func appendedEntriesReplayInOrder() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<Step>(url: url)
    let steps = [Step(name: "rename", index: 1), Step(name: "file", index: 2)]
    for step in steps {
        try await journal.append(step)
    }
    #expect(await journal.entries == steps)
    #expect(await journal.tornTailDropped == false)
}

@Test("Reopening replays what was appended — relaunch minus the kill")
func reopeningReplaysAppendedEntries() async throws {
    // The approximation, labeled: a second instance on the same file proves
    // the bytes left this instance's memory, not that they survive the
    // process — its blind spot is buffering, a write held in process memory
    // that would pass here and die with the process. The device rig's true
    // kill is the measurement that sees that; if the rig and this test ever
    // disagree, the deferred helper-process kill test becomes owed
    // (unit 04, ruling D4).
    let url = try temporaryJournalURL()
    let first = try Journal<Step>(url: url)
    let steps = [Step(name: "rename", index: 1), Step(name: "file", index: 2)]
    for step in steps {
        try await first.append(step)
    }
    try await first.close()

    let second = try Journal<Step>(url: url)
    #expect(await second.entries == steps)
    #expect(await second.tornTailDropped == false)
}

@Test("A torn tail is dropped, reported, and truncated away")
func tornTailIsDroppedAndReported() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<Step>(url: url)
    let steps = [Step(name: "rename", index: 1), Step(name: "file", index: 2)]
    for step in steps {
        try await journal.append(step)
    }
    try await journal.close()

    // Plant the tear: a record whose write never finished — no terminator.
    let planting = try FileHandle(forWritingTo: url)
    try planting.seekToEnd()
    try planting.write(contentsOf: Data(#"{"name":"summar"#.utf8))
    try planting.close()

    let reopened = try Journal<Step>(url: url)
    #expect(await reopened.entries == steps)
    #expect(await reopened.tornTailDropped == true)

    // The drop is physical: appending after it must not merge with the torn
    // bytes, so a third open sees three clean records and no tear.
    try await reopened.append(Step(name: "summarise", index: 3))
    try await reopened.close()
    let third = try Journal<Step>(url: url)
    #expect(await third.entries.count == 3)
    #expect(await third.tornTailDropped == false)
}

@Test("A corrupt non-final record refuses, never skips")
func corruptMiddleRecordRefuses() async throws {
    // The discriminating half of the pair: the same parse failure that is
    // dropped at the tail is refused in the middle, because records follow
    // it and skipping would fabricate a shorter history (ADR-0008).
    let url = try temporaryJournalURL()
    let journal = try Journal<Step>(url: url)
    for step in [Step(name: "rename", index: 1), Step(name: "file", index: 2)] {
        try await journal.append(step)
    }
    try await journal.close()

    var lines = String(decoding: try Data(contentsOf: url), as: UTF8.self)
        .split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    lines[1] = "###"
    try Data(lines.joined(separator: "\n").utf8).write(to: url)

    #expect(throws: JournalError.corruptRecord(line: 2)) {
        _ = try Journal<Step>(url: url)
    }
}

@Test("A header naming an unknown schema version refuses")
func unknownSchemaVersionRefuses() throws {
    let url = try temporaryJournalURL()
    try Data("{\"schemaVersion\":2}\n".utf8).write(to: url)

    #expect(throws: JournalError.unsupportedSchemaVersion(2)) {
        _ = try Journal<Step>(url: url)
    }
}

@Test("A torn header alone is a fresh journal, not a refusal")
func tornHeaderAloneRecovers() async throws {
    // A journal killed before its header write finished holds one
    // unterminated line and nothing else — the torn tail with zero valid
    // records, recoverable like any other tear.
    let url = try temporaryJournalURL()
    try Data(#"{"schemaVer"#.utf8).write(to: url)

    let journal = try Journal<Step>(url: url)
    #expect(await journal.entries.isEmpty)
    #expect(await journal.tornTailDropped == true)
    try await journal.append(Step(name: "rename", index: 1))
    try await journal.close()

    let reopened = try Journal<Step>(url: url)
    #expect(await reopened.entries == [Step(name: "rename", index: 1)])
}
