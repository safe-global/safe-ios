//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 05.01.22.
//

import Foundation
import Solidity
import SafeDeployments

extension Safe.Deployment: ContractABI {}

struct Generator {
    var contract: ContractABI
    var contractNamePrefix: String = ""
    var contractNameSuffix: String = ""

    func generate() -> String {
        file(contract: contract)
    }

    func file(contract: ContractABI) -> String {
        let contract = self.contract(contract: contract)
        let result = Template.file
            .replacingOccurrences(of: "<#content#>", with: contract)
        return result
    }

    // contract
    func contract(contract: ContractABI) -> String {
        let abi = contract.abi.abi.filter { $0.type == .function }.map { $0 as! Sol.Json.Function }
        let members = functions(abi)
        let result = Template.contract
            .replacingOccurrences(of: "<#ContractName#>", with: contractName(from: contract.contractName))
            .replacingOccurrences(of: "<#Members#>", with: members)
        return result
    }

    func contractName(from baseName: String) -> String {
        contractNamePrefix + baseName + contractNameSuffix
    }

        // functions
    func functions(_ functions: [Sol.Json.Function]) -> String {
        functions.map(function(_:)).joined(separator: "\n\n")
    }
            // function
    func function(_ function: Sol.Json.Function) -> String {
        let functionBody = tupleBody(components: named(variables: function.inputs))
        let returns = tuple(
            Sol.Json.Variable(name: "Returns",
                              type: "",
                              components: named(variables: function.outputs),
                              indexed: nil)
        )
        let result = Template.function
            .replacingOccurrences(of: "<#FunctionName#>", with: function.name)
            .replacingOccurrences(of: "<#TupleBody#>", with: functionBody)
            .replacingOccurrences(of: "<#Returns#>", with: returns)
        return result
    }

    static let swiftKeywords = [
        "guard"
    ]

    func named(variables: [Sol.Json.Variable]) -> [Sol.Json.Variable] {
        variables.enumerated().map {
            if $0.element.name.isEmpty {
                var replacement = $0.element
                replacement.name = "_arg\($0.offset)"
                return replacement
            } else if Self.swiftKeywords.contains($0.element.name) {
                var replacement = $0.element
                replacement.name = "`\(replacement.name)`"
                return replacement
            }
            return $0.element
        }
    }

                // tuple body
    func tupleBody(components: [Sol.Json.Variable]) -> String {
        let tupleComponents = tupleComponents(components: components)
        let keyPaths = tupleKeyPaths(components: components)
        let memberwiseInit = memberwiseInit(components: components)
        let defaultInit = defaultInit(components: components)

        let result = Template.tupleBody
            .replacingOccurrences(of: "<#Components#>", with: tupleComponents)
            .replacingOccurrences(of: "<#KeyPaths#>", with: keyPaths)
            .replacingOccurrences(of: "<#MemberwiseInit#>", with: memberwiseInit)
            .replacingOccurrences(of: "<#DefaultInit#>", with: defaultInit)
        return result
    }
                    // components
    func tupleComponents(components: [Sol.Json.Variable]) -> String {
        components.map(tupleComponent(_:)).joined(separator: "\n")
    }
                        // component
    func tupleComponent(_ component: Sol.Json.Variable) -> String {
        Template.tupleComponent
            .replacingOccurrences(of: "<#name#>", with: component.name)
            .replacingOccurrences(of: "<#type#>", with: swiftType(for: component.type))
    }


    func swiftType(for solidityType: String) -> String {
        switch solidityType {
        case "string":
            return "Sol.String"
        case "bytes":
            return "Sol.Bytes"
        case "address":
            return "Sol.Address"
        case "uint8":
            return "Sol.UInt8"
        case "uint256":
            return "Sol.UInt256"
        case "int256":
            return "Sol.Int256"
        case "uint16":
            return "Sol.UInt16"
        case "uint64":
            return "Sol.UInt64"
        case "uint128":
            return "Sol.UInt128"
        case "bool":
            return "Sol.Bool"
        case "bytes4":
            return "Sol.Bytes4"
        case "bytes32":
            return "Sol.Bytes32"
        case "bytes32[]":
            return "Sol.Array<Sol.Bytes32>"
        case "address[]":
            return "Sol.Array<Sol.Address>"
        default:
            preconditionFailure("Unknown type: \(solidityType)")
        }
    }
                    // key paths
    func tupleKeyPaths(components: [Sol.Json.Variable]) -> String {
        let keyPaths = components.map(tupleKeyPath(_:)).joined(separator: ",\n")
        let result = Template.keyPaths
            .replacingOccurrences(of: "<#KeyPaths#>", with: keyPaths)
        return result
    }
                        // key path
    func tupleKeyPath(_ component: Sol.Json.Variable) -> String {
        Template.keyPath
            .replacingOccurrences(of: "<#name#>", with: component.name)
    }
                    // if has components: memberwise init
    func memberwiseInit(components: [Sol.Json.Variable]) -> String {
        if components.isEmpty {
            return ""
        }

        let arguments = components.map(memberwiseInitArgumentDeclaration(_:)).joined(separator: ", ")
        let body = components.map(memberInitExpression(_:)).joined(separator: "\n")
        let result = Template.initDeclaration
            .replacingOccurrences(of: "<#Arguments#>", with: arguments)
            .replacingOccurrences(of: "<#Body#>", with: body)
        return result
    }
                        // init declaration
    func memberwiseInitArgumentDeclaration(_ component: Sol.Json.Variable) -> String {
        Template.initDeclarationArgument
            .replacingOccurrences(of: "<#name#>", with: component.name)
            .replacingOccurrences(of: "<#internalname#>", with: "")
            .replacingOccurrences(of: "<#type#>", with: swiftType(for: component.type))
    }

    func memberInitExpression(_ component: Sol.Json.Variable) -> String {
        Template.memberInit
            .replacingOccurrences(of: "<#name#>", with: component.name)
            .replacingOccurrences(of: "<#value#>", with: component.name)
    }
                    // default init
    func defaultInit(components: [Sol.Json.Variable]) -> String {

        var body = ""
        if !components.isEmpty {
            let initArguments = components.map(memberwiseInitArgumentInvocation(_:)).joined(separator: ", ")
            let initInvocation = Template.memberFuncInvocation
                .replacingOccurrences(of: "<#receiver#>", with: "self")
                .replacingOccurrences(of: "<#func#>", with: "init")
                .replacingOccurrences(of: "<#args#>", with: initArguments)
            body = initInvocation
        }

        let result = Template.initDeclaration
            .replacingOccurrences(of: "<#Arguments#>", with: "")
            .replacingOccurrences(of: "<#Body#>", with: body)
        return result
    }
                        // if has components:
                            // call memberwise init
                                // invocation argument
    func memberwiseInitArgumentInvocation(_ component: Sol.Json.Variable) -> String {
        Template.initInvocationArgument
            .replacingOccurrences(of: "<#name#>", with: removingVarEscaping(from: component.name))
            .replacingOccurrences(of: "<#value#>", with: ".init()")
    }

    func removingVarEscaping(from name: String) -> String {
        name.replacingOccurrences(of: "`", with: "")
    }

                // returns
    func tuple(_ tuple: Sol.Json.Variable) -> String {
        let tupleBody = tupleBody(components: tuple.components ?? [])
        let result = Template.tuple
            .replacingOccurrences(of: "<#TupleName#>", with: tuple.name)
            .replacingOccurrences(of: "<#TupleBody#>", with: tupleBody)

        return result
    }
                    // tuple
                        // tuple body
}
