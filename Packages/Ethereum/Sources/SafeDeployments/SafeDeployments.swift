//
//  File.swift
//
//
//  Created by Dmitry Bespalov on 04.01.22.
//

import Foundation
import Solidity

public enum Safe {}

extension Safe {
    public struct Deployment: Codable {
        public var defaultAddress: String
        public var version: String
        public var abi: Sol.Json.Contract
        public var networkAddresses: [String: String]
        public var contractName: String
        public var released: Bool

        public init(defaultAddress: String, version: String, abi: Sol.Json.Contract, networkAddresses: [String: String], contractName: String, released: Bool) {
            self.defaultAddress = defaultAddress
            self.version = version
            self.abi = abi
            self.networkAddresses = networkAddresses
            self.contractName = contractName
            self.released = released
        }
    }

    public enum ContractId: String, Codable {
        case GnosisSafe = "gnosis_safe"
        case GnosisSafeL2 = "gnosis_safe_l2"
        case CreateCall = "create_call"
        case CreateAndAddModules = "create_and_add_modules"
        case DefaultCallbackHandler = "default_callback_handler"
        case CompatibilityFallbackHandler = "compatibility_fallback_handler"
        case MultiSend = "multi_send"
        case MultiSendCallOnly = "multi_send_call_only"
        case ProxyFactory = "proxy_factory"
        case SignMessageLib = "sign_message_lib"
        case SimulateTxAccessor = "simulate_tx_accessor"
    }

    public enum Version: String, Codable {
        case v1_0_0 = "v1.0.0"
        case v1_1_1 = "v1.1.1"
        case v1_2_0 = "v1.2.0"
        case v1_3_0 = "v1.3.0"

        public var identifier: String {
            rawValue.replacingOccurrences(of: ".", with: "_")
        }
    }

    public enum ChainId: String, Codable, Hashable {
        case ethereum = "1"
        case ropstenTest = "3"
        case rinkebyTest = "4"
        case görli = "5"
        case optimism = "10"
        case bobaRinkebyTest = "28"
        case kovan = "42"
        case bsc = "56"
        case optimismTest = "69"
        case tomo = "88"
        case gnosis = "100"
        case fuse = "122"
        case fuseSparknet = "123"
        case polygon = "137"
        case ewc = "246"
        case boba = "288"
        case metisStardustTest = "588"
        case metisAndromeda = "1088"
        case moonriver = "1285"
        case moonbaseAlpha = "1287"
        case fantomTest = "4002"
        case arbitrumOne = "42161"
        case celo = "42220"
        case avalanche = "43114"
        case ewcVoltaTest = "73799"
        case polygonMumbaiTest = "80001"
        case polis = "333999"
        case aurora = "1313161554"
        case auroraTest = "1313161555"
    }
}

extension Safe.Deployment {
    // blocking, disk access, slow!
    public static func find(contract: Safe.ContractId, version: Safe.Version) throws -> Safe.Deployment? {
        guard let url = Bundle.module.url(forResource: contract.rawValue, withExtension: "json", subdirectory: "assets/\(version.rawValue)") else {
            // not found
            return nil
        }
        let data = try Data(contentsOf: url)
        let deployment = try JSONDecoder().decode(Safe.Deployment.self, from: data)
        return deployment
    }

    public func address(for chainId: String) -> Sol.Address? {
        let networkAddress = networkAddresses[chainId] ?? defaultAddress
        let result = Sol.Address(hex: networkAddress)
        return result
    }
}

