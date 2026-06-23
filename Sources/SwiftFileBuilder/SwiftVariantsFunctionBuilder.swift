public struct SwiftVariantsFunctionBuilder: ~Copyable {
    var funcBuilder: SwiftFunctionBuilder
    
    public mutating func appendVariant(
        replacingArguments: [(
            argumentName: String,
            usingDefault: String,
        )] = [],
        removingGenerics: [String] = [],
    ) {
        let originalAttributes = funcBuilder.attributes
        let originalAsGetter = funcBuilder.asGetter
        let originalAccessLevel = funcBuilder.accessLevel
        let originalIsStatic = funcBuilder.isStatic
        let originalIsOverride = funcBuilder.isOverride
        let originalIsConsuming = funcBuilder.isConsuming
        let originalIsMutating = funcBuilder.isMutating
        let originalIsThrowing = funcBuilder.isThrowing
        let originalTypedThrow = funcBuilder.typedThrow
        let originalIsRethrowing = funcBuilder.isRethrowing
        let originalIsAsync = funcBuilder.isAsync
        let originalInitPrefix = funcBuilder.initPrefix
        let originalName = funcBuilder.name
        let originalGenerics = funcBuilder.generics
        let originalArguments = funcBuilder.arguments
        let originalReturnType = funcBuilder.returnType
        var variantSwiftFunctionBuilder = funcBuilder
        variantSwiftFunctionBuilder.arguments.removeAll { arg in
            replacingArguments.contains(where: {$0.argumentName == arg.name})
        }
        variantSwiftFunctionBuilder.generics.removeAll(where: { removingGenerics.contains($0.name) })
        variantSwiftFunctionBuilder.start()
        var argsStr = ""
        for (i, arg) in originalArguments.enumerated() {
            if i > 0 {
                argsStr += ", "
            }
            if let outerLabel = arg.outerLabel {
                if outerLabel != "_" {
                    argsStr += "\(outerLabel): "
                }
            } else {
                argsStr += "\(arg.name): "
            }
            if arg.isInOut {
                argsStr += "&"
            }
            if let replacedArgument = replacingArguments.first(where: {$0.argumentName == arg.name}) {
                argsStr += replacedArgument.usingDefault
            } else {
                argsStr += arg.name
            }
        }
        variantSwiftFunctionBuilder.append(content: """
            return \(variantSwiftFunctionBuilder.name)(\(argsStr))
            """)
        let builder = variantSwiftFunctionBuilder.end()
        self = SwiftVariantsFunctionBuilder(funcBuilder: SwiftFunctionBuilder(
            asGetter: originalAsGetter,
            attributes: originalAttributes,
            accessLevel: originalAccessLevel,
            isStatic: originalIsStatic,
            isOverride: originalIsOverride,
            isConsuming: originalIsConsuming,
            isMutating: originalIsMutating,
            isThrowing: originalIsThrowing,
            typedThrow: originalTypedThrow,
            isRethrowing: originalIsRethrowing,
            isAsync: originalIsAsync,
            initPrefix: originalInitPrefix,
            name: originalName,
            generics: originalGenerics,
            arguments: originalArguments,
            returnType: originalReturnType,
            codeBuilder: builder
        ))
    }
}
