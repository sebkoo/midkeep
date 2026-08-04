import Foundation

/// The rehearsal run: the one job the app can do while the app is a
/// rehearsal, ruled in unit 04's decision D1. Each step's work is real,
/// tiny and deterministic — a prime count by sieve — and its product is
/// written to an artifact file distinct from the journal entry that
/// records it, because ADR-0002's ordering needs an effect that exists
/// apart from its record. The screen that shows this run names it a
/// rehearsal and promises no feature; nothing here pretends otherwise.
public enum RehearsalRun {

    /// The step limits, fixed so every run of the rehearsal computes the
    /// same products and resume is trivially safe to re-run.
    public static let limits = [2_000, 4_000, 8_000, 16_000]

    /// The steps, appending each product to the artifact at `artifactURL`.
    ///
    /// A step answers ADR-0002's resume question — "did this already
    /// happen?" — against the artifact itself, not the journal: a product
    /// line already present is not appended again, so a step killed
    /// between its artifact write and its completion record re-attempts
    /// without duplicating its effect.
    ///
    /// `pacing` is presentation, not work: a deliberate pause per step so
    /// a person can kill the app mid-job on a phone. Tests pass zero.
    public static func steps(artifactURL: URL, pacing: Duration = .zero) -> [RunStep] {
        limits.map { limit in
            RunStep(name: "count the primes below \(limit)") {
                if pacing > .zero {
                    try await Task.sleep(for: pacing)
                }
                let product = "\(primeCount(below: limit)) primes below \(limit)"
                try appendUnlessPresent(product, to: artifactURL)
                return product
            }
        }
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
