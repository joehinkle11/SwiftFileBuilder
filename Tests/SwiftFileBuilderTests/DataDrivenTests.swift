import Testing
import Foundation
@testable import SwiftFileBuilder

@Suite("DataDriven")
struct DataDrivenTests {

    @Test func generateStructFromPropertyList() {
        let properties = [
            (name: "firstName", type: "String"),
            (name: "lastName", type: "String"),
            (name: "age", type: "Int"),
        ]

        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .struct, name: "Person") { type in
            for (name, propType) in properties {
                type.appendStoredProperty(accessLevel: .public, name: name, type: propType)
            }
            type.appendNewline()
            type.appendInitializer(accessLevel: .public, arguments: properties.map { (name, propType) in
                SwiftFunctionArgument(name: name, type: propType)
            }) { fn in
                for (name, _) in properties {
                    fn.append(line: "self.\(name) = \(name)")
                }
            }
        }

        let result = file.finalize()
        #expect(result == """
            public struct Person {
                public var firstName: String
                public var lastName: String
                public var age: Int

                public init(firstName: String, lastName: String, age: Int) {
                    self.firstName = firstName
                    self.lastName = lastName
                    self.age = age
                }
            }

            """)
    }

    @Test func generateMultipleModelsFromDefinitions() {
        struct ModelDef {
            let name: String
            let properties: [(String, String)]
        }

        let models = [
            ModelDef(name: "User", properties: [("id", "Int"), ("name", "String")]),
            ModelDef(name: "Post", properties: [("title", "String"), ("content", "String"), ("authorId", "Int")]),
        ]

        var file = SwiftFileBuilder()
        for model in models {
            file.appendType(accessLevel: .public, kind: .struct, name: model.name) { type in
                for (name, propType) in model.properties {
                    type.appendStoredProperty(accessLevel: .public, name: name, type: propType)
                }
                type.appendNewline()
                type.appendInitializer(accessLevel: .public, arguments: model.properties.map { (name, propType) in
                    SwiftFunctionArgument(name: name, type: propType)
                }) { fn in
                    for (name, _) in model.properties {
                        fn.append(line: "self.\(name) = \(name)")
                    }
                }
            }
            file.appendNewline()
        }

        let result = file.finalize()
        #expect(result == """
            public struct User {
                public var id: Int
                public var name: String

                public init(id: Int, name: String) {
                    self.id = id
                    self.name = name
                }
            }

            public struct Post {
                public var title: String
                public var content: String
                public var authorId: Int

                public init(title: String, content: String, authorId: Int) {
                    self.title = title
                    self.content = content
                    self.authorId = authorId
                }
            }

            """)
    }

    @Test func generateEnumFromCaseList() {
        let statuses = ["pending", "active", "suspended", "archived"]

        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: "AccountStatus", inheritedTypes: ["String"]) { type in
            for status in statuses {
                type.appendCase(name: status, rawValue: "\"\(status)\"")
            }
            type.appendNewline()
            type.appendMethod(accessLevel: .public, name: "displayName", returnType: "String") { fn in
                fn.appendSwitch("self") { sw in
                    for status in statuses {
                        sw.appendCase(".\(status)") { fb in
                            let display = status.capitalized
                            fb.appendReturn("\"\(display)\"")
                        }
                    }
                }
            }
        }

        let result = file.finalize()
        #expect(result == """
            public enum AccountStatus: String {
                case pending = "pending"

                case active = "active"

                case suspended = "suspended"

                case archived = "archived"

                public func displayName() -> String {
                    switch self {
                    case .pending:
                        return "Pending"
                    case .active:
                        return "Active"
                    case .suspended:
                        return "Suspended"
                    case .archived:
                        return "Archived"
                    }
                }
            }

            """)
    }

    @Test func generateCodableStructFromPropertyList() {
        struct PropDef {
            let name: String
            let type: String
            let defaultValue: String?
        }

        let properties = [
            PropDef(name: "id", type: "UUID", defaultValue: nil),
            PropDef(name: "email", type: "String", defaultValue: nil),
            PropDef(name: "score", type: "Double", defaultValue: "0.0"),
        ]

        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .struct, name: "Player", inheritedTypes: ["Codable"]) { type in
            for prop in properties {
                type.appendStoredProperty(accessLevel: .public, name: prop.name, type: prop.type)
            }
            type.appendNewline()
            type.appendInitializer(accessLevel: .public, arguments: properties.map { prop in
                SwiftFunctionArgument(name: prop.name, type: prop.type, defaultValue: prop.defaultValue)
            }) { fn in
                for prop in properties {
                    fn.append(line: "self.\(prop.name) = \(prop.name)")
                }
            }
        }

        let result = file.finalize()
        #expect(result == """
            import Foundation

