import MidkeepUI
import SwiftUI

/// The composition root. Wires `MidkeepUI` and `MidkeepKit` together for the
/// app target. Nothing in the package imports this module; only the app-shell
/// layer (`App/`) may — INV-3 as amended in unit 03.
public enum Composition {

    /// The root view the app shell mounts: the rehearsal run screen, backed
    /// by a journal in Application Support. The pacing is presentation — it
    /// makes each step slow enough to kill mid-job on a phone, which is the
    /// measurement unit 04 exists for.
    ///
    /// `--start-job` is the device rig's entry point (unit 04, ruling D5):
    /// it starts a fresh job at launch, standing in for the tap a person
    /// gives the Start button. It adds no path a tap cannot reach — resume
    /// needs no argument and no tap, which is the capability itself.
    @MainActor public static func root() -> some View {
        RunView(
            directory: URL.applicationSupportDirectory
                .appendingPathComponent("Midkeep", isDirectory: true),
            pacing: .seconds(2),
            autostart: ProcessInfo.processInfo.arguments.contains("--start-job"))
    }
}
