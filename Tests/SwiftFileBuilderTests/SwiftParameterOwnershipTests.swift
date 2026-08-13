import Testing
@testable import SwiftFileBuilder

@Suite("SwiftParameterOwnership")
struct SwiftParameterOwnershipTests {
    @Test(arguments: [
        (SwiftParameterOwnership.none, "value: Value"),
        (.borrowing, "value: borrowing Value"),
        (.consuming, "value: consuming Value"),
        (.inout, "value: inout Value"),
    ])
    func rendersEveryOwnership(ownership: SwiftParameterOwnership, expected: String) {
        let argument = SwiftFunctionArgument(name: "value", ownership: ownership, type: "Value")
        #expect(argument.rendered == expected)
    }

    @Test func legacyFlagsRemainAvailable() {
        let inoutArgument = SwiftFunctionArgument(name: "value", isInOut: true, type: "Value")
        let borrowingArgument = SwiftFunctionArgument(name: "value", isBorrowing: true, type: "Value")
        #expect(inoutArgument.ownership == .inout)
        #expect(borrowingArgument.ownership == .borrowing)
        #expect(inoutArgument.isInOut)
        #expect(borrowingArgument.isBorrowing)
    }

    @Test func consumingParameterInFunction() {
        var file = SwiftFileBuilder()
        file.appendFunction(
            name: "consume",
            arguments: [.init(outerLabel: "_", name: "value", ownership: .consuming, type: "Value")]
        ) { _ in }
        #expect(file.finalize() == "func consume(_ value: consuming Value) {\n}\n")
    }
}
