public struct SwiftFunctionBuilder: ~Copyable {

    var asGetter = false
    var attributes: String?
    var attributeLayout: SwiftAttributeLayout = .inline
    var accessLevel: AccessLevel?
    var isStatic = false
    var isOverride = false
    var isConsuming = false
    var isMutating = false
    var isThrowing = false
    var typedThrow: String?
    var isRethrowing = false
    var isAsync = false
    var modifiers: [SwiftFunctionModifier] = []
    var initPrefix: String = ""
    var name: String
    var generics: [SwiftGeneric]
    var arguments: [SwiftFunctionArgument]
    var parameterLayout: SwiftFunctionParameterLayout = .compact
    var returnType: String?
    var codeBuilder: SwiftCodeBuilder

    mutating func start() {
        var genericsStr = ""
        if generics.isEmpty == false {
            if asGetter {
                Swift.assertionFailure("SwiftFunctionBuilder: generic getters are not supported by Swift. This is a codegen-template bug; check the caller of `appendMethod(asGetter: true, generics: ...)`.")
            }
            genericsStr = "<"
            for (i, generic) in generics.enumerated() {
                if i > 0 {
                    genericsStr += ", "
                }
                genericsStr += "\(generic.name)"
                if generic.constraints.isEmpty == false {
                    genericsStr += ": \(generic.constraints.joined(separator: " & "))"
                }
            }
            genericsStr += ">"
        }
        if attributeLayout == .separateLines, let attributes {
            codeBuilder.append(content: attributes)
        }
        let attributesStr = attributeLayout == .inline ? attributes.map { "\($0) " } ?? "" : ""
        let accessLevelStr = accessLevel.map { "\($0.rawValue) " } ?? ""
        let nameStr: String
        if name == "init" || name == "init?" {
            nameStr = "\(initPrefix)\(name)"
        } else if asGetter {
            nameStr = "var \(name)"
        } else {
            nameStr = "func \(name)"
        }
        let staticStr = isStatic ? "static " : ""
        let overrideStr = isOverride ? "override " : ""
        var renderedModifiers = modifiers.sorted { $0.sortOrder < $1.sortOrder }.map(\.rendered)
        if isConsuming && !renderedModifiers.contains("consuming") { renderedModifiers.append("consuming") }
        let modifiersStr = renderedModifiers.isEmpty ? "" : renderedModifiers.joined(separator: " ") + " "
        let mutatingStr = isMutating ? "mutating " : ""
        var line = "\(attributesStr)\(accessLevelStr)\(modifiersStr)\(overrideStr)\(staticStr)\(mutatingStr)\(nameStr)\(genericsStr)"
        if asGetter {
            guard let returnType else {
                Swift.assertionFailure("SwiftFunctionBuilder: getter requires an explicit return type. This is a codegen-template bug; check the caller of `appendMethod(asGetter: true, returnType: nil)`.")
                line.append(": Never")
                line += " {"
                codeBuilder.append(line: line)
                codeBuilder.indent()
                return
            }
            line.append(": \(returnType)")
        } else {
            switch parameterLayout {
            case .compact:
                line.append("(\(arguments.map { $0.rendered }.joined(separator: ", ")))")
            case .multiline:
                if arguments.isEmpty {
                    line.append("()")
                    break
                }
                line.append("(")
                codeBuilder.append(line: line)
                codeBuilder.indent()
                for argument in arguments {
                    codeBuilder.append(line: argument.rendered + ",")
                }
                codeBuilder.outdent()
                line = ")"
            }
            if isAsync {
                line += " async"
            }
            if let typedThrow {
                line += " throws(\(typedThrow))"
            } else if isThrowing {
                line += " throws"
            } else if isRethrowing {
                line += " rethrows"
            }
            if let returnType {
                line += " -> \(returnType)"
            }
        }
        line += " {"
        codeBuilder.append(line: line)
        codeBuilder.indent()
    }
    
    public mutating func appendNewline() {
        codeBuilder.appendNewline()
    }

    public mutating func append(line: String) {
        codeBuilder.append(line: line)
    }

