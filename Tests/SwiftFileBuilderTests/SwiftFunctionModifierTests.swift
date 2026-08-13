import Testing
@testable import SwiftFileBuilder

@Suite("SwiftFunctionModifier")
struct SwiftFunctionModifierTests {
    @Test func rendersStructuredModifiersInOrder() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, modifiers: [.nonisolatedUnsafe, .unsafe], name: "load") { _ in }
        file.appendType(kind: .struct, name: "Value") { type in
            type.appendMethod(isStatic: true, modifiers: [.borrowing], name: "read") { _ in }
        }
        #expect(file.finalize() == """
        public nonisolated(unsafe) unsafe func load() {
        }
        struct Value {
            borrowing static func read() {
            }
        }

        """)
    }

    @Test func nestedFunctionHasSignatureParity() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "outer") { function in
            function.appendFunction(
                attributes: "@discardableResult",
                modifiers: [.nonisolated],
                isThrowing: true,
                isAsync: true,
                name: "inner",
                generics: [.init(name: "T", constraints: ["Sendable"])],
                arguments: [.init(outerLabel: "_", name: "value", ownership: .borrowing, type: "T")],
                returnType: "T"
            ) { body in
                body.appendReturn("value")
            }
        }
        #expect(file.finalize() == """
        func outer() {
            @discardableResult nonisolated func inner<T: Sendable>(_ value: borrowing T) async throws -> T {
                return value
            }
        }

        """)
    }
}
