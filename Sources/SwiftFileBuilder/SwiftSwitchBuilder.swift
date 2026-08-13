public struct SwiftSwitchBuilder: ~Copyable {
    var parentFunction: SwiftFunctionBuilder
    
    public mutating func appendCase(_ switchCase: String, where whereClause: String? = nil, trailingComment: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        var line = "case \(switchCase)"
        if let whereClause {
            line += " where \(whereClause)"
        }
        line += ":"
        if let trailingComment { line += "  // \(trailingComment)" }
        parentFunction.append(line: line)
        parentFunction.codeBuilder.indent()
        builder(&parentFunction)
        parentFunction.codeBuilder.outdent()
    }

    public mutating func appendCase(patterns: [String], where whereClause: String? = nil, trailingComment: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendCase(patterns.joined(separator: ", "), where: whereClause, trailingComment: trailingComment, builder: builder)
    }

    public mutating func appendCase(
        _ switchCase: String,
        where condition: (inout SwiftConditionBuilder) -> Void,
        trailingComment: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        var conditionBuilder = SwiftConditionBuilder()
        condition(&conditionBuilder)
        let lines = conditionBuilder.lines
        if lines.count <= 1 {
            appendCase(switchCase, where: lines.first, trailingComment: trailingComment, builder: builder)
            return
        }
        parentFunction.append(line: "case \(switchCase) where \(lines[0])")
        parentFunction.codeBuilder.indent()
        for (index, line) in lines.dropFirst().enumerated() {
            var rendered = line
            if index == lines.count - 2 {
                rendered += ":"
                if let trailingComment { rendered += "  // \(trailingComment)" }
            }
            parentFunction.append(line: rendered)
        }
        builder(&parentFunction)
        parentFunction.codeBuilder.outdent()
    }
    
    public mutating func appendDefault(trailingComment: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        var line = "default:"
        if let trailingComment { line += "  // \(trailingComment)" }
        parentFunction.append(line: line)
        parentFunction.codeBuilder.indent()
        builder(&parentFunction)
        parentFunction.codeBuilder.outdent()
    }
}
