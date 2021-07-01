//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

final class ENS {

    let registryAddress: Address
    let rpcURL: URL

    init(registryAddress: String, rpcURL: URL) {
        self.registryAddress = Address(exactly: registryAddress)
        self.rpcURL = rpcURL
    }

    convenience init(registryAddress: Address, rpcURL: URL) {
        self.init(registryAddress: registryAddress.checksummed, rpcURL: rpcURL)
    }

    func address(for name: String) throws -> Address {
        let node: Node
        do {
            node = try namehash(normalized(name))
        } catch {
            throw GSError.ENSInvalidCharacters()
        }

        // get resolver
        let registry = ENSRegistry(registryAddress, rpcURL: rpcURL)
        let resolverAddress = try registry.resolver(node: node)
        if resolverAddress.isZero {
            throw GSError.ENSAddressNotFound()
        }

        // resolve address
        let resolver = ENSResolver(resolverAddress, rpcURL: rpcURL)
        let isResolvingSupported = try resolver.supportsInterface(ENSResolver.Selectors.address)
        guard isResolvingSupported else {
            throw GSError.ENSAddressNotFound()
        }
        let resolvedAddress = try resolver.address(node: node)
        if resolvedAddress.isZero {
            throw GSError.ENSAddressNotFound()
        }
        return resolvedAddress
    }

    func name(for address: Address) -> String? {
        // construct a reverse node
        let addressString = address.data.toHexString()
        let reverseName = addressString + ".addr.reverse"
        let registry = ENSRegistry(registryAddress, rpcURL: rpcURL)

        // get resolver
        guard let node = try? namehash(normalized(reverseName)),
              let resolverAddress = try? registry.resolver(node: node),
              !resolverAddress.isZero else { return nil }

        let reverseResolver = ENSReverseResolver(resolverAddress, rpcURL: rpcURL)
        // resolve the name
        guard let resolvedASCIIName = try? reverseResolver.name(node: node),
              let resolvedName = try? IDN.asciiToUTF8(resolvedASCIIName),
              let resolvedAddress = try? self.address(for: resolvedName),
              address == resolvedAddress else {
            return nil
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
