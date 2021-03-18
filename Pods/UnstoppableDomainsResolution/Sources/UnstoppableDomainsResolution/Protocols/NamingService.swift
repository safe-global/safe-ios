//
//  NamingService.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

protocol NamingService {
    var name: String { get }
    var network: String { get }
    var providerUrl: String { get }

    func namehash(domain: String) -> String
    func isSupported(domain: String) -> Bool

    func owner(domain: String) throws -> String
    func addr(domain: String, ticker: String) throws -> String
    func resolver(domain: String) throws -> String

    func batchOwners(domains: [String]) throws -> [String?]

    func record(domain: String, key: String) throws -> String
    func records(keys: [String], for domain: String) throws -> [String: String]
}
