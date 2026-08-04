import Foundation
import Testing

@testable import MidkeepKit

/// A hand-built fixture source for exercising the contract; its provenance
/// says so, per the D1 rider — nothing here pretends to be a recording of
/// anything but this file.
private func handBuiltSource(_ chunks: [StreamChunk]) -> FixtureStreamSource {
    FixtureStreamSource(
        provenance: .init(recordedFrom: "hand-built in StreamingTests", date: "2026-08-04"),
        chunks: chunks)
}

private let primesChunks = [
    StreamChunk(offset: 0, text: "2 "),
    StreamChunk(offset: 2, text: "3 "),
    StreamChunk(offset: 4, text: "5"),
]

private func temporaryJournalURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("midkeep-streaming-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("run.journal")
}

/// The effect a streaming step owes ADR-0002: an artifact append that
/// answers "did this already happen?" against the artifact itself — bytes
/// before the artifact's current length are already effected and are not
/// appended again.
private actor StreamArtifact {
    private(set) var text = ""
    private(set) var deliveries: [Int] = []

    func apply(_ chunk: StreamChunk) {
        deliveries.append(chunk.offset)
        let length = text.utf8.count
        let end = chunk.offset + chunk.text.utf8.count
        if end <= length {
            return
        }
        if chunk.offset > length {
            // A gap: nothing here can fill it, and appending would place
            // bytes at the wrong offset. Skipping leaves the text short,
            // which the test's final assertion sees.
            return
        }
        let suffix = Data(chunk.text.utf8).dropFirst(length - chunk.offset)
        text += String(decoding: suffix, as: UTF8.self)
    }
}

@Test("A fresh streaming run journals every chunk in order and completes with the whole answer")
func freshStreamingRunJournalsChunks() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let artifact = StreamArtifact()
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "stream", streaming: handBuiltSource(primesChunks)) { chunk in
                await artifact.apply(chunk)
            }
        ])
    try await engine.run()
    #expect(
        await journal.entries == [
            .attempted(stepIndex: 0),
            .streamChunk(stepIndex: 0, offset: 0, text: "2 "),
            .streamChunk(stepIndex: 0, offset: 2, text: "3 "),
            .streamChunk(stepIndex: 0, offset: 4, text: "5"),
            .completed(stepIndex: 0, product: "2 3 5"),
        ])
    #expect(await engine.states() == [.completed(product: "2 3 5")])
    #expect(await artifact.text == "2 3 5")
}

@Test("A killed stream resumes from the journalled offset, resumed record first")
func killedStreamResumesFromJournalledOffset() async throws {
    // The kill, simulated at the journal: attempted plus two chunk records,
    // exactly what a death mid-stream leaves. Resume must journal the
    // offset it continued from before any continued chunk (ruling D3) and
    // must not re-journal a byte it already holds.
    let url = try temporaryJournalURL()
    let before = try Journal<RunEntry>(url: url)
    try await before.append(.attempted(stepIndex: 0))
    try await before.append(.streamChunk(stepIndex: 0, offset: 0, text: "2 "))
    try await before.append(.streamChunk(stepIndex: 0, offset: 2, text: "3 "))
    try await before.close()

    let journal = try Journal<RunEntry>(url: url)
    let artifact = StreamArtifact()
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "stream", streaming: handBuiltSource(primesChunks)) { chunk in
                await artifact.apply(chunk)
            }
        ])
    try await engine.run()
    #expect(
        await journal.entries == [
            .attempted(stepIndex: 0),
            .streamChunk(stepIndex: 0, offset: 0, text: "2 "),
            .streamChunk(stepIndex: 0, offset: 2, text: "3 "),
            .streamResumed(stepIndex: 0, fromOffset: 4),
            .streamChunk(stepIndex: 0, offset: 4, text: "5"),
            .completed(stepIndex: 0, product: "2 3 5"),
        ])
    #expect(await artifact.text == "2 3 5")
}

