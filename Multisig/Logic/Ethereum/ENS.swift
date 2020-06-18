//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import idn2Swift

enum ENSAPIServiceError: LocalizedError {
    case resolverNotFound
    case addressResolutionNotSupported
    case addressNotFound
    case resolvedNameNotMatchingOriginalAddress

    var errorDescription: String? {
        switch self {
        case .resolverNotFound:
            return "No resolver set for the record"
        case .addressResolutionNotSupported:
            return "Address resolving is not supported"
        case .addressNotFound:
            return "Address not found in the resolver"
        case .resolvedNameNotMatchingOriginalAddress:
            return "Resolved to the name which is not resolving to the address"
        }
    }

}

final class ENS {

    let registryAddress: Address

    init(registryAddress: String) {
        self.registryAddress = try! Address(hex: registryAddress, eip55: false)
    }

    init(registryAddress: Address) {
        self.registryAddress = registryAddress
    }

    func address(for name: String) throws -> Address {
        let node = try namehash(normalized(name))

        // get resolver
        let registry = ENSRegistry(registryAddress)
        let resolverAddress = try registry.resolver(node: node)
        if resolverAddress.isZero {
            throw ENSAPIServiceError.resolverNotFound
        }

        // resolve address
        let resolver = ENSResolver(resolverAddress)
        let isResolvingSupported = try resolver.supportsInterface(ENSResolver.Selectors.address)
        guard isResolvingSupported else {
            throw ENSAPIServiceError.addressResolutionNotSupported
        }
        let resolvedAddress = try resolver.address(node: node)
        if resolvedAddress.isZero {
            throw ENSAPIServiceError.addressNotFound
        }
        return resolvedAddress
    }

    func name(for address: Address) throws -> String? {
        // construct a reverse node
        let addressString = address.data.toHexString()
        let reverseName = addressString + ".addr.reverse"
        let node = try namehash(normalized(reverseName))

        // get resolver
        let registry = ENSRegistry(registryAddress)
        let resolverAddress = try registry.resolver(node: node)
        if resolverAddress.isZero {
            throw ENSAPIServiceError.resolverNotFound
        }

        let reverseResolver = ENSReverseResolver(resolverAddress)
        // resolve the name
        guard let resolvedASCIIName = try reverseResolver.name(node: node) else {
            return nil
        }
        let resolvedName = try IDN.asciiToUTF8(resolvedASCIIName)
        let resolvedAddress = try self.address(for: resolvedName)
        guard address == resolvedAddress else {
            throw ENSAPIServiceError.resolvedNameNotMatchingOriginalAddress
        }
        return resolvedName
    }

    typealias Node = Data

    func normalized(_ name: String) throws -> String {
        try IDN.utf8ToASCII(name, useSTD3ASCIIRules: true)
    }

    func namehash(_ name: String) -> Node {
        if name.isEmpty {
            return Data(repeating: 0, count: 32)
        } else {
            let parts = name.split(separator: ".", maxSplits: 1)
            let label = parts.count > 0 ? String(parts.first!) : ""
            let remainder = parts.count > 1 ? String(parts.last!) : ""
            return sha3(namehash(remainder) + sha3(label))
        }
    }

    private func sha3(_ string: String) -> Data {
        sha3(string.data(using: .utf8)!)
    }

    private func sha3(_ data: Data) -> Data {
        EthHasher.hash(data)
    }

}
