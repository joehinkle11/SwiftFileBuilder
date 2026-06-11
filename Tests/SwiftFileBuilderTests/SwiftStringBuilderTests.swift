import Testing
@testable import SwiftFileBuilder

@Suite("SwiftStringBuilder")
struct SwiftStringBuilderTests {

    @Test func singleLinePlainText() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "Hello, World!")
        #expect(sb.build() == #"""
            "Hello, World!"
            """#)
    }

    @Test func singleLineWithInterpolation() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "Hello, ")
        sb.append(interpolation: "name")
        sb.append(literal: "!")
        #expect(sb.build() == #"""
            "Hello, \(name)!"
            """#)
    }

    @Test func singleLineEscapesQuotes() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "she said \"hello\"")
        #expect(sb.build() == #"""
            "she said \"hello\""
            """#)
    }

    @Test func singleLineEscapesBackslash() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "path\\to\\file")
        #expect(sb.build() == #"""
            "path\\to\\file"
            """#)
    }

    @Test func singleLineEscapesNewline() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "line1\nline2")
        #expect(sb.build() == #"""
            "line1\nline2"
            """#)
    }

    @Test func singleLineEscapesTab() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "col1\tcol2")
        #expect(sb.build() == #"""
            "col1\tcol2"
            """#)
    }

    @Test func singleLineEscapesCarriageReturn() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "a\rb")
        #expect(sb.build() == #"""
            "a\rb"
            """#)
    }

    @Test func singleLineMultipleInterpolations() {
        var sb = SwiftStringBuilder()
        sb.append(interpolation: "a")
        sb.append(literal: " + ")
        sb.append(interpolation: "b")
        #expect(sb.build() == #"""
            "\(a) + \(b)"
            """#)
    }

    @Test func multilinePlainText() {
        var sb = SwiftStringBuilder(isMultilineString: true)
        sb.append(literal: "Hello,\nWorld!")
        #expect(sb.build() == #"""
            """
            Hello,
            World!
            """
            """#)
    }

    @Test func multilineWithInterpolation() {
        var sb = SwiftStringBuilder(isMultilineString: true)
        sb.append(literal: "Hello, ")
        sb.append(interpolation: "name")
        sb.append(literal: "!")
        #expect(sb.build() == #"""
            """
            Hello, \(name)!
            """
            """#)
    }

    @Test func multilineDoesNotEscapeSingleQuotes() {
        var sb = SwiftStringBuilder(isMultilineString: true)
        sb.append(literal: #""hello""#)
        #expect(sb.build() == #"""
            """
            "hello"
            """
            """#)
    }

    @Test func multilineEscapesBackslash() {
        var sb = SwiftStringBuilder(isMultilineString: true)
        sb.append(literal: "a\\b")
        #expect(sb.build() == #"""
            """
            a\\b
            """
            """#)
    }

    @Test func appendToFileBuilder() {
        var builder = SwiftFileBuilder()
        var sb = SwiftStringBuilder()
        sb.append(literal: "Hello, ")
        sb.append(interpolation: "name")
        sb.append(literal: "!")
        builder.append(stringBuilder: sb)
        #expect(builder.finalize() == #"""
            "Hello, \(name)!"

            """#)
    }

    @Test func appendInFunctionBuilder() {
        var builder = SwiftFileBuilder()
        builder.appendFunction(name: "foo", arguments: []) { funcBuilder in
            var sb = SwiftStringBuilder()
            sb.append(literal: "debug")
            funcBuilder.append(stringBuilder: sb)
        }
        let result = builder.finalize()
        #expect(result == #"""
            func foo() {
                "debug"
            }

            """#)
    }

    @Test func appendInTypeBuilder() {
        var builder = SwiftFileBuilder()
        builder.appendType(kind: .struct, name: "Foo") { typeBuilder in
            var sb = SwiftStringBuilder()
            sb.append(literal: "value")
            typeBuilder.append(stringBuilder: sb)
        }
        let result = builder.finalize()
        #expect(result == #"""
            struct Foo {
                "value"
            }

            """#)
    }

    @Test func inlineViaBuild() {
        var sb = SwiftStringBuilder()
        sb.append(literal: "Hello, ")
        sb.append(interpolation: "name")
        sb.append(literal: "!")

        var builder = SwiftFileBuilder()
        builder.append(line: "let greeting = \(sb.build())")
        #expect(builder.finalize() == #"""
            let greeting = "Hello, \(name)!"

            """#)
    }

    @Test func userFacingExample() {
        var str = SwiftStringBuilder()
        str.append(literal: "Hello, ")
        str.append(interpolation: "templateVariable")
        str.append(literal: "!")

        var builder = SwiftFileBuilder()
        builder.append(line: "let output = \(str.build())")
        #expect(builder.finalize() == #"""
            let output = "Hello, \(templateVariable)!"

            """#)
    }

    @Test func multilineAppendToFileBuilder() {
        var builder = SwiftFileBuilder()
        var sb = SwiftStringBuilder(isMultilineString: true)
        sb.append(literal: "Hello, ")
        sb.append(interpolation: "name")
        sb.append(literal: "!")
        builder.append(stringBuilder: sb)
        let result = builder.finalize()
        #expect(result == #"""
            """
            Hello, \(name)!
            """

            """#)
    }

    @Test func emptyString() {
        let sb = SwiftStringBuilder()
        #expect(sb.build() == #"""
            ""
            """#)
    }

    @Test func emptyMultilineString() {
        let sb = SwiftStringBuilder(isMultilineString: true)
        #expect(sb.build() == #"""
            """

            """
            """#)
    }

    // MARK: - Convenience API (appendString)

    @Test func convenienceOnFileBuilderSingleLine() {
        var builder = SwiftFileBuilder()
        builder.appendString { sb in
            sb.append(literal: "Hello, ")
            sb.append(interpolation: "name")
            sb.append(literal: "!")
        }
        #expect(builder.finalize() == #"""
            "Hello, \(name)!"

            """#)
    }

    @Test func convenienceOnFileBuilderMultiline() {
        var builder = SwiftFileBuilder()
        builder.appendString(isMultilineString: true) { sb in
            sb.append(literal: "line1\nline2")
        }
        #expect(builder.finalize() == #"""
            """
            line1
            line2
            """

            """#)
    }

    @Test func convenienceOnFunctionBuilder() {
        var builder = SwiftFileBuilder()
        builder.appendFunction(name: "foo") { funcBuilder in
            funcBuilder.appendString { sb in
                sb.append(literal: "debug")
            }
        }
        #expect(builder.finalize() == #"""
            func foo() {
                "debug"
            }

            """#)
    }

    @Test func convenienceOnTypeBuilder() {
        var builder = SwiftFileBuilder()
        builder.appendType(kind: .struct, name: "Foo") { typeBuilder in
            typeBuilder.appendString(isMultilineString: true) { sb in
                sb.append(literal: "Hello,\nWorld!")
            }
        }
        #expect(builder.finalize() == #"""
            struct Foo {
                """
                Hello,
                World!
                """
            }

            """#)
    }
}
