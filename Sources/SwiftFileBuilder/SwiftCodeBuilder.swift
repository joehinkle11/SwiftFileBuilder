struct SwiftCodeBuilder: ~Copyable {
    private var content: String = ""
    private var currentIndent: Int = 0
    let indentString: String
    
    mutating func indent() {
        currentIndent += 1
    }
    
    mutating func outdent() {
        currentIndent -= 1
        precondition(currentIndent >= 0, "Indent underflow in SwiftFileBuilder outdent")
    }
    
    mutating func appendNewline() {
        content += "\n"
    }

    mutating func append(stringBuilder: consuming SwiftStringBuilder) {
        append(content: stringBuilder.build())
    }
    
    mutating func append<S: StringProtocol>(line: S, prefixingWith prefix: String = "") {
        content += String(repeating: indentString, count: currentIndent) + prefix + String(line) + "\n"
    }

    mutating func append<S: StringProtocol>(lines: [S], prefixingEachLineWith prefix: String = "") {
        for line in lines {
            append(line: line, prefixingWith: prefix)
        }
    }
    
    mutating func append(content: String, prefixingEachLineWith prefix: String = "") {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        while lines.last?.isEmpty == true {
            lines.removeLast()
        }
        self.append(lines: lines, prefixingEachLineWith: prefix)
    }

    mutating func appendTypeAlias(
        accessLevel: AccessLevel? = nil,
        name: String,
        type: String
    ) {
        var line = ""
        if let accessLevel { line += accessLevel.rawValue + " " }
        line += "typealias \(name) = \(type)"
        append(line: line)
    }

    mutating func append(comment: String, commentStyle: CommentStyle = .normal) {
        switch commentStyle {
        case .normal:
            self.append(content: comment, prefixingEachLineWith: "// ")
        case .doc:
            self.append(content: comment, prefixingEachLineWith: "/// ")
        }
    }
    
    consuming func finalize() -> String {
        while content.hasSuffix("\n\n") {
            content.removeLast()
        }
        if !content.hasSuffix("\n") && !content.isEmpty {
            content += "\n"
        }
        return content
    }
}
