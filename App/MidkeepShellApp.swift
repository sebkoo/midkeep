import MidkeepApp
import SwiftUI

/// The app-shell shim: the one sanctioned importer of `MidkeepApp`. It mounts
/// the composition root and holds nothing of its own — real code belongs in
/// the package, where the gates read it.
@main
struct MidkeepShellApp: App {

    var body: some Scene {
        WindowGroup {
            Composition.root()
        }
    }
}
