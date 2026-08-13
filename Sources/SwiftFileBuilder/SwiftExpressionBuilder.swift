public enum SwiftExpressionLayout: Sendable {
    case compact
    case multiline
}

public struct SwiftExpressionBuilder {
    fileprivate var expression: SwiftExpression = .raw("")

    public init() {}

    public mutating func append(_ expression: String) {
        self.expression = .raw(expression)
    }

    public mutating func appendCall(
        _ name: String,
        prefix: String? = nil,
        layout: SwiftExpressionLayout = .compact,
        builder: (inout SwiftCallExpressionBuilder) -> Void
    ) {
        var call = SwiftCallExpressionBuilder()
        builder(&call)
        expression = .call(name: name, prefix: prefix, layout: layout, arguments: call.arguments)
    }

    public mutating func appendArray(
        layout: SwiftExpressionLayout = .compact,
        builder: (inout SwiftArrayExpressionBuilder) -> Void
    ) {
        var array = SwiftArrayExpressionBuilder()
        builder(&array)
        expression = .array(layout: layout, elements: array.elements)
    }

    public mutating func appendDictionary(
        layout: SwiftExpressionLayout = .compact,
        builder: (inout SwiftDictionaryExpressionBuilder) -> Void
    ) {
        var dictionary = SwiftDictionaryExpressionBuilder()
        builder(&dictionary)
        expression = .dictionary(layout: layout, entries: dictionary.entries)
    }

    public mutating func appendClosure(
        parameters: [String] = [],
        isAsync: Bool = false,
        isThrowing: Bool = false,
        typedThrow: String? = nil,
        returnType: String? = nil,
        builder: (inout SwiftClosureExpressionBuilder) -> Void
    ) {
        var closure = SwiftClosureExpressionBuilder()
        builder(&closure)
        expression = .closure(
            parameters: parameters,
            isAsync: isAsync,
            isThrowing: isThrowing,
            typedThrow: typedThrow,
            returnType: returnType,
            body: closure.finish()
        )
    }
}

public struct SwiftCallExpressionBuilder {
    fileprivate var arguments: [SwiftCallArgument] = []

    public mutating func appendArgument(label: String? = nil, expression: String) {
        arguments.append(SwiftCallArgument(label: label, expression: .raw(expression)))
    }

    public mutating func appendArgument(
        label: String? = nil,
        expression builder: (inout SwiftExpressionBuilder) -> Void
    ) {
        var expression = SwiftExpressionBuilder()
        builder(&expression)
        arguments.append(SwiftCallArgument(label: label, expression: expression.expression))
    }

    public mutating func appendClosureArgument(
        label: String? = nil,
        parameters: [String] = [],
        isAsync: Bool = false,
        isThrowing: Bool = false,
        typedThrow: String? = nil,
        returnType: String? = nil,
        builder: (inout SwiftClosureExpressionBuilder) -> Void
    ) {
        var expression = SwiftExpressionBuilder()
        expression.appendClosure(
            parameters: parameters,
            isAsync: isAsync,
            isThrowing: isThrowing,
            typedThrow: typedThrow,
            returnType: returnType,
            builder: builder
        )
        arguments.append(SwiftCallArgument(label: label, expression: expression.expression))
    }

}

public struct SwiftClosureExpressionBuilder: ~Copyable {
    // Tabs are an internal, layout-independent indentation marker. They are
    // replaced with the destination builder's indentation string at render time.
    private var codeBuilder = SwiftCodeBuilder(indentString: "\t")

    public mutating func append(line: String) { codeBuilder.append(line: line) }
    public mutating func append(lines: [String]) { codeBuilder.append(lines: lines) }
    public mutating func append(content: String) { codeBuilder.append(content: content) }
    public mutating func appendNewline() { codeBuilder.appendNewline() }

    public mutating func appendReturn(_ expression: String? = nil) {
        codeBuilder.append(line: expression.map { "return \($0)" } ?? "return")
    }

    public mutating func appendReturn(builder: (inout SwiftExpressionBuilder) -> Void) {
        var expression = SwiftExpressionBuilder()
        builder(&expression)
        codeBuilder.append(expression: expression, prefix: "return ")
    }

