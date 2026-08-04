import MidkeepUI
import SwiftUI

/// The composition root. Wires `MidkeepUI` and `MidkeepKit` together for the
/// app target. Nothing in the package imports this module; only the app-shell
/// layer (`App/`) may — INV-3 as amended in unit 03.
public enum Composition {

    /// The root view the app shell mounts.
    @MainActor public static func root() -> some View {
        ShellView()
    }
}
