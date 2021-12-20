//
//  Json.swift
//  JsonRpc2
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import Foundation

// wrappers over basic json types in order to be able to encode and decode
// dynamic arrays or dictionaries in other types
// otherwise we have to know in advance concrete type fro decoding, which is possible
// but doesn't solve a situation when decoding of that concrete type fails
// and we still want to see what actual json we received.

public enum Json {
    public struct Object: Hashable {
        public var members: [String: Element]

        public init(members: [String: Element]) {
            self.members = members
        }
    }

    public struct Array: Hashable {
        public var elements: [Element]

        public init(elements: [Element]) {
            self.elements = elements
        }
    }

    public enum Element: Hashable {
        case object(Object)
        case array(Array)
        case string(String)
        case int(Int)
        case uint(UInt)
        case double(Double)
        case bool(Bool)
        case null
    }

    struct Key: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = String(intValue)
        }
    }
}

extension Json.Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        // for each case with associated value, encode the value directly
        switch self {
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .uint(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            // for null, encodeNil
            try container.encodeNil()
        }
    }
}

extension Json.Element: Decodable {
    public init(from decoder: Decoder) throws {
        // try decode primitve value
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            } else if let value = try? container.decode(Int.self) {
                self = .int(value)
                return
            } else if let value = try? container.decode(UInt.self) {
                self = .uint(value)
                return
            } else if let value = try? container.decode(Double.self) {
                self = .double(value)
                return
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
                return
            } else if container.decodeNil() {
                self = .null
                return
            } else {
                // not a single value, try something else.
            }
        }

        // try decoding object
        if (try? decoder.container(keyedBy: Json.Key.self)) != nil {

            let container = try decoder.singleValueContainer()
            self = try .object(container.decode(Json.Object.self))

        }
        // try decoding array
        else if (try? decoder.unkeyedContainer()) != nil {

            let container = try decoder.singleValueContainer()
            self = try .array(container.decode(Json.Array.self))

        }
        // default to null
        else {
            self = .null
        }
    }
}

extension Json.Object: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Json.Key.self)
        for (key, member) in members {
            if let codingKey = KeyedEncodingContainer<Json.Key>.Key(stringValue: key) {
                try container.encode(member, forKey: codingKey)
            }
        }
    }
}
extension Json.Object: Decodable {
    public init(from decoder: Decoder) throws {
        members = [:]
        let container = try decoder.container(keyedBy: Json.Key.self)
        for key in container.allKeys {
            let member = try container.decode(Json.Element.self, forKey: key)
            members[key.stringValue] = member
        }
    }
}

extension Json.Array: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for element in elements {
            try container.encode(element)
        }
    }
}

extension Json.Array: Decodable {
    public init(from decoder: Decoder) throws {
        elements = []
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            let element = try container.decode(Json.Element.self)
            elements.append(element)
        }
    }
}

// init from encodable
public protocol EncodableConvertible {
    init<T: Encodable>(value: T) throws
}

extension EncodableConvertible where Self: Decodable {
    // converts encodable value to the self assuming they encode to the same JSON elements
    public init<T: Encodable>(value: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}

// convert to Decodable
// converts to decodable type assuming that self and T has the same JSON elements
public protocol DecodableConvertible {
    func convert<T: Decodable>(to type: T.Type) throws -> T
}

extension DecodableConvertible where Self: Encodable {
    public func convert<T: Decodable>(to type: T.Type) throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let decoder = JSONDecoder()
        let value = try decoder.decode(type, from: data)
        return value
    }
}

// default implementation
extension Json.Element: EncodableConvertible, DecodableConvertible {}


// A way to encode and decode NSError to Json
extension Json {
    public struct NSError: Codable {
        var domain: String
        var code: Int
        var userInfo: Json.Object
    }
}

extension Json.NSError: JsonConvertible {
    public init(_ nsError: Foundation.NSError) {
        domain = nsError.domain
        code = nsError.code
        userInfo = Json.Object(
            members: Dictionary(uniqueKeysWithValues: nsError.userInfo.map({ (key: String, value: Any) -> (String, Json.Element) in
                // sometimes people extend String with Swift.Error, we don't want to encode that as NSError
                if let value = value as? String {
                    return (key, Json.Element(any: value))
                } else if let value = value as? Foundation.NSError {
                    // handle nexted NSError values
                    return (key, Json.Element(any: Json.NSError(value)))
                } else {
                    return (key, Json.Element(any: value))
                }
            }))
        )
    }


    public func nsError() -> NSError {
        NSError(domain: domain, code: code, userInfo: Dictionary(uniqueKeysWithValues: userInfo.members.map({ (key: String, value: Json.Element) -> (String, Any) in

            let resultValue = value.toAny()

            // handle nested NSError values
            if let object = resultValue as? [String: Any],
               let domain = object["domain"] as? String,
               let code = object["code"] as? Int,
               let userInfo = object["userInfo"] as? [String: Any] {
                return (key, Foundation.NSError(domain: domain, code: code, userInfo: userInfo) as Any)
            } else {
                return (key, resultValue)
            }
        })))
    }
}

// Allows to convert any value to Json element
public protocol JsonConvertible {
    func toJson() -> Json.Element
}

extension JsonConvertible where Self: Encodable {
    public func toJson() -> Json.Element {
        (try? Json.Element(value: self)) ?? .null
    }
}

// Allows to convert to and from Swift.Any erased type
public protocol AnyConvertible {
    func toAny() -> Any
    init(any value: Any)
}

// Convert to and from elements, including nested JsonConvertible values
extension Json.Element: AnyConvertible {
    public func toAny() -> Any {
        switch self {
        case .object(let object):
            return Dictionary(uniqueKeysWithValues: object.members.map { (key: String, value: Json.Element) in
                (key, value.toAny())
            })
        case .array(let array):
            return array.elements.map { $0.toAny() }
        case .string(let value):
            return value as Any
        case .int(let value):
            return value as Any
        case .uint(let value):
            return value as Any
        case .double(let value):
            return value as Any
        case .bool(let value):
            return value as Any
        case .null:
            return NSNull() as Any
        }
    }

    public init(any value: Any) {
        if let value = value as? Int {
            self = .int(value)
        } else if let value = value as? UInt {
            self = .uint(value)
        } else if let value = value as? Double {
            self = .double(value)
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? String {
            self = .string(value)
        } else if let value = value as? [Any] {
            self =  .array(Json.Array(elements: value.map(Json.Element.init(any:))))
        } else if let value = value as? [String: Any] {
            self =  .object(Json.Object(members: Dictionary(uniqueKeysWithValues: value.map { ($0, Json.Element(any: $1)) } )))
        } else if let value = value as? JsonConvertible {
            self = value.toJson()
        } else {
            self = .null
        }
    }
}
