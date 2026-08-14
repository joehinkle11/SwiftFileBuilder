import Testing
@testable import SwiftFileBuilder

@Suite("Closure statement bodies")
struct ClosureStatementBodyTests {
    @Test(arguments: ["  ", "\t"])
    func switchInMultilineCallUsesDestinationIndent(_ indent: String) {
        var file = SwiftFileBuilder(indentString: indent)
        file.appendVariable(isLet: true, name: "registration", initialValue: { expression in
            expression.appendCall("register", layout: .multiline) { call in
                call.appendClosureArgument(label: "handler", parameters: ["value"]) { closure in
                    closure.appendSwitch("value") { selection in
                        selection.appendCase(
                            patterns: [".first", ".legacy"],
                            where: "isEnabled",
                            trailingComment: "supported"
                        ) { body in
                            body.append(line: "prepare()")
                            body.appendReturn("makeFirstResult()")
                        }
                        selection.appendCase(".second(let payload)") { body in
                            body.appendReturn("makeSecondResult(payload)")
                        }
                        selection.appendDefault(trailingComment: "future values") { body in
                            body.append(line: "throw GenerationError.unsupportedValue")
                        }
                    }
                }
            }
        })

        let i = indent
        #expect(file.finalize() == """
        let registration = register(
        \(i)handler: { value in
        \(i)\(i)switch value {
        \(i)\(i)case .first, .legacy where isEnabled:  // supported
        \(i)\(i)\(i)prepare()
        \(i)\(i)\(i)return makeFirstResult()
        \(i)\(i)case .second(let payload):
        \(i)\(i)\(i)return makeSecondResult(payload)
        \(i)\(i)default:  // future values
        \(i)\(i)\(i)throw GenerationError.unsupportedValue
        \(i)\(i)}
        \(i)},
        )

        """)
    }

    @Test(arguments: ["    ", "  "])
    func typedDoAndMultipleCatchesInClosure(_ indent: String) {
        var file = SwiftFileBuilder(indentString: indent)
        file.appendVariable(isLet: true, name: "callback", initialValue: { expression in
            expression.appendClosure(parameters: ["value"]) { closure in
                closure.appendDo(
                    typedThrow: "CallbackError",
                    catches: [
                        (pattern: "let error as CallbackError", builder: { body in
                            body.append(line: "handle(error)")
                        }),
                        (pattern: nil, builder: { body in
                            body.append(line: "preconditionFailure(\"Callback failed: \\(error)\")")
                        }),
                    ]
                ) { body in
                    body.append(line: "let result = try performCallback(value)")
                    body.appendReturn("transform(result)")
                }
            }
        })

        let i = indent
        #expect(file.finalize() == """
        let callback = { value in
        \(i)do throws(CallbackError) {
        \(i)\(i)let result = try performCallback(value)
        \(i)\(i)return transform(result)
        \(i)} catch let error as CallbackError {
        \(i)\(i)handle(error)
        \(i)} catch {
        \(i)\(i)preconditionFailure("Callback failed: \\(error)")
        \(i)}
        }

        """)
    }

    @Test func plainDoInClosure() {
        var file = SwiftFileBuilder()
        file.appendVariable(isLet: true, name: "callback", initialValue: { expression in
            expression.appendClosure { closure in
                closure.appendDo { $0.append(line: "work()") }
            }
        })
        #expect(file.finalize().contains("    do {\n        work()\n    }"))
    }

    @Test func genericLocalFunctionSupportsFullSignatureAndLayouts() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendVariable(isLet: true, name: "operation", initialValue: { expression in
            expression.appendCall("run", layout: .multiline) { call in
                call.appendClosureArgument(label: "operation", parameters: ["input"]) { closure in
                    closure.appendFunction(
                        typedThrow: "ConversionError",
                        isAsync: true,
                        name: "convert",
                        generics: [.init(name: "T", constraints: ["Convertible", "Sendable"])],
                        arguments: [
                            .init(outerLabel: "_", name: "type", type: "T.Type"),
                            .init(name: "value", ownership: .consuming, type: "Input"),
                        ],
                        parameterLayout: .multiline,
                        returnType: "Output"
                    ) { function in
                        function.appendReturn("try await T.convert(value)")
                    }
                    closure.appendFunction(name: "finish", returnType: "Output") {
                        $0.appendReturn(".done")
                    }
                    closure.appendReturn("try await convert(Expected.self, value: input)")
                }
            }
        })

        #expect(file.finalize() == """
        let operation = run(
          operation: { input in
            func convert<T: Convertible & Sendable>(
              _ type: T.Type,
              value: consuming Input,
            ) async throws(ConversionError) -> Output {
              return try await T.convert(value)
            }
            func finish() -> Output {
              return .done
            }
            return try await convert(Expected.self, value: input)
          },
        )

        """)
    }

    @Test func typedDoIsAlsoAvailableInFunctions() {
        var file = SwiftFileBuilder()
        file.appendFunction(name: "perform") { function in
            function.appendDo(typedThrow: "OperationError") { body in
                body.append(line: "try work()")
            }
        }
        #expect(file.finalize().contains("    do throws(OperationError) {"))
    }
}
