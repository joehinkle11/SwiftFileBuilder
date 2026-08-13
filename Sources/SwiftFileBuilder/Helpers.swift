public struct SwiftGeneric {
    public let name: String
    public let constraints: [String]
    
    public init(name: String, constraints: [String] = []) {
        self.name = name
        self.constraints = constraints
    }
}

public enum SwiftParameterOwnership: String, Sendable {
    case none
    case borrowing
    case consuming
    case `inout`
}

public struct SwiftFunctionArgument {
    public let outerLabel: String?
    public let name: String
    public let isInOut: Bool
    public let isBorrowing: Bool
    public let ownership: SwiftParameterOwnership
    public let isVariadic: Bool
    public let type: String
    public let defaultValue: String?
    
    public init(outerLabel: String? = nil, name: String, isInOut: Bool = false, isBorrowing: Bool = false, isVariadic: Bool = false, type: String, defaultValue: String? = nil) {
        precondition(!(isInOut && isBorrowing), "A parameter cannot be both inout and borrowing")
        self.outerLabel = outerLabel
        self.name = name
        self.isInOut = isInOut
        self.isBorrowing = isBorrowing
        self.ownership = isInOut ? .inout : (isBorrowing ? .borrowing : .none)
        self.isVariadic = isVariadic
        self.type = type
        self.defaultValue = defaultValue
    }

    public init(
        outerLabel: String? = nil,
        name: String,
        ownership: SwiftParameterOwnership,
        isVariadic: Bool = false,
        type: String,
        defaultValue: String? = nil
    ) {
        self.outerLabel = outerLabel
        self.name = name
        self.ownership = ownership
        self.isInOut = ownership == .inout
        self.isBorrowing = ownership == .borrowing
        self.isVariadic = isVariadic
        self.type = type
        self.defaultValue = defaultValue
    }

    public var rendered: String {
        var result = ""
        if let outerLabel {
            result += "\(outerLabel) "
        }
        result += "\(name): "
        if ownership != .none {
            result += ownership.rawValue + " "
        }
        result += type
        if isVariadic {
            result += "..."
        }
        if let defaultValue {
            result += " = "
            if ownership == .inout {
                result += "&"
            }
            result += defaultValue
        }
        return result
    }
}
