//
//  Configuration.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Allows to fetch a variable from the main Info.plist or override it
/// with a concrete value.
///
/// All of the standard data types present in the Plist format
/// are supported as well, plus the URL type that is converted from String
/// value.
///
/// The supported values conform to the `InfoPlistValueType` protocol.
/// You can conform your own types to this protocol.
///
/// Example usage:
///
///     struct Configuration {
///
///         @ConfigurationKey("TERMS_URL")
///         var termsURL: URL
///
///         @ConfigurationKey("RELAY_SERVICE_URL")
///         var relayServiceURL: URL
///
///     }
///
/// IMPORTANT: test your configuration values, otherwise the app will
/// crash if the value with the specified key is not found or if the value
/// cannot be converted to the supported type.
///
@propertyWrapper
struct ConfigurationKey<T: InfoPlistValueType> {
    private let key: String
    private var override: T?

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T {
        get {
            if let overriden = override { return overriden }
            guard let value = Bundle.main.object(forInfoDictionaryKey: key) else {
                preconditionFailure("Configuration key \(key) not found in the info dictionary")
            }
            return T.convert(from: value)
        }
        set {
            override = newValue
        }
    }

    private func transform(_ value: Any) -> T {
        if
                T.self == String.self ||
                T.self == Int.self ||
                T.self == Double.self ||
                T.self == Bool.self ||
                T.self == Date.self ||
                T.self == Data.self ||
                T.self == [String: Any].self ||
                T.self == [Any].self
        {
            return value as! T
        } else if T.self == URL.self {
            return URL(string: value as! String)! as! T
        } else {
            preconditionFailure("The configuration value type \(T.self) is not supported")
        }
    }

}

protocol InfoPlistValueType {

    /// Converts value from a plist object to the protocol's implementation type
    /// - Parameter value: a value from Info.plist dictionary
    static func convert(from value: Any) -> Self
}

extension URL: InfoPlistValueType {
    static func convert(from value: Any) -> URL {
        URL(string: value as! String)!
    }
}

extension String: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! String
    }
}

extension Int: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! Int
    }
}

extension Double: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! Double
    }
}

extension Bool: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! Bool
    }
}

extension Dictionary: InfoPlistValueType where Key == String, Value == Any {
    static func convert(from value: Any) -> Self {
        value as! [String: Any]
    }
}

extension Array: InfoPlistValueType where Element == Any {
    static func convert(from value: Any) -> Self {
        value as! [Any]
    }
}

extension Date: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! Date
    }
}

extension Data: InfoPlistValueType {
    static func convert(from value: Any) -> Self {
        value as! Data
    }
}
