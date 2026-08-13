import Testing
@testable import SwiftFileBuilder

@Suite("Attribute layout")
struct SwiftAttributeLayoutTests {
    @Test func declarationsChooseInlineOrSeparateLines() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendVariable(attributes: "@MainActor\n@available(*, deprecated)", attributeLayout: .separateLines, name: "global")
        file.appendFunction(attributes: "@discardableResult", attributeLayout: .separateLines, name: "work") { _ in }
        file.appendType(attributes: "@MainActor", attributeLayout: .separateLines, kind: .struct, name: "Model") { type in
            type.appendStoredProperty(attributes: "@Wrapper", attributeLayout: .separateLines, name: "value", type: "Int")
            type.appendMethod(attributes: "@discardableResult", attributeLayout: .inline, name: "read") { _ in }
        }
        #expect(file.finalize() == """
        @MainActor
        @available(*, deprecated)
        var global
        @discardableResult
        func work() {
        }
        @MainActor
        struct Model {
          @Wrapper
          var value: Int
          @discardableResult func read() {
          }
        }

        """)
    }
}
