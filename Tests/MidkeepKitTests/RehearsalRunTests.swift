import Foundation
import Testing

@testable import MidkeepKit

private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("midkeep-rehearsal-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

/// The streamed answer, measured independently of the source it judges
/// (a Python trial-division loop, 2026-08-04):
///   python3 -c "print(' '.join(str(n) for n in range(2,300)
///     if all(n%d for d in range(2,int(n**0.5)+1))))"
/// 62 primes, 218 bytes — both counts from the same measurement.
private let independentlyMeasuredAnswer =
    "2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 "
    + "101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 "
    + "191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271 277 "
    + "281 283 293"

private func liveChunks() async throws -> [StreamChunk] {
    var chunks: [StreamChunk] = []
    for try await chunk in PrimeStreamSource(limit: RehearsalRun.streamLimit).stream(from: 0) {
        chunks.append(chunk)
    }
    return chunks
}

@Test("The rehearsal computes its four fixed products and writes the artifact")
func rehearsalComputesItsProducts() async throws {
    // The expected counts are fixtures measured independently of the sieve
    // (a Python sieve, 2026-08-04), so this test compares the
    // implementation to a measurement rather than to itself.
    let directory = try temporaryDirectory()
    let artifact = directory.appendingPathComponent("products.txt")
    let stream = directory.appendingPathComponent("stream.txt")
    let journal = try Journal<RunEntry>(url: directory.appendingPathComponent("run.journal"))
    let engine = RunEngine(
        journal: journal,
        steps: RehearsalRun.steps(artifactURL: artifact, streamArtifactURL: stream))
    try await engine.run()

    let lines = String(decoding: try Data(contentsOf: artifact), as: UTF8.self)
        .split(separator: "\n").map(String.init)
    #expect(
        lines == [
            "303 primes below 2000",
            "550 primes below 4000",
            "1007 primes below 8000",
            "1862 primes below 16000",
        ])
    // The fifth step's effect landed whole in its own artifact, and the
    // journal completed every step — the two-artifact shape of the run.
    #expect(
        String(decoding: try Data(contentsOf: stream), as: UTF8.self)
            == independentlyMeasuredAnswer)
    #expect(
        await engine.states().allSatisfy { state in
            if case .completed = state { return true }
            return false
        })
}

@Test("A re-attempted step does not duplicate its artifact line")
func reattemptDoesNotDuplicateArtifact() async throws {
    // The kill window ADR-0002 names: the step's effect landed, its
    // completion record did not. Resume re-attempts; the step's own
    // did-this-already-happen check — against the artifact, not the
    // journal — keeps the effect single.
    let directory = try temporaryDirectory()
    let artifact = directory.appendingPathComponent("products.txt")
    let journalURL = directory.appendingPathComponent("run.journal")

    let before = try Journal<RunEntry>(url: journalURL)
    try await before.append(.attempted(stepIndex: 0))
    try await before.close()
    try Data("303 primes below 2000\n".utf8).write(to: artifact)

    let journal = try Journal<RunEntry>(url: journalURL)
    let engine = RunEngine(
        journal: journal,
        steps: RehearsalRun.steps(
            artifactURL: artifact,
            streamArtifactURL: directory.appendingPathComponent("stream.txt")))
    try await engine.run()

    let lines = String(decoding: try Data(contentsOf: artifact), as: UTF8.self)
        .split(separator: "\n").map(String.init)
    #expect(lines.count == RehearsalRun.limits.count)
    #expect(lines.filter { $0 == "303 primes below 2000" }.count == 1)
}

@Test("The streamed answer matches the independently measured list of primes")
func streamedAnswerMatchesIndependentMeasurement() async throws {
    // Like the sieve counts above: the expectation was measured with an
    // instrument that shares no code with what it judges, so this compares
    // the source to a measurement rather than to itself.
    #expect(independentlyMeasuredAnswer.utf8.count == 218)
    let chunks = try await liveChunks()
    #expect(chunks.count == 62)
    #expect(chunks.map(\.text).joined() == independentlyMeasuredAnswer)
    // Offsets are consistent: each chunk begins where the answer so far
    // ends, which is what lets a journal offset name a place in it.
    var position = 0
    for chunk in chunks {
        #expect(chunk.offset == position)
        position += chunk.text.utf8.count
    }
}