    public mutating func appendExpression(builder: (inout SwiftExpressionBuilder) -> Void) {
        var expression = SwiftExpressionBuilder()
        builder(&expression)
        codeBuilder.append(expression: expression)
    }

    public mutating func appendVariable(
        attributes: String? = nil,
        modifiers: String? = nil,
        isLet: Bool = false,
        name: String,
        type: String? = nil,
        initialValue: String? = nil
    ) {
        var line = ""
        if let attributes { line += attributes + " " }
        if let modifiers { line += modifiers + " " }
        line += isLet ? "let " : "var "
        line += name
        if let type { line += ": \(type)" }
        if let initialValue { line += " = \(initialValue)" }
        codeBuilder.append(line: line)
    }

    public mutating func appendVariable(
        attributes: String? = nil,
        modifiers: String? = nil,
        isLet: Bool = false,
        name: String,
        type: String? = nil,
        initialValue builder: (inout SwiftExpressionBuilder) -> Void
    ) {
        var expression = SwiftExpressionBuilder()
        builder(&expression)
        var prefix = attributes.map { $0 + " " } ?? ""
        prefix += modifiers.map { $0 + " " } ?? ""
        prefix += isLet ? "let " : "var "
        prefix += name
        if let type { prefix += ": \(type)" }
        codeBuilder.append(expression: expression, prefix: prefix + " = ")
    }

    public mutating func appendGuard(condition: String, builder: (inout SwiftClosureExpressionBuilder) -> Void) {
        appendBlock(header: "guard \(condition) else", builder: builder)
    }

    public mutating func appendWhile(_ test: String, builder: (inout SwiftClosureExpressionBuilder) -> Void) {
        appendBlock(header: "while \(test)", builder: builder)
    }

    public mutating func appendIf(
        _ condition: String,
        builder: (inout SwiftClosureExpressionBuilder) -> Void,
        elseBuilder: ((inout SwiftClosureExpressionBuilder) -> Void)? = nil
    ) {
        codeBuilder.append(line: "if \(condition) {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        if let elseBuilder {
            codeBuilder.append(line: "} else {")
            codeBuilder.indent()
            elseBuilder(&self)
            codeBuilder.outdent()
        }
        codeBuilder.append(line: "}")
    }

    public mutating func appendBlock(header: String, builder: (inout SwiftClosureExpressionBuilder) -> Void) {
        codeBuilder.append(line: header.hasSuffix("{") ? header : header + " {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    fileprivate consuming func finish() -> [String] {
        codeBuilder.finalize().split(separator: "\n", omittingEmptySubsequences: false).dropLast().map(String.init)
    }
}

public struct SwiftArrayExpressionBuilder {
    fileprivate var elements: [SwiftExpression] = []

    public mutating func appendElement(_ expression: String) {
        elements.append(.raw(expression))
    }

    public mutating func appendElement(builder: (inout SwiftExpressionBuilder) -> Void) {
        var expression = SwiftExpressionBuilder()
        builder(&expression)
        elements.append(expression.expression)
    }
}

public struct SwiftDictionaryExpressionBuilder {
    fileprivate var entries: [(SwiftExpression, SwiftExpression)] = []

    public mutating func appendEntry(key: String, value: String) {
        entries.append((.raw(key), .raw(value)))
    }

    public mutating func appendEntry(
        key: String,
        value builder: (inout SwiftExpressionBuilder) -> Void
    ) {
        var value = SwiftExpressionBuilder()
        builder(&value)
        entries.append((.raw(key), value.expression))
    }

