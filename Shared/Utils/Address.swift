//
//  Address.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Web3
import Foundation
import UIKit

struct Address: Hashable, ExpressibleByStringInterpolation, CustomStringConvertible, Identifiable {
    var prefix: String?
    fileprivate var _store: EthereumAddress

    init(exactly data: Data) {
        _store = try! EthereumAddress(data)
    }

    init?(_ data: Data) {
        guard let v = try? EthereumAddress(data) else { return nil }
        _store = v
    }

    init(exactly value: String) {
        _store = try! EthereumAddress(hex: value, eip55: false)
    }

    init?(_ value: String) {
        self.init(value, checksummed: false)
    }

    init?(_ value: String, checksummed: Bool) {
        var hexValue = value
        if hexValue.hasPrefix("0x") || hexValue.hasPrefix("0X") {
            hexValue.removeFirst(2)
        }
        var checkForEIP55 = checksummed
        if hexValue == hexValue.lowercased() || hexValue == hexValue.uppercased() {
            checkForEIP55 = false
        }
        guard let value = try? EthereumAddress(hex: hexValue, eip55: checkForEIP55) else { return nil }
        _store = value
    }

    init(from value: String) throws {
        _store = try EthereumAddress(hex: value, eip55: false)
    }

    init(exactly value: UInt256) {
        let data =  Data(ethHex: String(value, radix: 16)).endTruncated(to: 20).leftPadded(to: 20)
        self.init(exactly: data)
    }

    init?(_ value: UInt256) {
        let data = Data(ethHex: String(value, radix: 16)).endTruncated(to: 20).leftPadded(to: 20)
        guard let v = try? EthereumAddress(hex: data.toHexStringWithPrefix(), eip55: false) else { return nil }
        _store = v
    }
    
    init(_ ethereumAddress: EthereumAddress) {
        _store = ethereumAddress
    }

    var id: String {
        return checksummed
    }

    var checksummed: String {
        _store.hex(eip55: true)
    }

    var checksummedWithoutPrefix: String {
        String(checksummed.dropFirst(2))
    }

    var hexadecimal: String {
        _store.hex(eip55: false)
    }

    func ellipsized(prefix: Int = 6, suffix: Int = 4, checksummed: Bool = true) -> String {
        let value = checksummed ? self.checksummed : self.hexadecimal
        return value.prefix(prefix) + "…" + value.suffix(suffix)
    }

    var data: Data {
        Data(_store.rawAddress)
    }

    var data32: Data {
        Data(repeating: 0, count: 32 - data.count) + data
    }

    var count: Int {
        _store.rawAddress.count
    }

    static let zero = Self(exactly: Data(repeating: 0, count: 20))
    static let nativeCoin = Self.zero

    var isZero: Bool {
        self == .zero
    }

    init(stringLiteral value: StringLiteralType) {
        self.init(exactly: value)
    }

    var description: String {
        checksummed
    }

    var truncatedInMiddle: String {
        hexadecimal.prefix(6) + "…" + hexadecimal.suffix(4)
    }

    // This will check if ERC681 or EIP3770
    static func addressWithPrefix(text: String) throws -> Address {
        let (prefix, addressString) = addressWithPrefix(text)
        var address = try Address.init(from: addressString)
        address.prefix = prefix
        return address
    }

    static func addressWithPrefix(_ string: String) -> (prefix: String?, address: String) {
        var prefix: String?
        var withoutScheme: String
        let hexPrefix = "0x"
        let ethereumPayPrefix = "ethereum:pay-"
        let ethereumPrefix = "ethereum:"

        // We don't need to save the prefix of ERC681 for now, only the EIP3770
        if string.hasPrefix(ethereumPayPrefix) {
            withoutScheme = string.replacingOccurrences(of: ethereumPayPrefix, with: "")
        } else if string.hasPrefix(ethereumPrefix) {
            withoutScheme = string.replacingOccurrences(of: ethereumPrefix, with: "")
        } else if string.contains(":") {
            let components = string.components(separatedBy: ":")
            prefix = components.count == 2 ? components.first! : nil
            withoutScheme = components.last!
        } else {
            withoutScheme = string
        }

        let hasPrefix = withoutScheme.hasPrefix(hexPrefix)
        let withoutPrefix = hasPrefix ? String(withoutScheme.dropFirst(hexPrefix.count)) : withoutScheme
        let leadingHexChars = withoutPrefix.filter { (c) -> Bool in
            return !c.unicodeScalars.contains(where: { !CharacterSet.hexadecimals.contains($0)})
        }

        return (prefix, hexPrefix + leadingHexChars)
    }
}

extension EthereumAddress.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .addressMalformed:
            return "The address is malformed. Please provide an Ethereum address."
        case .checksumWrong:
            return "The address is typed incorrectly. Please double-check it."
        }
    }
}

// lowercased: 0xhex
// uppercased hex: 0xHEX
// uppercased all: 0XHEX
// checksum/eip-55: if not one of above

// has ":"? - can be eip-3770, caip-10, or eip-681 (either target or recipient when function is transfer.

// or it could be an ens name
// or it could be an UD name

// EIP-3770 chain-specific account identifiers
public struct Eip3770_AccountID {
    public var shortName: String
    public var address: String // eip-55 (mixed-case checksum encoded)

