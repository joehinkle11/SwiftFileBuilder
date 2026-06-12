import Testing
@testable import SwiftFileBuilder

@Suite("SwiftFileBuilder")
struct SwiftFileBuilderTests {

    @Test func emptyFileProducesEmptyString() {
        let file = SwiftFileBuilder()
        let result = file.finalize()
        #expect(result == "")
    }

    @Test func singleImport() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        let result = file.finalize()
        #expect(result == "import Foundation\n")
    }

    @Test func multipleImports() {
        var file = SwiftFileBuilder()
        file.appendImports(modules: ["Foundation", "UIKit"])
        let result = file.finalize()
        #expect(result == "import Foundation\nimport UIKit\n")
    }

    @Test func selectiveImport() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", type: "URL", kind: SwiftTypeBuilderStructKind())
        let result = file.finalize()
        #expect(result == "import struct Foundation.URL\n")
    }

    @Test func selectiveImportClass() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", type: "NSObject", kind: SwiftTypeBuilderClassKind())
        let result = file.finalize()
        #expect(result == "import class Foundation.NSObject\n")
    }

    @Test func selectiveImportEnum() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", type: "ComparisonResult", kind: SwiftTypeBuilderEnumKind())
        let result = file.finalize()
        #expect(result == "import enum Foundation.ComparisonResult\n")
    }

    @Test func selectiveImportProtocol() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", type: "Codable", kind: SwiftTypeBuilderProtocolKind())
        let result = file.finalize()
        #expect(result == "import protocol Foundation.Codable\n")
    }

    @Test func appendNewline() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendImport(module: "UIKit")
        let result = file.finalize()
        #expect(result == "import Foundation\n\nimport UIKit\n")
    }

    @Test func appendLine() {
        var file = SwiftFileBuilder()
        file.append(line: "let x = 42")
        let result = file.finalize()
        #expect(result == "let x = 42\n")
    }

    @Test func appendContent() {
        var file = SwiftFileBuilder()
        file.append(content: "let x = 1\nlet y = 2")
        let result = file.finalize()
        #expect(result == "let x = 1\nlet y = 2\n")
    }

    @Test func appendComment() {
        var file = SwiftFileBuilder()
        file.append(comment: "This is a comment")
        let result = file.finalize()
        #expect(result == "// This is a comment\n")
    }

    @Test func appendDocComment() {
        var file = SwiftFileBuilder()
        file.append(comment: "Doc comment", commentStyle: .doc)
        let result = file.finalize()
        #expect(result == "/// Doc comment\n")
    }

    @Test func appendMultilineComment() {
        var file = SwiftFileBuilder()
        file.append(comment: "Line one\nLine two")
        let result = file.finalize()
        #expect(result == "// Line one\n// Line two\n")
    }

    @Test func appendMultilineDocComment() {
        var file = SwiftFileBuilder()
        file.append(comment: "Summary\nDetails here", commentStyle: .doc)
        let result = file.finalize()
        #expect(result == "/// Summary\n/// Details here\n")
    }

    @Test func appendMark() {
        var file = SwiftFileBuilder()
        file.appendMark("Properties")
        let result = file.finalize()
        #expect(result == "// MARK: - Properties\n")
    }

    @Test func appendMarkWithoutSeparator() {
        var file = SwiftFileBuilder()
        file.appendMark("Properties", withSeparator: false)
        let result = file.finalize()
        #expect(result == "// MARK: Properties\n")
    }

    @Test func emptyImportsArray() {
        var file = SwiftFileBuilder()
        file.appendImports(modules: [])
        let result = file.finalize()
        #expect(result == "")
    }

    @Test func multipleNewlinesInSequence() {
        var file = SwiftFileBuilder()
        file.append(line: "let a = 1")
        file.appendNewline()
        file.appendNewline()
        file.append(line: "let b = 2")
        let result = file.finalize()
        #expect(result == "let a = 1\n\n\nlet b = 2\n")
    }

    @Test func mixedImportsAndContent() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.append(comment: "Global constant")
        file.append(line: "let version = \"1.0\"")
        let result = file.finalize()
        #expect(result == "import Foundation\n\n// Global constant\nlet version = \"1.0\"\n")
    }

    @Test func spiImport() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", spi: "Testable")
        let result = file.finalize()
        #expect(result == "@_spi(Testable) import Foundation\n")
    }

    @Test func spiImportSelective() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation", type: "URL", kind: SwiftTypeBuilderStructKind(), spi: "Testable")
        let result = file.finalize()
        #expect(result == "@_spi(Testable) import struct Foundation.URL\n")
    }

    @Test func spiImportMultiple() {
        var file = SwiftFileBuilder()
        file.appendImports(modules: ["Foundation", "UIKit"], spi: "Testable")
        let result = file.finalize()
        #expect(result == "@_spi(Testable) import Foundation\n@_spi(Testable) import UIKit\n")
    }

    @Test func typeAliasAtFileLevel() {
        var file = SwiftFileBuilder()
        file.appendTypeAlias(accessLevel: .public, name: "StringMap", type: "Dictionary<String, String>")
        let result = file.finalize()
        #expect(result == "public typealias StringMap = Dictionary<String, String>\n")
    }

    @Test func typeAliasNoAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendTypeAlias(name: "ID", type: "Int")
        let result = file.finalize()
        #expect(result == "typealias ID = Int\n")
    }
}
