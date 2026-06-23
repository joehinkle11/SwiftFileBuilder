import Testing
import Foundation
@testable import SwiftFileBuilder

@Suite("CompileVerification")
struct CompileVerificationTests {

    private func typeCheckSwift(_ code: String) throws -> (exitCode: Int32, stderr: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "SwiftFileBuilderTest_\(UUID().uuidString).swift"
        let fileURL = tempDir.appendingPathComponent(fileName)
        try code.write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        process.arguments = ["-typecheck", fileURL.path]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrStr = String(data: stderrData, encoding: .utf8) ?? ""
        return (process.terminationStatus, stderrStr)
    }

    @Test func simpleStructCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Point") { type in
            type.appendStoredProperty(accessLevel: .public, name: "x", type: "Int")
            type.appendStoredProperty(accessLevel: .public, name: "y", type: "Int")
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func enumWithMethodCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "Direction") { type in
            type.appendCase(name: "north")
            type.appendCase(name: "south")
            type.appendCase(name: "east")
            type.appendCase(name: "west")
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "isVertical", returnType: "Bool") { fn in
                fn.appendSwitch("self") { sw in
                    sw.appendCase(".north, .south") { fb in
                        fb.appendReturn("true")
                    }
                    sw.appendCase(".east, .west") { fb in
                        fb.appendReturn("false")
                    }
                }
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func classWithInitAndMethodCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .class, name: "Counter") { type in
            type.appendStoredProperty(accessLevel: .private, name: "count", type: "Int")
            type.appendNewline()
            type.appendInitializer(accessLevel: .public) { fn in
                fn.append(line: "self.count = 0")
            }
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "increment") { fn in
                fn.append(line: "count += 1")
            }
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "currentCount", returnType: "Int") { fn in
                fn.appendReturn("count")
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func fullFileWithImportAndControlFlowCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendFunction(accessLevel: .public, name: "process", arguments: [
            SwiftFunctionArgument(name: "items", type: "[Int]"),
        ], returnType: "Int") { fn in
            fn.append(line: "var total = 0")
            fn.appendForLoop(element: "item", collection: "items") { fb in
                fb.appendIf("item > 0") { inner in
                    inner.append(line: "total += item")
                }
            }
            fn.appendReturn("total")
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func protocolAndExtensionCompile() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .protocol, name: "Describable") { type in
            type.appendProperty("var description: String { get }")
        }
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .struct, name: "Item", inheritedTypes: ["Describable"]) { type in
            type.appendStoredProperty(accessLevel: .public, name: "name", type: "String")
            type.appendNewline()
            type.appendMethod(accessLevel: .public, asGetter: true, name: "description", returnType: "String") { fn in
                fn.appendReturn("name")
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func nestedTypesCompile() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Outer") { outer in
            outer.appendNestedType(accessLevel: .public, kind: .enum, name: "Status") { status in
                status.appendCase(name: "active")
                status.appendCase(name: "inactive")
            }
            outer.appendNewline()
            outer.appendStoredProperty(accessLevel: .public, name: "status", type: "Status")
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func throwingFunctionCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "ParseError", inheritedTypes: ["Error"]) { type in
            type.appendCase(name: "invalidInput")
        }
        file.appendNewline()
        file.appendFunction(accessLevel: .public, isThrowing: true, name: "parse", arguments: [
            SwiftFunctionArgument(name: "input", type: "String"),
        ], returnType: "Int") { fn in
            fn.appendGuard(condition: "let value = Int(input)") { fb in
                fb.append(line: "throw ParseError.invalidInput")
            }
            fn.appendReturn("value")
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func repeatWhileCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .public, name: "process", arguments: [
            SwiftFunctionArgument(name: "items", type: "[Int]"),
        ]) { fn in
            fn.append(line: "var i = 0")
            fn.appendRepeatWhile("i < items.count") { fb in
                fb.append(line: "i += 1")
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func doCatchCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "MyError", inheritedTypes: ["Error"]) { type in
            type.appendCase(name: "bad")
        }
        file.appendNewline()
        file.appendFunction(accessLevel: .public, isThrowing: true, name: "run") { fn in
            fn.appendDo(catches: [
                (pattern: nil, builder: { fb in
                    fb.append(line: "print(\"caught\")")
                })
            ]) { fb in
                fb.append(line: "throw MyError.bad")
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func typedThrowingFunctionCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "ParseError", inheritedTypes: ["Error"]) { type in
            type.appendCase(name: "invalidInput")
        }
        file.appendNewline()
        file.appendFunction(accessLevel: .public, typedThrow: "ParseError", name: "parse", arguments: [
            SwiftFunctionArgument(name: "input", type: "String"),
        ], returnType: "Int") { fn in
            fn.appendGuard(condition: "let value = Int(input)") { fb in
                fb.append(line: "throw ParseError.invalidInput")
            }
            fn.appendReturn("value")
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }

    @Test func subscriptCompiles() throws {
        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Storage") { type in
            type.appendStoredProperty(accessLevel: .private, name: "items", type: "[Int]")
            type.appendNewline()
            type.appendSubscript(accessLevel: .public, arguments: [
                SwiftFunctionArgument(outerLabel: "_", name: "index", type: "Int"),
            ], returnType: "Int") { fn in
                fn.append(line: "get { items[index] }")
                fn.append(line: "set { items[index] = newValue }")
            }
        }
        let code = file.finalize()
        let result = try typeCheckSwift(code)
        #expect(result.exitCode == 0, "swiftc -typecheck failed:\n\(result.stderr)")
    }
}
