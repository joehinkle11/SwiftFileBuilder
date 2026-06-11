# SwiftFileBuilder

A Swift DSL for generating Swift source code programmatically. Build functions, types, control flow, and string literals with a builder pattern — no string interpolation or manual indentation needed.

## Usage

```swift
import SwiftFileBuilder

var file = SwiftFileBuilder()

file.appendImport(module: "Foundation")

file.appendType(accessLevel: .public, kind: .struct, name: "Person") { type in
    type.appendStoredProperty(accessLevel: .public, name: "name", type: "String")
    type.appendStoredProperty(accessLevel: .public, name: "age", type: "Int")

    type.appendInitializer(accessLevel: .public, arguments: [
        SwiftFunctionArgument(name: "name", type: "String"),
        SwiftFunctionArgument(name: "age", type: "Int"),
    ]) { fn in
        fn.append(line: "self.name = name")
        fn.append(line: "self.age = age")
    }
}

let output = file.finalize()
```

Produces:

```swift
import Foundation

public struct Person {
    public var name: String
    public var age: Int

    public init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}
```

## Builder hierarchy

- **`SwiftFileBuilder`** — top-level file (imports, types, functions, variables, typealiases)
- **`SwiftTypeBuilder<Kind>`** — inside a type declaration (methods, properties, initializers, nested types, enum cases)
- **`SwiftFunctionBuilder`** — inside a function body (control flow, return/break/continue, blocks, nested functions)
- **`SwiftStringBuilder`** — constructs a `"..."` or `"""..."""` string literal with escapes and interpolation
- **`SwiftSwitchBuilder`** — builds `switch`/`case` blocks inside a function
- **`SwiftVariantsFunctionBuilder`** — generates overload variants with defaulted arguments or removed generics

## Reference

### SwiftFileBuilder

| Method | Description |
|---|---|
| `appendImport(module:)` | Add `import Module` |
| `appendImport(module:type:kind:)` | Add `import Kind Module.Type` |
| `appendImports(modules:)` | Add multiple imports |
| `appendNewline()` | Blank line |
| `append(line:)` | Raw indented line |
| `append(content:)` | Multi-line content (indented per line) |
| `append(comment:commentStyle:)` | Comment (`//` or `///`) |
| `appendMark(_:withSeparator:)` | `// MARK: - Title` |
| `appendString(isMultilineString:builder:)` | String literal via `SwiftStringBuilder` |
| `appendFunction(...)` | Function/method declaration |
| `appendType(kind:name:...)` | Type declaration |
| `appendTypeAlias(...)` | `typealias` |
| `appendVariable(...)` | `let`/`var` at file scope |
| `finalize()` | Returns the generated source |

### SwiftTypeBuilder

| Method | Description |
|---|---|
| `appendMethod(...)` | Method declaration (supports all modifiers) |
| `appendPropertyBlock(header:)` | Computed property or subscript block |
| `appendProperty(_:)` | Protocol property declaration |
| `appendStoredProperty(...)` | Stored property |
| `appendInitializer(...)` | `init`/`init?` (convenience, required, failable) |
| `appendDeinitializer(builder:)` | `deinit { }` |
| `appendSubscript(...)` | `subscript(...)` |
| `appendTypeAlias(...)` | `typealias` inside a type |
| `appendCase(name:...)` | Enum case (raw value, associated type, comment) |
| `appendNestedType(kind:name:...)` | Nested type declaration |
| `appendMark(...)` | `// MARK:` |
| `appendString(...)` | String literal |

### SwiftFunctionBuilder

| Method | Description |
|---|---|
| `append(line:)` / `append(content:)` / `append(lines:)` | Raw output |
| `appendNewline()` | Blank line |
| `appendString(...)` | String literal |
| `appendIf(_:builder:elseIf:elseBuilder:)` | `if`/`else if`/`else` |
| `appendIfLet(binding:optional:builder:)` | `if let` |
| `appendGuard(condition:builder:)` | `guard...else` |
| `appendForLoop(element:collection:builder:)` | `for...in` |
| `appendWhile(_:label:builder:)` | `while` loop |
| `appendRepeatWhile(_:label:builder:)` | `repeat...while` |
| `appendSwitch(_:builder:)` | `switch` |
| `appendDo(builder:catches:)` | `do`/`catch` |
| `appendDefer(builder:)` | `defer` |
| `appendBlock(header:builder:)` | Generic brace block |
| `appendClosureBlock(call:parameters:builder:)` | Closure argument |
| `appendCompilerIf(_:builder:elseBuilder:)` | `#if`/`#else`/`#endif` |
| `appendReturn(_:)` | `return`/`return expr` |
| `appendBreak(_:)` / `appendContinue(_:)` | `break`/`continue` with optional label |
| `appendFunction(...)` | Nested function declaration |

### SwiftStringBuilder

| Method | Description |
|---|---|
| `append(literal:)` | Plain text segment |
| `append(literalString:)` | Plain text from `String` |
| `append(interpolation:)` | `\(variable)` segment |
| `build()` | Returns `"..."` or `"""..."""` |

Contructor: `SwiftStringBuilder(isMultilineString: false)` — when `true`, produces a `"""` multiline string literal.

### Helpers

- **`AccessLevel`**: `.open`, `.public`, `.package`, `.internal`, `.fileprivate`, `.private`
- **`CommentStyle`**: `.normal` (`//`), `.doc` (`///`)
- **`SwiftGeneric`**: `init(name:constraints:)` e.g. `SwiftGeneric(name: "T", constraints: ["Hashable"])`
- **`SwiftFunctionArgument`**: `init(outerLabel:name:isInOut:isBorrowing:isVariadic:type:defaultValue:)`

### SwiftSwitchBuilder

| Method | Description |
|---|---|
| `addCase(_:where:builder:)` | `case pattern:` |
| `addCase(patterns:where:builder:)` | `case p1, p2:` |
| `addDefault(builder:)` | `default:` |

### SwiftVariantsFunctionBuilder

| Method | Description |
|---|---|
| `appendVariant(replacingArguments:removingGenerics:)` | Generates an overload that forwards with defaults |

## Installation

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/joehinkle11/SwiftFileBuilder", from: "1.0.0"),
]
```