@Test("Resume re-delivers journalled chunks as reconstruction and the effect stays single")
func resumeReconstructsEffectsWithoutDuplication() async throws {
    // The window ADR-0002 permits, planted: the second chunk's record is on
    // disk and its effect never ran — the artifact holds one chunk, the
    // journal holds two. Reconstruction re-delivers both journalled chunks;
    // the artifact's own check heals the gap without doubling a byte.
    let url = try temporaryJournalURL()
    let before = try Journal<RunEntry>(url: url)
    try await before.append(.attempted(stepIndex: 0))
    try await before.append(.streamChunk(stepIndex: 0, offset: 0, text: "2 "))
    try await before.append(.streamChunk(stepIndex: 0, offset: 2, text: "3 "))
    try await before.close()

    let artifact = StreamArtifact()
    await artifact.apply(StreamChunk(offset: 0, text: "2 "))

    let journal = try Journal<RunEntry>(url: url)
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "stream", streaming: handBuiltSource(primesChunks)) { chunk in
                await artifact.apply(chunk)
            }
        ])
    try await engine.run()
    // Reconstruction delivered offsets 0 and 2 again, then the continuation
    // delivered 4 — and the artifact holds the answer exactly once.
    #expect(await artifact.deliveries == [0, 0, 2, 4])
    #expect(await artifact.text == "2 3 5")
}

@Test("States show the partial answer growing as chunk records land")
func statesShowPartialAnswer() async throws {
    let url = try temporaryJournalURL()
    let journal = try Journal<RunEntry>(url: url)
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "stream", streaming: handBuiltSource(primesChunks)) { _ in }
        ])
    let reported = ReportedStreamStates()
    try await engine.run { states in
        await reported.record(states)
    }
    #expect(
        await reported.all == [
            [.attempted],
            [.streaming(partial: "2 ")],
            [.streaming(partial: "2 3 ")],
            [.streaming(partial: "2 3 5")],
            [.completed(product: "2 3 5")],
        ])
}

private actor ReportedStreamStates {
    private(set) var all: [[RunEngine.StepState]] = []
    func record(_ states: [RunEngine.StepState]) {
        all.append(states)
    }
}

@Test("A fixture source resumed mid-answer delivers no byte before the offset")
func fixtureSourceTrimsToResumeOffset() async throws {
    let source = handBuiltSource([
        StreamChunk(offset: 0, text: "abc"),
        StreamChunk(offset: 3, text: "def"),
    ])
    var resumed: [StreamChunk] = []
    for try await chunk in source.stream(from: 4) {
        resumed.append(chunk)
    }
    #expect(resumed == [StreamChunk(offset: 4, text: "ef")])

    var fromBoundary: [StreamChunk] = []
    for try await chunk in source.stream(from: 3) {
        fromBoundary.append(chunk)
    }
    #expect(fromBoundary == [StreamChunk(offset: 3, text: "def")])

    var pastEnd: [StreamChunk] = []
    for try await chunk in source.stream(from: 6) {
        pastEnd.append(chunk)
    }
    #expect(pastEnd.isEmpty)
}

@Test("A fixture round-trips through its format, and a malformed line refuses with its number")
func fixtureRoundTripsAndRefusesMalformedLines() throws {
    let provenance = FixtureStreamSource.Provenance(
        recordedFrom: "hand-built in StreamingTests", date: "2026-08-04")
    let data = try FixtureStreamSource.fixtureData(provenance: provenance, chunks: primesChunks)

    let parsed = try FixtureStreamSource(fixtureData: data)
    #expect(parsed.provenance == provenance)
    #expect(parsed.chunks == primesChunks)

    var lines = String(decoding: data, as: UTF8.self)
        .split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    lines[2] = "###"
    let corrupted = Data(lines.joined(separator: "\n").utf8)
    #expect(throws: StreamFixtureError.malformed(line: 3)) {
        _ = try FixtureStreamSource(fixtureData: corrupted)
    }
}
