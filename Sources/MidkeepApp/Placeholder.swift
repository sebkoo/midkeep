/// Stands in for the composition root. `MidkeepApp` wires `MidkeepUI` and
/// `MidkeepKit` together, and nothing imports it.
///
/// It is a library product rather than an executable because at this commit it
/// composes nothing: an executable target would need a `main.swift` or an
/// `@main` type, which is feature code this unit does not write, and an
/// executable product would be meaningless on the iOS platform this package
/// targets. The application target arrives with the Xcode project and depends
/// on this library. Until then the boundary is drawn before there is anything
/// to put on either side of it.
struct Placeholder {}
