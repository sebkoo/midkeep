/// Stands in for what will live in `MidkeepKit`: the run engine, the
/// append-only journal, and the engine contracts a run is executed against.
///
/// The module imports no UI framework and no third-party module.
struct Placeholder {

    /// Version of the on-disk journal schema this build expects.
    static let schemaVersion = 1
}
