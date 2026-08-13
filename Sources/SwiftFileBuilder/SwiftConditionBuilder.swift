public struct SwiftConditionBuilder {
    var lines: [String] = []

    public init() {}

    public mutating func append(_ line: String) {
        lines.append(line)
    }

    public mutating func append(lines: [String]) {
        self.lines.append(contentsOf: lines)
    }
}
