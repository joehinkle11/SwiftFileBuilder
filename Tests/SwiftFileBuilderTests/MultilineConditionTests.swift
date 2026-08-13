import Testing
@testable import SwiftFileBuilder

@Suite("Multiline conditions and switch comments")
struct MultilineConditionTests {
    @Test func guardIfAndWhileConditions() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendFunction(name: "test") { function in
            function.appendGuard(condition: { condition in
                condition.append("let value = source")
                condition.append(".map(transform)")
                condition.append(".first")
            }) { $0.appendReturn("nil") }
            function.appendIf(condition: { $0.append(lines: ["value.isReady", "&& value.isValid"]) }) { body in
                body.appendWhile(condition: { $0.append(lines: ["await hasNext", "&& !cancelled"]) }) { $0.appendBreak() }
            }
        }
        #expect(file.finalize() == """
        func test() {
          guard let value = source
            .map(transform)
            .first else {
            return nil
          }
          if value.isReady
            && value.isValid {
            while await hasNext
              && !cancelled {
              break
            }
          }
        }

        """)
    }

    @Test func commentsAndMultilineWhere() {
        var file = SwiftFileBuilder(indentString: "  ")
        file.appendFunction(name: "test") { function in
            function.appendSwitch("value") { selection in
                selection.appendCase(patterns: ["0", "1"], trailingComment: "first operation") { $0.appendBreak() }
                selection.appendCase("value", where: { $0.append(lines: ["value > 10", "&& value < 20"]) }, trailingComment: "range") { $0.appendBreak() }
                selection.appendDefault(trailingComment: "fallback") { $0.appendBreak() }
            }
        }
        #expect(file.finalize() == """
        func test() {
          switch value {
          case 0, 1:  // first operation
            break
          case value where value > 10
            && value < 20:  // range
            break
          default:  // fallback
            break
          }
        }

        """)
    }
}
