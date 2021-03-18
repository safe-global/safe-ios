//
//  ZNS.swift
//  Resolution
//
//  Created by Serg Merenkov on 9/8/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class ZNS: CommonNamingService, NamingService {
    var network: String

    let registryAddress: String
    let registryMap: [String: String] = [
        "mainnet": "0x9611c53be6d1b32058b2747bdececed7e1216793"
    ]

    init(_ config: NamingServiceConfig) throws {

        guard let registryAddress = registryMap[config.network] else {
            throw ResolutionError.unsupportedNetwork
        }
        self.network = config.network

        self.registryAddress = registryAddress
        super.init(name: "ZNS", providerUrl: config.providerUrl, networking: config.networking)
    }

    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".zil")
    }

    func owner(domain: String) throws -> String {
        let recordAddresses = try self.recordsAddresses(domain: domain)
        let (ownerAddress, _ ) = recordAddresses
        guard Utillities.isNotEmpty(ownerAddress) else {
            throw ResolutionError.unregisteredDomain
        }

        return ownerAddress
    }

    func batchOwners(domains: [String]) throws -> [String?] {
        throw ResolutionError.methodNotSupported
    }

    func addr(domain: String, ticker: String) throws -> String {
        let key = "crypto.\(ticker.uppercased()).address"
        let result = try record(domain: domain, key: key)
        return result
    }

    func record(domain: String, key: String) throws -> String {
        let records = try self.records(keys: [key], for: domain)

        guard
            let record = records[key] else {
            throw ResolutionError.recordNotFound
        }

        return record
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        guard let records = try self.records(address: try resolver(domain: domain), keys: keys) as? [String: String] else {
            throw ResolutionError.recordNotFound
        }
        return records
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let recordAddresses = try self.recordsAddresses(domain: domain)
        let (_, resolverAddress ) = recordAddresses
        guard Utillities.isNotEmpty(resolverAddress) else {
            throw ResolutionError.unspecifiedResolver
        }

        return resolverAddress
    }

    // MARK: - CommonNamingService
    override func childHash(parent: [UInt8], label: [UInt8]) -> [UInt8] {
        return (parent + label.sha2(.sha256)).sha2(.sha256)
    }

    // MARK: - Helper functions

    private func recordsAddresses(domain: String) throws -> (String, String) {

        if !self.isSupported(domain: domain) {
            throw ResolutionError.unsupportedDomain
        }

        let namehash = self.namehash(domain: domain)
        let records = try self.records(address: self.registryAddress, keys: [namehash])

        guard
            let record = records[namehash] as? [String: Any],
            let arguments = record["arguments"] as? [Any], arguments.count == 2,
            let ownerAddress = arguments[0] as? String, let resolverAddress = arguments[1] as? String
        else {
            throw ResolutionError.unregisteredDomain
        }

        return (ownerAddress, resolverAddress)
    }

    private func records(address: String, keys: [String] = []) throws -> [String: Any] {
        let resolverContract: ContractZNS = self.buildContract(address: address)

        guard let records = try resolverContract.fetchSubState(
            field: "records",
            keys: keys
        ) as? [String: Any]
        else {
            throw ResolutionError.unspecifiedResolver
        }

        return records
    }

    func buildContract(address: String) -> ContractZNS {
        return ContractZNS(providerUrl: self.providerUrl, address: address.replacingOccurrences(of: "0x", with: ""), networking: networking)
    }
}
