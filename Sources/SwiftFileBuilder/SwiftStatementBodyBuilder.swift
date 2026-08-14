public protocol SwiftStatementBodyBuilder: ~Copyable {
    mutating func append(line: String)
    mutating func append(lines: [String])
    mutating func append(content: String)
    mutating func appendNewline()
    mutating func appendReturn(_ expression: String?)
    mutating func appendReturn(builder: (inout SwiftExpressionBuilder) -> Void)
    mutating func appendExpression(builder: (inout SwiftExpressionBuilder) -> Void)
    mutating func _indentStatementBody()
    mutating func _outdentStatementBody()
}

extension SwiftStatementBodyBuilder where Self: ~Copyable {
    // Defaults preserve source compatibility for third-party conformers. Built-in
    // builders override these hooks to provide structural indentation.
    public mutating func _indentStatementBody() {}
    public mutating func _outdentStatementBody() {}

    public mutating func appendSwitch(
        _ test: String,
        builder: (inout SwiftSwitchBuilder<Self>) -> Void
    ) {
        append(line: "switch \(test) {")
        var switchBuilder = SwiftSwitchBuilder(body: self)
        builder(&switchBuilder)
        self = switchBuilder.takeBody()
        append(line: "}")
    }

    public mutating func appendDo(
        typedThrow: String? = nil,
        catches: [(pattern: String?, builder: (inout Self) -> Void)] = [],
        builder: (inout Self) -> Void
    ) {
        let throwsClause = typedThrow.map { " throws(\($0))" } ?? ""
        append(line: "do\(throwsClause) {")
        _indentStatementBody()
        builder(&self)
        _outdentStatementBody()
        for (pattern, catchBuilder) in catches {
            append(line: pattern.map { "} catch \($0) {" } ?? "} catch {")
            _indentStatementBody()
            catchBuilder(&self)
            _outdentStatementBody()
        }
        append(line: "}")
    }
}

public struct SwiftClosureParameter: Sendable {
    public let name: String
    public let type: String?
    public let ownership: SwiftParameterOwnership

    public init(
        name: String,
        type: String? = nil,
        ownership: SwiftParameterOwnership = .none
    ) {
        self.name = name
        self.type = type
        self.ownership = ownership
    }

    public var rendered: String {
        if let type {
            let ownershipText = ownership == .none ? "" : ownership.rawValue + " "
            return "\(name): \(ownershipText)\(type)"
        }
        return ownership == .none ? name : "\(ownership.rawValue) \(name)"
    }
}

extension SwiftFunctionBuilder: SwiftStatementBodyBuilder {}
