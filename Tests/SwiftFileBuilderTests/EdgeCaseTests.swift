import Testing
@testable import SwiftFileBuilder

@Suite("EdgeCases")
struct EdgeCaseTests {

    @Test func emptyFunctionBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "noop") { _ in }
        let result = file.finalize()
        #expect(result == "public func noop() {\n}\n")
    }

    @Test func emptyMethodBody() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(accessLevel: .public, name: "doNothing") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    public func doNothing() {\n    }"))
    }

    @Test func emptyInitializerBody() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendInitializer(accessLevel: .public) { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    public init() {\n    }"))
    }

    @Test func emptyGuardBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendGuard(condition: "condition") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    guard condition else {\n    }"))
    }

    @Test func emptyIfBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendIf("true") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    if true {\n    }"))
    }

    @Test func emptyWhileBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendWhile("false") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    while false {\n    }"))
    }

    @Test func emptyForLoopBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendForLoop(element: "i", collection: "items") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    for i in items {\n    }"))
    }

    @Test func emptySwitchNoCases() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendSwitch("value") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    switch value {\n    }"))
    }

    @Test func emptyDeferBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendDefer { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    defer {\n    }"))
    }

    @Test func emptyNestedFunctionBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "outer") { fn in
            fn.appendFunction(name: "inner") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    func inner() {\n    }"))
    }

    @Test func emptyPropertyBlockBody() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendPropertyBlock(header: "var x: Int") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    var x: Int {\n    }"))
    }

    @Test func emptyDeinitializerBody() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "C") { type in
            type.appendDeinitializer { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    deinit {\n    }"))
    }

    @Test func emptyRepeatWhileBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendRepeatWhile("true") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    repeat {\n    } while true"))
    }

    @Test func emptyDoBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendDo { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    do {\n    }"))
    }

    @Test func emptyDoCatchBody() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "test") { fn in
            fn.appendDo(catches: [
                (pattern: nil, builder: { _ in })
            ]) { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    do {\n    } catch {\n    }"))
    }

    @Test func emptySubscriptBody() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendSubscript(returnType: "Int") { _ in }
        }
        let result = file.finalize()
        #expect(result.contains("    subscript() -> Int {\n    }"))
    }

    @Test func threeDeepNestedTypes() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "L1") { l1 in
            l1.appendNestedType(kind: .enum, name: "L2") { l2 in
                l2.appendNestedType(kind: .struct, name: "L3") { l3 in
                    l3.appendStoredProperty(name: "value", type: "Int")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("public struct L1 {"))
        #expect(result.contains("    enum L2 {"))
        #expect(result.contains("        struct L3 {"))
        #expect(result.contains("            var value: Int"))
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        let closingBraces = lines.filter { $0.trimmingCharacters(in: .whitespaces) == "}" }
        #expect(closingBraces.count == 3)
    }

    @Test func fourDeepNestedTypesWithMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "A") { a in
            a.appendNestedType(kind: .class, name: "B") { b in
                b.appendNestedType(kind: .enum, name: "C") { c in
                    c.appendNestedType(kind: .struct, name: "D") { d in
                        d.appendMethod(name: "deepMethod") { fn in
                            fn.append(line: "print(\"deep\")")
                        }
                    }
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("struct A {"))
        #expect(result.contains("    class B {"))
        #expect(result.contains("        enum C {"))
        #expect(result.contains("            struct D {"))
        #expect(result.contains("                func deepMethod() {"))
        #expect(result.contains("                    print(\"deep\")"))
    }

    @Test func unicodeIdentifier() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "grüßen") { fn in
            fn.append(line: "print(\"Héllo Wörld 🌍\")")
        }
        let result = file.finalize()
        #expect(result.contains("func grüßen() {"))
        #expect(result.contains("    print(\"Héllo Wörld 🌍\")"))
    }

    @Test func unicodeInTypeAndProperty() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "日本語") { type in
            type.appendStoredProperty(name: "名前", type: "String")
        }
        let result = file.finalize()
        #expect(result.contains("struct 日本語 {"))
        #expect(result.contains("    var 名前: String"))
    }

    @Test func emojiInComment() {
        var file = SwiftFileBuilder()
        file.append(comment: "🚀 Launch sequence")
        let result = file.finalize()
        #expect(result == "// 🚀 Launch sequence\n")
    }

    @Test func finalizeNormalizesMultipleTrailingNewlines() {
        var file = SwiftFileBuilder()
        file.append(line: "let x = 1")
        file.appendNewline()
        file.appendNewline()
        let result = file.finalize()
        #expect(result.hasSuffix("\n"))
        #expect(!result.hasSuffix("\n\n"))
    }

    @Test func finalizeAddsTrailingNewlineIfMissing() {
        let file = SwiftFileBuilder()
        let result = file.finalize()
        #expect(result == "")
    }

    @Test func finalizePreservesSingleTrailingNewline() {
        var file = SwiftFileBuilder()
        file.append(line: "let x = 1")
        let result = file.finalize()
        #expect(result == "let x = 1\n")
    }

    @Test func appendContentPreservesBlankLines() {
        var file = SwiftFileBuilder()
        file.append(content: "line1\n\nline3")
        let result = file.finalize()
        #expect(result.contains("line1\n\nline3"))
    }

    @Test func complexCompositionProducesValidStructure() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .struct, name: "Container") { type in
            type.appendStoredProperty(accessLevel: .private, name: "items", type: "[Int]")
            type.appendNewline()
            type.appendInitializer(accessLevel: .public) { fn in
                fn.append(line: "self.items = []")
            }
            type.appendNewline()
            type.appendMethod(accessLevel: .public, isMutating: true, name: "process") { fn in
                fn.appendGuard(condition: "!items.isEmpty") { fb in
                    fb.appendReturn()
                }
                fn.appendForLoop(element: "item", collection: "items") { fb in
                    fb.appendIf("item > 0") { inner in
                        inner.append(line: "handle(item)")
                    }
                }
            }
        }
        let result = file.finalize()
        let openBraces = result.filter { $0 == "{" }.count
        let closeBraces = result.filter { $0 == "}" }.count
        #expect(openBraces == closeBraces)
    }
}
