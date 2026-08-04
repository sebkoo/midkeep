import SwiftUI

/// The shell's whole screen: the app's name and the true state of the work.
///
/// Each line is derived from the tree; the derivations are recorded in the
/// unit-03 ratification entry in `docs/ROADMAP.md`. The third line is a claim
/// about this screen itself — the diff that adds a second screen must remove
/// it. No gate reads screen text; that removal is enforced by diff review,
/// by convention.
public struct ShellView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("midkeep")
                .font(.largeTitle.weight(.semibold))
            Text("No journal yet. No runs yet.")
                .foregroundStyle(.secondary)
            Text("This screen is the whole app.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
