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

@Test("The rehearsal computes its four fixed products and writes the artifact")
func rehearsalComputesItsProducts() async throws {
    // The expected counts are fixtures measured independently of the sieve
    // (a Python sieve, 2026-08-04), so this test compares the
    // implementation to a measurement rather than to itself.
    let directory = try temporaryDirectory()
    let artifact = directory.appendingPathComponent("products.txt")
    let journal = try Journal<RunEntry>(url: directory.appendingPathComponent("run.journal"))
    let engine = RunEngine(journal: journal, steps: RehearsalRun.steps(artifactURL: artifact))
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
    let engine = RunEngine(journal: journal, steps: RehearsalRun.steps(artifactURL: artifact))
    try await engine.run()

    let lines = String(decoding: try Data(contentsOf: artifact), as: UTF8.self)
        .split(separator: "\n").map(String.init)
    #expect(lines.count == RehearsalRun.limits.count)
    #expect(lines.filter { $0 == "303 primes below 2000" }.count == 1)
}
