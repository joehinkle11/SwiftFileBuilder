import Testing
@testable import SwiftFileBuilder

@Suite("Integration")
struct IntegrationTests {

    @Test func deepNestingIndentation() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Outer") { type in
            type.appendMethod(accessLevel: .public, name: "run") { fn in
                fn.appendSwitch("value") { sw in
                    sw.appendCase(".a") { fb in
                        fb.append(line: "print(\"deeply nested\")")
                    }
                }
            }
        }
        let result = file.finalize()
        #expect(result == """
            struct Outer {
                public func run() {
                    switch value {
                    case .a:
                        print("deeply nested")
                    }
                }
            }

            """)
    }

    @Test func multipleTypesInFile() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "A") { type in
            type.appendStoredProperty(name: "x", type: "Int")
        }
        file.appendNewline()
        file.appendType(kind: .struct, name: "B") { type in
            type.appendStoredProperty(name: "y", type: "Int")
        }
        let result = file.finalize()
        #expect(result == """
            struct A {
                var x: Int
            }

            struct B {
                var y: Int
            }

            """)
    }

    @Test func fullFileComposition() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .enum, name: "Level", inheritedTypes: ["Int"]) { type in
            type.appendCase(name: "low", rawValue: "0")
            type.appendCase(name: "high", rawValue: "1")
        }
        file.appendNewline()
        file.appendFunction(accessLevel: .public, name: "describe", arguments: [
            SwiftFunctionArgument(name: "level", type: "Level"),
        ]) { fn in
            fn.appendSwitch("level") { sw in
                sw.appendCase(".low") { fb in
                    fb.append(line: "print(\"low\")")
                }
                sw.appendCase(".high") { fb in
                    fb.append(line: "print(\"high\")")
                }
            }
        }
        let result = file.finalize()
        #expect(result == """
            import Foundation

            public enum Level: Int {
                case low = 0

                case high = 1
            }

            public func describe(level: Level) {
                switch level {
                case .low:
                    print("low")
                case .high:
                    print("high")
                }
            }

            """)
    }

    @Test func methodWithControlFlowNesting() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Processor") { type in
            type.appendMethod(accessLevel: .public, name: "process") { fn in
                fn.appendGuard(condition: "let input = self.input") { fb in
                    fb.append(line: "return")
                }
                fn.appendForLoop(element: "item", collection: "input") { fb in
                    fb.appendIf("item.isValid", builder: { inner in
                        inner.append(line: "handle(item)")
                    }, elseBuilder: { inner in
                        inner.append(line: "skip(item)")
                    })
                }
            }
        }
        let result = file.finalize()
        #expect(result == """
            struct Processor {
                public func process() {
                    guard let input = self.input else {
                        return
                    }
                    for item in input {
                        if item.isValid {
                            handle(item)
                        } else {
                            skip(item)
                        }
                    }
                }
            }

            """)
    }

    @Test func importsWithTypeAndFunction() {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendImport(module: "UIKit")
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .class, name: "VC", inheritedTypes: ["UIViewController"]) { type in
            type.appendMethod(accessLevel: .public, isOverride: true, name: "viewDidLoad") { fn in
                fn.append(line: "super.viewDidLoad()")
            }
        }
        let result = file.finalize()
        #expect(result == """
            import Foundation
            import UIKit

            public class VC: UIViewController {
                public override func viewDidLoad() {
                    super.viewDidLoad()
                }
            }

            """)
    }

    @Test func enumWithMethodsAndCases() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "Op") { type in
            type.appendCase(name: "add", comment: "Addition")
            type.appendCase(name: "sub", comment: "Subtraction")
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "apply", arguments: [
                SwiftFunctionArgument(name: "a", type: "Int"),
                SwiftFunctionArgument(name: "b", type: "Int"),
            ], returnType: "Int") { fn in
                fn.appendSwitch("self") { sw in
                    sw.appendCase(".add") { fb in
                        fb.append(line: "return a + b")
                    }
                    sw.appendCase(".sub") { fb in
                        fb.append(line: "return a - b")
                    }
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("public enum Op {"))
        #expect(result.contains("    // Addition"))
        #expect(result.contains("    case add"))
        #expect(result.contains("    // Subtraction"))
        #expect(result.contains("    case sub"))
        #expect(result.contains("    public func apply(a: Int, b: Int) -> Int {"))
        #expect(result.contains("        switch self {"))
        #expect(result.contains("        case .add:"))
        #expect(result.contains("            return a + b"))
    }

    @Test func structWithNestedEnumAndMethod() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Config") { type in
            type.appendNestedType(accessLevel: .public, kind: .enum, name: "Mode") { nested in
                nested.appendCase(name: "debug")
                nested.appendCase(name: "release")
            }
            type.appendNewline()
            type.appendStoredProperty(accessLevel: .public, name: "mode", type: "Mode")
            type.appendNewline()
            type.appendInitializer(accessLevel: .public, arguments: [
                SwiftFunctionArgument(name: "mode", type: "Mode"),
            ]) { fn in
                fn.append(line: "self.mode = mode")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public struct Config {"))
        #expect(result.contains("    public enum Mode {"))
        #expect(result.contains("        case debug"))
        #expect(result.contains("    }"))
        #expect(result.contains("    public var mode: Mode"))
        #expect(result.contains("    public init(mode: Mode) {"))
    }

    @Test func extensionWithComputedPropertyAndMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .extension, name: "Array") { type in
            type.appendMethod(accessLevel: .public, asGetter: true, name: "isNotEmpty", returnType: "Bool") { fn in
                fn.append(line: "return !isEmpty")
            }
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "safeIndex", arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "index", type: "Int"),
            ], returnType: "Element?") { fn in
                fn.appendGuard(condition: "index >= 0, index < count") { fb in
                    fb.append(line: "return nil")
                }
                fn.append(line: "return self[index]")
            }
        }
        let result = file.finalize()
        #expect(result.contains("extension Array {"))
        #expect(result.contains("    public var isNotEmpty: Bool {"))
        #expect(result.contains("        return !isEmpty"))
        #expect(result.contains("    public func safeIndex(_ index: Int) -> Element? {"))
        #expect(result.contains("        guard index >= 0, index < count else {"))
    }

    @Test func protocolWithExtension() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .protocol, name: "Identifiable") { type in
            type.appendProperty("var id: String { get }")
        }
        file.appendNewline()
        file.appendType(kind: .extension, name: "Identifiable") { type in
            type.appendMethod(accessLevel: .public, name: "matches", arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "other", type: "any Identifiable"),
            ], returnType: "Bool") { fn in
                fn.append(line: "return id == other.id")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public protocol Identifiable {"))
        #expect(result.contains("    var id: String { get }"))
        #expect(result.contains("extension Identifiable {"))
        #expect(result.contains("    public func matches(_ other: any Identifiable) -> Bool {"))
    }
}
