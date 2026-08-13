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
        }
    }
}

extension SwiftExpressionBuilder {
    func rendered(indentString: String) -> [String] {
        expression.rendered(indentString: indentString)
    }
}