    init?(string: String) {
        let parts = string.split(separator: ":").map(String.init)
        guard parts.count == 2 else { return nil }
        shortName = parts[0]
        address = parts[1]
    }
}

// CAIP-2 Blockchain Identifier
// CA = ChainAgnostic
public struct Caip2_ChainID: Hashable {
    public var namespace: String
    public var reference: String

    public init?(string: String) {
        let regexPattern = "([-a-z0-9]{3,8}):([-a-zA-Z0-9]{1,32})"
        let parts = string.matches(pattern: regexPattern, string: string)
        guard parts.count == 2 else { return nil }
        namespace = parts[0]
        reference = parts[1]
    }

    public var string: String {
        "\(namespace):\(reference)"
    }

    public init(namespace: String, reference: String) {
        self.namespace = namespace
        self.reference = reference
    }
}

// CAIP-10 Account Identifier
public struct Caip10_AccountID {
    public var chainId: Caip2_ChainID
    public var address: String

    public init?(string: String) {
        let regexPattern = "([:-a-zA-Z0-9]{5,41}):([a-zA-Z0-9]{1,64})"
        let parts = string.matches(pattern: regexPattern, string: string)
        guard parts.count == 2 else { return nil }
        guard let chainId = Caip2_ChainID(string: parts[0]) else { return nil }
        self.chainId = chainId
        address = parts[1]
    }

    public init(chainId: Caip2_ChainID, address: String) {
        self.chainId = chainId
        self.address = address
    }
}

extension String {
    func matches(pattern: String, string: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        let parts = matches.map { result in
            result.range(at: 0)
        }.map { range in
            (string as NSString).substring(with: range)
        }
        return parts
    }
}

// EIP-681 URL for Transaction Requests
public struct Eip681_TransactionRequestURL {
    public var schema: String
    public var target: Eip681_TransactionRequestURL.Address
    public var chainId: String?
    public var functionName: String?
    public var parameters: [String: String] = [:]

    public enum Address {
        case address(String)
        case ensName(String)
    }

    public init?(string: String) {
        // (schema)(target)['@' chain]['/' function]['?' params]
        // schema = ethereum:[pay-]
        // target = eth_address
        // eth_address = address | ens
        // address = 0x\h{40}
        // ens = label | ens '.' label
        // label = '' or any valid domain string per uts46
        // chain = \d+
        // function = percent-encoded-string
        // params = param ['&' param]*
        // param = key'='value
        // key = value | gas | gasLimit | gasPrice | abiType
        // abiType = abi type name per abi spec
        // value = number | eth_address | percent-encoded-string
        // number = [[-+]] \d+ ['.' \d+] [[eE] \d+] (integer or scientific integer)

        let scanner = Scanner(string: string)

        // scan schema
        guard let prefix = scanner.scanString("ethereum:") else { return nil }
        schema = prefix

        if let pay = scanner.scanString("pay-") {
            schema += pay
        }

        // scan target address
            // try hex
        if let hexPrefix = scanner.scanString("0x") {
            if let hexDigits = scanner.scanCharacters(from: CharacterSet(charactersIn: "0123456789abcdefABCDEF")) {
                // must have exactly 40 digits

                guard hexDigits.count == 40 else {
                    // error
                    return nil
                }

                target = .address(hexPrefix + hexDigits)

            } else {
                // error
                return nil
            }
        // next delimiters
        } else if let ensString = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "@/?")) {
            // treat as ens, no validation performed
            target = .ensName(ensString)
        } else {
            // error
            return nil
        }

        // optional scan chain
        if scanner.scanString("@") != nil {
            if let digits = scanner.scanCharacters(from: CharacterSet.decimalDigits) {
                chainId = digits
            } else {
                // error
                return nil
            }
        }

        // optional scan function
        if scanner.scanString("/") != nil {
            if let function = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "?")) {
                functionName = function
            } else {
                // error
                return nil
            }
        }

        // optional scan params
        if scanner.scanString("?") != nil {

            let remaining = scanner.string[scanner.currentIndex...]

            let pairs = remaining.split(separator: "&").map(String.init)
                .map { $0.split(separator: "=").map(String.init) }
                .compactMap { pair -> (key: String, value: String)? in
                    guard pair.count == 2 else { return nil }
                    return (pair[0], pair[1])
                }
            parameters = Dictionary(uniqueKeysWithValues: pairs)
        }
    }

    public init(schema: String, target: Address, chainId: String? = nil, functionName: String? = nil, parameters: [String: String] = [:]) {
        self.schema = schema
        self.target = target
        self.chainId = chainId
        self.functionName = functionName
        self.parameters = parameters
    }

    public init(schema: String, address: String, chainId: String? = nil, functionName: String? = nil, parameters: [String: String] = [:]) {
        self.schema = schema
        self.target = .address(address)
        self.chainId = chainId
        self.functionName = functionName
        self.parameters = parameters
    }

    public init(schema: String, ens: String, chainId: String? = nil, functionName: String? = nil, parameters: [String: String] = [:]) {
        self.schema = schema
        self.target = .ensName(ens)
        self.chainId = chainId
        self.functionName = functionName
        self.parameters = parameters
    }
}
