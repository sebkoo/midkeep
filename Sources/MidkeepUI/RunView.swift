import MidkeepKit
import Observation
import SwiftUI

/// Drives the run screen from the journal and nothing else: every state a
/// row shows was reconstructed from records on disk, reported by the
/// engine's hook after each append, so the screen can never claim more
/// than the journal holds.
@MainActor @Observable public final class RunScreenModel {

    public struct StepRow: Identifiable, Equatable {
        public let id: Int
        public let name: String
        public var state: RunEngine.StepState
    }

    public enum Phase: Equatable {
        case idle
        case running
        case complete
        case refused(String)
    }

    public private(set) var rows: [StepRow] = []
    public private(set) var phase: Phase = .idle

    /// True when opening found a job in flight and continued it — the
    /// capability itself, surfaced so the screen can say it happened.
    public private(set) var resumed = false

    private let directory: URL
    private let journalURL: URL
    private let artifactURL: URL
    private let streamArtifactURL: URL
    private let pacing: Duration
    private var journal: Journal<RunEntry>?
    private var engine: RunEngine?

    public init(directory: URL, pacing: Duration) {
        self.directory = directory
        journalURL = directory.appendingPathComponent("rehearsal.journal")
        artifactURL = directory.appendingPathComponent("rehearsal-products.txt")
        streamArtifactURL = directory.appendingPathComponent("rehearsal-stream.txt")
        self.pacing = pacing
    }

    /// Opens the journal and — without being asked — resumes a job the
    /// journal shows unfinished. Relaunching is how a killed job carries
    /// on, so resuming is the default and idle is the exception.
    public func open() async {
        do {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            let steps = RehearsalRun.steps(
                artifactURL: artifactURL, streamArtifactURL: streamArtifactURL, pacing: pacing)
            let journal = try Journal<RunEntry>(url: journalURL)
            let engine = RunEngine(journal: journal, steps: steps)
            self.journal = journal
            self.engine = engine

            let states = await engine.states()
            rows = zip(steps.indices, states).map { index, state in
                StepRow(id: index, name: steps[index].name, state: state)
            }
            let started = states.contains { $0 != .pending }
            let unfinished = states.contains { state in
                if case .completed = state { return false }
                return true
            }
            if started && unfinished {
                resumed = true
                await start()
            } else if started {
                phase = .complete
            }
        } catch let error as JournalError {
            phase = .refused(refusal(for: error))
        } catch {
            phase = .refused("The journal could not be opened: \(error.localizedDescription)")
        }
    }

    /// Runs the job, reflecting each journal record as it lands.
    public func start() async {
        guard let engine, phase != .running else { return }
        phase = .running
        let (stream, continuation) = AsyncStream<[RunEngine.StepState]>.makeStream()
        let reflect = Task {
            for await states in stream {
                apply(states)
            }
        }
        do {
            try await engine.run { states in
                continuation.yield(states)
            }
            continuation.finish()
            await reflect.value
            phase = .complete
        } catch {
            continuation.finish()
            await reflect.value
            phase = .refused("A step failed: \(error.localizedDescription)")
        }
    }

    /// A rehearsal-only affordance, explicit and user-initiated: this job's
    /// record and artifact may be thrown away to rehearse again. A real
    /// run's record never gets this button — ADR-0002 says every run
    /// leaves a record, and this one did, until its owner discarded it.
    public func discard() async {
        try? await journal?.close()
        journal = nil
        engine = nil
        for url in [journalURL, artifactURL]
        where FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                phase = .refused(
                    "The rehearsal could not be discarded: \(error.localizedDescription)")
                return
            }
        }
        rows = []
        phase = .idle
        resumed = false
        await open()
    }

    private func apply(_ states: [RunEngine.StepState]) {
        for index in rows.indices where index < states.count {
            rows[index].state = states[index]
        }
    }

    private func refusal(for error: JournalError) -> String {
        switch error {
        case .corruptRecord(let line):
            "The journal refused: a corrupt record at line \(line). "
                + "Nothing was skipped and nothing was guessed."
        case .unsupportedSchemaVersion(let version):
            "The journal refused: it was written under schema version "
                + "\(version), which this build cannot read."
        }
    }
}

/// The run screen: a rehearsal job that says so. Every step state comes
/// from the journal via the model; the screen adds words, never claims.
public struct RunView: View {

    @State private var model: RunScreenModel
    private let autostart: Bool

    /// `autostart` starts a fresh job at launch — the rig's stand-in for a
    /// person's tap on Start, never a different path (unit 04, ruling D5).
    public init(directory: URL, pacing: Duration, autostart: Bool = false) {
        _model = State(initialValue: RunScreenModel(directory: directory, pacing: pacing))
        self.autostart = autostart
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("midkeep")
                .font(.largeTitle.weight(.semibold))
            Text(
                "A rehearsal job — real arithmetic, written down step by step. "
                    + "The last step streams: its answer arrives as the search "
                    + "finds it, each piece on disk before it is shown. It exists "
                    + "to prove that a killed job carries on, and it promises no "
                    + "feature."
            )
            .foregroundStyle(.secondary)

            ForEach(model.rows) { row in
                if case .streaming(let partial) = row.state {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.name)
                        Text(partial)
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                } else {
                    HStack {
                        Text(row.name)
                        Spacer()
                        stateText(row.state)
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
            }

            controls

            Spacer()
            Text("This job and this screen are the whole app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task {
            await model.open()
            if autostart && model.phase == .idle {
                await model.start()
            }
        }
    }

    @ViewBuilder private var controls: some View {
        switch model.phase {
        case .idle:
            Button("Start the job") {
                Task {
                    await model.start()
                }
            }
            .buttonStyle(.borderedProminent)
        case .running:
            VStack(alignment: .leading, spacing: 4) {
                if model.resumed {
                    Text("Resumed from the journal: finished steps were not re-run.")
                }
                Text("Kill the app now and reopen it to watch the job carry on.")
            }
            .font(.callout)
        case .complete:
            VStack(alignment: .leading, spacing: 8) {
                if model.resumed {
                    Text("Resumed from the journal: finished steps were not re-run.")
                        .font(.callout)
                }
                Text("Job complete. Every step's product is written down.")
                    .font(.callout)
                Button("Discard the rehearsal and start over", role: .destructive) {
                    Task {
                        await model.discard()
                    }
                }
            }
        case .refused(let message):
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
        }
    }

    private func stateText(_ state: RunEngine.StepState) -> Text {
        switch state {
        case .pending: Text("waiting")
        case .attempted: Text("working…")
        case .streaming(let partial): Text(partial)
        case .completed(let product): Text(product)
        }
    }
}
