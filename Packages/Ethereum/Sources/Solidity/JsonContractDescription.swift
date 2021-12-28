//
//  JsonContractDescription.swift
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

    public struct ReceiveFunctionDescription: SolJsonDescription, Codable {
        public var type: DescriptionType
        public var stateMutability: StateMutability

        public init(type: Sol.Json.DescriptionType, stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.stateMutability = stateMutability
        }
    }

    public struct FallbackFunctionDescription: SolJsonDescription, Codable {
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

extension SolJsonDescription where Self: Encodable {
    func encode(container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }
}

extension SolJsonDescription where Self: Decodable {
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Self {
        try container.decode(Self.self)
    }
}

extension Sol.Json.ContractDescription: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for description in descriptions {
            if let d = description as? SolJsonDescription & Encodable {
                try d.encode(container: &container)
            }
        }
    }
}

extension Sol.Json.ContractDescription: Decodable {
    struct DescriptionHeader: Codable {
        var type: Sol.Json.DescriptionType

        var decodable: (SolJsonDescription & Decodable).Type {
            switch type {
            case .function:
                return Sol.Json.FunctionDescription.self
            case .event:
                return Sol.Json.EventDescription.self
            case .error:
                return Sol.Json.ErrorDescription.self
            case .constructor:
                return Sol.Json.ConstructorDescription.self
            case .fallback:
                return Sol.Json.FallbackFunctionDescription.self
            case .receive:
                return Sol.Json.ReceiveFunctionDescription.self
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let headers = try container.decode([DescriptionHeader].self)
        descriptions = []
        var array = try decoder.unkeyedContainer()
        for header in headers {
            let value = try header.decodable.decode(from: &array)
            descriptions.append(value)
        }
    }
}
