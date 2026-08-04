import Foundation

/// One record in a run's journal. A step is recorded as attempted before its
/// work runs, and its outcome is a later record — ADR-0002, INV-10. The
/// product a completed step carries is the step's own artifact, distinct
/// from the record of it (unit 04, ruling D1).
///
/// A streaming step adds two records (unit 05, rulings D2 and D3): each
/// chunk of its answer is recorded before that chunk is observable, and a
/// resume records the offset it continued from — ADR-0007's sentence as a
/// case. The vocabulary grows under schema version 1: the version names the
/// framing contract, not this list (ruling D2; ADR-0008 as amended).
public enum RunEntry: Codable, Sendable, Equatable {
    case attempted(stepIndex: Int)
    case completed(stepIndex: Int, product: String)
    case streamChunk(stepIndex: Int, offset: Int, text: String)
    case streamResumed(stepIndex: Int, fromOffset: Int)
}

/// One step of a run: a name for the screen and the work that yields the
/// step's product. Unitary work yields its product all at once; streaming
/// work delivers it in chunks through a `StreamSource`, with an effect the
/// engine calls per chunk only after that chunk's record is on disk — the
/// INV-10 orientation, held per chunk (unit 05, ruling D2).
///
/// Either kind must be safe to run again, because resume re-attempts work
/// whose completion never landed — the recoverable direction ADR-0002
/// chose. A streaming effect must additionally answer "did this already
/// happen?" against its own artifact, never the journal, because resume
/// re-delivers journalled chunks to it as reconstruction (ruling D3). A
/// step whose work cannot promise that has no place in this engine yet,
/// and the engine does not pretend otherwise.
public struct RunStep: Sendable {

    public enum Work: Sendable {
        case unitary(@Sendable () async throws -> String)
        case streaming(
            source: any StreamSource,
            effect: @Sendable (StreamChunk) async throws -> Void)
    }

    public var name: String
    public var work: Work

    public init(name: String, work: @escaping @Sendable () async throws -> String) {
        self.name = name
        self.work = .unitary(work)
    }

    public init(
        name: String,
        streaming source: any StreamSource,
        effect: @escaping @Sendable (StreamChunk) async throws -> Void
    ) {
        self.name = name
        self.work = .streaming(source: source, effect: effect)
    }
}

/// Executes steps against a journal, journalling each attempt before the
/// step's work runs and each completion after its product exists. Resume is
/// the same loop: a completed step is skipped — its work is not re-run,
/// which is what "carries on from where it stopped" means — and an
/// attempted step without a completion is re-attempted, both attempts kept
/// in the history. A streaming step's re-attempt record is its resumed
/// record, which carries the offset it continued from.
public actor RunEngine {

    /// A step's state as reconstructed from the journal, forward.
    public enum StepState: Sendable, Equatable {
        case pending
        case attempted
        case streaming(partial: String)
        case completed(product: String)
    }

    private let journal: Journal<RunEntry>
    private let steps: [RunStep]

    public init(journal: Journal<RunEntry>, steps: [RunStep]) {
        self.journal = journal
        self.steps = steps
    }

    /// One state per step, derived from the journal alone — no run state
    /// lives only in memory (INV-10). A streaming step's partial answer is
    /// the concatenation of its chunk records, so the screen showing it
    /// shows exactly what the journal holds.
    public func states() async -> [StepState] {
        var states = [StepState](repeating: .pending, count: steps.count)
        var partials = [Int: String]()
        for entry in await journal.entries {
            switch entry {
            case .attempted(let index) where steps.indices.contains(index):
                states[index] = .attempted
            case .streamChunk(let index, _, let text) where steps.indices.contains(index):
                let partial = (partials[index] ?? "") + text
                partials[index] = partial
                states[index] = .streaming(partial: partial)
            case .streamResumed(let index, _) where steps.indices.contains(index):
                states[index] = .streaming(partial: partials[index] ?? "")
            case .completed(let index, let product) where steps.indices.contains(index):
                states[index] = .completed(product: product)
            default:
                break
            }
        }
        return states
    }

    /// Runs every step the journal does not show completed, in order. Every
    /// record reaches the journal before the moment it precedes: the
    /// attempted record before the step's work, each chunk record before
    /// that chunk's effect, the resumed record before any continued chunk,
    /// and the completion after the product it names. `afterEachRecord`
    /// reports the reconstructed states after every append, so a screen can
    /// show exactly what the journal holds — never more.
    public func run(
        afterEachRecord: (@Sendable ([RunEngine.StepState]) async -> Void)? = nil
    ) async throws {
        for index in steps.indices {
            let current = await states()
            if case .completed = current[index] {
                continue
            }
            switch steps[index].work {
            case .unitary(let work):
                try await journal.append(.attempted(stepIndex: index))
                await afterEachRecord?(states())
                let product = try await work()
                try await journal.append(.completed(stepIndex: index, product: product))
                await afterEachRecord?(states())
            case .streaming(let source, let effect):
                let prior = await journalledChunks(for: index)
                var answer = prior.map(\.text).joined()
                let offset = answer.utf8.count
                if case .pending = current[index] {
                    try await journal.append(.attempted(stepIndex: index))
                    await afterEachRecord?(states())
                } else {
                    // The resumed record lands before any continued chunk is
                    // observable (ruling D3), and it is this step's second
                    // attempt record — both attempts kept, ADR-0002's
                    // bookkeeping, carrying the offset ADR-0007 names.
                    try await journal.append(
                        .streamResumed(stepIndex: index, fromOffset: offset))
                    await afterEachRecord?(states())
                    // Reconstruction, not duplication: journalled chunks are
                    // re-delivered to the effect, whose own artifact check
                    // keeps the effect single. This is also the healing path
                    // for the window ADR-0002 permits — a chunk recorded
                    // whose effect never ran.
                    for chunk in prior {
                        try await effect(chunk)
                    }
                }
                for try await chunk in source.stream(from: offset) {
                    try await journal.append(
                        .streamChunk(stepIndex: index, offset: chunk.offset, text: chunk.text))
                    try await effect(chunk)
                    await afterEachRecord?(states())
                    answer += chunk.text
                }
                try await journal.append(.completed(stepIndex: index, product: answer))
                await afterEachRecord?(states())
            }
        }
    }

    private func journalledChunks(for index: Int) async -> [StreamChunk] {
        var chunks: [StreamChunk] = []
        for entry in await journal.entries {
            if case .streamChunk(let step, let offset, let text) = entry, step == index {
                chunks.append(StreamChunk(offset: offset, text: text))
            }
        }
        return chunks
    }
}
