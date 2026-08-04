import Foundation
import Testing

@testable import MidkeepKit

/// Records what a step's work observed, from inside the work.
private actor WorkLog {
    private(set) var calls: [String] = []
    func record(_ note: String) {
        calls.append(note)
    }
}

private func temporaryJournalURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("midkeep-engine-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("run.journal")
}

@Test("A step's attempted record is on disk before its work runs — INV-10's first test")
func attemptedRecordPrecedesWork() async throws {
    // The work reads the journal file from disk — not the actor's memory —
    // so what it asserts is INV-10's own wording: the record is durable
    // before the effect it precedes. The mark this test carries moved
    // INV-10 to PARTIAL; a test sees only the step types it drives.
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let log = WorkLog()
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "observe") {
                let onDisk = String(decoding: try Data(contentsOf: url), as: UTF8.self)
                await log.record(onDisk.contains(#""attempted""#) ? "record-first" : "work-first")
                return "seen"
            }
        ])
    try await engine.run()
    #expect(await log.calls == ["record-first"])
}

@Test("A chunk's record is on disk before the chunk's effect runs — INV-10 for the streaming step")
func chunkRecordPrecedesEffect() async throws {
    // The second step type the ordering test drives (unit 05, ruling D5).
    // The effect reads the journal file from disk — not the actor's memory —
    // and records whether this chunk's own record preceded it, which is
    // INV-10's wording held per chunk (ruling D2).
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let log = WorkLog()
    let source = FixtureStreamSource(
        provenance: .init(recordedFrom: "hand-built in this test", date: "2026-08-04"),
        chunks: [StreamChunk(offset: 0, text: "ab"), StreamChunk(offset: 2, text: "cd")])
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "stream", streaming: source) { chunk in
                let onDisk = String(decoding: try Data(contentsOf: url), as: UTF8.self)
                await log.record(
                    onDisk.contains(#""offset":\#(chunk.offset)"#) ? "record-first" : "effect-first"
                )
            }
        ])
    try await engine.run()
    #expect(await log.calls == ["record-first", "record-first"])
}

@Test("A fresh run completes every step in order and journals both records per step")
func freshRunCompletesEverything() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "rename") { "renamed" },
            RunStep(name: "file") { "filed" },
        ])
    try await engine.run()
    #expect(
        await engine.states() == [
            .completed(product: "renamed"), .completed(product: "filed"),
        ])
    #expect(
        await journal.entries == [
            .attempted(stepIndex: 0), .completed(stepIndex: 0, product: "renamed"),
            .attempted(stepIndex: 1), .completed(stepIndex: 1, product: "filed"),
        ])
}

@Test("Resume skips completed steps — their work does not run again")
func resumeSkipsCompletedSteps() async throws {
    // The kill, simulated at the journal: a prefix holding step 0 completed
    // and nothing else, exactly what a process death after one step leaves.
    let url = try temporaryJournalURL()
    let before = try Journal<RunEntry>(url: url)
    try await before.append(.attempted(stepIndex: 0))
    try await before.append(.completed(stepIndex: 0, product: "renamed"))
    try await before.close()

    let journal = try Journal<RunEntry>(url: url)
    let log = WorkLog()
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "rename") {
                await log.record("rename ran")
                return "renamed"
            },
            RunStep(name: "file") {
                await log.record("file ran")
                return "filed"
            },
        ])
    try await engine.run()
    #expect(await log.calls == ["file ran"])
    #expect(
        await engine.states() == [
            .completed(product: "renamed"), .completed(product: "filed"),
        ])
}

@Test("An attempted step without a completion is re-attempted, both attempts kept")
func attemptedWithoutCompletionIsReAttempted() async throws {
    // The other half of the kill: death inside a step's work leaves an
    // attempted record with no completion — the recoverable direction, so
    // resume re-runs the work and the history keeps both attempts.
    let url = try temporaryJournalURL()
    let before = try Journal<RunEntry>(url: url)
    try await before.append(.attempted(stepIndex: 0))
    try await before.close()

    let journal = try Journal<RunEntry>(url: url)
    let log = WorkLog()
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "rename") {
                await log.record("rename ran")
                return "renamed"
            }
        ])
    try await engine.run()
    #expect(await log.calls == ["rename ran"])
    #expect(
        await journal.entries == [
            .attempted(stepIndex: 0),
            .attempted(stepIndex: 0),
            .completed(stepIndex: 0, product: "renamed"),
        ])
}

@Test("The hook reports states after every record, in journal order")
func hookReportsEveryRecord() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "rename") { "renamed" },
            RunStep(name: "file") { "filed" },
        ])
    let reported = ReportedStates()
    try await engine.run { states in
        await reported.record(states)
    }
    #expect(
        await reported.all == [
            [.attempted, .pending],
            [.completed(product: "renamed"), .pending],
            [.completed(product: "renamed"), .attempted],
            [.completed(product: "renamed"), .completed(product: "filed")],
        ])
}

private actor ReportedStates {
    private(set) var all: [[RunEngine.StepState]] = []
    func record(_ states: [RunEngine.StepState]) {
        all.append(states)
    }
}

@Test("A step that throws leaves its attempted record and no completion")
func failingStepLeavesAttemptedOnly() async throws {
    struct StepFailure: Error {}
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let engine = RunEngine(
        journal: journal,
        steps: [RunStep(name: "rename") { throw StepFailure() }])
    await #expect(throws: StepFailure.self) {
        try await engine.run()
    }
    #expect(await journal.entries == [.attempted(stepIndex: 0)])
    #expect(await engine.states() == [.attempted])
}
