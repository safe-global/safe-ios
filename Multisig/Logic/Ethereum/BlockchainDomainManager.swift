//
//  BlockchainDomainManager.swift
//  Multisig
//
//  Created by Johnny Good on 1/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
class BlockchainDomainManager {
    
    let ens: ENS;
    
    init() {
        ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e");
    }
    
    func resolve(domain: String) throws -> Address {
        if (domain.isUDdomain(domain))  {
            print("resolving unstoppable domain")
        }
        return try ens.address(for: domain);
    }
    
}

fileprivate extension String {
    func isUDdomain(_ target: String) -> Bool {
        return self.hasSuffix(".crypto") || self.hasSuffix(".zil")
    }
}
