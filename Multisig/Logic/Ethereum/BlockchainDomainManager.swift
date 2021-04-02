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
    
    let ens: ENS;
    let resolution: Resolution;
    
    init() {
        ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e");
        self.resolution = try! Resolution();
    }
    
    func resolveUD(_ domain: String) throws -> Address {
        var address: String = "";
        var err: Error? = nil;
        
        let dispatchGroup = DispatchGroup();
        dispatchGroup.enter();
        resolution.addr(domain: domain, ticker: "eth") { result in
            switch result {
                case .success(let returnValue):
                    address = returnValue;
                case .failure(let error):
                  print("Expected btc Address, but got \(error)")
                  err = error;
          }
            dispatchGroup.leave();
        };
        dispatchGroup.wait();
        
        guard err == nil else {
            if (err is ResolutionError) {
                throw self.throwCorrectUdError(err as! ResolutionError, domain);
            }
            throw err!;
        }
        return Address(address)!;
    }
    
    func resolve(domain: String) throws -> Address {
        return domain.isUDdomain(domain) ? try self.resolveUD(domain) : try ens.address(for: domain);
    }
    
    func throwCorrectUdError(_ err: ResolutionError, _ domain: String) -> DetailedLocalizedError {
        switch err {
        case .unregisteredDomain:
            return GSError.BlockhainAddressNotFound()
        case .unspecifiedResolver:
            return GSError.UDResolverNotFound()
        default:
            return GSError.ThirdPartyError(
                reason: err.localizedDescription
            )
        }
    }
}

fileprivate extension String {
    func isUDdomain(_ target: String) -> Bool {
        return self.hasSuffix(".crypto") || self.hasSuffix(".zil")
    }
}
