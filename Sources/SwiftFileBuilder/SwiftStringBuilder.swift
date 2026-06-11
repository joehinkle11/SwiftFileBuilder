import Foundation

public struct SwiftStringBuilder: ~Copyable {
    private enum Segment {
        case literal(String)
        case interpolation(String)
    }

    private var segments: [Segment] = []
    private let isMultiline: Bool

    public init(isMultilineString: Bool = false) {
        self.isMultiline = isMultilineString
    }

    public mutating func append(literal: String) {
        segments.append(.literal(literal))
    }

    public mutating func append(interpolation: String) {
        segments.append(.interpolation(interpolation))
    }

    public consuming func build() -> String {
        if isMultiline {
            return buildMultiline()
        }
        return buildSingleLine()
    }

    private func buildSingleLine() -> String {
        var result = "\""
        for segment in segments {
            switch segment {
            case .literal(let text):
                for c in text {
                    switch c {
                    case "\\": result += "\\\\"
                    case "\"": result += "\\\""
                    case "\n": result += "\\n"
                    case "\r": result += "\\r"
                    case "\t": result += "\\t"
                    default: result.append(c)
                    }
                }
            case .interpolation(let name):
                result += "\\(\(name))"
            }
        }
        result += "\""
        return result
    }

    private func buildMultiline() -> String {
        var result = "\"\"\"\n"
        for segment in segments {
            switch segment {
            case .literal(let text):
                for c in text {
                    switch c {
                    case "\\": result += "\\\\"
                    case "\n": result += "\n"
                    case "\r": break
                    case "\"": result += "\""
                    default: result.append(c)
                    }
                }
            case .interpolation(let name):
                result += "\\(\(name))"
            }
        }
        result += "\n\"\"\""
        return result
    }
}
