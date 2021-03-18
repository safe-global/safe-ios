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
    
    init() {
        ens = ENS(registryAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e");
        
    
    }
    
    func resolve(domain: String) throws -> Address {
        if (domain.isUDdomain(domain))  {
            print("resolving unstoppable domain");
            guard let resolution = try? Resolution() else {
              print ("Init of Resolution instance with default parameters failed...")
                return "";
            }
            var address: String = "";
            resolution.addr(domain: "brad.crypto", ticker: "eth") { result in
              switch result {
              case .success(let returnValue):
                // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
                address = returnValue;
                
              case .failure(let error):
                print("Expected eth Address, but got \(error)")
              }
            }
            return Address(address)!;
        }
        return try ens.address(for: domain);
    }
    
}

fileprivate extension String {
    func isUDdomain(_ target: String) -> Bool {
        return self.hasSuffix(".crypto") || self.hasSuffix(".zil")
    }
}