    public mutating func appendEntry(
        key keyBuilder: (inout SwiftExpressionBuilder) -> Void,
        value valueBuilder: (inout SwiftExpressionBuilder) -> Void
    ) {
        var key = SwiftExpressionBuilder()
        var value = SwiftExpressionBuilder()
        keyBuilder(&key)
        valueBuilder(&value)
        entries.append((key.expression, value.expression))
    }
}

private struct SwiftCallArgument {
    let label: String?
    let expression: SwiftExpression
}

private indirect enum SwiftExpression {
    case raw(String)
    case call(name: String, prefix: String?, layout: SwiftExpressionLayout, arguments: [SwiftCallArgument])
    case array(layout: SwiftExpressionLayout, elements: [SwiftExpression])
    case dictionary(layout: SwiftExpressionLayout, entries: [(SwiftExpression, SwiftExpression)])
    case closure(parameters: [String], isAsync: Bool, isThrowing: Bool, typedThrow: String?, returnType: String?, body: [String])

    func rendered(indent: Int = 0, indentString: String) -> [String] {
        switch self {
        case .raw(let value):
            return value.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        case .call(let name, let prefix, let layout, let arguments):
            let callee = [prefix, name].compactMap { $0 }.joined(separator: " ")
            guard layout == .multiline, !arguments.isEmpty else {
                let values = arguments.map { argument in
                    let value = argument.expression.rendered(indentString: indentString).joined(separator: " ")
                    return argument.label.map { "\($0): \(value)" } ?? value
                }
                return ["\(callee)(\(values.joined(separator: ", ")))"]
            }
            var lines = ["\(callee)("]
            for argument in arguments {
                var valueLines = argument.expression.rendered(indentString: indentString)
                let label = argument.label.map { "\($0): " } ?? ""
                lines.append(String(repeating: indentString, count: indent + 1) + label + valueLines.removeFirst())
                lines.append(contentsOf: valueLines.map { String(repeating: indentString, count: indent + 1) + $0 })
                lines[lines.count - 1] += ","
            }
            lines.append(String(repeating: indentString, count: indent) + ")")
            return lines
        case .array(let layout, let elements):
            guard layout == .multiline, !elements.isEmpty else {
                return ["[\(elements.map { $0.rendered(indentString: indentString).joined(separator: " ") }.joined(separator: ", "))]"]
            }
            var lines = ["["]
            for element in elements {
                var elementLines = element.rendered(indentString: indentString)
                lines.append(String(repeating: indentString, count: indent + 1) + elementLines.removeFirst())
                lines.append(contentsOf: elementLines.map { String(repeating: indentString, count: indent + 1) + $0 })
                lines[lines.count - 1] += ","
            }
            lines.append(String(repeating: indentString, count: indent) + "]")
            return lines
        case .dictionary(let layout, let entries):
            guard !entries.isEmpty else { return ["[:]"] }
            guard layout == .multiline else {
                let values = entries.map { key, value in
                    "\(key.rendered(indentString: indentString).joined(separator: " ")): \(value.rendered(indentString: indentString).joined(separator: " "))"
                }
                return ["[\(values.joined(separator: ", "))]"]
            }
            var lines = ["["]
            for (key, value) in entries {
                let keyText = key.rendered(indentString: indentString).joined(separator: " ")
                var valueLines = value.rendered(indentString: indentString)
                lines.append(String(repeating: indentString, count: indent + 1) + keyText + ": " + valueLines.removeFirst())
                lines.append(contentsOf: valueLines.map { String(repeating: indentString, count: indent + 1) + $0 })
                lines[lines.count - 1] += ","
            }
            lines.append(String(repeating: indentString, count: indent) + "]")
            return lines
        case .closure(let parameters, let isAsync, let isThrowing, let typedThrow, let returnType, let body):
            var signature = parameters.joined(separator: ", ")
            if parameters.isEmpty && (isAsync || isThrowing || typedThrow != nil || returnType != nil) { signature = "()" }
            if isAsync { signature += " async" }
            if let typedThrow { signature += " throws(\(typedThrow))" }
            else if isThrowing { signature += " throws" }
            if let returnType { signature += " -> \(returnType)" }
            var lines = [signature.isEmpty ? "{" : "{ \(signature) in"]
            lines.append(contentsOf: body.map { line in
                let depth = line.prefix { $0 == "\t" }.count
                return String(repeating: indentString, count: indent + 1 + depth) + line.dropFirst(depth)
            })
            lines.append(String(repeating: indentString, count: indent) + "}")
            return lines
        }
    }
}

extension SwiftExpressionBuilder {
    func rendered(indentString: String) -> [String] {
        expression.rendered(indentString: indentString)
    }
}
