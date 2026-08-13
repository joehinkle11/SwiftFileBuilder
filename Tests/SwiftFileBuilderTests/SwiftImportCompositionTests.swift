import Testing
@testable import SwiftFileBuilder

@Suite("Import composition")
struct SwiftImportCompositionTests {
    @Test func attributesSpiAndModifiersCompose() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "SomeModule", attributes: ["@unsafe", "@preconcurrency"])
        file.appendImport(module: "Internals", attributes: [], modifiers: [.public], spi: "Internal")
        file.appendImport(module: "Models", type: "Value", kind: .struct, attributes: ["@testable"], modifiers: [.package])
        #expect(file.finalize() == """
        @unsafe @preconcurrency import SomeModule
        @_spi(Internal) public import Internals
        @testable package import struct Models.Value

        """)
    }

    @Test func attributedMultipleImports() {
        var file = SwiftFileBuilder()
        file.appendImports(modules: ["A", "B"], attributes: ["@preconcurrency"], modifiers: [.internal])
        #expect(file.finalize() == "@preconcurrency internal import A\n@preconcurrency internal import B\n")
    }
}
