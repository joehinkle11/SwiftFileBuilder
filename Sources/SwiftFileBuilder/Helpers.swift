public struct SwiftGeneric {
    public let name: String
    public let constraints: [String]
    
    public init(name: String, constraints: [String] = []) {
        self.name = name
        self.constraints = constraints
    }
}

public struct SwiftFunctionArgument {
    public let outerLabel: String?
    public let name: String
    public let isInOut: Bool
    public let isBorrowing: Bool
    public let isVariadic: Bool
    public let type: String
    public let defaultValue: String?
    
    public init(outerLabel: String? = nil, name: String, isInOut: Bool = false, isBorrowing: Bool = false, isVariadic: Bool = false, type: String, defaultValue: String? = nil) {
        self.outerLabel = outerLabel
        self.name = name
        self.isInOut = isInOut
        self.isBorrowing = isBorrowing
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
        if isInOut {
            result += "inout "
        }
        if isBorrowing {
            result += "borrowing "
        }
        result += type
        if isVariadic {
            result += "..."
        }
        if let defaultValue {
            result += " = "
            if isInOut {
                result += "&"
            }
            result += defaultValue
        }
        return result
    }
}