            public struct Player: Codable {
                public var id: UUID
                public var email: String
                public var score: Double

                public init(id: UUID, email: String, score: Double = 0.0) {
                    self.id = id
                    self.email = email
                    self.score = score
                }
            }

            """)
    }

    @Test func generateApiClientFromEndpointList() {
        struct EndpointDef {
            let name: String
            let method: String
            let returnType: String
            let path: String
        }

        let endpoints = [
            EndpointDef(name: "fetchUsers", method: "GET", returnType: "[User]", path: "/users"),
            EndpointDef(name: "fetchPosts", method: "GET", returnType: "[Post]", path: "/posts"),
            EndpointDef(name: "createUser", method: "POST", returnType: "User", path: "/users"),
        ]

        var file = SwiftFileBuilder()
        file.appendImport(module: "Foundation")
        file.appendNewline()
        file.appendType(accessLevel: .public, kind: .class, name: "APIClient") { type in
            for (index, ep) in endpoints.enumerated() {
                type.appendMethod(accessLevel: .public, isThrowing: true, isAsync: true, name: ep.name, returnType: ep.returnType) { fn in
                    fn.append(line: #"let url = URL(string: "\#(ep.path)")!"#)
                    fn.append(line: #"var request = URLRequest(url: url)"#)
                    fn.append(line: #"request.httpMethod = "\#(ep.method)""#)
                    fn.append(line: #"let (data, _) = try await URLSession.shared.data(for: request)"#)
                    fn.append(line: #"return try JSONDecoder().decode(\#(ep.returnType).self, from: data)"#)
                }
                if index < endpoints.count - 1 {
                    type.appendNewline()
                }
            }
        }

        let result = file.finalize()
        #expect(result == """
            import Foundation

            public class APIClient {
                public func fetchUsers() async throws -> [User] {
                    let url = URL(string: "/users")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    let (data, _) = try await URLSession.shared.data(for: request)
                    return try JSONDecoder().decode([User].self, from: data)
                }

                public func fetchPosts() async throws -> [Post] {
                    let url = URL(string: "/posts")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    let (data, _) = try await URLSession.shared.data(for: request)
                    return try JSONDecoder().decode([Post].self, from: data)
                }

                public func createUser() async throws -> User {
                    let url = URL(string: "/users")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    let (data, _) = try await URLSession.shared.data(for: request)
                    return try JSONDecoder().decode(User.self, from: data)
                }
            }

            """)
    }

    @Test func generateHierarchicalTypesFromTreeData() {
        struct TreeNode {
            let name: String
            let children: [TreeNode]
        }

        let tree = TreeNode(name: "Animal", children: [
            TreeNode(name: "Mammal", children: [
                TreeNode(name: "Dog", children: []),
                TreeNode(name: "Cat", children: []),
            ]),
            TreeNode(name: "Bird", children: [
                TreeNode(name: "Eagle", children: []),
                TreeNode(name: "Parrot", children: []),
            ]),
        ])

        func appendType<Kind: SwiftTypeBuilderKind>(from node: TreeNode, to type: inout SwiftTypeBuilder<Kind>) {
            for child in node.children {
                type.appendNestedType(accessLevel: .public, kind: .enum, name: child.name) { nested in
                    appendType(from: child, to: &nested)
                }
            }
        }

        var file = SwiftFileBuilder()
        file.appendType(accessLevel: .public, kind: .enum, name: tree.name) { type in
            appendType(from: tree, to: &type)
        }

        let result = file.finalize()
        #expect(result == """
            public enum Animal {
                public enum Mammal {
                    public enum Dog {
                    }
                    public enum Cat {
                    }
                }
                public enum Bird {
                    public enum Eagle {
                    }
                    public enum Parrot {
                    }
                }
            }

            """)
    }
}
