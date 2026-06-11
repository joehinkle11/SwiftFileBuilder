import Testing
@testable import SwiftFileBuilder

@Suite("SwiftSwitchBuilder")
struct SwiftSwitchBuilderTests {

    @Test func switchWithCases() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("x") { sw in
                sw.appendCase(".a") { fb in
                    fb.append(line: "print(\"a\")")
                }
                sw.appendCase(".b") { fb in
                    fb.append(line: "print(\"b\")")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    switch x {"))
        #expect(result.contains("    case .a:"))
        #expect(result.contains("        print(\"a\")"))
        #expect(result.contains("    case .b:"))
        #expect(result.contains("    }"))
    }

    @Test func switchWithDefault() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("value") { sw in
                sw.appendCase("1") { fb in
                    fb.append(line: "handle()")
                }
                sw.appendDefault { fb in
                    fb.append(line: "break")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    default:"))
        #expect(result.contains("        break"))
    }

    @Test func nestedIndentation() {
        var file = SwiftFileBuilder()
        file.appendType(kind: .struct, name: "Outer") { type in
            type.appendMethod(accessLevel: .internal, name: "foo") { method in
                method.appendSwitch("x") { sw in
                    sw.appendCase(".a") { fb in
                        fb.append(line: "print(\"a\")")
                    }
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("            print(\"a\")"))
    }

    @Test func switchWithManyCases() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("direction") { sw in
                sw.appendCase(".north") { fb in
                    fb.append(line: "goNorth()")
                }
                sw.appendCase(".south") { fb in
                    fb.append(line: "goSouth()")
                }
                sw.appendCase(".east") { fb in
                    fb.append(line: "goEast()")
                }
                sw.appendCase(".west") { fb in
                    fb.append(line: "goWest()")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    case .north:"))
        #expect(result.contains("    case .south:"))
        #expect(result.contains("    case .east:"))
        #expect(result.contains("    case .west:"))
    }

    @Test func switchFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("value") { sw in
                sw.appendCase(".a") { fb in
                    fb.append(line: "handleA()")
                }
                sw.appendCase(".b") { fb in
                    fb.append(line: "handleB()")
                }
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                switch value {
                case .a:
                    handleA()
                case .b:
                    handleB()
                }
            }

            """)
    }

    @Test func switchDefaultOnly() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("x") { sw in
                sw.appendDefault { fb in
                    fb.append(line: "fallback()")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    switch x {"))
        #expect(result.contains("    default:"))
        #expect(result.contains("        fallback()"))
        #expect(result.contains("    }"))
    }

    @Test func switchCaseWithMultipleStatements() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("op") { sw in
                sw.appendCase(".add") { fb in
                    fb.append(line: "let a = pop()")
                    fb.append(line: "let b = pop()")
                    fb.append(line: "push(a + b)")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("        let a = pop()"))
        #expect(result.contains("        let b = pop()"))
        #expect(result.contains("        push(a + b)"))
    }

    @Test func switchCaseWithWhereClause() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("value") { sw in
                sw.appendCase(".some(let x)", where: "x > 0") { fb in
                    fb.append(line: "handlePositive(x)")
                }
                sw.appendDefault { fb in
                    fb.append(line: "handleOther()")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    case .some(let x) where x > 0:"))
        #expect(result.contains("        handlePositive(x)"))
    }

    @Test func switchMultiPatternCase() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("direction") { sw in
                sw.appendCase(patterns: [".north", ".south"]) { fb in
                    fb.append(line: "handleVertical()")
                }
                sw.appendCase(patterns: [".east", ".west"]) { fb in
                    fb.append(line: "handleHorizontal()")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    case .north, .south:"))
        #expect(result.contains("    case .east, .west:"))
    }

    @Test func switchMultiPatternWithWhere() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("value") { sw in
                sw.appendCase(patterns: [".a(let x)", ".b(let x)"], where: "x > 0") { fb in
                    fb.append(line: "handle(x)")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("    case .a(let x), .b(let x) where x > 0:"))
    }

    @Test func switchCaseWithWhereFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("point") { sw in
                sw.appendCase("(let x, let y)", where: "x == y") { fb in
                    fb.append(line: "onDiagonal()")
                }
                sw.appendDefault { fb in
                    fb.appendBreak()
                }
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                switch point {
                case (let x, let y) where x == y:
                    onDiagonal()
                default:
                    break
                }
            }

            """)
    }
}