    public mutating func append(stringBuilder: consuming SwiftStringBuilder) {
        codeBuilder.append(stringBuilder: stringBuilder)
    }

    public mutating func appendString(
        isMultilineString: Bool = false,
        builder: (inout SwiftStringBuilder) -> Void
    ) {
        var sb = SwiftStringBuilder(isMultilineString: isMultilineString)
        builder(&sb)
        codeBuilder.append(stringBuilder: sb)
    }

    public mutating func append(lines: [String]) {
        codeBuilder.append(lines: lines)
    }
    
    public mutating func append(content: String) {
        codeBuilder.append(content: content)
    }
    
    public mutating func appendMark(_ title: String, withSeparator: Bool = true) {
        if withSeparator {
            codeBuilder.append(line: "// MARK: - \(title)")
        } else {
            codeBuilder.append(line: "// MARK: \(title)")
        }
    }
    
    public mutating func _indentStatementBody() { codeBuilder.indent() }
    public mutating func _outdentStatementBody() { codeBuilder.outdent() }
    
    public mutating func appendWhile(_ test: String, label: String? = nil, builder: (inout SwiftFunctionBuilder) -> Void) {
        var labelStr = ""
        if let label = label {
            labelStr = "\(label): "
        }
        codeBuilder.append(line: "\(labelStr)while \(test) {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendWhile(
        condition: (inout SwiftConditionBuilder) -> Void,
        label: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        var conditionBuilder = SwiftConditionBuilder()
        condition(&conditionBuilder)
        appendMultilineBlock(keyword: label.map { "\($0): while " } ?? "while ", condition: conditionBuilder, suffix: " {", builder: builder)
    }

    public mutating func appendBlock(header: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        let headerLine = header.hasSuffix("{") ? header : header + " {"
        codeBuilder.append(line: headerLine)
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendForLoop(element: String, collection: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendBlock(header: "for \(element) in \(collection) {", builder: builder)
    }

    public mutating func appendGuard(condition: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendBlock(header: "guard \(condition) else {", builder: builder)
    }

    public mutating func appendGuard(
        condition: (inout SwiftConditionBuilder) -> Void,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        var conditionBuilder = SwiftConditionBuilder()
        condition(&conditionBuilder)
        appendMultilineBlock(keyword: "guard ", condition: conditionBuilder, suffix: " else {", builder: builder)
    }

    public mutating func appendIf(
        _ condition: String,
        builder: (inout SwiftFunctionBuilder) -> Void,
        elseIf: [(condition: String, builder: (inout SwiftFunctionBuilder) -> Void)] = [],
        elseBuilder: ((inout SwiftFunctionBuilder) -> Void)? = nil
    ) {
        codeBuilder.append(line: "if \(condition) {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()

        for clause in elseIf {
            codeBuilder.append(line: "} else if \(clause.condition) {")
            codeBuilder.indent()
            clause.builder(&self)
            codeBuilder.outdent()
        }

        if let elseBuilder {
            codeBuilder.append(line: "} else {")
            codeBuilder.indent()
            elseBuilder(&self)
            codeBuilder.outdent()
        }

        codeBuilder.append(line: "}")
    }

    public mutating func appendIf(
        condition: (inout SwiftConditionBuilder) -> Void,
        builder: (inout SwiftFunctionBuilder) -> Void,
        elseBuilder: ((inout SwiftFunctionBuilder) -> Void)? = nil
    ) {
        var conditionBuilder = SwiftConditionBuilder()
        condition(&conditionBuilder)
        appendMultilineHeader(keyword: "if ", condition: conditionBuilder, suffix: " {")
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

    private mutating func appendMultilineHeader(keyword: String, condition: SwiftConditionBuilder, suffix: String) {
        guard let first = condition.lines.first else {
            codeBuilder.append(line: keyword + suffix)
            return
        }
        if condition.lines.count == 1 {
            codeBuilder.append(line: keyword + first + suffix)
            return
        }
        codeBuilder.append(line: keyword + first)
        codeBuilder.indent()
        for (index, line) in condition.lines.dropFirst().enumerated() {
            codeBuilder.append(line: line + (index == condition.lines.count - 2 ? suffix : ""))
        }
        codeBuilder.outdent()
    }

    private mutating func appendMultilineBlock(
        keyword: String,
        condition: SwiftConditionBuilder,
        suffix: String,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        appendMultilineHeader(keyword: keyword, condition: condition, suffix: suffix)
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendIfLet(binding: String, optional: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendIf("let \(binding) = \(optional)", builder: builder)
    }

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
        var prefix = ""
        if let attributes { prefix += attributes + " " }
        if let modifiers { prefix += modifiers + " " }
        prefix += isLet ? "let " : "var "
        prefix += name
        if let type { prefix += ": \(type)" }
        codeBuilder.append(expression: expression, prefix: prefix + " = ")
    }

    public mutating func appendContinue(_ label: String? = nil) {
        codeBuilder.append(line: label.map { "continue \($0)" } ?? "continue")
    }

    public mutating func appendBreak(_ label: String? = nil) {
        codeBuilder.append(line: label.map { "break \($0)" } ?? "break")
    }

    public mutating func appendDefer(builder: (inout SwiftFunctionBuilder) -> Void) {
        appendBlock(header: "defer", builder: builder)
    }

    public mutating func appendClosureBlock(
        call: String,
        parameterClause: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let header: String
        if let parameterClause {
            header = "\(call) { \(parameterClause) in"
        } else {
            header = "\(call) {"
        }
        codeBuilder.append(line: header)
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendRepeatWhile(
        _ test: String,
        label: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        var labelStr = ""
        if let label = label {
            labelStr = "\(label): "
        }
        codeBuilder.append(line: "\(labelStr)repeat {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        codeBuilder.append(line: "} while \(test)")
    }

    public mutating func appendCompilerIf(
        _ condition: String,
        builder: (inout SwiftFunctionBuilder) -> Void,
        elseBuilder: ((inout SwiftFunctionBuilder) -> Void)? = nil
    ) {
        codeBuilder.append(line: "#if \(condition)")
        builder(&self)
        if let elseBuilder {
            codeBuilder.append(line: "#else")
            elseBuilder(&self)
        }
        codeBuilder.append(line: "#endif")
    }

    consuming func end() -> SwiftCodeBuilder {
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
        return codeBuilder
    }
    
    public mutating func appendFunction(
        attributes: String? = nil,
        attributeLayout: SwiftAttributeLayout = .inline,
        modifiers: [SwiftFunctionModifier] = [],
        isThrowing: Bool = false,
        typedThrow: String? = nil,
        isRethrowing: Bool = false,
        isAsync: Bool = false,
        name: String,
        generics: [SwiftGeneric] = [],
        arguments: [SwiftFunctionArgument] = [],
        parameterLayout: SwiftFunctionParameterLayout = .compact,
        returnType: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let outer = (
            asGetter, attributes, attributeLayout, accessLevel, isStatic, isOverride,
            isConsuming, isMutating, isThrowing, typedThrow, isRethrowing, isAsync,
            modifiers, initPrefix, name, generics, arguments, parameterLayout, returnType
        )
        var funcBuilder = SwiftFunctionBuilder(attributes: attributes, attributeLayout: attributeLayout, isThrowing: isThrowing, typedThrow: typedThrow, isRethrowing: isRethrowing, isAsync: isAsync, modifiers: modifiers, name: name, generics: generics, arguments: arguments, parameterLayout: parameterLayout, returnType: returnType, codeBuilder: codeBuilder)
        funcBuilder.start()
        builder(&funcBuilder)
        self = SwiftFunctionBuilder(
            asGetter: outer.0, attributes: outer.1, attributeLayout: outer.2,
            accessLevel: outer.3, isStatic: outer.4, isOverride: outer.5,
            isConsuming: outer.6, isMutating: outer.7, isThrowing: outer.8,
            typedThrow: outer.9, isRethrowing: outer.10, isAsync: outer.11,
            modifiers: outer.12, initPrefix: outer.13, name: outer.14,
            generics: outer.15, arguments: outer.16, parameterLayout: outer.17,
            returnType: outer.18, codeBuilder: funcBuilder.end()
        )
    }
}
