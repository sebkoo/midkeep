import Testing

@testable import MidkeepKit

@Test("Kit placeholder declares schema version 1")
func placeholderDeclaresSchemaVersion() {
    let placeholder = Placeholder()
    #expect(type(of: placeholder).schemaVersion == 1)
}
