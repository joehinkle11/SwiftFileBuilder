public struct SwiftSwitchBuilder<Body: SwiftStatementBodyBuilder & ~Copyable>: ~Copyable {
    private var body: Body

    init(body: consuming Body) {
        self.body = body
    }

    consuming func takeBody() -> Body { body }
    
    public mutating func appendCase(_ switchCase: String, where whereClause: String? = nil, trailingComment: String? = nil, builder: (inout Body) -> Void) {
        var line = "case \(switchCase)"
        if let whereClause {
            line += " where \(whereClause)"
        }
        line += ":"
        if let trailingComment { line += "  // \(trailingComment)" }
        body.append(line: line)
        body._indentStatementBody()
        builder(&body)
        body._outdentStatementBody()
    }

    public mutating func appendCase(patterns: [String], where whereClause: String? = nil, trailingComment: String? = nil, builder: (inout Body) -> Void) {
        appendCase(patterns.joined(separator: ", "), where: whereClause, trailingComment: trailingComment, builder: builder)
    }

    public mutating func appendCase(
        _ switchCase: String,
        where condition: (inout SwiftConditionBuilder) -> Void,
        trailingComment: String? = nil,
        builder: (inout Body) -> Void
    ) {
        var conditionBuilder = SwiftConditionBuilder()
        condition(&conditionBuilder)
        let lines = conditionBuilder.lines
        if lines.count <= 1 {
            appendCase(switchCase, where: lines.first, trailingComment: trailingComment, builder: builder)
            return
        }
        body.append(line: "case \(switchCase) where \(lines[0])")
        body._indentStatementBody()
        for (index, line) in lines.dropFirst().enumerated() {
            var rendered = line
            if index == lines.count - 2 {
                rendered += ":"
                if let trailingComment { rendered += "  // \(trailingComment)" }
            }
            body.append(line: rendered)
        }
        builder(&body)
        body._outdentStatementBody()
    }
    
    public mutating func appendDefault(trailingComment: String? = nil, builder: (inout Body) -> Void) {
        var line = "default:"
        if let trailingComment { line += "  // \(trailingComment)" }
        body.append(line: line)
        body._indentStatementBody()
        builder(&body)
        body._outdentStatementBody()
    }
}
