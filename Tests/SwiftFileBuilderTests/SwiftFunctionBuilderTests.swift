import Testing
@testable import SwiftFileBuilder

@Suite("SwiftFunctionBuilder")
struct SwiftFunctionBuilderTests {

    @Test func functionWithAttribute() {
        var file = SwiftFileBuilder()
        file.appendFunction(attributes: "@MainActor", accessLevel: .public, name: "updateUI") { fn in
            fn.append(line: "print(\"updated\")")
        }
        let result = file.finalize()
        #expect(result.contains("@MainActor public func updateUI() {"))
        #expect(result.contains("    print(\"updated\")"))
        #expect(result.contains("}"))
    }

    @Test func simpleFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "greet") { fn in
            fn.append(line: "print(\"hello\")")
        }
        let result = file.finalize()
        #expect(result.contains("public func greet() {"))
        #expect(result.contains("    print(\"hello\")"))
        #expect(result.contains("}"))
    }

    @Test func functionWithArguments() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "add", arguments: [
            SwiftFunctionArgument(outerLabel: "_", name: "a", type: "Int"),
            SwiftFunctionArgument(outerLabel: "_", name: "b", type: "Int"),
        ]) { fn in
            fn.append(line: "return a + b")
        }
        let result = file.finalize()
        #expect(result.contains("internal func add(_ a: Int, _ b: Int) {"))
    }

    @Test func functionWithGenerics() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "identity", generics: [
            SwiftGeneric(name: "T"),
        ], arguments: [
            SwiftFunctionArgument(outerLabel: "_", name: "value", type: "T"),
        ]) { fn in
            fn.append(line: "return value")
        }
        let result = file.finalize()
        #expect(result.contains("public func identity<T>(_ value: T) {"))
    }

    @Test func functionWithGenericConstraints() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "compare", generics: [
            SwiftGeneric(name: "T", constraints: ["Comparable"]),
        ], arguments: [
            SwiftFunctionArgument(name: "a", type: "T"),
            SwiftFunctionArgument(name: "b", type: "T"),
        ]) { fn in
            fn.append(line: "return a < b")
        }
        let result = file.finalize()
        #expect(result.contains("public func compare<T: Comparable>(a: T, b: T) {"))
    }

    @Test func functionWithDefaultValue() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "log", arguments: [
            SwiftFunctionArgument(name: "message", type: "String"),
            SwiftFunctionArgument(name: "level", type: "Int", defaultValue: "0"),
        ]) { _ in }
        let result = file.finalize()
        #expect(result.contains("internal func log(message: String, level: Int = 0) {"))
    }

    @Test func functionWithInOutArgument() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "increment", arguments: [
            SwiftFunctionArgument(name: "value", isInOut: true, type: "Int"),
        ]) { fn in
            fn.append(line: "value += 1")
        }
        let result = file.finalize()
        #expect(result.contains("internal func increment(value: inout Int) {"))
    }

    @Test func appendLines() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "multi") { fn in
            fn.append(lines: ["let a = 1", "let b = 2"])
        }
        let result = file.finalize()
        #expect(result.contains("    let a = 1\n    let b = 2"))
    }

    @Test func appendNewlineInFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.append(line: "let a = 1")
            fn.appendNewline()
            fn.append(line: "let b = 2")
        }
        let result = file.finalize()
        #expect(result.contains("    let a = 1\n\n    let b = 2"))
    }

    @Test func nestedFunctions() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "outer") { fn in
            fn.appendFunction(name: "inner") { inner in
                inner.append(line: "print(\"inner\")")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public func outer() {"))
        #expect(result.contains("    func inner() {"))
        #expect(result.contains("        print(\"inner\")"))
    }

    @Test func functionWithOuterLabel() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "move", arguments: [
            SwiftFunctionArgument(outerLabel: "to", name: "position", type: "Point"),
        ]) { fn in
            fn.append(line: "self.pos = position")
        }
        let result = file.finalize()
        #expect(result.contains("public func move(to position: Point) {"))
    }

    @Test func functionWithBorrowingArgument() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "read", arguments: [
            SwiftFunctionArgument(name: "data", isBorrowing: true, type: "Buffer"),
        ]) { fn in
            fn.append(line: "process(data)")
        }
        let result = file.finalize()
        #expect(result.contains("public func read(data: borrowing Buffer) {"))
    }

    @Test func functionWithReturnType() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "getCount", returnType: "Int") { fn in
            fn.append(line: "return 42")
        }
        let result = file.finalize()
        #expect(result.contains("public func getCount() -> Int {"))
    }

    @Test func fileLevelFunctionWithNoAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "helper") { fn in
            fn.append(line: "doWork()")
        }
        let result = file.finalize()
        #expect(result.contains("func helper() {"))
        #expect(!result.contains("public"))
        #expect(!result.contains("internal"))
    }

    @Test func fileLevelFunctionWithReturnTypeAndGenerics() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "transform", generics: [
            SwiftGeneric(name: "T", constraints: ["Equatable"]),
        ], arguments: [
            SwiftFunctionArgument(name: "value", type: "T"),
        ], returnType: "T") { fn in
            fn.append(line: "return value")
        }
        let result = file.finalize()
        #expect(result.contains("public func transform<T: Equatable>(value: T) -> T {"))
    }

    @Test func functionWithPrivateAccess() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .private, name: "secret") { fn in
            fn.append(line: "return 42")
        }
        let result = file.finalize()
        #expect(result.contains("private func secret() {"))
    }

    @Test func functionWithMultipleGenerics() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "zip", generics: [
            SwiftGeneric(name: "A"),
            SwiftGeneric(name: "B"),
        ], arguments: [
            SwiftFunctionArgument(name: "a", type: "A"),
            SwiftFunctionArgument(name: "b", type: "B"),
        ]) { fn in
            fn.append(line: "return (a, b)")
        }
        let result = file.finalize()
        #expect(result.contains("public func zip<A, B>(a: A, b: B) {"))
    }

    @Test func functionWithMultipleGenericConstraints() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "merge", generics: [
            SwiftGeneric(name: "T", constraints: ["Equatable", "Hashable"]),
        ], arguments: [
            SwiftFunctionArgument(name: "items", type: "[T]"),
        ]) { fn in
            fn.append(line: "return Set(items)")
        }
        let result = file.finalize()
        #expect(result.contains("public func merge<T: Equatable & Hashable>(items: [T]) {"))
    }

    @Test func functionWithInOutDefaultValue() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "reset", arguments: [
            SwiftFunctionArgument(name: "value", isInOut: true, type: "Int", defaultValue: "defaultVal"),
        ]) { fn in
            fn.append(line: "value = 0")
        }
        let result = file.finalize()
        #expect(result.contains("public func reset(value: inout Int = &defaultVal) {"))
    }

    @Test func functionAppendContent() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.append(content: "let x = 1\nlet y = 2")
        }
        let result = file.finalize()
        #expect(result.contains("    let x = 1\n    let y = 2"))
    }

    @Test func functionFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "greet", arguments: [
            SwiftFunctionArgument(name: "name", type: "String"),
        ]) { fn in
            fn.append(line: "print(\"Hello, \\(name)!\")")
        }
        let result = file.finalize()
        #expect(result == """
            public func greet(name: String) {
                print("Hello, \\(name)!")
            }

            """)
    }

    @Test func functionVariant() {
        var file = SwiftFileBuilder()
        file.appendFunction(
            accessLevel: .public,
            name: "fetch",
            arguments: [
                SwiftFunctionArgument(name: "url", type: "String"),
                SwiftFunctionArgument(name: "timeout", type: "Int"),
            ],
            builder: { fn in
                fn.append(line: "doFetch(url, timeout)")
            },
            variantsBuilder: { variants in
                variants.appendVariant(replacingArguments: [
                    (argumentName: "timeout", usingDefault: "30"),
                ])
            }
        )
        let result = file.finalize()
        #expect(result.contains("public func fetch(url: String) {"))
        #expect(result.contains("return fetch(url: url, timeout: 30)"))
        #expect(result.contains("public func fetch(url: String, timeout: Int) {"))
        #expect(result.contains("doFetch(url, timeout)"))
    }

    @Test func functionVariantRemovingGenerics() {
        var file = SwiftFileBuilder()
        file.appendFunction(
            accessLevel: .public,
            name: "process",
            generics: [
                SwiftGeneric(name: "T"),
                SwiftGeneric(name: "U"),
            ],
            arguments: [
                SwiftFunctionArgument(name: "value", type: "T"),
                SwiftFunctionArgument(name: "extra", type: "U"),
            ],
            builder: { fn in
                fn.append(line: "handle(value, extra)")
            },
            variantsBuilder: { variants in
                variants.appendVariant(
                    replacingArguments: [(argumentName: "extra", usingDefault: "0 as! U")],
                    removingGenerics: ["U"]
                )
            }
        )
        let result = file.finalize()
        #expect(result.contains("public func process<T>(value: T) {"))
        #expect(result.contains("public func process<T, U>(value: T, extra: U) {"))
    }

    @Test func nestedFunctionFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "outer") { fn in
            fn.appendFunction(name: "inner") { inner in
                inner.append(line: "print(\"nested\")")
            }
            fn.append(line: "inner()")
        }
        let result = file.finalize()
        #expect(result == """
            public func outer() {
                func inner() {
                    print("nested")
                }
                inner()
            }

            """)
    }

    @Test func nestedFunctionPreservesOuterState() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(accessLevel: .public, isMutating: true, name: "process", arguments: [
                SwiftFunctionArgument(name: "items", type: "[Int]"),
            ], returnType: "Int") { fn in
                fn.appendFunction(name: "helper", arguments: [
                    SwiftFunctionArgument(name: "x", type: "Int"),
                ]) { inner in
                    inner.append(line: "return x * 2")
                }
                fn.append(line: "return helper(items[0])")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public mutating func process(items: [Int]) -> Int {"))
        #expect(result.contains("        func helper(x: Int) {"))
        #expect(result.contains("            return x * 2"))
        #expect(result.contains("        return helper(items[0])"))
    }

    @Test func functionVariantWithStaticModifier() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Factory") { type in
            type.appendMethod(
                accessLevel: .public,
                isStatic: true,
                name: "create",
                arguments: [
                    SwiftFunctionArgument(name: "name", type: "String"),
                    SwiftFunctionArgument(name: "count", type: "Int"),
                ],
                returnType: "Factory"
            ) { fn in
                fn.append(line: "return Factory()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public static func create(name: String, count: Int) -> Factory {"))
    }

    @Test func throwingFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, isThrowing: true, name: "load", returnType: "Data") { fn in
            fn.append(line: "try readFile()")
        }
        let result = file.finalize()
        #expect(result.contains("public func load() throws -> Data {"))
    }

    @Test func rethrowingFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, isRethrowing: true, name: "map", arguments: [
            SwiftFunctionArgument(name: "transform", type: "(Int) throws -> Int"),
        ], returnType: "[Int]") { fn in
            fn.append(line: "try items.map(transform)")
        }
        let result = file.finalize()
        #expect(result.contains("public func map(transform: (Int) throws -> Int) rethrows -> [Int] {"))
    }

    @Test func asyncFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, isAsync: true, name: "fetch", returnType: "String") { fn in
            fn.append(line: "await getData()")
        }
        let result = file.finalize()
        #expect(result.contains("public func fetch() async -> String {"))
    }

    @Test func asyncThrowingFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, isThrowing: true, isAsync: true, name: "download", returnType: "Data") { fn in
            fn.append(line: "try await fetch()")
        }
        let result = file.finalize()
        #expect(result.contains("public func download() async throws -> Data {"))
    }

    @Test func throwingFunctionNoReturnType() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, isThrowing: true, name: "validate") { fn in
            fn.append(line: "guard valid else { throw Error() }")
        }
        let result = file.finalize()
        #expect(result.contains("internal func validate() throws {"))
    }

    @Test func throwingMethodInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Parser") { type in
            type.appendMethod(accessLevel: .public, isThrowing: true, name: "parse", returnType: "AST") { fn in
                fn.append(line: "try doParse()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public func parse() throws -> AST {"))
    }

    @Test func variadicArgument() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "sum", arguments: [
            SwiftFunctionArgument(outerLabel: "_", name: "values", isVariadic: true, type: "Int"),
        ], returnType: "Int") { fn in
            fn.append(line: "values.reduce(0, +)")
        }
        let result = file.finalize()
        #expect(result.contains("public func sum(_ values: Int...) -> Int {"))
    }

    @Test func variadicWithOtherArgs() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "log", arguments: [
            SwiftFunctionArgument(name: "level", type: "Int"),
            SwiftFunctionArgument(outerLabel: "_", name: "items", isVariadic: true, type: "Any"),
        ]) { fn in
            fn.append(line: "print(items)")
        }
        let result = file.finalize()
        #expect(result.contains("public func log(level: Int, _ items: Any...) {"))
    }

    @Test func appendReturnWithExpression() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "getCount", returnType: "Int") { fn in
            fn.appendReturn("42")
        }
        let result = file.finalize()
        #expect(result.contains("    return 42"))
    }

    @Test func appendReturnBare() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "earlyExit") { fn in
            fn.appendReturn()
        }
        let result = file.finalize()
        #expect(result.contains("    return\n"))
    }

    @Test func appendContinueUnlabeled() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendForLoop(element: "i", collection: "items") { fb in
                fb.appendContinue()
            }
        }
        let result = file.finalize()
        #expect(result.contains("        continue\n"))
    }

    @Test func appendContinueLabeled() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendWhile("true", label: "outer") { fb in
                fb.appendContinue("outer")
            }
        }
        let result = file.finalize()
        #expect(result.contains("        continue outer\n"))
    }

    @Test func appendBreakUnlabeled() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendWhile("true") { fb in
                fb.appendBreak()
            }
        }
        let result = file.finalize()
        #expect(result.contains("        break\n"))
    }

    @Test func appendBreakLabeled() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendWhile("true", label: "loop") { fb in
                fb.appendBreak("loop")
            }
        }
        let result = file.finalize()
        #expect(result.contains("        break loop\n"))
    }

    @Test func appendDefer() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendDefer { fb in
                fb.append(line: "cleanup()")
            }
            fn.append(line: "doWork()")
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                defer {
                    cleanup()
                }
                doWork()
            }

            """)
    }

    @Test func fileprivateFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .fileprivate, name: "helper") { fn in
            fn.append(line: "doWork()")
        }
        let result = file.finalize()
        #expect(result.contains("fileprivate func helper() {"))
    }

    @Test func nestedFunctionPreservesThrowingAsync() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, isThrowing: true, isAsync: true, name: "outer", returnType: "Int") { fn in
            fn.appendFunction(name: "inner") { inner in
                inner.append(line: "print(\"nested\")")
            }
            fn.appendReturn("try await compute()")
        }
        let result = file.finalize()
        #expect(result.contains("public func outer() async throws -> Int {"))
        #expect(result.contains("    func inner() {"))
        #expect(result.contains("    return try await compute()"))
    }
    
    @Test func multilinePlainTextInFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "example") { fn in
            fn.append(line: "before()")
            var sb = SwiftStringBuilder(isMultilineString: true)
            sb.append(literal: "Hello,\nWorld!")
            fn.append(content: sb.build())
            fn.append(line: "after()")
        }
        let result = file.finalize()
        #expect(result.contains(#"""
            func example() {
                before()
                """
                Hello,
                World!
                """
                after()
            }
            
            """#))
    }
}
