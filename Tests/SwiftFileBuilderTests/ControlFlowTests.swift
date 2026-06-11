import Testing
@testable import SwiftFileBuilder

@Suite("ControlFlow")
struct ControlFlowTests {

    @Test func guardStatement() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendGuard(condition: "let x = optional") { fb in
                fb.append(line: "return")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    guard let x = optional else {"))
        #expect(result.contains("        return"))
        #expect(result.contains("    }"))
    }

    @Test func simpleIf() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("x > 0") { fb in
                fb.append(line: "process()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    if x > 0 {"))
        #expect(result.contains("        process()"))
        #expect(result.contains("    }"))
    }

    @Test func ifElse() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("count > 0", builder: { fb in
                fb.append(line: "process()")
            }, elseBuilder: { fb in
                fb.append(line: "skip()")
            })
        }
        let result = file.finalize()
        #expect(result.contains("    if count > 0 {"))
        #expect(result.contains("        process()"))
        #expect(result.contains("    } else {"))
        #expect(result.contains("        skip()"))
        #expect(result.contains("    }"))
    }

    @Test func ifElseIfElse() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("x > 10", builder: { fb in
                fb.append(line: "large()")
            }, elseIf: [
                ("x > 5", { fb in fb.append(line: "medium()") }),
            ], elseBuilder: { fb in
                fb.append(line: "small()")
            })
        }
        let result = file.finalize()
        #expect(result.contains("    if x > 10 {"))
        #expect(result.contains("        large()"))
        #expect(result.contains("    } else if x > 5 {"))
        #expect(result.contains("        medium()"))
        #expect(result.contains("    } else {"))
        #expect(result.contains("        small()"))
        #expect(result.contains("    }"))
    }

    @Test func ifLet() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIfLet(binding: "value", optional: "opt") { fb in
                fb.append(line: "use(value)")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    if let value = opt {"))
        #expect(result.contains("        use(value)"))
    }

    @Test func forLoop() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendForLoop(element: "item", collection: "items") { fb in
                fb.append(line: "process(item)")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    for item in items {"))
        #expect(result.contains("        process(item)"))
    }

    @Test func whileLoop() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendWhile("running") { fb in
                fb.append(line: "step()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    while running {"))
        #expect(result.contains("        step()"))
    }

    @Test func labeledWhileLoop() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendWhile("true", label: "outer") { fb in
                fb.append(line: "break outer")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    outer: while true {"))
    }

    @Test func genericBlock() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendBlock(header: "do {") { fb in
                fb.append(line: "try something()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    do {"))
        #expect(result.contains("        try something()"))
        #expect(result.contains("    }"))
    }

    @Test func ifElseFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("x > 0", builder: { fb in
                fb.append(line: "positive()")
            }, elseBuilder: { fb in
                fb.append(line: "nonPositive()")
            })
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                if x > 0 {
                    positive()
                } else {
                    nonPositive()
                }
            }

            """)
    }

    @Test func ifElseIfElseFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("x > 10", builder: { fb in
                fb.append(line: "large()")
            }, elseIf: [
                ("x > 5", { fb in fb.append(line: "medium()") }),
            ], elseBuilder: { fb in
                fb.append(line: "small()")
            })
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                if x > 10 {
                    large()
                } else if x > 5 {
                    medium()
                } else {
                    small()
                }
            }

            """)
    }

    @Test func multipleElseIfClauses() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("x > 100", builder: { fb in
                fb.append(line: "huge()")
            }, elseIf: [
                ("x > 50", { fb in fb.append(line: "large()") }),
                ("x > 10", { fb in fb.append(line: "medium()") }),
                ("x > 0", { fb in fb.append(line: "small()") }),
            ], elseBuilder: { fb in
                fb.append(line: "none()")
            })
        }
        let result = file.finalize()
        #expect(result.contains("    if x > 100 {"))
        #expect(result.contains("    } else if x > 50 {"))
        #expect(result.contains("    } else if x > 10 {"))
        #expect(result.contains("    } else if x > 0 {"))
        #expect(result.contains("    } else {"))
    }

    @Test func nestedWhileWithIf() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "run") { fn in
            fn.appendWhile("running") { fb in
                fb.appendIf("shouldStop()", builder: { inner in
                    inner.append(line: "break")
                })
                fb.append(line: "step()")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func run() {
                while running {
                    if shouldStop() {
                        break
                    }
                    step()
                }
            }

            """)
    }

    @Test func guardWithMultipleStatements() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendGuard(condition: "let x = optional") { fb in
                fb.append(line: "log(\"missing value\")")
                fb.append(line: "return nil")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    guard let x = optional else {"))
        #expect(result.contains("        log(\"missing value\")"))
        #expect(result.contains("        return nil"))
    }

    @Test func nestedForWithGuard() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "process") { fn in
            fn.appendForLoop(element: "item", collection: "items") { fb in
                fb.appendGuard(condition: "item.isValid") { guard_fb in
                    guard_fb.append(line: "continue")
                }
                fb.append(line: "handle(item)")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func process() {
                for item in items {
                    guard item.isValid else {
                        continue
                    }
                    handle(item)
                }
            }

            """)
    }

    @Test func switchWithMultipleLinesPerCase() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendSwitch("op") { sw in
                sw.appendCase(".add") { fb in
                    fb.append(line: "let result = a + b")
                    fb.append(line: "stack.push(result)")
                }
                sw.appendDefault { fb in
                    fb.append(line: "fatalError(\"unknown op\")")
                }
            }
        }
        let result = file.finalize()
        #expect(result.contains("        let result = a + b"))
        #expect(result.contains("        stack.push(result)"))
        #expect(result.contains("        fatalError(\"unknown op\")"))
    }

    @Test func ifWithoutElse() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendIf("condition") { fb in
                fb.append(line: "doSomething()")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                if condition {
                    doSomething()
                }
            }

            """)
    }

    @Test func repeatWhile() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendRepeatWhile("running") { fb in
                fb.append(line: "step()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    repeat {"))
        #expect(result.contains("        step()"))
        #expect(result.contains("    } while running"))
    }

    @Test func labeledRepeatWhile() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendRepeatWhile("true", label: "outer") { fb in
                fb.append(line: "break outer")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    outer: repeat {"))
        #expect(result.contains("    } while true"))
    }

    @Test func repeatWhileFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "process") { fn in
            fn.appendRepeatWhile("!queue.isEmpty") { fb in
                fb.append(line: "let item = queue.removeFirst()")
                fb.append(line: "handle(item)")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func process() {
                repeat {
                    let item = queue.removeFirst()
                    handle(item)
                } while !queue.isEmpty
            }

            """)
    }

    @Test func doCatch() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendDo(catches: [
                (pattern: nil, builder: { fb in
                    fb.append(line: "handle()")
                })
            ]) { fb in
                fb.append(line: "try something()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    do {"))
        #expect(result.contains("        try something()"))
        #expect(result.contains("    } catch {"))
        #expect(result.contains("        handle()"))
    }

    @Test func doCatchWithPattern() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendDo(catches: [
                (pattern: "SomeError", builder: { fb in
                    fb.append(line: "recover()")
                })
            ]) { fb in
                fb.append(line: "try riskyOp()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    } catch SomeError {"))
    }

    @Test func doCatchMultiplePatterns() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendDo(catches: [
                (pattern: "IOError", builder: { fb in
                    fb.append(line: "retry()")
                }),
                (pattern: nil, builder: { fb in
                    fb.append(line: "fatalError()")
                }),
            ]) { fb in
                fb.append(line: "try operation()")
            }
        }
        let result = file.finalize()
        #expect(result.contains("    } catch IOError {"))
        #expect(result.contains("        retry()"))
        #expect(result.contains("    } catch {"))
        #expect(result.contains("        fatalError()"))
    }

    @Test func doCatchFullOutput() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "load") { fn in
            fn.appendDo(catches: [
                (pattern: "NetworkError", builder: { fb in
                    fb.append(line: "retry()")
                }),
                (pattern: nil, builder: { fb in
                    fb.append(line: "fallback()")
                }),
            ]) { fb in
                fb.append(line: "let data = try fetch()")
                fb.append(line: "process(data)")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func load() {
                do {
                    let data = try fetch()
                    process(data)
                } catch NetworkError {
                    retry()
                } catch {
                    fallback()
                }
            }

            """)
    }

    @Test func doWithoutCatch() {
        var file = SwiftFileBuilder()
        file.appendFunction(accessLevel: .internal, name: "test") { fn in
            fn.appendDo { fb in
                fb.append(line: "try something()")
            }
        }
        let result = file.finalize()
        #expect(result == """
            internal func test() {
                do {
                    try something()
                }
            }

            """)
    }
}