private func committedFixtureData() throws -> Data {
    let url = try #require(
        Bundle.module.url(
            forResource: "rehearsal-stream", withExtension: "jsonl", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

@Test("The committed fixture is a recording of the live source, byte for byte")
func committedFixtureIsARecordingOfTheLiveSource() async throws {
    // The D1 rider made a check: the fixture's provenance line names the
    // source, and re-recording that source today reproduces the committed
    // bytes exactly — so the recorded-fixture tests inherit provenance
    // from a real source on every run, not from a claim made once.
    let data = try committedFixtureData()
    let fixture = try FixtureStreamSource(fixtureData: data)
    let live = try await liveChunks()
    #expect(fixture.chunks == live)
    let rerecorded = try FixtureStreamSource.fixtureData(
        provenance: fixture.provenance, chunks: live)
    #expect(rerecorded == data)
}

@Test("The recorded fixture drives a killed stream back to the measured answer")
func recordedFixtureDrivesResumeToTheMeasuredAnswer() async throws {
    // The recorded-fixture test the ROADMAP bullet has named since
    // unit 01: the kill simulated at the journal mid-answer, the resume
    // driven entirely by the recording, judged against the independent
    // measurement.
    let fixture = try FixtureStreamSource(fixtureData: committedFixtureData())
    let directory = try temporaryDirectory()
    let journalURL = directory.appendingPathComponent("run.journal")

    let before = try Journal<RunEntry>(url: journalURL)
    try await before.append(.attempted(stepIndex: 0))
    var offset = 0
    for chunk in fixture.chunks.prefix(10) {
        try await before.append(
            .streamChunk(stepIndex: 0, offset: chunk.offset, text: chunk.text))
        offset = chunk.offset + chunk.text.utf8.count
    }
    try await before.close()

    let artifact = StreamRecorder()
    let journal = try Journal<RunEntry>(url: journalURL)
    let engine = RunEngine(
        journal: journal,
        steps: [
            RunStep(name: "replay", streaming: fixture) { chunk in
                await artifact.apply(chunk)
            }
        ])
    try await engine.run()

    let entries = await journal.entries
    #expect(entries.contains(.streamResumed(stepIndex: 0, fromOffset: offset)))
    #expect(
        await engine.states() == [.completed(product: independentlyMeasuredAnswer)])
    #expect(await artifact.text == independentlyMeasuredAnswer)
}

/// Offset-checked accumulation, the test-side twin of the stream artifact.
private actor StreamRecorder {
    private(set) var text = ""
    func apply(_ chunk: StreamChunk) {
        let length = text.utf8.count
        let end = chunk.offset + chunk.text.utf8.count
        if end <= length || chunk.offset > length {
            return
        }
        let suffix = Data(chunk.text.utf8).dropFirst(length - chunk.offset)
        text += String(decoding: suffix, as: UTF8.self)
    }
}

@Test("The stream artifact refuses a gap rather than fabricating bytes")
func streamEffectRefusesAGap() throws {
    let directory = try temporaryDirectory()
    let url = directory.appendingPathComponent("stream.txt")
    try RehearsalRun.appendStreamChunk(StreamChunk(offset: 0, text: "2 "), to: url)
    #expect(throws: StreamArtifactError.gap(artifactLength: 2, chunkOffset: 5)) {
        try RehearsalRun.appendStreamChunk(StreamChunk(offset: 5, text: "7"), to: url)
    }
}

@Test("A re-delivered chunk appends nothing — the stream effect's own idempotence")
func streamEffectStaysSingleOnRedelivery() throws {
    let directory = try temporaryDirectory()
    let url = directory.appendingPathComponent("stream.txt")
    try RehearsalRun.appendStreamChunk(StreamChunk(offset: 0, text: "2 "), to: url)
    try RehearsalRun.appendStreamChunk(StreamChunk(offset: 2, text: "3 "), to: url)
    // Reconstruction after a resume re-delivers from the top; nothing
    // doubles, and a chunk straddling the artifact's end appends only the
    // bytes past it.
    try RehearsalRun.appendStreamChunk(StreamChunk(offset: 0, text: "2 "), to: url)
    try RehearsalRun.appendStreamChunk(StreamChunk(offset: 2, text: "3 5"), to: url)
    #expect(String(decoding: try Data(contentsOf: url), as: UTF8.self) == "2 3 5")
}
