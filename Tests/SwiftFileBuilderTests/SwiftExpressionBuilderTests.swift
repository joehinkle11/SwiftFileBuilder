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
}
