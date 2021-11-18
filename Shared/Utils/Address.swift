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
        guard let value = try? EthereumAddress(hex: value, eip55: false) else { return nil }
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
    static func addressWithPrefix(text: String) throws -> (prefix: String?, address: Address) {
        let (prefix, addressString) = addressWithPrefix(text)
        let address = try Address.init(from: addressString)
        return (prefix, address)
    }

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-681.md
    private static func addressFromERC681(_ address: String) -> String {
        let hexPrefix = "0x"
        let withoutScheme = address.replacingOccurrences(of: "ethereum:pay-", with: "").replacingOccurrences(of: "ethereum:", with: "")
        let hasPrefix = withoutScheme.hasPrefix(hexPrefix)
        let withoutPrefix = hasPrefix ? String(withoutScheme.dropFirst(hexPrefix.count)) : withoutScheme
        let leadingHexChars = withoutPrefix.filter { (c) -> Bool in
            return !c.unicodeScalars.contains(where: { !CharacterSet.hexadecimals.contains($0)})
        }

        return hexPrefix + leadingHexChars
    }

    private static func addressWithPrefix(_ string: String) -> (prefix: String?, address: String) {
        var prefix: String?
        var withoutScheme: String
        let hexPrefix = "0x"
        let ethereumPayPrefix = "ethereum:pay-"
        let ethereumPrefix = "ethereum:"

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
