import Testing
@testable import SwiftFileBuilder

@Suite("SwiftTypeBuilder")
struct SwiftTypeBuilderTests {

    @Test func emptyStruct() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Foo") { _ in }
        let result = file.finalize()
        #expect(result == "struct Foo {\n}\n")
    }

    @Test func emptyActor() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .actor, name: "MyActor") { _ in }
        let result = file.finalize()
        #expect(result == "actor MyActor {\n}\n")
    }

    @Test func publicClassWithInheritance() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .class, name: "Dog", inheritedTypes: ["Animal", "Hashable"]) { _ in }
        let result = file.finalize()
        #expect(result == "public class Dog: Animal, Hashable {\n}\n")
    }

    @Test func enumWithCases() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "Color", inheritedTypes: ["String"]) { type in
            type.appendCase(name: "red", rawValue: "\"red\"")
            type.appendCase(name: "blue", rawValue: "\"blue\"")
        }
        let result = file.finalize()
        #expect(result.contains("public enum Color: String {"))
        #expect(result.contains("    case red = \"red\""))
        #expect(result.contains("    case blue = \"blue\""))
        #expect(result.contains("}"))
    }

    @Test func enumCaseWithAssociatedType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .enum, name: "Result") { type in
            type.appendCase(name: "success", associatedType: "String")
            type.appendCase(name: "failure", associatedType: "Error")
        }
        let result = file.finalize()
        #expect(result.contains("case success(String)"))
        #expect(result.contains("case failure(Error)"))
    }

    @Test func enumCaseWithComment() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .enum, name: "Op") { type in
            type.appendCase(name: "add", comment: "Addition operator")
        }
        let result = file.finalize()
        #expect(result.contains("// Addition operator"))
        #expect(result.contains("case add"))
    }

    @Test func extensionType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .extension, name: "String", inheritedTypes: ["CustomDebugStringConvertible"]) { _ in }
        let result = file.finalize()
        #expect(result == "extension String: CustomDebugStringConvertible {\n}\n")
    }
    
    @Test func protocolDeclaration() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .protocol, name: "Drawable", inheritedTypes: ["AnyObject"]) { type in
            type.appendProperty("var color: String { get }")
        }
        let result = file.finalize()
        #expect(result.contains("public protocol Drawable: AnyObject {"))
        #expect(result.contains("    var color: String { get }"))
    }
    
    @Test func protocolDeclaration2() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .protocol, name: "Drawable", inheritedTypes: []) { type in
            type.appendProperty("var color: String { get }")
        }
        let result = file.finalize()
        #expect(result.contains("public protocol Drawable {"))
        #expect(result.contains("    var color: String { get }"))
    }

    @Test func storedProperty() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Point") { type in
            type.appendStoredProperty(name: "x", type: "Int")
            type.appendStoredProperty(accessLevel: .public, name: "y", type: "Int", initialValue: "0")
        }
        let result = file.finalize()
        #expect(result.contains("    var x: Int"))
        #expect(result.contains("    public var y: Int = 0"))
    }

    @Test func storedPropertyLet() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Config") { type in
            type.appendStoredProperty(isLet: true, name: "id", type: "String")
        }
        let result = file.finalize()
        #expect(result.contains("    let id: String"))
    }

    @Test func storedPropertyWithModifiers() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "VC") { type in
            type.appendStoredProperty(accessLevel: .private, modifiers: "weak", name: "delegate", type: "Delegate?")
        }
        let result = file.finalize()
        #expect(result.contains("    private weak var delegate: Delegate?"))
    }

    @Test func methodInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Calculator") { type in
            type.appendMethod(accessLevel: .public, name: "add", arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "a", type: "Int"),
                SwiftFunctionArgument(outerLabel: "_", name: "b", type: "Int"),
            ], returnType: "Int") { fn in
                fn.append(line: "return a + b")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public func add(_ a: Int, _ b: Int) -> Int {"))
        #expect(result.contains("        return a + b"))
    }

    @Test func initializerInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Point") { type in
            type.appendInitializer(accessLevel: .public, arguments: [
                SwiftFunctionArgument(name: "x", type: "Int"),
                SwiftFunctionArgument(name: "y", type: "Int"),
            ]) { fn in
                fn.append(line: "self.x = x")
                fn.append(line: "self.y = y")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public init(x: Int, y: Int) {"))
    }

    @Test func typeBuilderNewline() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendStoredProperty(name: "x", type: "Int")
            type.appendNewline()
            type.appendStoredProperty(name: "y", type: "Int")
        }
        let result = file.finalize()
        #expect(result.contains("    var x: Int\n\n    var y: Int"))
    }

    @Test func typeBuilderMark() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "C") { type in
            type.appendMark("Properties")
            type.appendStoredProperty(name: "x", type: "Int")
        }
        let result = file.finalize()
        #expect(result.contains("    // MARK: - Properties"))
    }

    @Test func nestedType() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Container") { type in
            type.appendNestedType(accessLevel: .public, kind: .enum, name: "Status", inheritedTypes: ["String"]) { nested in
                nested.appendCase(name: "active", rawValue: "\"active\"")
                nested.appendCase(name: "inactive", rawValue: "\"inactive\"")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public struct Container {"))
        #expect(result.contains("    public enum Status: String {"))
        #expect(result.contains("        case active = \"active\""))
        #expect(result.contains("}"))
    }

    @Test func propertyBlock() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendPropertyBlock(header: "var computed: Int {") { fn in
                fn.append(line: "return 42")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    var computed: Int {"))
        #expect(result.contains("        return 42"))
        #expect(result.contains("    }"))
    }

    @Test func getterMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(accessLevel: .public, asGetter: true, name: "count", returnType: "Int") { fn in
                fn.append(line: "return items.count")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public var count: Int {"))
    }

    @Test func staticMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(accessLevel: .public, isStatic: true, name: "create", returnType: "S") { fn in
                fn.append(line: "return S()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public static func create() -> S {"))
    }

    @Test func mutatingMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(accessLevel: .public, isMutating: true, name: "reset") { fn in
                fn.append(line: "value = 0")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public mutating func reset() {"))
    }

    @Test func overrideMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Child") { type in
            type.appendMethod(accessLevel: .public, isOverride: true, name: "doSomething") { fn in
                fn.append(line: "print(\"overridden\")")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public override func doSomething() {"))
    }

    @Test func consumingMethod() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Token") { type in
            type.appendMethod(accessLevel: .public, isConsuming: true, name: "use", returnType: "String") { fn in
                fn.append(line: "return value")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public consuming func use() -> String {"))
    }

    @Test func typeWithPrivateAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .private, kind: .class, name: "Cache") { type in
            type.appendStoredProperty(name: "data", type: "[String]")
        }
        let result = file.finalize()
        #expect(result.contains("private class Cache {"))
    }

    @Test func typeWithPackageAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .package, kind: .struct, name: "Internal") { _ in }
        let result = file.finalize()
        #expect(result == "package struct Internal {\n}\n")
    }

    @Test func typeWithThreeInheritedTypes() {
        var file = SwiftFileBuilder()
        file.appendType(
            accessLevel: .public,
            kind: .struct,
            name: "Vector",
            inheritedTypes: ["Equatable", "Hashable", "CustomStringConvertible"]
        ) { _ in }
        let result = file.finalize()
        #expect(result == "public struct Vector: Equatable, Hashable, CustomStringConvertible {\n}\n")
    }

    @Test func storedPropertyLetWithAccessAndInit() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendStoredProperty(accessLevel: .public, isLet: true, name: "pi", type: "Double", initialValue: "3.14159")
        }
        let result = file.finalize()
        #expect(result.contains("    public let pi: Double = 3.14159"))
    }

    @Test func storedPropertyWithStaticModifier() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendStoredProperty(accessLevel: .public, modifiers: "static", name: "shared", type: "S", initialValue: "S()")
        }
        let result = file.finalize()
        #expect(result.contains("    public static var shared: S = S()"))
    }

    @Test func appendPropertyInline() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendProperty("var description: String { \"hello\" }")
        }
        let result = file.finalize()
        #expect(result.contains("    var description: String { \"hello\" }"))
    }

    @Test func markWithoutSeparatorInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMark("Helpers", withSeparator: false)
        }
        let result = file.finalize()
        #expect(result.contains("    // MARK: Helpers"))
    }

    @Test func nestedStructInClass() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Parent") { type in
            type.appendNestedType(kind: .struct, name: "Config") { nested in
                nested.appendStoredProperty(name: "timeout", type: "Int")
            }
        }
        let result = file.finalize()
        #expect(result.contains("class Parent {"))
        #expect(result.contains("    struct Config {"))
        #expect(result.contains("        var timeout: Int"))
    }

    @Test func enumCaseSimple() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .enum, name: "E") { type in
            type.appendCase(name: "a")
        }
        let result = file.finalize()
        #expect(result.contains("    case a\n"))
        #expect(!result.contains("case a("))
        #expect(!result.contains("case a ="))
    }

    @Test func methodWithMultipleModifiers() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(
                accessLevel: .public,
                isStatic: true,
                name: "create",
                arguments: [SwiftFunctionArgument(name: "value", type: "Int")],
                returnType: "S"
            ) { fn in
                fn.append(line: "return S()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public static func create(value: Int) -> S {"))
    }

    @Test func typeWithMultipleMembersFullOutput() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Vec2") { type in
            type.appendMark("Properties")
            type.appendStoredProperty(accessLevel: .public, name: "x", type: "Float")
            type.appendStoredProperty(accessLevel: .public, name: "y", type: "Float")
            type.appendNewline()
            type.appendMark("Init")
            type.appendInitializer(accessLevel: .public, arguments: [
                SwiftFunctionArgument(name: "x", type: "Float"),
                SwiftFunctionArgument(name: "y", type: "Float"),
            ]) { fn in
                fn.append(line: "self.x = x")
                fn.append(line: "self.y = y")
            }
            type.appendNewline()
            type.appendMark("Methods")
            type.appendMethod(accessLevel: .public, name: "length", returnType: "Float") { fn in
                fn.append(line: "return sqrt(x * x + y * y)")
            }
        }
        let result = file.finalize()
        #expect(result == """
            public struct Vec2 {
                // MARK: - Properties
                public var x: Float
                public var y: Float

                // MARK: - Init
                public init(x: Float, y: Float) {
                    self.x = x
                    self.y = y
                }

                // MARK: - Methods
                public func length() -> Float {
                    return sqrt(x * x + y * y)
                }
            }

            """)
    }

    @Test func initializerWithGenericArgs() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Box") { type in
            type.appendInitializer(
                accessLevel: .public,
                generics: [SwiftGeneric(name: "T")],
                arguments: [SwiftFunctionArgument(name: "value", type: "T")]
            ) { fn in
                fn.append(line: "self.value = value")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public init<T>(value: T) {"))
    }

    @Test func methodThenNestedTypePreservesOwnerState() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "MyStruct") { type in
            type.appendMethod(accessLevel: .private, name: "helper") { fn in
                fn.append(line: "print(\"help\")")
            }
            type.appendNestedType(accessLevel: .internal, kind: .enum, name: "Status") { nested in
                nested.appendCase(name: "active")
            }
            type.appendMethod(accessLevel: .public, name: "doWork") { fn in
                fn.append(line: "print(\"work\")")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public struct MyStruct {"))
        #expect(result.contains("    private func helper() {"))
        #expect(result.contains("    internal enum Status {"))
        #expect(result.contains("    public func doWork() {"))
    }

    @Test func initializerThenMethodPreservesOwnerState() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Point") { type in
            type.appendInitializer(accessLevel: .internal, arguments: [
                SwiftFunctionArgument(name: "x", type: "Int"),
            ]) { fn in
                fn.append(line: "self.x = x")
            }
            type.appendNewline()
            type.appendPropertyBlock(header: "var description: String {") { fn in
                fn.append(line: "return \"Point(\\(x))\"")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public struct Point {"))
        #expect(result.contains("    internal init(x: Int) {"))
        #expect(result.contains("    var description: String {"))
    }

    @Test func failableInitializer() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Wrapper") { type in
            type.appendInitializer(accessLevel: .public, isFailable: true, arguments: [
                SwiftFunctionArgument(name: "value", type: "Int"),
            ]) { fn in
                fn.append(line: "guard value > 0 else { return nil }")
                fn.append(line: "self.value = value")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public init?(value: Int) {"))
    }

    @Test func convenienceInitializer() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Obj") { type in
            type.appendInitializer(accessLevel: .public, isConvenience: true, arguments: [
                SwiftFunctionArgument(name: "name", type: "String"),
            ]) { fn in
                fn.append(line: "self.init(name: name, id: 0)")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public convenience init(name: String) {"))
    }

    @Test func requiredInitializer() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Base") { type in
            type.appendInitializer(accessLevel: .public, isRequired: true) { fn in
                fn.append(line: "// required init")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public required init() {"))
    }

    @Test func requiredFailableInitializer() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Base") { type in
            type.appendInitializer(accessLevel: .public, isRequired: true, isFailable: true, arguments: [
                SwiftFunctionArgument(name: "raw", type: "String"),
            ]) { fn in
                fn.append(line: "return nil")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public required init?(raw: String) {"))
    }

    @Test func initializerWithNoAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendInitializer { fn in
                fn.append(line: "// default init")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    init() {"))
        #expect(!result.contains("public"))
    }

    @Test func methodWithNoAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendMethod(name: "helper") { fn in
                fn.append(line: "doWork()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    func helper() {"))
        #expect(!result.contains("public"))
        #expect(!result.contains("internal"))
    }

    @Test func appendCaseNoLeadingNewlineForFirstCase() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .enum, name: "Color") { type in
            type.appendCase(name: "red")
            type.appendCase(name: "green")
            type.appendCase(name: "blue")
        }
        let result = file.finalize()
        #expect(result == """
            enum Color {
                case red

                case green

                case blue
            }

            """)
    }

    @Test func appendBlockAutoAppendsBrace() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendBlock(header: "do") { fb in
                fb.append(line: "try something()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    do {"))
        #expect(result.contains("        try something()"))
        #expect(result.contains("    }"))
    }

    @Test func appendPropertyBlockAutoAppendsBrace() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendPropertyBlock(header: "var computed: Int") { fn in
                fn.append(line: "return 42")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    var computed: Int {"))
        #expect(result.contains("        return 42"))
        #expect(result.contains("    }"))
    }

    @Test func methodThenPropertyBlockPreservesOwnerState() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .class, name: "Container") { type in
            type.appendMethod(accessLevel: .private, name: "reset") { fn in
                fn.append(line: "items = []")
            }
            type.appendPropertyBlock(header: "var count: Int {") { fn in
                fn.append(line: "return items.count")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public class Container {"))
        #expect(result.contains("    private func reset() {"))
        #expect(result.contains("    var count: Int {"))
    }

    @Test func typeAliasInType() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Container") { type in
            type.appendTypeAlias(accessLevel: .public, name: "Element", type: "Int")
        }
        let result = file.finalize()
        #expect(result.contains("    public typealias Element = Int"))
    }

    @Test func typeAliasInTypeNoAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "S") { type in
            type.appendTypeAlias(name: "Value", type: "String")
        }
        let result = file.finalize()
        #expect(result.contains("    typealias Value = String"))
    }

    @Test func deinitializer() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .class, name: "Resource") { type in
            type.appendDeinitializer { fn in
                fn.append(line: "release()")
            }
        }
        let result = file.finalize()
        #expect(result == """
            public class Resource {
                deinit {
                    release()
                }
            }

            """)
    }

    @Test func deinitializerPreservesTypeState() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .class, name: "MyClass") { type in
            type.appendStoredProperty(name: "value", type: "Int")
            type.appendDeinitializer { fn in
                fn.append(line: "cleanup()")
            }
            type.appendMethod(accessLevel: .public, name: "doWork") { fn in
                fn.append(line: "process()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("public class MyClass {"))
        #expect(result.contains("    var value: Int"))
        #expect(result.contains("    deinit {"))
        #expect(result.contains("        cleanup()"))
        #expect(result.contains("    public func doWork() {"))
    }

    @Test func fileprivateType() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .fileprivate, kind: .struct, name: "Helper") { _ in }
        let result = file.finalize()
        #expect(result == "fileprivate struct Helper {\n}\n")
    }

    @Test func throwingMethodInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Validator") { type in
            type.appendMethod(accessLevel: .public, isThrowing: true, name: "validate", returnType: "Bool") { fn in
                fn.appendReturn("true")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public func validate() throws -> Bool {"))
        #expect(result.contains("        return true"))
    }

    @Test func asyncMethodInType() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "Fetcher") { type in
            type.appendMethod(accessLevel: .public, isAsync: true, name: "fetch", returnType: "Data") { fn in
                fn.append(line: "await download()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public func fetch() async -> Data {"))
    }

    @Test func subscriptGetSet() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Storage") { type in
            type.appendSubscript(accessLevel: .public, arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "index", type: "Int"),
            ], returnType: "Int") { fn in
                fn.append(line: "get { items[index] }")
                fn.append(line: "set { items[index] = newValue }")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public subscript(_ index: Int) -> Int {"))
        #expect(result.contains("        get { items[index] }"))
        #expect(result.contains("        set { items[index] = newValue }"))
    }

    @Test func subscriptStatic() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Registry") { type in
            type.appendSubscript(accessLevel: .public, isStatic: true, arguments: [
                SwiftFunctionArgument(name: "key", type: "String"),
            ], returnType: "Value?") { fn in
                fn.append(line: "return storage[key]")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    public static subscript(key: String) -> Value? {"))
    }

    @Test func subscriptWithAccessLevel() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .class, name: "SafeArray") { type in
            type.appendSubscript(accessLevel: .private, arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "index", type: "Int"),
            ], returnType: "Int?") { fn in
                fn.appendGuard(condition: "index >= 0, index < items.count") { fb in
                    fb.appendReturn("nil")
                }
                fn.appendReturn("items[index]")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    private subscript(_ index: Int) -> Int? {"))
        #expect(result.contains("        return items[index]"))
    }

    @Test func subscriptFullOutput() {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Matrix") { type in
            type.appendSubscript(accessLevel: .public, arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "row", type: "Int"),
                SwiftFunctionArgument(outerLabel: "_", name: "col", type: "Int"),
            ], returnType: "Double") { fn in
                fn.append(line: "get { rows[row][col] }")
                fn.append(line: "set { rows[row][col] = newValue }")
            }
        }
        let result = file.finalize()
        #expect(result == """
            public struct Matrix {
                public subscript(_ row: Int, _ col: Int) -> Double {
                    get { rows[row][col] }
                    set { rows[row][col] = newValue }
                }
            }

            """)
    }
}
