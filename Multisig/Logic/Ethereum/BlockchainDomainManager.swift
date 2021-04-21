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
    
    let ens: ENS
    let resolution: Resolution?
    
    init() {
        ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
        self.resolution = try? Resolution(
            configs: Configurations(
                cns: NamingServiceConfig(
                    providerUrl: App.configuration.services.ethereumServiceURL.absoluteString,
                    network: App.configuration.app.network.rawValue.lowercased()
                )
            )
        )
    }
    
    func resolveUD(_ domain: String) throws -> Address {
        guard let resolution = resolution else {
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
        return try ens.address(for: domain)
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
