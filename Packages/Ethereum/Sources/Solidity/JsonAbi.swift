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

public protocol SolJsonAbiType {
    var type: Sol.Json.TypeId { get }
}

// solidity compiler v0.7.6 - 0.8.11
extension Sol.Json {
    public struct Contract {
        public var abi: [SolJsonAbiType]
    }

    public struct Function: SolJsonAbiType, Codable {
        public var type: TypeId
        public var name: String
        public var inputs: [Variable]
        public var outputs: [Variable]
        public var stateMutability: StateMutability

        public init(type: Sol.Json.TypeId, name: String, inputs: [Sol.Json.Variable], outputs: [Sol.Json.Variable], stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.name = name
            self.inputs = inputs
            self.outputs = outputs
            self.stateMutability = stateMutability
        }
    }

    public struct Constructor: SolJsonAbiType, Codable {
        public var type: TypeId
        public var inputs: [Variable]
        public var stateMutability: StateMutability
        public init(type: Sol.Json.TypeId, inputs: [Sol.Json.Variable], stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.inputs = inputs
            self.stateMutability = stateMutability
        }
    }

    public struct Receive: SolJsonAbiType, Codable {
        public var type: TypeId
        public var stateMutability: StateMutability

        public init(type: Sol.Json.TypeId, stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.stateMutability = stateMutability
        }
    }

    public struct Fallback: SolJsonAbiType, Codable {
        public var type: TypeId
        public var stateMutability: StateMutability

        public init(type: Sol.Json.TypeId, stateMutability: Sol.Json.StateMutability) {
            self.type = type
            self.stateMutability = stateMutability
        }
    }

    public struct Event: SolJsonAbiType, Codable {
        public var type: TypeId
        public var name: String
        public var inputs: [Variable]
        public var anonymous: Bool
        public init(type: Sol.Json.TypeId, name: String, inputs: [Sol.Json.Variable], anonymous: Bool) {
            self.type = type
            self.name = name
            self.inputs = inputs
            self.anonymous = anonymous
        }
    }

    public struct Error: SolJsonAbiType, Codable {
        public var type: TypeId
        public var name: String
        public var components: [Variable]?
        public init(type: Sol.Json.TypeId, name: String, components: [Sol.Json.Variable]?) {
            self.type = type
            self.name = name
            self.components = components
        }
    }

    public enum TypeId: String, Codable {
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

    public struct Variable: Codable {
        public var name: String
        public var type: String
        public var components: [Variable]?
        public var indexed: Bool?

        public init(name: String, type: String, components: [Sol.Json.Variable]?, indexed: Bool? = nil) {
            self.name = name
            self.type = type
            self.components = components
            self.indexed = indexed
        }
    }
}

extension SolJsonAbiType where Self: Encodable {
    func encode(container: inout UnkeyedEncodingContainer) throws {
        try container.encode(self)
    }
}

extension SolJsonAbiType where Self: Decodable {
    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Self {
        try container.decode(Self.self)
    }
}

extension Sol.Json.Contract: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for description in abi {
            if let d = description as? SolJsonAbiType & Encodable {
                try d.encode(container: &container)
            }
        }
    }

    struct DescriptionHeader: Codable {
        var type: Sol.Json.TypeId

        var decodable: (SolJsonAbiType & Decodable).Type {
            switch type {
            case .function:
                return Sol.Json.Function.self
            case .event:
                return Sol.Json.Event.self
            case .error:
                return Sol.Json.Error.self
            case .constructor:
                return Sol.Json.Constructor.self
            case .fallback:
                return Sol.Json.Fallback.self
            case .receive:
                return Sol.Json.Receive.self
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let headers = try container.decode([DescriptionHeader].self)
        abi = []
        var array = try decoder.unkeyedContainer()
        for header in headers {
            let value = try header.decodable.decode(from: &array)
            abi.append(value)
        }
    }
}
