public struct SwiftFileBuilder: ~Copyable {
    
    private var codeBuilder: SwiftCodeBuilder

    public init(indentString: String = "    ") {
        self.codeBuilder = SwiftCodeBuilder(indentString: indentString)
    }

    public mutating func appendImports(modules: [String], spi: String? = nil) {
        for module in modules {
            appendImport(module: module, spi: spi)
        }
    }
    
    public mutating func appendImport(module: String, spi: String? = nil) {
        if let spi {
            codeBuilder.append(line: "@_spi(\(spi)) import \(module)")
        } else {
            codeBuilder.append(line: "import \(module)")
        }
    }
    
    public mutating func appendImport<Kind: SwiftTypeBuilderKind>(module: String, type: String, kind: Kind, spi: String? = nil) {
        if let spi {
            codeBuilder.append(line: "@_spi(\(spi)) import \(kind.stringValue) \(module).\(type)")
        } else {
            codeBuilder.append(line: "import \(kind.stringValue) \(module).\(type)")
        }
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

    public mutating func append(comment: String, commentStyle: CommentStyle = .normal) {
        codeBuilder.append(comment: comment, commentStyle: commentStyle)
    }

    public mutating func appendMark(_ title: String, withSeparator: Bool = true) {
        if withSeparator {
            codeBuilder.append(line: "// MARK: - \(title)")
        } else {
            codeBuilder.append(line: "// MARK: \(title)")
        }
    }

    public mutating func appendFunction(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        asGetter: Bool = false,
        isThrowing: Bool = false,
        typedThrow: String? = nil,
        isRethrowing: Bool = false,
        isAsync: Bool = false,
        name: String,
        generics: [SwiftGeneric] = [],
        arguments: [SwiftFunctionArgument] = [],
        returnType: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void,
        variantsBuilder: (inout SwiftVariantsFunctionBuilder) -> Void = { _ in }
    ) {
        var funcBuilder = SwiftFunctionBuilder(asGetter: asGetter, attributes: attributes, accessLevel: accessLevel, isThrowing: isThrowing, typedThrow: typedThrow, isRethrowing: isRethrowing, isAsync: isAsync, name: name, generics: generics, arguments: arguments, returnType: returnType, codeBuilder: codeBuilder)
        var variants = SwiftVariantsFunctionBuilder(funcBuilder: funcBuilder)
        variantsBuilder(&variants)
        funcBuilder = variants.funcBuilder
        funcBuilder.start()
        builder(&funcBuilder)
        self = SwiftFileBuilder(codeBuilder: funcBuilder.end())
    }
    
    public mutating func appendType<Kind: SwiftTypeBuilderKind>(attributes: String? = nil, accessLevel: AccessLevel? = nil, kind: Kind, name: String, generics: [SwiftGeneric] = [], inheritedTypes: [String] = [], builder: (inout SwiftTypeBuilder<Kind>) -> Void) {
        var typeBuilder = SwiftTypeBuilder(kind: kind, accessLevel: accessLevel, name: name, generics: generics, inheritedTypes: inheritedTypes, attributes: attributes, codeBuilder: codeBuilder)
        typeBuilder.start()
        builder(&typeBuilder)
        self = SwiftFileBuilder(codeBuilder: typeBuilder.end())
    }
    
    public mutating func appendTypeAlias(
        accessLevel: AccessLevel? = nil,
        name: String,
        type: String
    ) {
        codeBuilder.appendTypeAlias(accessLevel: accessLevel, name: name, type: type)
    }

    public mutating func appendVariable(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        modifiers: String? = nil,
        isLet: Bool = false,
        name: String,
        type: String? = nil,
        initialValue: String? = nil
    ) {
        var line = ""
        if let attributes { line += attributes + " " }
        if let accessLevel { line += accessLevel.rawValue + " " }
        if let modifiers { line += modifiers + " " }
        line += isLet ? "let " : "var "
        line += name
        if let type { line += ": \(type)" }
        if let initialValue { line += " = \(initialValue)" }
        codeBuilder.append(line: line)
    }

    public consuming func finalize() -> String {
        return codeBuilder.finalize()
    }

    private init(codeBuilder: consuming SwiftCodeBuilder) {
        self.codeBuilder = codeBuilder
    }
}
