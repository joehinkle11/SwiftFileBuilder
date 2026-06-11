public struct SwiftSwitchBuilder: ~Copyable {
    var parentFunction: SwiftFunctionBuilder
    
    public mutating func appendCase(_ switchCase: String, where whereClause: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        var line = "case \(switchCase)"
        if let whereClause {
            line += " where \(whereClause)"
        }
        line += ":"
        parentFunction.append(line: line)
        parentFunction.codeBuilder.indent()
        builder(&parentFunction)
        parentFunction.codeBuilder.outdent()
    }

    public mutating func appendCase(patterns: [String], where whereClause: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendCase(patterns.joined(separator: ", "), where: whereClause, builder: builder)
    }
    
    public mutating func appendDefault(builder: (inout SwiftFunctionBuilder) -> Void) {
        parentFunction.append(line: "default:")
        parentFunction.codeBuilder.indent()
        builder(&parentFunction)
        parentFunction.codeBuilder.outdent()
    }
}
