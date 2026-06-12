public protocol SwiftTypeBuilderKind {
    var stringValue: String { get }
}

public struct SwiftTypeBuilderClassKind: SwiftTypeBuilderKind {
    public var stringValue: String { "class" }
}

public struct SwiftTypeBuilderEnumKind: SwiftTypeBuilderKind {
    public var stringValue: String { "enum" }
}

public struct SwiftTypeBuilderStructKind: SwiftTypeBuilderKind {
    public var stringValue: String { "struct" }
}

public struct SwiftTypeBuilderExtensionKind: SwiftTypeBuilderKind {
    public var stringValue: String { "extension" }
}

public struct SwiftTypeBuilderProtocolKind: SwiftTypeBuilderKind {
    public var stringValue: String { "protocol" }
}

public struct SwiftTypeBuilderActorKind: SwiftTypeBuilderKind {
    public var stringValue: String { "actor" }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderClassKind {
    public static var `class`: Self { Self() }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderEnumKind {
    public static var `enum`: Self { Self() }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderStructKind {
    public static var `struct`: Self { Self() }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderExtensionKind {
    public static var `extension`: Self { Self() }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderProtocolKind {
    public static var `protocol`: Self { Self() }
}

extension SwiftTypeBuilderKind where Self == SwiftTypeBuilderActorKind {
    public static var actor: Self { Self() }
}

public struct SwiftTypeBuilder<Kind: SwiftTypeBuilderKind>: ~Copyable {
    
    let kind: Kind
    let accessLevel: AccessLevel?
    let name: String
    let generics: [SwiftGeneric]
    let inheritedTypes: [String]
    let attributes: String?
    var isFirstCase: Bool = true
    var codeBuilder: SwiftCodeBuilder
    
    mutating func start() {
        var line: String = ""
        if let attributes {
            line += attributes + " "
        }
        if let accessLevel {
            line += accessLevel.rawValue + " "
        }
        line.append("\(kind.stringValue) \(name)")
        if generics.isEmpty == false {
            var genericsStr = "<"
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
            line += genericsStr
        }
        if !inheritedTypes.isEmpty {
            line += ": \(inheritedTypes.joined(separator: ", "))"
        }
        line += " {"
        codeBuilder.append(line: line)
        codeBuilder.indent()
    }

    public mutating func appendNewline() {
        codeBuilder.appendNewline()
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

    public mutating func appendMark(_ title: String, withSeparator: Bool = true) {
        if withSeparator {
            codeBuilder.append(line: "// MARK: - \(title)")
        } else {
            codeBuilder.append(line: "// MARK: \(title)")
        }
    }

    public mutating func appendStoredProperty(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        modifiers: String? = nil,
        isLet: Bool = false,
        name: String,
        type: String,
        initialValue: String? = nil
    ) {
        var line = ""
        if let attributes { line += attributes + " " }
        if let accessLevel { line += accessLevel.rawValue + " " }
        if let modifiers { line += modifiers + " " }
        line += isLet ? "let " : "var "
        line += "\(name): \(type)"
        if let initialValue {
            line += " = \(initialValue)"
        }
        codeBuilder.append(line: line)
    }

    public mutating func append(lines: [String]) {
        codeBuilder.append(lines: lines)
    }

    public mutating func appendProperty(_ content: String) {
        codeBuilder.append(content: content)
    }

    public mutating func appendPropertyBlock(header: String, builder: (inout SwiftFunctionBuilder) -> Void) {
        let headerLine = header.hasSuffix("{") ? header : header + " {"
        codeBuilder.append(line: headerLine)
        codeBuilder.indent()
        let typeAttributes = self.attributes
        let typeIsFirstCase = self.isFirstCase
        var funcBuilder = SwiftFunctionBuilder(name: "", generics: [], arguments: [], codeBuilder: codeBuilder)
        builder(&funcBuilder)
        self = SwiftTypeBuilder(kind: kind, accessLevel: accessLevel, name: name, generics: generics, inheritedTypes: inheritedTypes, attributes: typeAttributes, isFirstCase: typeIsFirstCase, codeBuilder: funcBuilder.codeBuilder)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendMethod(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        asGetter: Bool = false,
        isStatic: Bool = false,
        isOverride: Bool = false,
        isConsuming: Bool = false,
        isMutating: Bool = false,
        isThrowing: Bool = false,
        isRethrowing: Bool = false,
        isAsync: Bool = false,
        name: String,
        generics: [SwiftGeneric] = [],
        arguments: [SwiftFunctionArgument] = [],
        returnType: String? = nil,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let typeAttributes = self.attributes
        let typeAccessLevel = self.accessLevel
        let typeName = self.name
        let typeGenerics = self.generics
        let typeIsFirstCase = self.isFirstCase
        var funcBuilder = SwiftFunctionBuilder(asGetter: asGetter, attributes: attributes, accessLevel: accessLevel, isStatic: isStatic, isOverride: isOverride, isConsuming: isConsuming, isMutating: isMutating, isThrowing: isThrowing, isRethrowing: isRethrowing, isAsync: isAsync, name: name, generics: generics, arguments: arguments, returnType: returnType, codeBuilder: codeBuilder)
        funcBuilder.start()
        builder(&funcBuilder)
        self = SwiftTypeBuilder(kind: kind, accessLevel: typeAccessLevel, name: typeName, generics: typeGenerics, inheritedTypes: inheritedTypes, attributes: typeAttributes, isFirstCase: typeIsFirstCase, codeBuilder: funcBuilder.end())
    }

    public mutating func appendInitializer(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        isConvenience: Bool = false,
        isRequired: Bool = false,
        isFailable: Bool = false,
        isThrowing: Bool = false,
        isAsync: Bool = false,
        generics: [SwiftGeneric] = [],
        arguments: [SwiftFunctionArgument] = [],
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let typeAttributes = self.attributes
        let typeAccessLevel = self.accessLevel
        let typeGenerics = self.generics
        let typeIsFirstCase = self.isFirstCase
        let initName = isFailable ? "init?" : "init"
        var modifiers: [String] = []
        if isRequired { modifiers.append("required") }
        if isConvenience { modifiers.append("convenience") }
        let initPrefix = modifiers.isEmpty ? "" : modifiers.joined(separator: " ") + " "
        var funcBuilder = SwiftFunctionBuilder(attributes: attributes, accessLevel: accessLevel, isThrowing: isThrowing, isAsync: isAsync, name: initName, generics: generics, arguments: arguments, codeBuilder: codeBuilder)
        funcBuilder.initPrefix = initPrefix
        funcBuilder.start()
        builder(&funcBuilder)
        self = SwiftTypeBuilder(kind: kind, accessLevel: typeAccessLevel, name: name, generics: typeGenerics, inheritedTypes: inheritedTypes, attributes: typeAttributes, isFirstCase: typeIsFirstCase, codeBuilder: funcBuilder.end())
    }

    public mutating func appendTypeAlias(
        accessLevel: AccessLevel? = nil,
        name: String,
        type: String
    ) {
        codeBuilder.appendTypeAlias(accessLevel: accessLevel, name: name, type: type)
    }

    public mutating func appendDeinitializer(
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let typeAttributes = self.attributes
        let typeAccessLevel = self.accessLevel
        let typeName = self.name
        let typeGenerics = self.generics
        let typeIsFirstCase = self.isFirstCase
        codeBuilder.append(line: "deinit {")
        codeBuilder.indent()
        var funcBuilder = SwiftFunctionBuilder(name: "", generics: [], arguments: [], codeBuilder: codeBuilder)
        builder(&funcBuilder)
        self = SwiftTypeBuilder(kind: kind, accessLevel: typeAccessLevel, name: typeName, generics: typeGenerics, inheritedTypes: inheritedTypes, attributes: typeAttributes, isFirstCase: typeIsFirstCase, codeBuilder: funcBuilder.codeBuilder)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendSubscript(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        isStatic: Bool = false,
        arguments: [SwiftFunctionArgument] = [],
        returnType: String,
        builder: (inout SwiftFunctionBuilder) -> Void
    ) {
        let typeAttributes = self.attributes
        let typeAccessLevel = self.accessLevel
        let typeName = self.name
        let typeGenerics = self.generics
        let typeIsFirstCase = self.isFirstCase
        var line = ""
        if let attributes { line += attributes + " " }
        if let accessLevel { line += accessLevel.rawValue + " " }
        if isStatic { line += "static " }
        let argsStr = arguments.map { $0.rendered }.joined(separator: ", ")
        line += "subscript(\(argsStr)) -> \(returnType) {"
        codeBuilder.append(line: line)
        codeBuilder.indent()
        var funcBuilder = SwiftFunctionBuilder(name: "", generics: [], arguments: [], codeBuilder: codeBuilder)
        builder(&funcBuilder)
        self = SwiftTypeBuilder(kind: kind, accessLevel: typeAccessLevel, name: typeName, generics: typeGenerics, inheritedTypes: inheritedTypes, attributes: typeAttributes, isFirstCase: typeIsFirstCase, codeBuilder: funcBuilder.codeBuilder)
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
    }

    public mutating func appendCase(name: String, rawValue: String? = nil, associatedType: String? = nil, comment: String? = nil) where Kind == SwiftTypeBuilderEnumKind {
        precondition(rawValue == nil || associatedType == nil,
            "Enum case cannot have both a raw value and an associated type")
        if isFirstCase {
            isFirstCase = false
        } else {
            codeBuilder.appendNewline()
        }
        if let comment {
            codeBuilder.append(comment: comment)
        }
        var line = "case \(name)"
        if let rawValue {
            line += " = \(rawValue)"
        } else if let associatedType {
            line += "(\(associatedType))"
        }
        codeBuilder.append(line: line)
    }
    
    public mutating func appendNestedType<NestedKind: SwiftTypeBuilderKind>(
        attributes: String? = nil,
        accessLevel: AccessLevel? = nil,
        kind: NestedKind,
        name: String,
        generics: [SwiftGeneric] = [],
        inheritedTypes: [String] = [],
        builder: (inout SwiftTypeBuilder<NestedKind>) -> Void
    ) {
        let typeAttributes = self.attributes
        let typeIsFirstCase = self.isFirstCase
        var nestedBuilder = SwiftTypeBuilder<NestedKind>(
            kind: kind,
            accessLevel: accessLevel,
            name: name,
            generics: generics,
            inheritedTypes: inheritedTypes,
            attributes: attributes,
            codeBuilder: codeBuilder
        )
        nestedBuilder.start()
        builder(&nestedBuilder)
        self = SwiftTypeBuilder(
            kind: self.kind,
            accessLevel: self.accessLevel,
            name: self.name,
            generics: self.generics,
            inheritedTypes: self.inheritedTypes,
            attributes: typeAttributes,
            isFirstCase: typeIsFirstCase,
            codeBuilder: nestedBuilder.end()
        )
    }

    consuming func end() -> SwiftCodeBuilder {
        codeBuilder.outdent()
        codeBuilder.append(line: "}")
        return codeBuilder
    }
}
