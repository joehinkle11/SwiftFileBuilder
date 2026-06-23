public struct SwiftFunctionBuilder: ~Copyable {

    var asGetter = false
    var attributes: String?
    var accessLevel: AccessLevel?
    var isStatic = false
    var isOverride = false
    var isConsuming = false
    var isMutating = false
    var isThrowing = false
    var typedThrow: String?
    var isRethrowing = false
    var isAsync = false
    var initPrefix: String = ""
    var name: String
    var generics: [SwiftGeneric]
    var arguments: [SwiftFunctionArgument]
    var returnType: String?
    var codeBuilder: SwiftCodeBuilder

    mutating func start() {
        let argumentsStr = arguments.map { $0.rendered }.joined(separator: ", ")
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
        let attributesStr = attributes.map { "\($0) " } ?? ""
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
        let consumingStr = isConsuming ? "consuming " : ""
        let mutatingStr = isMutating ? "mutating " : ""
        var line = "\(attributesStr)\(accessLevelStr)\(overrideStr)\(staticStr)\(consumingStr)\(mutatingStr)\(nameStr)\(genericsStr)"
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
            line.append("(\(argumentsStr))")
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
    
    public mutating func appendSwitch(_ test: String, builder: (inout SwiftSwitchBuilder) -> Void) {
        codeBuilder.append(line: "switch \(test) {")
        var switchBuilder = SwiftSwitchBuilder(parentFunction: self)
        builder(&switchBuilder)
        self = switchBuilder.parentFunction
        codeBuilder.append(line: "}")
    }
    
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

    public mutating func appendIfLet(binding: String, optional: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        appendIf("let \(binding) = \(optional)", builder: builder)
    }

    public mutating func appendReturn(_ expression: String? = nil) {
        codeBuilder.append(line: expression.map { "return \($0)" } ?? "return")
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

    public mutating func appendDo(
        catches: [(pattern: String?, builder: (inout SwiftFunctionBuilder) -> Void)] = [],
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        codeBuilder.append(line: "do {")
        codeBuilder.indent()
        builder(&self)
        codeBuilder.outdent()
        for (pattern, catchBuilder) in catches {
            if let pattern {
                codeBuilder.append(line: "} catch \(pattern) {")
            } else {
                codeBuilder.append(line: "} catch {")
            }
            codeBuilder.indent()
            catchBuilder(&self)
            codeBuilder.outdent()
        }
        codeBuilder.append(line: "}")
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
        name: String,
        generics: [SwiftGeneric] = [],
        arguments: [SwiftFunctionArgument] = [],
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let outerAttributes = self.attributes
        let outerAsGetter = self.asGetter
        let outerAccessLevel = self.accessLevel
        let outerIsStatic = self.isStatic
        let outerIsOverride = self.isOverride
        let outerIsConsuming = self.isConsuming
        let outerIsMutating = self.isMutating
        let outerIsThrowing = self.isThrowing
        let outerTypedThrow = self.typedThrow
        let outerIsRethrowing = self.isRethrowing
        let outerIsAsync = self.isAsync
        let outerInitPrefix = self.initPrefix
        let outerName = self.name
        let outerGenerics = self.generics
        let outerArguments = self.arguments
        let outerReturnType = self.returnType
        var funcBuilder = SwiftFunctionBuilder(attributes: attributes, name: name, generics: generics, arguments: arguments, codeBuilder: codeBuilder)
        funcBuilder.start()
        builder(&funcBuilder)
        self = SwiftFunctionBuilder(
            asGetter: outerAsGetter,
            attributes: outerAttributes,
            accessLevel: outerAccessLevel,
            isStatic: outerIsStatic,
            isOverride: outerIsOverride,
            isConsuming: outerIsConsuming,
            isMutating: outerIsMutating,
            isThrowing: outerIsThrowing,
            typedThrow: outerTypedThrow,
            isRethrowing: outerIsRethrowing,
            isAsync: outerIsAsync,
            initPrefix: outerInitPrefix,
            name: outerName,
            generics: outerGenerics,
            arguments: outerArguments,
            returnType: outerReturnType,
            codeBuilder: funcBuilder.end()
        )
    }
}
