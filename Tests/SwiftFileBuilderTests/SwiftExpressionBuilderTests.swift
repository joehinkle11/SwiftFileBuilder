import Testing
@testable import SwiftFileBuilder

@Suite("SwiftExpressionBuilder")
struct SwiftExpressionBuilderTests {
    @Test func nestedMultilineCall() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendVariable(name: "value", initialValue: { expression in
            expression.appendCall("Container", prefix: "unsafe", layout: .multiline) { call in
                call.appendArgument(label: "id", expression: "makeID()")
                call.appendArgument(label: "metadata") { argument in
                    argument.appendCall("Metadata", layout: .multiline) { nested in
                        nested.appendArgument(label: "name", expression: "name")
                    }
                }
            }
        })
        #expect(file.finalize() == """
        var value = unsafe Container(
          id: makeID(),
          metadata: Metadata(
            name: name,
          ),
        )

        """)
    }

    @Test func arrayAndDictionaryLayouts() {
        var expression = SwiftExpressionBuilder()
        expression.appendDictionary(layout: .multiline) { dictionary in
            dictionary.appendEntry(key: "1", value: ".first")
            dictionary.appendEntry(key: "2") { value in
                value.appendArray(layout: .multiline) { array in
                    array.appendElement(".second")
                }
            }
        }
        #expect(expression.rendered(indentString: "  ").joined(separator: "\n") == """
        [
          1: .first,
          2: [
            .second,
          ],
        ]
        """)
    }

    @Test func emptyCollections() {
        var array = SwiftExpressionBuilder()
        array.appendArray(layout: .multiline) { _ in }
        var dictionary = SwiftExpressionBuilder()
        dictionary.appendDictionary(layout: .multiline) { _ in }
        #expect(array.rendered(indentString: "    ") == ["[]"])
        #expect(dictionary.rendered(indentString: "    ") == ["[:]"])
    }

    @Test func expressionSitesAndLocalVariables() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendVariable(isLet: true, name: "global") { expression in
            expression.appendArray { $0.appendElement("1") }
        }
        file.appendType(kind: .struct, name: "Values") { type in
            type.appendStoredProperty(name: "stored", type: "[Int]") { expression in
                expression.appendArray(layout: .multiline) { $0.appendElement("2") }
            }
            type.appendMethod(name: "make") { function in
                function.appendVariable(attributes: "@Wrapper", modifiers: "nonisolated", isLet: true, name: "local", type: "Int") { expression in
                    expression.appendCall("value") { _ in }
                }
                function.appendExpression { expression in
                    expression.appendCall("consume") { $0.appendArgument(expression: "local") }
                }
                function.appendReturn { expression in
                    expression.appendCall("finish", layout: .multiline) { $0.appendArgument(expression: "local") }
                }
            }
        }
        #expect(file.finalize() == """
        let global = [1]
        struct Values {
          var stored: [Int] = [
            2,
          ]
          func make() {
            @Wrapper nonisolated let local: Int = value()
            consume(local)
            return finish(
              local,
            )
          }
        }

        """)
    }

    @Test func closureArgumentWithTypedThrowsAndBodyBuilders() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendFunction(name: "register") { function in
            function.appendExpression { expression in
                expression.appendCall("run", layout: .multiline) { call in
                    call.appendClosureArgument(
                        label: "handler",
                        parameters: ["value", "_"],
                        isAsync: true,
                        typedThrow: "ProcessingError",
                        returnType: "Result"
                    ) { closure in
                        closure.appendVariable(isLet: true, name: "result", initialValue: "process(value)")
                        closure.appendIf("result.isEmpty") { body in
                            body.appendReturn(".empty")
                        }
                        closure.appendReturn { $0.append("result") }
                    }
                }
            }
        }
        #expect(file.finalize() == """
        func register() {
          run(
            handler: { value, _ async throws(ProcessingError) -> Result in
              let result = process(value)
              if result.isEmpty {
                return .empty
              }
              return result
            },
          )
        }

        """)
    }
}
