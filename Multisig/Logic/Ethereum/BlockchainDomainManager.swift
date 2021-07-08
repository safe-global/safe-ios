//
//  BlockchainDomainManager.swift
//  Multisig
//
//  Created by Johnny Good on 1/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UnstoppableDomainsResolution

class BlockchainDomainManager {
    private(set) var ens: ENS?
    private(set) var unstoppableDomainResolution: Resolution?

    init(rpcURL: URL, networkName: String, ensRegistryAddress: String?) {
        if let string = ensRegistryAddress, let address = Address(string) {
            ens = ENS(registryAddress: address, rpcURL: rpcURL)
        }

        self.unstoppableDomainResolution = try? Resolution(
            configs: Configurations(
                cns: NamingServiceConfig(
                    providerUrl: rpcURL.absoluteString,
                    network: networkName.lowercased()
                )
            )
        )
    }
    
    func resolveUD(_ domain: String) throws -> Address {
        guard let resolution = unstoppableDomainResolution else {
            throw GSError.UDUnsupportedNetwork()
        }
        
        guard domain.hasSuffix(".crypto") || domain.hasSuffix(".zil") else {
            throw GSError.UDUnsuportedName()
        }

        var address: String = ""
        var resolutionError: Error? = nil
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        resolution.addr(domain: domain, ticker: "eth") { result in
            switch result {
                case .success(let returnValue):
                    address = returnValue
                case .failure(let error):
                  resolutionError = error
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        
        if let error = resolutionError as? ResolutionError {
          throw self.throwCorrectUdError(error, domain)
        } else if let error = resolutionError {
          throw error
        }

        return try Address(from: address)
    }
    
    func resolveEnsDomain(domain: String) throws -> Address {
        try ens!.address(for: domain)
    }

    func ensName(for address: Address) -> String? {
        ens!.name(for: address)
    }
    
    func throwCorrectUdError(_ error: ResolutionError, _ domain: String) -> DetailedLocalizedError {
        switch error {
        case .unregisteredDomain:
            return GSError.UDUnregisteredName()
        case .unspecifiedResolver:
            return GSError.UDResolverNotFound()
        default:
            return GSError.ThirdPartyError(
                reason: error.localizedDescription
            )
        }
    }
}
