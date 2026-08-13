public protocol SwiftStatementBodyBuilder: ~Copyable {
    mutating func append(line: String)
    mutating func append(lines: [String])
    mutating func append(content: String)
    mutating func appendNewline()
    mutating func appendReturn(_ expression: String?)
    mutating func appendReturn(builder: (inout SwiftExpressionBuilder) -> Void)
    mutating func appendExpression(builder: (inout SwiftExpressionBuilder) -> Void)
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
