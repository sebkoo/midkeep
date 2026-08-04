import Foundation

/// One record in a run's journal. A step is recorded as attempted before its
/// work runs, and its outcome is a later record — ADR-0002, INV-10. The
/// product a completed step carries is the step's own artifact, distinct
/// from the record of it (unit 04, ruling D1).
public enum RunEntry: Codable, Sendable, Equatable {
    case attempted(stepIndex: Int)
    case completed(stepIndex: Int, product: String)
}

/// One step of a run: a name for the screen and work that yields the step's
/// product. The work must be safe to re-run, because resume re-attempts a
/// step recorded as attempted whose completion never landed — the
/// recoverable direction ADR-0002 chose. A step whose work cannot promise
/// that has no place in this engine yet, and the engine does not pretend
/// otherwise.
public struct RunStep: Sendable {
    public var name: String
    public var work: @Sendable () async throws -> String

    public init(name: String, work: @escaping @Sendable () async throws -> String) {
        self.name = name
        self.work = work
    }
}

/// Executes steps against a journal, journalling each attempt before the
/// step's work runs and each completion after its product exists. Resume is
/// the same loop: a completed step is skipped — its work is not re-run,
/// which is what "carries on from where it stopped" means — and an
/// attempted step without a completion is re-attempted, both attempts kept
/// in the history.
public actor RunEngine {

    /// A step's state as reconstructed from the journal, forward.
    public enum StepState: Sendable, Equatable {
        case pending
        case attempted
        case completed(product: String)
    }

    private let journal: Journal<RunEntry>
    private let steps: [RunStep]

    public init(journal: Journal<RunEntry>, steps: [RunStep]) {
        self.journal = journal
        self.steps = steps
    }

    /// One state per step, derived from the journal alone — no run state
    /// lives only in memory (INV-10).
    public func states() async -> [StepState] {
        var states = [StepState](repeating: .pending, count: steps.count)
        for entry in await journal.entries {
            switch entry {
            case .attempted(let index) where steps.indices.contains(index):
                states[index] = .attempted
            case .completed(let index, let product) where steps.indices.contains(index):
                states[index] = .completed(product: product)
            default:
                break
            }
        }
        return states
    }

    /// Runs every step the journal does not show completed, in order. The
    /// attempted record reaches the journal before the step's work runs;
    /// the completion follows the product it names.
    public func run() async throws {
        for index in steps.indices {
            let current = await states()
            if case .completed = current[index] {
                continue
            }
            try await journal.append(.attempted(stepIndex: index))
            let product = try await steps[index].work()
            try await journal.append(.completed(stepIndex: index, product: product))
        }
    }
}
