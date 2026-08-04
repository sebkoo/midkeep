import Foundation

/// What the stream artifact refuses on. The engine's reconstruction makes
/// a gap impossible, so meeting one means the artifact is not this run's,
/// and appending past it would fabricate bytes of an answer nobody
/// produced.
public enum StreamArtifactError: Error, Equatable, Sendable {
    case gap(artifactLength: Int, chunkOffset: Int)
}

/// Streams the primes below a limit as each one is found — real local
/// work arriving incrementally, the honest stream ruling D1 chose: the
/// text exists only as the search produces it, so watching it arrive is
/// watching the work happen. The answer is fully determined by `limit`,
/// which is what lets a recording of it stand as a fixture and lets any
/// resume offset land in an answer every run agrees on.
public struct PrimeStreamSource: StreamSource {

    public var limit: Int

    /// Presentation, not work: a pause per chunk so a person can watch
    /// the answer arrive and kill the app in the middle of it. Tests
    /// pass zero.
    public var pacing: Duration

    public init(limit: Int, pacing: Duration = .zero) {
        self.limit = limit
        self.pacing = pacing
    }

    public func stream(from offset: Int) -> AsyncThrowingStream<StreamChunk, Error> {
        let limit = self.limit
        let pacing = self.pacing
        return AsyncThrowingStream { continuation in
            let search = Task {
                do {
                    var found: [Int] = []
                    var position = 0
                    for candidate in 2..<max(limit, 2) {
                        let divisors = found.prefix { $0 * $0 <= candidate }
                        guard divisors.allSatisfy({ candidate % $0 != 0 }) else {
                            continue
                        }
                        found.append(candidate)
                        let text = position == 0 ? "\(candidate)" : " \(candidate)"
                        let end = position + text.utf8.count
                        defer { position = end }
                        if end <= offset {
                            continue
                        }
                        if pacing > .zero {
                            try await Task.sleep(for: pacing)
                        }
                        if position >= offset {
                            continuation.yield(StreamChunk(offset: position, text: text))
                        } else {
                            let suffix = Data(text.utf8).dropFirst(offset - position)
                            continuation.yield(
                                StreamChunk(
                                    offset: offset, text: String(decoding: suffix, as: UTF8.self)))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in search.cancel() }
        }
    }
}

/// The rehearsal run: the one job the app can do while the app is a
/// rehearsal, ruled in unit 04's decision D1. Each step's work is real,
/// tiny and deterministic — a prime count by sieve, and since unit 05 a
/// prime search streamed as it runs — and its product is written to an
/// artifact file distinct from the journal entry that records it, because
/// ADR-0002's ordering needs an effect that exists apart from its record.
/// The screen that shows this run names it a rehearsal and promises no
/// feature; nothing here pretends otherwise.
public enum RehearsalRun {

    /// The step limits, fixed so every run of the rehearsal computes the
    /// same products and resume is trivially safe to re-run.
    public static let limits = [2_000, 4_000, 8_000, 16_000]

    /// The streaming step's limit, fixed for the same reason.
    public static let streamLimit = 300

    /// The steps: four counting steps appending to the artifact at
    /// `artifactURL`, then the streaming step whose answer's bytes land
    /// at `streamArtifactURL`.
    ///
    /// A step answers ADR-0002's resume question — "did this already
    /// happen?" — against its artifact itself, not the journal: a product
    /// line already present is not appended again, and a chunk whose
    /// bytes the stream artifact already holds appends nothing, so a
    /// step killed between its artifact write and its completion record
    /// re-attempts without duplicating its effect.
    ///
    /// `pacing` is presentation, not work: a deliberate pause per step —
    /// per chunk, scaled down, in the streaming step — so a person can
    /// kill the app mid-job on a phone. Tests pass zero.
    public static func steps(
        artifactURL: URL, streamArtifactURL: URL, pacing: Duration = .zero
    ) -> [RunStep] {
        var steps = limits.map { limit in
            RunStep(name: "count the primes below \(limit)") {
                if pacing > .zero {
                    try await Task.sleep(for: pacing)
                }
                let product = "\(primeCount(below: limit)) primes below \(limit)"
                try appendUnlessPresent(product, to: artifactURL)
                return product
            }
        }
        steps.append(
            RunStep(
                name: "list the primes below \(streamLimit) as they are found",
                streaming: PrimeStreamSource(limit: streamLimit, pacing: pacing / 16)
            ) { chunk in
                try appendStreamChunk(chunk, to: streamArtifactURL)
            })
        return steps
    }

    /// Sieve of Eratosthenes; the real work of a step.
    static func primeCount(below limit: Int) -> Int {
        guard limit > 2 else { return 0 }
        var composite = [Bool](repeating: false, count: limit)
        var count = 0
        for candidate in 2..<limit where !composite[candidate] {
            count += 1
            var multiple = candidate * candidate
            while multiple < limit {
                composite[multiple] = true
                multiple += candidate
            }
        }
        return count
    }

    /// The streaming step's effect, and its own idempotence check in
    /// offset form: bytes the artifact already holds are not appended
    /// again, so reconstruction after a resume re-delivers without
    /// doubling — the shape `appendUnlessPresent` gives the unitary
    /// steps, held per chunk. A chunk past the artifact's end refuses
    /// with `StreamArtifactError.gap`.
    static func appendStreamChunk(_ chunk: StreamChunk, to url: URL) throws {
        let existing: Data
        if FileManager.default.fileExists(atPath: url.path) {
            existing = try Data(contentsOf: url)
        } else {
            existing = Data()
            try existing.write(to: url)
        }
        let length = existing.count
        let end = chunk.offset + chunk.text.utf8.count
        if end <= length {
            return
        }
        guard chunk.offset <= length else {
            throw StreamArtifactError.gap(artifactLength: length, chunkOffset: chunk.offset)
        }
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(chunk.text.utf8).dropFirst(length - chunk.offset))
        try handle.close()
    }

    /// The step's effect, and its own idempotence check. Reading before
    /// appending is what makes re-attempting safe without consulting the
    /// journal — the shape ADR-0002 demands of a resumable step.
    private static func appendUnlessPresent(_ product: String, to url: URL) throws {
        let line = product + "\n"
        if FileManager.default.fileExists(atPath: url.path) {
            let existing = String(decoding: try Data(contentsOf: url), as: UTF8.self)
            if existing.split(separator: "\n").contains(Substring(product)) {
                return
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
            try handle.close()
        } else {
            try Data(line.utf8).write(to: url)
        }
    }
}
