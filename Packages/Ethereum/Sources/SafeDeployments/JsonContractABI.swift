//
//  JsonContractABI.swift
//  
//
//  Created by Mouaz on 8/8/22.
//

import Foundation
import Solidity

public protocol ContractABI: Codable {
    var contractName: String { get }
    var abi: Sol.Json.Contract { get }
}

public struct JsonContractABI: ContractABI {
    public var contractName: String
    public var abi: Sol.Json.Contract
    public static func find(contractName: String) throws -> JsonContractABI? {
        guard let url = Bundle.module.url(forResource: contractName,
                                          withExtension: "json",
                                          subdirectory: "assets/\(contractName)") else {
            // not found
            return nil
        }

        let data = try Data(contentsOf: url)
        let deployment = try JSONDecoder().decode(JsonContractABI.self, from: data)
        return deployment
    }
}
