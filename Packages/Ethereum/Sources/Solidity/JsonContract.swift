//
//  File.swift
//
//
//  Created by Dmitry Bespalov on 28.12.21.
//

import Foundation

extension Sol {
    public enum Json {}
}

protocol SolJsonDescription {
    var type: Sol.Json.DescriptionType { get }
}

// solidity compiler v0.7.6 - 0.8.11
extension Sol.Json {
    public struct ContractDescription {
        var descriptions: [SolJsonDescription]
    }

    public struct FunctionDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var name: String
        public var inputs: [VariableDescription]
        public var outputs: [VariableDescription]
        public var stateMutability: StateMutability

        public init(type: Sol.Json.DescriptionType, name: String, inputs: [Sol.Json.VariableDescription], outputs: [Sol.Json.VariableDescription], stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.name = name
            self.inputs = inputs
            self.outputs = outputs
            self.stateMutability = stateMutability
        }
    }

    public struct ConstructorDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var inputs: [VariableDescription]
        public var stateMutability: StateMutability
        public init(type: Sol.Json.DescriptionType, inputs: [Sol.Json.VariableDescription], stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.inputs = inputs
            self.stateMutability = stateMutability
        }
    }

    public struct DefaultDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var stateMutability: StateMutability

        public init(type: Sol.Json.DescriptionType, stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.stateMutability = stateMutability
        }
    }

    public struct EventDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var name: String
        public var inputs: [EventVariableDescription]
        public var anonymous: Bool
        public init(type: Sol.Json.DescriptionType, name: String, inputs: [Sol.Json.EventVariableDescription], anonymous: Bool) {
            self.type = type
            self.name = name
            self.inputs = inputs
            self.anonymous = anonymous
        }
    }

    public struct ErrorDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var name: String
        public var components: [VariableDescription]?
        public init(type: Sol.Json.DescriptionType, name: String, components: [Sol.Json.VariableDescription]?) {
            self.type = type
            self.name = name
            self.components = components
        }
    }

    public enum DescriptionType: String, Codable {
        // functions
        case function
        case constructor
        case receive
        case fallback
        // event
        case event
        // error
        case error
    }

    public enum StateMutability: String, Codable {
        case pure
        case view
        case nonpayable
        case payable
    }

    public struct VariableDescription: Codable {
        public var name: String
        public var type: String
        public var components: [VariableDescription]?
        public init(name: String, type: String, components: [Sol.Json.VariableDescription]?) {
            self.name = name
            self.type = type
            self.components = components
        }
    }

    public struct EventVariableDescription: Codable {
        public var name: String
        public var type: String
        public var components: [VariableDescription]?
        public var indexed: Bool
        public init(name: String, type: String, components: [Sol.Json.VariableDescription]?, indexed: Bool) {
            self.name = name
            self.type = type
            self.components = components
            self.indexed = indexed
        }
    }
}

extension Sol.Json.ContractDescription: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for description in descriptions {
            switch description {
            case let value as Sol.Json.FunctionDescription:
                try container.encode(value)
            case let value as Sol.Json.ConstructorDescription:
                try container.encode(value)
            case let value as Sol.Json.DefaultDescription:
                try container.encode(value)
            case let value as Sol.Json.EventDescription:
                try container.encode(value)
            case let value as Sol.Json.ErrorDescription:
                try container.encode(value)
            default:
                break
            }
        }
    }
}

extension Sol.Json.ContractDescription: Decodable {
    struct DescriptionHeader: Codable {
        var type: Sol.Json.DescriptionType
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let headers = try container.decode([DescriptionHeader].self)
        descriptions = []
        var array = try decoder.unkeyedContainer()
        for header in headers {
            switch header.type {
            case .function:
                let value = try array.decode(Sol.Json.FunctionDescription.self)
                descriptions.append(value)
            case .constructor:
                let value = try array.decode(Sol.Json.ConstructorDescription.self)
                descriptions.append(value)
            case .fallback, .receive:
                let value = try array.decode(Sol.Json.DefaultDescription.self)
                descriptions.append(value)
            case .event:
                let value = try array.decode(Sol.Json.EventDescription.self)
                descriptions.append(value)
            case .error:
                let value = try array.decode(Sol.Json.ErrorDescription.self)
                descriptions.append(value)
            }
        }
    }
}
